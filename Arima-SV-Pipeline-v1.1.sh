#!/bin/bash

############################################################################
###                       Computing Environment                          ###
############################################################################

# Computing Resources: For shallow sequencing (0.5 - 2 million raw paired-end reads), the Arima SV pipeline requires 8 - 12 CPU cores with 32 - 48 GB RAM. The shallow sequencing analysis should complete in less than 2 hours. For deep sequencing (50 – 500 million raw paired-end reads), we recommend 20 - 30 CPU cores with at 80 - 120 GB RAM. Samples with 200 million raw paired-end reads will run in about 3 days with the recommended computational resources. Additional resources can be added to decrease the analysis time.

# Please install the following dependencies and add them to your PATH variable to ensure HiCUP and hic_breakfinder will execute in your computing environment:
# IMPORTANT NOTE: Only bamtools v2.4.0 is compatible with hic_breakfinder!!!
# IMPORTANT NOTE: Please use gcc v4.8.5 to build and compile hic_breakfinder!!!

# Dependencies:
# R 3.4.3 packages: argparse (v2.0.1)
# HTSLIB (v1.10.2)
# samtools (v1.10)
# bamtools (v2.4.0)
# bedtools (v2.25)
# bcftools (v1.10)

# References:
# Wingett S, et al. (2015) HiCUP: pipeline for mapping and processing Hi-C data F1000Research, 4:1310 (doi: 10.12688/f1000research.7334.1)
# Dixon, J. R., Xu, J., Dileep, V., Zhan, Y., Song, F., Le, V. T., ... & Yue, F. (2018). Integrative detection and analysis of structural variation in cancer genomes. Nature genetics, 50(10), 1388-1398.
# Neva C. Durand, Muhammad S. Shamim, Ido Machol, Suhas S. P. Rao, Miriam H. Huntley, Eric S. Lander, and Erez Lieberman Aiden. "Juicer provides a one-click system for analyzing loop-resolution Hi-C experiments." Cell Systems 3(1), 2016.

# Websites:
# HiCUP: https://github.com/StevenWingett/HiCUP
# HiC_breakfinder: https://github.com/dixonlab/hic_breakfinder
# Juicer: https://github.com/aidenlab/juicer

version="v1.1"
cwd=$(dirname $0)

############################################################################
###                    Arima Recommended Parameters                      ###
############################################################################

# The parameter settings in this section are based on the default parameters for HiCUP and Juicer with some minor adjustments. These parameters have been optimized by internal benchmarking using Arima's dual-enzyme chemistry.
run_hicup=1 # "1" to run HiCUP pipeline, "0" to skip
run_hic_breakfinder=1 # "1" to run hic_breakfinder to call SVs, "0" to skip
run_juicer=1 # "1" to run Juicer pipeline, "0" to skip
run_hiccups=0 # "1" to run HiCCUPS to call loops, "0" to skip
# resolution="5kb" # Resolution of the loops called, must be one of "1kb", "2kb", "5kb" or "10kb"
threads=12 # number of threads to run SV pipeline

# Use hg38 by default
reference_file="/FFPE/Arima_files/reference/hg38/hg38.fa"
chrom_sizes_file="/FFPE/Arima_files/Juicer/hg38.chrom.sizes"
cut_site_file="/FFPE/Arima_files/Juicer/hg38_GATC_GANTC.txt"
bowtie2_index_basename="/FFPE/Arima_files/reference/hg38/hg38"
digest="/FFPE/Arima_files/HiCUP/Digest_hg38_Arima.txt"
exp_file_intra="/FFPE/Arima_files/hic_breakfinder/intra_expect_100kb.hg38.txt"
exp_file_inter="/FFPE/Arima_files/hic_breakfinder/inter_expect_1Mb.hg38.txt"

# Default tool path
bwa="/root/anaconda3/bin/bwa"
bowtie2="/root/anaconda3/bin/bowtie2"
hicup_dir="/FFPE/HiCUP-0.8.0/"
hic_breakfinder_dir="/usr/local/bin/"
juicer_dir="/FFPE/juicer-1.6/"

############################################################################
###                      Command Line Arguments                          ###
############################################################################
usage_Help="Usage: ${0##*/} [-W run_hicup] [-B run_hic_breakfinder] [-J run_juicer]
              [-H run_hiccups] [-r reference_file] [-s chrom_sizes_file] [-c cut_site_file]
              [-a bowtie2] [-x bowtie2_index_basename] [-d digest] [-w hicup_dir]
              [-b hic_breakfinder_dir] [-j juicer_dir] [-I FASTQ_string] [-o out_dir]
              [-p output_prefix] [-e exp_file_intra] [-E exp_file_inter] [-t threads] [-v] [-h] \n"
