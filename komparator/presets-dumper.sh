#!/bin/bash

# algo:
# - get list of presets
# - for each preset:
#   - encode dummy file
#   - get encoder settings from resulted file

# get presets list from x264 help
presets=$(x264 --help | grep -e '--preset <string>' -A3 | grep -e '- ' | sed 's/ *- //g' | sed 's/,/\n/g')

# for each preset
for preset in $presets; do
  echo $preset

  # generate test file
  #ffmpeg -f lavfi -i testsrc=duration=10:size=1920x1080:rate=60 -c:v libx264 -preset $preset -crf 16 -pix_fmt yuv420p -y output/$preset.mkv 2> logs/$preset.log
  ffmpeg -f lavfi -i color -t 1 -c:v libx264 -preset $preset -crf 16 -pix_fmt yuv420p -threads 1 -y output/$preset.mkv 2> logs/$preset.log

  # grab encoder settings from resulted test file
  # actually you can grab this info during encoding, but ..
  mediainfo output/$preset.mkv | grep 'Encoding settings' | sed 's/.*: //g' | sed 's/\/ /\n/g' | sort > presets/$preset

done
