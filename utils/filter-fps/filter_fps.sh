# Assign arguments to variables
calls_file_unmod="$1"
CNV_dir="$2"
out_dir="$3"
pref="$4"

# Cut columns beyond 6, & if there is a header, remove it
if head -n 1 "$calls_file_unmod" | grep -q '^#'; then
    tail -n +2 "$calls_file_unmod" | cut -f1-6 > "$out_dir/${pref}_calls.bedpe"
else
    cut -f1-6 "$calls_file_unmod" > "$out_dir/${pref}_calls.bedpe"
fi

# Make output subfolders for each script output
mkdir "$out_dir/mapp-filter"
mkdir "$out_dir/comp-filter"
mkdir "$out_dir/tl-filter"

# Run mappability filter
./filter_mappability_FPs.sh "$out_dir/${pref}_calls.bedpe" "$out_dir/mapp-filter" "$pref"
# Output folder "$out_dir/mapp-filter/" contains files "${pref}_filtered_calls.bedpe", "${pref}_FPs.bedpe" & "${pref}_all_calls_annotated.bedpe"

# Run compartment filter
./filter_compartment_FPs_bedpe.sh "$out_dir/${pref}_calls.bedpe" "$out_dir/comp-filter" "$pref"
# Output folder "$out_dir/comp-filter/" contains files "${pref}_filtered_calls.bedpe", "${pref}_FPs.bedpe" & "${pref}_all_calls_annotated.bedpe"

# Run TAD/Loop filter
./TL_filter.sh "$out_dir/${pref}_calls.bedpe" "$out_dir/tl-filter" "$pref" "$CNV_dir"
# Output folder "$out_dir/tl-filter/" contains files "${pref}_filtered_calls.bedpe" & "${pref}_FPs.bedpe"

# Generate filtered calls file: if a call exists in all 3 filtered calls files, 
# i.e. it wasn't removed by any of them, retain that call
sort "$out_dir/${pref}_calls.bedpe" > "$out_dir/${pref}_calls_sorted.bedpe"
sort "$out_dir/mapp-filter/${pref}_filtered_calls.bedpe" > "$out_dir/mapp-filter/${pref}_filtered_calls_sorted.bedpe"
sort "$out_dir/comp-filter/${pref}_filtered_calls.bedpe" > "$out_dir/comp-filter/${pref}_filtered_calls_sorted.bedpe"
sort "$out_dir/tl-filter/${pref}_filtered_calls.bedpe" > "$out_dir/tl-filter/${pref}_filtered_calls_sorted.bedpe"

comm -12 "$out_dir/${pref}_calls_sorted.bedpe" "$out_dir/mapp-filter/${pref}_filtered_calls_sorted.bedpe" > "$out_dir/${pref}_temp1.bedpe"
comm -12 "$out_dir/${pref}_temp1.bedpe" "$out_dir/comp-filter/${pref}_filtered_calls_sorted.bedpe" > "$out_dir/${pref}_temp2.bedpe"
comm -12 "$out_dir/${pref}_temp2.bedpe" "$out_dir/tl-filter/${pref}_filtered_calls_sorted.bedpe" > "$out_dir/${pref}_calls_filtered_all.bedpe"

# Set of retained calls in "$out_dir/${pref}_calls_filtered_all.bedpe"
# Sort calls and add a header
sort -k1,1 -k4,4 -k2,2 -k5,5 "$out_dir/${pref}_calls_filtered_all.bedpe" > "$out_dir/${pref}_calls_filtered_all.sorted.bedpe"
(echo -e "#chr1\tx1\tx2\tchr2\ty1\ty2"; cat "$out_dir/${pref}_calls_filtered_all.sorted.bedpe") > "$out_dir/${pref}_calls_filtered.bedpe"

# Remove individual filter outputs
rm -r "$out_dir/mapp-filter"
rm -r "$out_dir/comp-filter"
rm -r "$out_dir/tl-filter"

# Remove all other intermediate files
rm "$out_dir/${pref}_calls.bedpe"
rm "$out_dir/${pref}_calls_sorted.bedpe"
rm "$out_dir/${pref}_temp1.bedpe"
rm "$out_dir/${pref}_temp2.bedpe"
rm "$out_dir/${pref}_calls_filtered_all.bedpe"
rm "$out_dir/${pref}_calls_filtered_all.sorted.bedpe"