run_hicup_Help="* [-W run_hicup]: \"1\" (default) to run HiCUP pipeline, \"0\" to skip. If skipping,
    HiCUP_summary_report_*.txt and *R1_2*.hicup.bam need to be in the HiCUP output folder."
run_hic_breakfinder_Help="* [-B run_hic_breakfinder]: \"1\" (default) to run hic_breakfinder, \"0\" to skip"
run_juicer_Help="* [-J run_juicer]: \"1\" (default) to run Juicer pipeline, \"0\" to skip"
run_hiccups_Help="* [-H run_hiccups]: \"1\" to run HiCCUPS, \"0\" (default) to skip"
reference_file_Help="* [-r reference_file]: reference FASTA file"
chrom_sizes_file_Help="* [-s chrom_sizes_file]: chrom.sizes file generated from the reference file"
cut_site_file_Help="* [-c cut_site_file]: cut site file used by Juicer pipeline"
bowtie2_Help="* [-a bowtie2]: bowtie2 tool location"
bowtie2_index_basename_Help="* [-x bowtie2_index_basename]: bowtie2 index file prefix"
digest_Help="* [-d digest]: genome digest file produced by hicup_digester"
hicup_dir_Help="* [-w hicup_dir]: directory of the HiCUP tool"
hic_breakfinder_dir_Help="* [-b hic_breakfinder_dir]: directory of the hic_breakfinder tool"
juicer_dir_Help="* [-j juicer_dir]: directory of the Juicer tool"
FASTQ_string_Help="* [-I FASTQ_string]: a pair of FASTQ files separated by \",\" (no space is allowed)"
out_dir_Help="* [-o out_dir]: output directory"
output_prefix_Help="* [-p output_prefix]: output file prefix (filename only, not including the path)"
exp_file_intra_Help="* [-e exp_file_intra]: intra-chromosomal background model file for normalization"
exp_file_inter_Help="* [-E exp_file_inter]: inter-chromosomal background model file for normalization"
threads_Help="* [-t threads]: number of threads to run HiCUP and Juicer"
version_Help="* [-v]: print version number and exit"
help_Help="* [-h]: print this help and exit"

printHelpAndExit() {
    echo -e "$usage_Help"
    echo -e "$run_hicup_Help"
    echo -e "$run_hic_breakfinder_Help"
    echo -e "$run_juicer_Help"
    echo -e "$run_hiccups_Help"
    echo -e "$reference_file_Help"
    echo -e "$chrom_sizes_file_Help"
    echo -e "$cut_site_file_Help"
    echo -e "$bowtie2_Help"
    echo -e "$bowtie2_index_basename_Help"
    echo -e "$digest_Help"
    echo -e "$hicup_dir_Help"
    echo -e "$hic_breakfinder_dir_Help"
    echo -e "$juicer_dir_Help"
    echo -e "$FASTQ_string_Help"
    echo -e "$out_dir_Help"
    echo -e "$output_prefix_Help"
    echo -e "$exp_file_intra_Help"
    echo -e "$exp_file_inter_Help"
    echo -e "$threads_Help"
    echo -e "$version_Help"
    echo -e "$help_Help"
    exit "$1"
}

printVersionAndExit() {
    echo "$version"
    exit 0
}

while getopts "a:b:B:c:d:e:E:hH:I:j:J:o:p:r:s:t:vw:W:x:" opt; do
    case $opt in
    h) printHelpAndExit 0;;
    v) printVersionAndExit 0;;
    W) run_hicup=$OPTARG ;;
    B) run_hic_breakfinder=$OPTARG ;;
    J) run_juicer=$OPTARG ;;
    H) run_hiccups=$OPTARG ;;
    r) reference_file=$OPTARG ;;
    s) chrom_sizes_file=$OPTARG ;;
    c) cut_site_file=$OPTARG ;;
    a) bowtie2=$OPTARG ;;
    x) bowtie2_index_basename=$OPTARG ;;
    d) digest=$OPTARG ;;
    w) hicup_dir=$OPTARG ;;
    b) hic_breakfinder_dir=$OPTARG ;;
    j) juicer_dir=$OPTARG ;;
    I) FASTQ_string=$OPTARG ;;
    o) out_dir=$OPTARG ;;
    p) output_prefix=$OPTARG ;;
    e) exp_file_intra=${OPTARG} ;;
    E) exp_file_inter=${OPTARG} ;;
    t) threads=$OPTARG ;;
    [?]) printHelpAndExit 1;;
    esac
done

IFS=',' read -a FASTQ <<< "$FASTQ_string"

############################################################################
###                            Sanity checks!!!                          ###
############################################################################

#hash Rscript &> /dev/null
command -v Rscript &> /dev/null
if [[ $? -ne 0 ]]; then
    echo -e "\nCould not find R. Please install or include it into the \"PATH\" variable!\n"
    printHelpAndExit 1
fi

