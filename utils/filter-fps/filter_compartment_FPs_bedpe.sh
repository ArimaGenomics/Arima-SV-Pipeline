calls_file="$1"
output_dir="$2"
prefix="$3"

# Intersect calls file with compartments file using pairtopair -type both, write to overlaps.bedpe
bedtools pairtopair -a "$calls_file" -b ./recurring_compartment_regions_1Mb.bedpe -f 0.8 -type both > "$output_dir/${prefix}_overlaps.bedpe"

touch "$output_dir/${prefix}_overlaps_cut.bedpe"
touch "$output_dir/${prefix}_all_calls_annotated.bedpe"

if [ -s "$output_dir/${prefix}_overlaps.bedpe" ]; then
    # Overlap file is NOT empty
    # Remove extra columns
    cut -f1-6 "$output_dir/${prefix}_overlaps.bedpe" > "$output_dir/${prefix}_overlaps_cut.bedpe"
    # Go through each row of calls and annotate whether it's in overlaps_cut.bedpe and therefore a compartment FP
    awk 'NR==FNR {a[$0]; next} {print $0 "\t" (($0 in a) ? "FP-Compartment" : "Needs review")}' "$output_dir/${prefix}_overlaps_cut.bedpe" "$calls_file" > "$output_dir/${prefix}_all_calls_annotated.bedpe"
    rm "$output_dir/${prefix}_overlaps_cut.bedpe"
else
    # Overlap file is empty
    # Go through each row of calls and append 'Needs review'
    awk '{print $0 "\tNeeds review"}' "$calls_file" > "$output_dir/${prefix}_all_calls_annotated.bedpe"
fi

touch "$output_dir/${prefix}_FPs.bedpe"
touch "$output_dir/${prefix}_filtered_calls_7col.bedpe"

# Split up "$output_dir/${prefix}_all_calls_annotated.bedpe" into 2 files: one with FPs, one with calls needing review
awk -v fp_file="$output_dir/${prefix}_FPs.bedpe" -v nr_file="$output_dir/${prefix}_filtered_calls_7col.bedpe" '{if ($7 == "FP-Compartment") print > fp_file; else print > nr_file}' "$output_dir/${prefix}_all_calls_annotated.bedpe"

# Remove "Needs review" annotations from filtered calls file
cut -f1-6 "$output_dir/${prefix}_filtered_calls_7col.bedpe" > "$output_dir/${prefix}_filtered_calls.bedpe"

rm "$output_dir/${prefix}_overlaps.bedpe"
rm "$output_dir/${prefix}_filtered_calls_7col.bedpe"