from pyffi.formats.nif import NifFormat
from pathlib import Path

import os
import shutil

root_in = "./reduce_animation_speed_input"
root_out = "./reduce_animation_speed_output"


def reduce_speed(animation, output):
    stream = open(animation, 'rb')
    wstream = open(output, 'wb')

    data = NifFormat.Data()

    data.read(stream)

    for root in data.roots:
        for block in root.tree():
            if isinstance(block, NifFormat.NiTextKeyExtraData):
                for key in block.text_keys:
                    key.time = key.time / 2
            if isinstance(block, NifFormat.NiKeyframeController):
                block.start_time = block.start_time / 2
                block.stop_time = block.stop_time / 2
            if isinstance(block, NifFormat.NiKeyframeData):
                for key in block.quaternion_keys:
                    key.time = key.time / 2
                for key in block.translations.keys:
                    key.time = key.time / 2

    data.write(wstream)


shutil.rmtree(root_out, ignore_errors=True)

for subdir, dirs, files in os.walk(root_in):
    for file in files:
        animation = os.path.join(subdir, file)
        path = os.path.relpath(animation, root_in)
        Path(root_out + "/" + os.path.dirname(path)).mkdir(
            parents=True, exist_ok=True
        )
        print("Processning: " + animation)
        reduce_speed(animation, os.path.join(root_out, path))