#hash samtools &> /dev/null
command -v samtools &> /dev/null
if [[ $? -ne 0 ]]; then
    echo -e "\nCould not find samtools. Please install or include it into the \"PATH\" variable!\n"
    printHelpAndExit 1
fi

#hash bamtools &> /dev/null
command -v bamtools &> /dev/null
if [[ $? -ne 0 ]]; then
    echo -e "\nCould not find bamtools. Please install or include it into the \"PATH\" variable!\n"
    printHelpAndExit 1
fi

#hash bgzip &> /dev/null

#hash bedtools &> /dev/null
command -v bedtools &> /dev/null
if [[ $? -ne 0 ]]; then
    echo -e "\nCould not find bedtools. Please install or include it into the \"PATH\" variable!\n"
    printHelpAndExit 1
fi

#hash java &> /dev/null
command -v java &> /dev/null
if [[ $? -ne 0 ]]; then
    echo -e "\nCould not find java. Please install or include it into the \"PATH\" variable!\n"
    printHelpAndExit 1
fi

#hash bwa &> /dev/null
command -v bwa &> /dev/null
if [[ $? -ne 0 ]]; then
    echo -e "\nCould not find bwa. Please install or include it into the \"PATH\" variable!\n"
    printHelpAndExit 1
fi

#hash bowtie2 &> /dev/null
command -v bowtie2 &> /dev/null
if [[ $? -ne 0 ]]; then
    echo -e "\nCould not find bowtie2. Please install or include it into the \"PATH\" variable!\n"
    printHelpAndExit 1
fi

#hash bc &> /dev/null
command -v bc &> /dev/null
if [[ $? -ne 0 ]]; then
    echo -e "\nCould not find bc. Please install or include it into the \"PATH\" variable!\n"
    printHelpAndExit 1
fi

if ! [[ "$run_hicup" == "0" || "$run_hicup" == "1" ]]; then
    echo -e "\nThe argument \"run_hicup\" must be either 0 or 1 (-W)!\n"
    printHelpAndExit 1
fi

if ! [[ "$run_hic_breakfinder" == "0" || "$run_hic_breakfinder" == "1" ]]; then
    echo -e "\nThe argument \"run_hic_breakfinder\" must be either 0 or 1 (-B)!\n"
    printHelpAndExit 1
fi

if ! [[ "$run_juicer" == "0" || "$run_juicer" == "1" ]]; then
    echo -e "\nThe argument \"run_juicer\" must be either 0 or 1 (-J)!\n"
    printHelpAndExit 1
fi

if ! [[ "$run_hiccups" == "0" || "$run_hiccups" == "1" ]]; then
    echo -e "\nThe argument \"run_hiccups\" must be either 0 or 1 (-H)!\n"
    printHelpAndExit 1
fi

if [ ! -x "$bowtie2" ]; then
    echo -e "\nPlease provide a correct bowtie2 tool location (-a)!\n"
    printHelpAndExit 1
fi

if [ ! -d "$hicup_dir" ]; then
    echo -e "\nPlease provide the directory of the HiCUP tool (-w)!\n"
    printHelpAndExit 1
fi

if [ ! -d "$hic_breakfinder_dir" ]; then
    echo -e "\nPlease provide the directory of the hic_breakfinder tool (-b)!\n"
    printHelpAndExit 1
fi

if [ ! -d "$juicer_dir" ]; then
    echo -e "\nPlease provide the directory of the Juicer tool (-j)!\n"
    printHelpAndExit 1
fi

if [[ -z "$bowtie2_index_basename" || `ls $bowtie2_index_basename.* 2> /dev/null | wc -l` -eq 0 ]]; then
    echo -e "\nPlease provide a correct bowtie2 index file prefix (-x)!\n"
    printHelpAndExit 1
fi

if [ ! -f "$digest" ]; then
    echo -e "\nPlease provide a correct genome digest file produced by hicup_digester (-d)!\n"
    printHelpAndExit 1
fi

if [ -z "$FASTQ_string" ]; then
    echo -e "\nPlease provide a pair of FASTQ files separated by \",\" only (no space) (-I)!\n"
    printHelpAndExit 1
else
    IFS=',' read -a FASTQ <<< "$FASTQ_string"
    for i in "${FASTQ[@]}"; do
        if [ ! -f "$i" ]; then
            echo -e "\n$i does not exist (-I)!\n"
            printHelpAndExit 1
        fi
    done
fi

if [ -z "$out_dir" ]; then
    echo -e "\nPlease provide an output directory (-o)!\n"
    printHelpAndExit 1
fi

if [ -z "$output_prefix" ]; then
    echo -e "\nPlease provide an output file prefix (-p)!\n"
    printHelpAndExit 1
fi

if [[ $run_hic_breakfinder == "1" && ! -f "$exp_file_intra" ]]; then
    echo -e "\nPlease provide a correct intra-chromosomal expectation file used by hic_breakfinder (-e)!\n"
    printHelpAndExit 1
