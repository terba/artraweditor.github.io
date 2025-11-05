#!/bin/bash

# Python interpreter to use
PYTHON=$HOME/src/ART-AI-venv/bin/python

# directory where SMART is located
SMART_DIR=$HOME/src/SMART

export PATH=$HOME/.local/bin:/opt/local/bin:/usr/local/bin:$PATH
ART_CLI=ART-cli

#############################################################################

# turn off cropping and modules coming later in the pipeline
d=$(mktemp -d)
t=$d/p1.arp
cat <<EOF > $t
[Version]
Version=1037

[Crop]
Enabled=false
EOF

# process the raw files with ART-cli, adding a progress dialog 
# for user notification
"${ART_CLI}" --progress $fast "${sidecar[@]}" -f -d -s -p $t -Y -j -o "$d/out.jpg" -c "$@" 2>"$d/error" \
    | zenity --width=500 --progress --auto-close --text="Exporting..."

# a non-zero exit status means the user cancelled the operation
if [ $? -ne 0 ]; then
    # if so, we just exit gracefully
    rm -rf $d
    exit 0
fi

# check if there was an error
err=
if [ ! -f "$d/out.jpg" ]; then
    err=$(cat "$d/error")
fi

if [ "$err" != "" ]; then
    # show the error message if something went wrong
    zenity --error --text="$err"
else
    outfile=${d}/out.jpg
    on="${1%.*}_SMART.jpg"
    i=1
    while [ -f "${on}" ]; do
        on="${1%.*}_SMART-${i}.jpg"
        i=$(expr $i + 1)
    done
    mv "${outfile}" "${on}"
    "${PYTHON}" "${SMART_DIR}/src/main.py" "${on}" &
fi

# remove the temporary dir
rm -rf $d
