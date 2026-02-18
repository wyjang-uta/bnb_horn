#!/bin/bash
in_dir="/exp/icarus/data/users/wyjang/share/data/sbn/sbnd/bnb_horn/run5/projected"
out_dir="${in_dir}/plots"

mkdir -p $out_dir

for infile in "$in_dir"/*.root; do
  [ -e $infile ] || continue
  filename=$(basename $infile)
  outfile="${out_dir}/${filename}"
  echo "Processing: $filename ..."
  root -b -q -l "bnb_plot.C(\"$infile\", \"${outfile}\")"
done
echo "All jobs finished!"