fi

if [[ $run_hic_breakfinder == "1" && ! -f "$exp_file_inter" ]]; then
    echo -e "\nPlease provide a correct inter-chromosomal expectation file used by hic_breakfinder (-E)!\n"
    printHelpAndExit 1
fi

if ! [[ "$threads" =~ ^[0-9]+$ ]]; then
    echo $threads
    echo -e "\nThe # of threads must be an integer (-t)!\n"
    printHelpAndExit 1
fi

# output_prefix=$(basename ${FASTQ[0]} | sed 's/^\(.*\)[._]R1.f.*q.*$/\1/')

out_hicup=$out_dir"/hicup/"
out_hic_breakfinder=$out_dir"/hic_breakfinder/"
out_juicer=$out_dir"/juicer/"
out_hiccups=$out_dir"/juicer/aligned/hiccups/"

[ -d "$out_dir" ] || mkdir -p $out_dir
[ -d "$out_hicup" ] || mkdir -p $out_hicup
[ -d "$out_hic_breakfinder" ] || mkdir -p $out_hic_breakfinder
[ -d "$out_juicer/fastq/" ] || mkdir -p $out_juicer"/fastq/"

hicup_config=$out_hicup"/hicup.conf"
if [ "$run_hicup" -eq 1 ]; then
    if [ ! -f $cwd"/utils/hicup_example.conf" ]; then
        echo "ERROR: Missing hicup_example.conf file in $cwd/utils/"
        exit 1
    fi
    cp $cwd"/utils/hicup_example.conf" $hicup_config
    chmod +w $hicup_config

    sed -r -i -e "s@\[OUT_DIR\]@$out_hicup@" -e "s@\[THREADS\]@$threads@" -e "s@\[bowtie2_toolpath\]@$bowtie2@" -e "s@\[bowtie2_index_basename\]@$bowtie2_index_basename@" -e "s@\[DIGEST_FILE\]@$digest@" -e "s@\[FASTQ_R1\]@${FASTQ[0]}@" -e "s@\[FASTQ_R2\]@${FASTQ[1]}@" $hicup_config
fi

############################################################################
###                            Log information                           ###
############################################################################
echo "Running: $0 [$version]"
echo "Command: $0 $@"
echo
echo "User Defined Inputs:"
echo run_hicup=$run_hicup
echo run_hic_breakfinder=$run_hic_breakfinder
echo run_juicer=$run_juicer
echo run_hiccups=$run_hiccups
echo reference_file=$reference_file
echo chrom_sizes_file=$chrom_sizes_file
echo cut_site_file=$cut_site_file
#echo bwa=$bwa
echo bowtie2=$bowtie2
echo bowtie2_index_basename=$bowtie2_index_basename
echo hicup_dir=$hicup_dir
echo hic_breakfinder_dir=$hic_breakfinder_dir
echo juicer_dir=$juicer_dir
echo digest=$digest
echo hicup_config=$hicup_config
echo FASTQ_string=$FASTQ_string
echo out_dir=$out_dir
echo out_hicup=$out_hicup
echo out_hic_breakfinder=$out_hic_breakfinder
echo out_juicer=$out_juicer
echo output_prefix=$output_prefix

if [[ "$run_hic_breakfinder" -eq 1 || ( -f $exp_file_intra && -f $exp_file_inter ) ]]; then
    echo exp_file_intra=$exp_file_intra
    echo exp_file_inter=$exp_file_inter
fi

#echo resolution=$resolution
echo threads=$threads
echo

############################################################################
###                          Arima SV pipeline                         ###
############################################################################

if [ "$run_hicup" -eq 0 ]; then
    echo "Skipping HiCUP pipeline and using previous HiCUP output from $out_hicup"
else
    timestamp=`date '+%Y/%m/%d %H:%M:%S'`
    echo "Running HiCUP [$timestamp] ..."
    echo "$hicup_dir/hicup --config $hicup_config &> $out_hicup/hicup.log"
    $hicup_dir"/hicup" --config $hicup_config &> $out_hicup"/hicup.log"
    timestamp=`date '+%Y/%m/%d %H:%M:%S'`
    echo -e "Finished running HiCUP! [$timestamp]\n"
fi

hicup_output_bam=$out_hicup"/*R1_2*.hicup.bam"
if [ `ls $hicup_output_bam 2> /dev/null | wc -l` -ne 1 ]; then
    echo -e "ERROR: There should be exactly one *R1_2*.hicup.bam file in the HiCUP output!\n"
    exit 1
fi

hicup_output_bam_string=`echo $hicup_output_bam`
echo -e "Output BAM file from HiCUP: $hicup_output_bam_string\n"

if [ "$run_hic_breakfinder" -eq 0 ]; then
    echo "Skipping hic_breakfinder and using previous hic_breakfinder output from $out_hic_breakfinder"
