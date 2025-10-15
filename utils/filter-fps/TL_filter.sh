calls_file="$1"
output_dir="$2"
prefix="$3"
CNV="$4"

# Intersect calls file with TAD/loop file using pairtopair -type both, write to overlaps.bedpe
bedtools pairtopair -a "$calls_file" -b ./loops_plus_loopified_TADs.bedpe -f 1.0 -type both > "$output_dir/${prefix}_overlaps.bedpe"

if [ -s "$output_dir/${prefix}_overlaps.bedpe" ]; then
    # Overlap file is NOT empty
    # Go through each row of calls and annotate whether it matches the first 6 entries in any row of overlaps_cut.bedpe and is therefore a TAD/loop FP
    awk '
  NR==FNR {
    key = $1 "\t" $2 "\t" $3 "\t" $4 "\t" $5 "\t" $6
    a[key]
    next
  }
  {
    key = $1 "\t" $2 "\t" $3 "\t" $4 "\t" $5 "\t" $6
    print $0 "\t" ((key in a) ? "FP-TAD_Loop" : "Needs review")
  }
' "$output_dir/${prefix}_overlaps.bedpe" "$calls_file" > "$output_dir/${prefix}_pre_CNV_decisions.bedpe"
else
    # Overlap file is empty, so no calls get removed
    #awk '{print $0 "\tNeeds review"}' "$calls_file" > "$output_dir/${prefix}_post_CNV_decisions.bedpe"
    rm "$output_dir/${prefix}_overlaps.bedpe"
    cp "$calls_file" "$output_dir/${prefix}_filtered_calls.bedpe"
    exit 0
fi

# Split calls file into initial FPs and TPs
awk -F'\t' '$7 == "FP-TAD_Loop"' "$output_dir/${prefix}_pre_CNV_decisions.bedpe" > "$output_dir/${prefix}_pre_CNV_FP_calls.bedpe"
awk -F'\t' '$7 == "Needs review"' "$output_dir/${prefix}_pre_CNV_decisions.bedpe" > "$output_dir/${prefix}_pre_CNV_TP_calls.bedpe"

# Keep only the first 6 columns of TP file
cut -f1-6 "$output_dir/${prefix}_pre_CNV_TP_calls.bedpe" > "$output_dir/${prefix}_TP_calls_6col.bedpe"

# Create an empty file for post-CNV FPs 
touch "$output_dir/${prefix}_FPs.bedpe"

## For each call in "$output_dir/${prefix}_pre_CNV_FP_calls.bedpe", run CNV check
while IFS=$'\t' read -r c1 c2 c3 c4 c5 c6 c7 rest; do
    temp="$output_dir/1call.bedpe"
    echo -e "$c1\t$c2\t$c3\t$c4\t$c5\t$c6${rest:+\t$rest}" > "$temp"
    ./CNV_check.sh "$temp" "$CNV" "$output_dir" "$prefix"
    # Remove 1call.bedpe
    if [[ -e "$temp" ]]; then
      rm "$temp"
    fi
done < "$output_dir/${prefix}_pre_CNV_FP_calls.bedpe"

# Now, "$output_dir/${prefix}_TP_calls_6col.bedpe" should have all of the non-TAD/loop calls from the original file
# And "$output_dir/${prefix}_FPs.bedpe" should have all of the maintained TAD/loop calls

# Rename filtered calls file
mv "$output_dir/${prefix}_TP_calls_6col.bedpe" "$output_dir/${prefix}_filtered_calls.bedpe"

# Remove unnecessary files
rm "$output_dir/${prefix}_overlaps.bedpe"
rm "$output_dir/${prefix}_pre_CNV_decisions.bedpe"
rm "$output_dir/${prefix}_pre_CNV_FP_calls.bedpe"
rm "$output_dir/${prefix}_pre_CNV_TP_calls.bedpe"
if [[ -e "$output_dir/temp.bedpe" ]]; then
  rm "$output_dir/temp.bedpe"
fi