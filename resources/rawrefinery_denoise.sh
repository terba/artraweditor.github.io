#!/bin/bash

# select the device to use for denoising (cuda, mps, cpu, ...)
DEVICE=mps

# Python interpreter to use
PYTHON=$HOME/src/RawRefinery-venv/bin/python

export PATH=$HOME/.local/bin:/opt/local/bin:/usr/local/bin:$PATH

#############################################################################
# create a temporary dir for storing intermediate files

# create the python script
d=$(mktemp -d)
t=$d/rr.py
cat <<EOF > $t
import argparse
import os
import sys
import time
import subprocess
import numpy
import json
from RawRefinery.application.ModelHandler import (
    ModelController, MODEL_REGISTRY, InferenceWorker
)
from RawHandler.RawHandler import CoreRawMetadata
from PySide6.QtCore import Slot


def getopts():
    p = argparse.ArgumentParser()
    p.add_argument('input')
    p.add_argument('output')
    models = sorted(MODEL_REGISTRY.keys())
    p.add_argument('--model', choices=models, default='Tree Net Denoise')
    p.add_argument('--device', default='cpu')
    p.add_argument('--exiftool')
    def get_iso(s):
        s = s.lower()
        return int(s) if s != 'auto' else s
    p.add_argument('--iso', type=get_iso)
    def get_strength(s):
        v = int(s)
        if not (0 < v <= 50):
            raise ValueError("invalid strength value")
        return v / 10.0
    p.add_argument('--strength', type=get_strength, default="10")
    return p.parse_args()

def main():
    opts = getopts()
    controller = ModelController()
    controller.set_device(opts.device)
    controller.load_model(opts.model)
    print("1", flush=True)

    controller.colorspace = 'camera'

    iso = controller.load_rh(opts.input)
    print("2", flush=True)

    if opts.iso is not None:
        if opts.iso == 'auto':
            if opts.exiftool:
                res = subprocess.run([opts.exiftool, '-json', opts.input],
                                     stdout=subprocess.PIPE, check=True,
                                     text=True)
                data = json.loads(res.stdout)[0]
                try:
                    v = data['ISO']
                    if isinstance(v, str) and v.startswith('Hi '):
                        v = v[3:]
                    iso = int(v)
                except (KeyError, ValueError) as e:
                    pass
                iso = int(round(iso * float(data.get('ScaleFactor35efl', 1))))
            print(f'auto iso set to: {iso}')
        else:
            iso = opts.iso
    iso *= opts.strength

    controller.rh.colorspace = 'camera'
    md = controller.rh.core_metadata
    controller.rh.core_metadata = CoreRawMetadata(
        md.black_level_per_channel,
        md.white_level,
        numpy.eye(3),
        md.raw_pattern,
        md.camera_white_balance,
        md.iheight,
        md.iwidth)
    def rgb_colorspace_transform(*args, **kwds):
        return numpy.array(
            [
                [1.0, 0.0, 0.0],
                [0.0, 1.0, 0.0],
                [0.0, 0.0, 1.0],
            ]
        )
    controller.rh.rgb_colorspace_transform = rgb_colorspace_transform
    
    conditioning = [iso, 0]

    @Slot(float)
    def on_progress(val):
        print(str(2 + int(98 * val)), flush=True)

    @Slot(str)
    def on_error(msg):
        for line in msg.splitlines():
            sys.stderr.write(f'ERROR: {line}\n')
        sys.stderr.flush()
        sys.exit(0)

    controller.filename = opts.output
    controller.save_cfa = True
    controller.start_time = time.perf_counter()
    w = InferenceWorker(controller.model, 
                        controller.model_params,
                        controller.device, controller.rh, conditioning, None)
    w.finished.connect(controller.handle_full_image)
    w.progress.connect(on_progress)
    w.error.connect(on_error)
    w.run()
    if opts.exiftool and os.path.exists(opts.output):
        subprocess.run([opts.exiftool, '-TagsFromFile', opts.input, opts.output,
                        '-all', '-icc_profile', '-overwrite_original'])

if __name__ == '__main__':
    main()
EOF

$PYTHON "${d}/rr.py" \
        --device $DEVICE \
        "$1" "${d}/out.dng" \
        --exiftool exiftool \
        --iso auto \
    | zenity --progress --auto-kill --auto-close --text="Denoising..."

# check if there was an error
err=
if [ -f "$d/error" ]; then
    err=$(cat "$d/error" | awk '/ERROR:/ { $1=""; print $0 }' | sed 's/^ //g')
fi

if [ "$err" != "" ]; then
    # show the error message if something went wrong
    zenity --error --text="$err"
elif [ -f "${d}/out.dng" ]; then
    on="${1%.*}-denoised.dng"
    i=1
    while [ -f "${on}" ]; do
        on="${1%.*}-denoised-${i}.dng"
        i=$(expr $i + 1)
    done
    mv "${d}/out.dng" "${on}"
    # finally, use the same sidecar for the denoise image as for the
    # original image, except that we override WB and denoising settings
    if [ -f "$1.arp" ]; then
        cp "$1.arp" "${on}.arp"
        cat <<EOF >> "${on}.arp"

[Impulse Denoising]
Enabled=false

[Denoise]
Enabled=false
EOF
    fi
else
    zenity --error --text="Denoising error!"
fi

# remove the temporary dir
rm -rf $d