else
    timestamp=`date '+%Y/%m/%d %H:%M:%S'`
    echo "Running hic_breakfinder [$timestamp] ..."
    echo "$hic_breakfinder_dir/hic_breakfinder --bam-file $hicup_output_bam_string --exp-file-inter $exp_file_inter --exp-file-intra $exp_file_intra --name $out_hic_breakfinder/$output_prefix --min-1kb &> $out_hic_breakfinder/hic_breakfinder.log"
    $hic_breakfinder_dir"/hic_breakfinder" --bam-file $hicup_output_bam_string --exp-file-inter $exp_file_inter --exp-file-intra $exp_file_intra --name $out_hic_breakfinder"/"$output_prefix --min-1kb &> $out_hic_breakfinder"/hic_breakfinder.log"
    timestamp=`date '+%Y/%m/%d %H:%M:%S'`
    echo -e "Finished running hic_breakfinder! [$timestamp]\n"
fi

SV_file_txt=$out_hic_breakfinder"/"$output_prefix".breaks.txt"
SV_file_bedpe=$out_hic_breakfinder"/"$output_prefix".breaks.bedpe"
if [ ! -f $SV_file_txt ]; then
    echo -e "WARNING: Could not find the output SV file!\n"
    total_SVs="NA"
else
    # Convert the .txt SV file into bedpe format
    awk -v OFS="\t" 'BEGIN { print "#chr1","x1","x2","chr2","y1","y2","strand1","strand2","resolution","-logP" } { print $2,$3,$4,$6,$7,$8,$5,$9,$10,$1 }' $SV_file_txt > $SV_file_bedpe
    echo -e "Output SV .txt file from hic_breakfinder: $SV_file_txt"
    echo -e "Output SV .bedpe file from hic_breakfinder: $SV_file_bedpe\n"
    total_SVs=`wc -l $SV_file_txt | awk '{print $1}'`
fi

#hicup_stat_1=$out_hicup"/hicup_truncater_summary_*.txt"
#hicup_stat_2=$out_hicup"/hicup_mapper_summary_*.txt"
#hicup_stat_3=$out_hicup"/hicup_filter_summary_*.txt"
#hicup_stat_4=$out_hicup"/hicup_deduplicator_summary_*.txt"
hicup_summary_report=$out_hicup"/HiCUP_summary_report_*.txt"

if [[ `ls $hicup_summary_report 2> /dev/null | wc -l` -ne 1 ]]; then
    echo -e "ERROR: There should be exactly one HiCUP_summary_report_*.txt file in the HiCUP output!\n"
    exit 1
fi

raw_R1=$( head $hicup_summary_report | grep -v "Total_Reads_1" | head -1 | cut -f2 )
raw_R2=$( head $hicup_summary_report | grep -v "Total_Reads_1" | head -1 | cut -f3 )
raw_pairs=$(( ($raw_R1 + $raw_R2)/2 ))

uniq_mapped_R1=$( head $hicup_summary_report | grep -v "Total_Reads_1" | head -1 | cut -f12 )
uniq_mapped_R2=$( head $hicup_summary_report | grep -v "Total_Reads_1" | head -1 | cut -f13 )
uniq_mapped_SE=$(( $uniq_mapped_R1 + $uniq_mapped_R2 ))

multi_mapped_R1=$( head $hicup_summary_report | grep -v "Total_Reads_1" | head -1 | cut -f14 )
multi_mapped_R2=$( head $hicup_summary_report | grep -v "Total_Reads_1" | head -1 | cut -f15 )
multi_mapped_SE=$(( $multi_mapped_R1 + $multi_mapped_R2 ))

mapped_SE=$(( $uniq_mapped_SE + $multi_mapped_SE ))
mapped_p=`echo "scale=4; 100 * $mapped_SE / $raw_pairs / 2" | bc | awk '{ printf("%.1f", $0) }'`

total_pairs=$( head $hicup_summary_report | grep -v "Total_Reads_1" | head -1 | cut -f18 )
valid_pairs=$( head $hicup_summary_report | grep -v "Total_Reads_1" | head -1 | cut -f20 )
uniq_valid_pairs=$( head $hicup_summary_report | grep -v "Total_Reads_1" | head -1 | cut -f31 )
duplicated_pairs=$(( $valid_pairs - $uniq_valid_pairs ))

# Modified based on the metrics definition spreadsheet, but is inconsistent with HiCUP summary report output!
uniq_valid_pairs_p=`echo "scale=4; 100 * $uniq_valid_pairs / $total_pairs" | bc | awk '{ printf("%.1f", $0) }'`
duplicated_pairs_p=`echo "scale=4; 100 * $duplicated_pairs / $total_pairs" | bc | awk '{ printf("%.1f", $0) }'`

