#!/bin/bash

# read input
metricsmask="*$1*"

# get metrics and process them in loop
metrics=$(ls metrics/$metricsmask.json)
for metricfile in $metrics; do
  # get encode file and therefore logname
  encode=$(echo "$(basename $metricfile)" | sed 's/.json$//g')
  logfile="logs/$encode.log"

  # extract data from log
  log=$(cat "$logfile")
  logstats=$(echo "$log" | sed -e 's/\r/\n/g' | grep 'frame=.* fps=.* bitrate=.*' | tail -n1)
  fps=$(echo "$logstats" | sed -e 's/.*fps=\(.*\).*$/\1/' | awk '{print $1}')
  bitrate=$(echo "$logstats" | sed -e 's/.*bitrate=\(.*\).*$/\1/' | awk '{print $1}' | sed 's/kbits\/s//g')
  options=$(echo "$log" | grep ' options: ' | sed 's/.* options: //g; s/,/;/g; s/ threads=[^ ]*//g; s/ lookahead_threads=[^ ]*//g')

  # extract metrics from metricsfile
  metricvalues=$(cat $metricfile | jq -r '.global | .vmaf.stdev,.vmaf.min,.vmaf.average,.vmaf.median,.vmaf.max,.psnr.stdev,.psnr.min,.psnr.average,.psnr.median,.psnr.max,.ssim.stdev,.ssim.min,.ssim.average,.ssim.median,.ssim.max,.vif.stdev,.vif.min,.vif.average,.vif.median,.vif.max' | tr '\n' ',' | sed 's/,$//g')

  # form a line for .csv export
  #echo "$encode,$fps,$bitrate,$metricvalues"
  echo "$(echo $encode | sed 's/,/;/g'),$fps,$bitrate,$metricvalues,$options"

done
