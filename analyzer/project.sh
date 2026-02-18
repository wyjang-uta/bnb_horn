#!/bin/bash
in_dir="/exp/icarus/data/users/wyjang/share/data/sbn/sbnd/bnb_horn/run2"
out_dir="${in_dir}/projected"

for infile in "$in_dir"/*.root; do
  [ -e $infile ] || continue
  filename=$(basename $infile)
  outfile="${out_dir}/${filename}"
  echo "Processing: $filename ..."
  root -b -q -l "project_at_110m.C(\"$infile\", \"${outfile}\")"
done
echo "All jobs finished!"