# Change the calculation of %Lcis. Use "uniq_total_pairs" as the denominator (Modified in v1.5).
uniqueness_rate=`echo "scale=9; $uniq_valid_pairs / $valid_pairs" | bc | awk '{ printf("%.9f", $0) }'`
#invalid_pairs=$( head $hicup_summary_report | grep -v "Total_Reads_1" | head -1 | cut -f24 )
#uniq_invalid_pairs=`echo "scale=4; $invalid_pairs * $uniqueness_rate + 0.5" | bc | awk '{ printf("%d", $0) }'`
uniq_total_pairs=`echo "scale=4; $total_pairs * $uniqueness_rate + 0.5" | bc | awk '{ printf("%d", $0) }'`

# Modified the calculation of inter- and intra- percentages in v1.0
inter_pairs=$( head $hicup_summary_report | grep -v "Total_Reads_1" | head -1 | cut -f34 )
# Modified in v1.1
inter_pairs_p=`echo "scale=4; 100 * $inter_pairs / $uniq_total_pairs" | bc | awk '{ printf("%.1f", $0) }'`
# Modified in v1.1
intra_pairs=$(( $uniq_total_pairs - $inter_pairs ))
#intra_close_pairs=$( head $hicup_summary_report | grep -v "Total_Reads_1" | head -1 | cut -f32 )
#intra_far_pairs=$( head $hicup_summary_report | grep -v "Total_Reads_1" | head -1 | cut -f33 )
# Modified in v1.1
intra_pairs_p=`echo "scale=4; 100 * $intra_pairs / $uniq_total_pairs" | bc | awk '{ printf("%.1f", $0) }'`

# Calculate long cis from HiCUP BAM file
hicup_output_bam_bedpe=${hicup_output_bam_string%.bam}.bedpe
if [ ! -f "$hicup_output_bam_bedpe" ]; then
    bedtools bamtobed -i $hicup_output_bam_string -bedpe > $hicup_output_bam_bedpe
fi
intra_ge_15kb_pairs=$( awk '{ if($1==$4 && ($5+$6)/2 - ($2+$3)/2 >= 15000) intra_ge_15kb++ } END { print intra_ge_15kb }' $hicup_output_bam_bedpe )
# Modified in v1.1
intra_ge_15kb_pairs_p=`echo "scale=4; 100 * $intra_ge_15kb_pairs / $uniq_total_pairs" | bc | awk '{ printf("%.1f", $0) }'`

Lcis_trans_ratio=`echo "scale=2; $intra_ge_15kb_pairs / $inter_pairs" | bc | awk '{ printf("%.1f", $0) }'`

# Modified in v1.0
# We use 0.8 for map rate and 0.7 for uniqueness rate
# target_raw_pairs=`echo "scale=4; 36500000 / ($intra_ge_15kb_pairs_p / 100) / ($uniq_valid_pairs_p / 100) / 0.8 / 0.7" | bc | awk '{ printf("%d", $0) }'`
target_raw_pairs=`echo "scale=4; 3.65 / ($intra_ge_15kb_pairs_p / 100) / ($uniq_valid_pairs_p / 100) / 0.8 / 0.7 + 0.5" | bc | awk '{ x = sprintf("%d", $0); print x * 10000000 }'`

echo -e "Key Metrics:"
echo raw_R1=$raw_R1
echo raw_R2=$raw_R2
echo raw_pairs=$raw_pairs
echo uniq_mapped_R1=$uniq_mapped_R1
echo uniq_mapped_R2=$uniq_mapped_R2
echo uniq_mapped_SE=$uniq_mapped_SE
echo multi_mapped_R1=$multi_mapped_R1
echo multi_mapped_R2=$multi_mapped_R2
echo multi_mapped_SE=$multi_mapped_SE
echo mapped_SE=$mapped_SE
echo mapped_p=$mapped_p

echo total_pairs=$total_pairs
echo valid_pairs=$valid_pairs
echo uniq_total_pairs=$uniq_total_pairs
echo uniq_valid_pairs=$uniq_valid_pairs
echo uniqueness_rate=$uniqueness_rate
echo duplicated_pairs=$duplicated_pairs
echo duplicated_pairs_p=$duplicated_pairs_p
echo uniq_valid_pairs_p=$uniq_valid_pairs_p

echo inter_pairs=$inter_pairs
echo inter_pairs_p=$inter_pairs_p
echo intra_pairs=$intra_pairs
echo intra_pairs_p=$intra_pairs_p
echo intra_ge_15kb_pairs=$intra_ge_15kb_pairs
echo intra_ge_15kb_pairs_p=$intra_ge_15kb_pairs_p
echo Lcis_trans_ratio=$Lcis_trans_ratio
echo total_SVs=$total_SVs
echo target_raw_pairs=$target_raw_pairs
echo

if [ "$run_juicer" -eq 0 ]; then
    echo "Skipping Juicer pipeline and using previous Juicer output from $out_juicer"
