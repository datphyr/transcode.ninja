#!/bin/bash

# hardcoded variables
#hcffmpegopts="-threads 16 -pix_fmt yuv420p -g 120 -maxrate 8M -bufsize 16M"
#hcffmpegopts="-threads 16 -pix_fmt yuv420p -g 120"
#hcffmpegopts="-threads 16 -pix_fmt yuv420p -g 120 -b:v 8M -minrate 8M -maxrate 8M -bufsize 16M"
#hcffmpegopts="-threads 16 -pix_fmt yuv420p -g 120 -minrate 8M"
#hcffmpegopts="-threads 16 -pix_fmt yuv420p"
#hcffmpegopts="-threads 16 -pix_fmt nv12"
hcffmpegopts="-pix_fmt nv12"
#hcx264opts="bitrate=8000:vbv-maxrate=8000:vbv-bufsize=16000"
hcx264opts="threads=16:nal-hrd=cbr:bitrate=8000:vbv-maxrate=8000:vbv-bufsize=16000:keyint=120"
#hcx264opts="nal-hrd=cbr"

# function to deduplicate x264 opts and also sort them
# - replace ':' with newlines
# - sort and uniq
# - replace newlines with ':'
# - fix possible ':' at start/end
function x264optsdedup { echo "$@" | sed 's/:/\n/g' | sort -uV | tr '\n' ':' | sed 's/:$//g; s/^://g' ;}

# function to deduplicate options in every encode
function encodesdedup {
  for encode in $@; do
    x264optsdedup "$encode"
    echo
  done
}

# check for input
if [[ ! $1 ]]; then
  echo "SYNTAX: $0 <video file> [encode list] [preset]"
  exit
fi

# read variables from input or use defaults
file=$1
filename=$(basename "$file")
encodelist=$2
#encodelist="${2:-encode.list}"
preset=${3:-veryfast}

# get encodes and sort them
encodes=$(cat lists/$encodelist)
if [[ ! $encodelist ]]; then
  encodelist="encode.list"
  encodes=$(cat $encodelist)
else
  encodes=$(cat lists/$encodelist)
fi

encodes=$(encodesdedup $encodes | sort -uV)
encodescount=$(echo "$encodes" | wc -l)

# print info
echo "        video file: $file"
echo "      encodes file: $encodelist"
echo "base   x264 preset: $preset"
echo "base   x264 params: $hcx264opts"
echo "base ffmpeg params: $hcffmpegopts"
echo
echo "$encodescount encodes:"
echo "$encodes" | nl -w3 -s'. '
echo

# encoding loop
echo "encoding ..."
for encode in $encodes; do
  #encode=$(x264optsdedup "$encode")
  x264opts=$(x264optsdedup "$hcx264opts:$encode")
  encodefile="$file.$preset.$encode.mkv"
  if [ ! -f "$encodefile" ] || [ ! -s "$encodefile" ]; then
    echo "       encoding $encodefile ..."
    ffmpeg -i $file -c:v libx264 -x264-params "$x264opts" -preset $preset $ffmpegopts -n $encodefile 2> logs/$filename.$preset.$encode.log
  else
    echo "already encoded $encodefile"
  fi
done | nl -w3 -s'. '

echo

# metrics loop
echo "computing metrics ..."
for encode in $encodes; do
  #encode=$(x264optsdedup "$encode")
  encodefile="$file.$preset.$encode.mkv"
  metricsfile="metrics/$filename.$preset.$encode.json"
  if [ ! -f "$metricsfile" ] || [ ! -s "$metricsfile" ]; then
    echo "       computing metrics at $metricsfile ..."
    ffmpeg_quality_metrics --metrics vmaf psnr ssim vif -t 16 "$encodefile" "$file" > $metricsfile
  else
    echo "metrics already computed at $metricsfile"
  fi
done | nl -w3 -s'. '
