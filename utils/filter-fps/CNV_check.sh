input_call="$1"
CNV_files="$2"
out="$3"
file_prefix="$4"

# Merge CNV gain and loss files if not already merged
if [[ ! -e "$CNV_files/${file_prefix}_CNV_gains_losses_GM_rmvd.bed" ]]; then
    cat "$CNV_files/${file_prefix}_CNV_gains_GM_rmvd.bed" "$CNV_files/${file_prefix}_CNV_losses_GM_rmvd.bed" > "$CNV_files/${file_prefix}_CNV_gains_losses_GM_rmvd.bed"
fi

## If the CNV file shows a CNV gain or loss in the call region, add the call to TP file
bedtools pairtobed -a "$input_call" -b "$CNV_files/${file_prefix}_CNV_gains_losses_GM_rmvd.bed" > "$out/temp.bedpe"

# If temp.bedpe is not empty, meaning a CNV gain or loss overlaps with the call region, print the input call to "$output_dir/${prefix}_pre_CNV_TP_calls_7col.bedpe"
if [ -s "$out/temp.bedpe" ]; then
    cat "$input_call" >> "$out/${file_prefix}_TP_calls_6col.bedpe"
else
    cat "$input_call" >> "$out/${file_prefix}_FPs.bedpe"
fi