else
    ln -s ${FASTQ[0]} $out_juicer"/fastq/"$output_prefix"_R1.fastq.gz"
    ln -s ${FASTQ[1]} $out_juicer"/fastq/"$output_prefix"_R2.fastq.gz"

    timestamp=`date '+%Y/%m/%d %H:%M:%S'`
    echo "Running Juicer [$timestamp] ..."
    echo "$juicer_dir/scripts/juicer.sh -d $out_juicer -p $chrom_sizes_file -s Arima -y $cut_site_file -z $reference_file -D $juicer_dir -t $threads &> $out_juicer/juicer.log"
    $juicer_dir"/scripts/juicer.sh" -d $out_juicer -p $chrom_sizes_file -s "Arima" -y $cut_site_file -z $reference_file -D $juicer_dir -t $threads &> $out_juicer/"juicer.log"
    timestamp=`date '+%Y/%m/%d %H:%M:%S'`
    echo -e "Finished running Juicer! [$timestamp]\n"
fi

hic_file=$out_juicer"/aligned/inter.hic"
hic_file_30=$out_juicer"/aligned/inter_30.hic"
txt_file_30=$out_juicer"/aligned/inter_30.txt"
if [ ! -f $hic_file ]; then
    echo -e "WARNING: Could not find inter.hic file!\n"
fi
if [ ! -f $hic_file_30 ]; then
    echo -e "WARNING: Could not find inter_30.hic file!\n"
fi
if [ ! -f $txt_file_30 ]; then
    echo -e "WARNING: Could not find inter_30.txt file!\n"
    lib_complexity="NA"
else
    lib_complexity=`grep "Library Complexity Estimate:" $txt_file_30 | sed s/,//g | cut -d" " -f4`
fi

loop_file=$out_hiccups"/merged_loops.bedpe"
if [[ -f $hic_file_30 && "$run_hiccups" -eq 1 ]]; then
    [ -d "$out_hiccups" ] || mkdir -p $out_hiccups

    timestamp=`date '+%Y/%m/%d %H:%M:%S'`
    echo "Running HiCCUPS [$timestamp] ..."
    echo "java -jar $juicer_dir/scripts/common/juicer_tools.jar hiccups --cpu -k KR --threads $threads -r 2500000,1000000,500000,250000,100000,50000,25000,10000,5000,1000,500 --ignore-sparsity $hic_file_30 $out_hiccups &> $out_hiccups/hiccups.log"
    java -jar $juicer_dir/scripts/common/juicer_tools.jar hiccups --cpu -k KR --threads $threads -r 2500000,1000000,500000,250000,100000,50000,25000,10000,5000,1000,500 --ignore-sparsity $hic_file_30 $out_hiccups &> $out_hiccups/hiccups.log
    timestamp=`date '+%Y/%m/%d %H:%M:%S'`
    echo -e "Finished running HiCCUPS! [$timestamp]\n"

    if [ ! -f $loop_file ]; then
        echo -e "WARNING: Could not find the output loop file!\n"
    fi
fi

############################################################################
###               Arima Genomics Post-processing and QC                  ###
############################################################################
# Write QC tables
QC_result_deep=$out_dir"/"$output_prefix"_Arima_QC_deep.txt"
QC_result_shallow=$out_dir"/"$output_prefix"_Arima_QC_shallow.txt"

header_deep=("Sample_name" "Raw_pairs" "Mapped_SE_reads" "%_Mapped_SE_reads" "Duplicated_pairs" "%_Duplicated_pairs" "Unique_valid_pairs" "%_Unique_valid_pairs" "Library_complexity" "Intra_pairs" "%_Intra_pairs" "Intra_ge_15kb_pairs" "%_Intra_ge_15kb_pairs" "Inter_pairs" "%_Inter_pairs" "Lcis_trans_ratio" "SVs")
IFS=$'\t'; echo "${header_deep[*]}" > $QC_result_deep

result_deep=($output_prefix $raw_pairs $mapped_SE $mapped_p $duplicated_pairs $duplicated_pairs_p $uniq_valid_pairs $uniq_valid_pairs_p $lib_complexity $intra_pairs $intra_pairs_p $intra_ge_15kb_pairs $intra_ge_15kb_pairs_p $inter_pairs $inter_pairs_p $Lcis_trans_ratio $total_SVs)
IFS=$'\t'; echo "${result_deep[*]}" >> $QC_result_deep

header_shallow=("Sample_name" "Raw_pairs" "Mapped_SE_reads" "%_Mapped_SE_reads" "Duplicated_pairs" "%_Duplicated_pairs" "Unique_valid_pairs" "%_Unique_valid_pairs" "Library_complexity" "Intra_pairs" "%_Intra_pairs" "Intra_ge_15kb_pairs" "%_Intra_ge_15kb_pairs" "Inter_pairs" "%_Inter_pairs" "Lcis_trans_ratio" "Target_raw_pairs")
IFS=$'\t'; echo "${header_shallow[*]}" > $QC_result_shallow

