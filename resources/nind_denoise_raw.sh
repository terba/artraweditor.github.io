#!/bin/bash

# select the device to use for denoising (cuda, mps, cpu, ...)
DEVICE=mps

# Python interpreter to use
PYTHON=$HOME/src/ART-AI-venv/bin/python

# directory where nind-denoise is located
NIND_DENOISE_DIR=$HOME/src/nind-denoise

export PATH=$HOME/.local/bin:/opt/local/bin:/usr/local/bin:$PATH
ART_CLI=ART-cli

#############################################################################

# create a temporary dir for storing a default processing profile
# and error information

# create an .arp sidecar with a custom output profile and settings
# suitable for denoising
d=$(mktemp -d)
t=$d/p1.arp
cat <<EOF > $t
[Version]
Version=1037

[Color Management]
OutputProfile=RTv4_Rec2100_PQ

[ToneCurve]
Enabled=false

[Sharpening]
Enabled=false

[OutputSharpening]
Enabled=false

[SoftLight]
Enabled=false

[Film Simulation]
Enabled=false

[Smoothing]
Enabled=false

[TextureBoost]
Enabled=false

[Denoise]
Enabled=false

[Resize]
Enabled=false

[RAW Bayer]
Method=lmmse

[RAW X-Trans]
Method=3-pass (best)
EOF

if [ -f "$1.arp" ]; then
    # if the selected file has a sidecar, we are going to use (some parameters
    # of) that (except that we override some of the settings, see above)
    cat "$1.arp" | awk 'BEGIN {p=0} /\[(White Balance|RAW|Exposure)/ {p=1; print; next} /\[/ { p=0; next } { if (p) print }' > "$d/p2.arp"
    sidecar=("-p" "$d/p2.arp")
else
    # if the selected file has no sidecar, we create a default one 
    sidecar=()
    cat <<EOF >> $t
[Exposure]
HLRecovery=Balanced

[ToneCurve]
Enabled=false

[RAW]
CAEnabled=true
CA=true
CAAvoidColourshift=true
CAAutoIterations=2
HotDeadPixelEnabled=true
HotPixelFilter=true
DeadPixelFilter=true
HotDeadPixelThresh=100
EOF
fi

# process the raw files with ART-cli, adding a progress dialog 
# for user notification
"${ART_CLI}" --progress "${sidecar[@]}" -p $t -Y -t -b16 -o "$d/out.tif" -c "$@" 2>"$d/error" \
    | zenity --width=500 --progress --auto-close --text="Converting to TIFF..."

# a non-zero exit status means the user cancelled the operation
if [ $? -ne 0 ]; then
    # if so, we just exit gracefully
    rm -rf $d
    exit 0
fi

# check if there was an error
err=
if [ -f "$d/error" ]; then
    err=$(cat "$d/error")
fi

if [ "$err" != "" ]; then
    # show the error message if something went wrong
    zenity --error --text="$err"
else
    err=""
    # otherwise, let's denoise
    ifile=${d}/out.tif
    outfile=${d}/denoised.tif

    # model to use
    DENOISE_MODEL=$NIND_DENOISE_DIR/models/nind_denoise/2019-02-18T20:10_run_nn.py_--time_limit_259200_--batch_size_94_--test_reserve_ursulines-red_stefantiek_ursulines-building_MuseeL-Bobo_CourtineDeVillersDebris_MuseeL-Bobo-C500D_--skip_sizecheck_--lr_3e-4/model_257.pth

    ("$PYTHON" "${NIND_DENOISE_DIR}/src/nind_denoise/denoise_image.py" \
             --network UNet \
             --model_path "${DENOISE_MODEL}" \
             --device $DEVICE \
             --cs 512 \
             --ucs 400 \
             --input "${ifile}" \
             -o "${outfile}" \
             2>&1) | zenity --progress --text="Denoising..." --pulsate --auto-kill --auto-close
    res=$?
    on="${1%.*}-denoised.tif"
    i=1
    while [ -f "${on}" ]; do
        on="${1%.*}-denoised-${i}.tif"
        i=$(expr $i + 1)
    done
    if [ $res -eq 0 ]; then
        mv "${outfile}" "${on}"
        # finally, use the same sidecar for the denoise image as for the
        # original image, except that we override WB and denoising settings
        if [ -f "$1.arp" ]; then
            cp "$1.arp" "${on}.arp"
            cat <<EOF >> "${on}.arp"

[Exposure]
Enabled=false

[White Balance]
Enabled=true
Setting=Camera

[Impulse Denoising]
Enabled=false

[Denoise]
Enabled=false
EOF
        fi
    else
        zenity --error --text="Denoising error!"
    fi
fi

# remove the temporary dir
rm -rf $d
