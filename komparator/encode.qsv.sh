#!/bin/bash

# haxx
# we have ffmpeg 5 build for windows so lets use it to encode
function ffmpeg {
  /mnt/d/Garbage/ffmpeg/ffmpeg-5.0.1-full_build/bin/ffmpeg.exe "$@"
}

# hardcoded variables
hcffmpegopts="-pix_fmt nv12"

# check for input
if [[ ! $1 ]]; then
  echo "SYNTAX: $0 <video file> [encode list]"
  exit
fi

# read variables from input or use defaults
file=$1
filename=$(basename "$file")
filewin=$(wslpath -w $file)
encodelist=${2:-*}

encodes=$(cat lists/qsv/$encodelist | sort -uV)
encodescount=$(echo "$encodes" | wc -l)

# print info
echo "        video file: $file"
echo "      encodes file: $encodelist"
echo "base ffmpeg params: $hcffmpegopts"
echo
echo "$encodescount encodes:"
echo "$encodes" | nl -w3 -s'. '
echo

# encoding loop
echo "encoding ..."
while read encode; do
  suffix=$(echo "$encode" | sed 's/ /_/g')
  encodefile="$file.qsv.$suffix.mkv"
  encodefilewin="$filewin.qsv.$suffix.mkv"
  if [ ! -f "$encodefile" ] || [ ! -s "$encodefile" ]; then
    echo "       encoding $encodefile ..."
    ffmpeg -i $filewin -c:v h264_qsv $encode $hcffmpegopts -n $encodefilewin 2> logs/$filename.qsv.$suffix.log
  else
    echo "already encoded $encodefile"
  fi
done <<< "$encodes"
# | nl -w3 -s'. '

echo

# metrics loop
echo "computing metrics ..."
while read encode; do
  suffix=$(echo "$encode" | sed 's/ /_/g')
  encodefile="$file.qsv.$suffix.mkv"
  metricsfile="metrics/$filename.qsv.$suffix.json"
  if [ ! -f "$metricsfile" ] || [ ! -s "$metricsfile" ]; then
    echo "       computing metrics at $metricsfile ..."
    ffmpeg_quality_metrics --metrics vmaf psnr ssim vif -t 16 "$encodefile" "$file" > $metricsfile
  else
    echo "metrics already computed at $metricsfile"
  fi
done <<< "$encodes"
# | nl -w3 -s'. '