result_shallow=($output_prefix $raw_pairs $mapped_SE $mapped_p $duplicated_pairs $duplicated_pairs_p $uniq_valid_pairs $uniq_valid_pairs_p $lib_complexity $intra_pairs $intra_pairs_p $intra_ge_15kb_pairs $intra_ge_15kb_pairs_p $inter_pairs $inter_pairs_p $Lcis_trans_ratio $target_raw_pairs)
IFS=$'\t'; echo "${result_shallow[*]}" >> $QC_result_shallow


timestamp=`date '+%Y/%m/%d %H:%M:%S'`
echo -e "Arima SV pipeline finished successfully! [$timestamp]\n"
echo "Please download the QC result from: $QC_result_deep and $QC_result_shallow and then copy the contents to the corresponding tables in the QC worksheet."
echo

if [ -f $hicup_summary_report ]; then
    hicup_summary_report_new=$out_dir"/"$output_prefix"_HiCUP_summary_report.txt"
    cp $hicup_summary_report $hicup_summary_report_new
    echo "The detailed HiCUP mapping statistics is located at: $hicup_summary_report_new"
fi

if [ -f $hic_file_30 ]; then
    echo "The filtered .hic file from Juicer pipeline for visualization using Juicebox is located at: $hic_file_30"
fi

if [ -f $SV_file_txt ]; then
    echo "The SV .txt file from hic_breakfinder is located at: $SV_file_txt"
    echo "The SV .bedpe file from hic_breakfinder is located at: $SV_file_bedpe"
fi

if [[ -f $loop_file ]]; then
    echo "The loop file from HiCCUPS is located at: $loop_file"
fi

exit 0


# bash Arima-SV-Pipeline-v1.1.sh -W 1 -B 1 -J 1 -H 0 -a /home/xiangz/tools/bowtie2-2.3.4.3-linux-x86_64/bowtie2 -b /home/xiangz/tools/hic_breakfinder/bin/ -w /home/xiangz/tools/HiCUP-0.8.0/ -j /home/xiangz/tools/juicer_v1.6/ -r /home/xiangz/scratch/reference/hg19.fa -s /home/xiangz/scratch/reference/Juicer/hg19.chrom.sizes -c /home/xiangz/tools/juicer_v1.6/restriction_sites/hg19_GATC_GANTC.txt -x /oasis/tscc/scratch/xiangz/reference/bowtie2/hg19 -d /oasis/tscc/scratch/xiangz/reference/HiCUP/Digest_hg19_Arima.txt -I /oasis/tscc/scratch/xiangz/CHiCAGO/Arima_CHiC/fastq/AGI_2_25M_R1.fastq.gz,/oasis/tscc/scratch/xiangz/CHiCAGO/Arima_CHiC/fastq/AGI_2_25M_R2.fastq.gz -o /oasis/tscc/scratch/xiangz/tmp/FFPE/ -p 100M_mytest -e /oasis/tscc/scratch/xiangz/tmp/FFPE/utils/intra_expect_100kb.hg19.txt -E /oasis/tscc/scratch/xiangz/tmp/FFPE/utils/inter_expect_1Mb.hg19.txt -t 12 &> log.txt

# bash Arima-SV-Pipeline-v1.1.sh -W 0 -B 0 -J 0 -H 0 -a /home/xiangz/tools/bowtie2-2.3.4.3-linux-x86_64/bowtie2 -b /home/xiangz/tools/hic_breakfinder/bin/ -w /home/xiangz/tools/HiCUP-0.8.0/ -j /home/xiangz/tools/juicer_v1.6/ -r /home/xiangz/scratch/reference/hg38.fa -s /home/xiangz/scratch/reference/Juicer/hg38.chrom.sizes -c /home/xiangz/tools/juicer_v1.6/restriction_sites/hg38_GATC_GANTC.txt -x /oasis/tscc/scratch/xiangz/reference/bowtie2/hg38 -d /oasis/tscc/scratch/xiangz/reference/HiCUP/Digest_hg38_Arima.txt -I /oasis/tscc/scratch/xiangz/tmp/FFPE/fastq/002DS_1_R1.fastq.gz,/oasis/tscc/scratch/xiangz/tmp/FFPE/fastq/002DS_1_R2.fastq.gz -o /oasis/tscc/scratch/xiangz/tmp/FFPE/ -p 002DS_1 -e /oasis/tscc/scratch/xiangz/tmp/FFPE/utils/intra_expect_100kb.hg38.txt -E /oasis/tscc/scratch/xiangz/tmp/FFPE/utils/inter_expect_1Mb.hg38.txt -t 4 &> log.txt
