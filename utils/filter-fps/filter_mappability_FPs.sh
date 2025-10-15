#!/bin/bash

#########################################################
#
# Usage 
#
#########################################################

# ./filter_mappability_FPs.sh <SV_CALLS.bedpe> <OUTPUT_DIR> <OUTPUT_PREFIX>

# Intersect BEDPE SV calls and BED low coverage regions files, write result to a new file intersections.bedpe
# IG + TCR regions BED file must be the extended version created in step 5 of extraction script

#########################################################
#
#  Assign arguments to variables
#
#########################################################

calls_file="$1"
output_dir="$2"
prefix="$3"

# Create empty files for splitting up calls
touch "$output_dir/${prefix}_intra_calls.bedpe"
touch "$output_dir/${prefix}_inter_calls.bedpe"

# Set filepath variables
intra_filepath="$output_dir/${prefix}_intra_calls.bedpe"
inter_filepath="$output_dir/${prefix}_inter_calls.bedpe"

# Go through each entry in SAMPLE_merged_filtered.bedpe
    # If intrachromosomal:
        # If coordinate pairs are within 2Mb of each other, add to intra_calls.bedpe (without extra cols)
        # If not, add to inter_calls.bedpe (without extra cols)
    # If interchromosomal:
        # Add to inter_calls.bedpe (without extra cols)
awk -v intra="$intra_filepath" -v inter="$inter_filepath" 'BEGIN {OFS="\t"} {
    if ($1 == $4) {
        distance = ($3 > $6) ? $3 - $6 : $6 - $3;
        if (distance <= 2000000) {
            print $0 > intra;
        } else {
            print $0 > inter;
        }
    } else {
        print $0 > inter;
    }
}' "$calls_file"

# Intersect intra_calls.bedpe with lcrs.bed using pairtobed -type either, write to intra_overlaps.bedpe
bedtools pairtobed -a "$intra_filepath" -b ./GM12878_low_cov_regions.bed -f 1.0 -type either > "$output_dir/${prefix}_intra_overlaps.bedpe"
# Intersect inter_calls.bedpe with lcrs.bed using pairtobed -type both, write to inter_overlaps.bedpe
bedtools pairtobed -a "$inter_filepath" -b ./GM12878_low_cov_regions.bed -f 1.0 -type both > "$output_dir/${prefix}_inter_overlaps.bedpe"

if [ -s "$output_dir/${prefix}_intra_overlaps.bedpe" ]; then
    # Intra overlap file is NOT empty
    # Remove extra columns
    cut -f1-6 "$output_dir/${prefix}_intra_overlaps.bedpe" > "$output_dir/${prefix}_intra_overlaps_cut.bedpe"
    # Remove calls from intra_overlaps.bedpe if intersecting with Ig or TCR region
    bedtools pairtobed -a "$output_dir/${prefix}_intra_overlaps_cut.bedpe" -b ./IG_TCR_extended.bed -type neither > "$output_dir/${prefix}_intra_overlaps_filtered.bedpe"
    # Go through each row of intra calls and append whether or not it's in intra_overlaps_filtered.bedpe and therefore a mappability FP
    awk 'NR==FNR {a[$0]; next} {print $0 "\t" (($0 in a) ? "FP-Mappability" : "Needs review")}' "$output_dir/${prefix}_intra_overlaps_filtered.bedpe" "$intra_filepath" > "$output_dir/${prefix}_intra_calls_filtered.bedpe"
else
    # Intra overlap file is empty
    # Go through each row of intra calls and append 'Needs review'
    awk '{print $0 "\tNeeds review"}' "$intra_filepath" > "$output_dir/${prefix}_intra_calls_filtered.bedpe"
fi

if [ -s "$output_dir/${prefix}_inter_overlaps.bedpe" ]; then
    # Inter overlap file is NOT empty
    # Remove extra columns
    cut -f1-6 "$output_dir/${prefix}_inter_overlaps.bedpe" > "$output_dir/${prefix}_inter_overlaps_cut.bedpe"
    # Remove calls from inter_overlaps.bedpe if intersecting with Ig or TCR region
    bedtools pairtobed -a "$output_dir/${prefix}_inter_overlaps_cut.bedpe" -b ./IG_TCR_extended.bed -type neither > "$output_dir/${prefix}_inter_overlaps_filtered.bedpe"
    # Go through each row of inter calls and append whether or not it's in inter_overlaps_filtered.bedpe and therefore a mappability FP
    awk 'NR==FNR {a[$0]; next} {print $0 "\t" (($0 in a) ? "FP-Mappability" : "Needs review")}' "$output_dir/${prefix}_inter_overlaps_filtered.bedpe" "$inter_filepath" > "$output_dir/${prefix}_inter_calls_filtered.bedpe"
else
    # Inter overlap file is empty
    # Go through each row of inter calls and append 'Needs review'
    awk '{print $0 "\tNeeds review"}' "$inter_filepath" > "$output_dir/${prefix}_inter_calls_filtered.bedpe"
fi

# Concatenate call files
cat "$output_dir/${prefix}_intra_calls_filtered.bedpe" "$output_dir/${prefix}_inter_calls_filtered.bedpe" > "$output_dir/${prefix}_all_calls_annotated.bedpe"

# MOD: created empty FP & filtered calls files to avoid "file not found" errors
touch "$output_dir/${prefix}_FPs.bedpe"
touch "$output_dir/${prefix}_filtered_calls_7col.bedpe"

# Split up *_all_calls_annotated.bedpe into 2 files: one with FPs, one with calls needing review
awk -v fp_file="$output_dir/${prefix}_FPs.bedpe" -v nr_file="$output_dir/${prefix}_filtered_calls_7col.bedpe" '{if ($7 == "FP-Mappability") print > fp_file; else print > nr_file}' "$output_dir/${prefix}_all_calls_annotated.bedpe"

# Remove "Needs review" annotations from filtered calls file
cut -f1-6 "$output_dir/${prefix}_filtered_calls_7col.bedpe" > "$output_dir/${prefix}_filtered_calls.bedpe"

# Remove all intermediate files
#rm "$output_dir/${prefix}_calls_only.bedpe"
rm "$output_dir/${prefix}_filtered_calls_7col.bedpe"
rm "$output_dir/${prefix}_inter_calls_filtered.bedpe"
rm "$output_dir/${prefix}_inter_calls.bedpe"
rm "$output_dir/${prefix}_inter_overlaps.bedpe"
rm "$output_dir/${prefix}_intra_calls_filtered.bedpe"
rm "$output_dir/${prefix}_intra_calls.bedpe"
rm "$output_dir/${prefix}_intra_overlaps.bedpe"
rm "$output_dir/${prefix}_intra_overlaps_cut.bedpe"
rm "$output_dir/${prefix}_intra_overlaps_filtered.bedpe"
#rm "$output_dir/${prefix}_no_header.bedpe"