![alt text](https://arimagenomics.com/wp-content/files/2021/08/Arima-Genomics-logo.png "Celebrating Science and Scientist")

# Arima SV Pipeline for Mapping, SV Detection and QC

To order Arima kits, please visit our website:
https://arimagenomics.com/

## Getting Started
We provide both Docker and Singularity containers implementation of the pipeline to allow users run Arima SV pipeline out of the box. You can mount the necessary input and output locations and run Arima SV pipeline in two ways.

### Using Docker image
Please refer to the manual on Arima's DockerHub: https://hub.docker.com/repository/docker/arimaxiang/arima_ffpe

### Using Singularity image
```

```

```
singularity shell -B YOUR_HOST_OUTPUT_DIR:/FFPE/test_data/test_output_docker/ Arima-SV-Pipeline-singularity-v0.sif
```


## Usage (Command line options)
Arima-FFPE-v0.1.sh [-W run_hicup] [-B run_hic_breakfinder] [-J run_juicer]
              [-H run_hiccups] [-r reference_file] [-s chrom_sizes_file] [-c cut_site_file]
              [-a bowtie2] [-x bowtie2_index_basename] [-d digest] [-w hicup_dir]
              [-b hic_breakfinder_dir] [-j juicer_dir] [-I FASTQ_string] [-o out_dir]
              [-p output_prefix] [-e exp_file_intra] [-E exp_file_inter] [-t threads] [-v] [-h]

* [-W run_hicup]: "1" (default) to run HiCUP pipeline, "0" to skip. If skipping,
    HiCUP_summary_report_*.txt and *R1_2*.hicup.bam need to be in the HiCUP output folder.
* [-B run_hic_breakfinder]: "1" (default) to run hic_breakfinder, "0" to skip
* [-J run_juicer]: "1" (default) to run Juicer, "0" to skip
* [-H run_hiccups]: "1" (default) to run HiCCUPS, "0" to skip
* [-r reference_file]: reference FASTA file
* [-s chrom_sizes_file]: chrom.sizes file generated from the reference file
* [-c cut_site_file]: cut site file used by Juicer pipeline
* [-a bowtie2]: bowtie2 tool location
* [-x bowtie2_index_basename]: bowtie2 index file prefix
* [-d digest]: genome digest file produced by hicup_digester
* [-w hicup_dir]: directory of the HiCUP tool
* [-b hic_breakfinder_dir]: directory of the hic_breakfinder tool
* [-j juicer_dir]: directory of the Juicer tool
* [-I FASTQ_string]: a pair of FASTQ files separated by "," (no space is allowed)
* [-o out_dir]: output directory
* [-p output_prefix]: output file prefix (filename only, not including the path)
* [-e exp_file_intra]: intra-chromosomal background model file for normalization
* [-E exp_file_inter]: inter-chromosomal background model file for normalization
* [-t threads]: number of threads to run HiCUP and Juicer
* [-v]: print version number and exit
* [-h]: print this help and exit

### Example

```
bash /FFPE/Arima-FFPE-v0.1.sh -W 1 -B 1 -J 1 -H 1 -a /root/anaconda3/bin/bowtie2 -b /usr/local/bin/ -w /FFPE/HiCUP-0.8.0/ -j /FFPE/juicer-1.6/ -r /FFPE/Arima_files/reference/hg38/hg38.fa -s /FFPE/Arima_files/Juicer/hg38.chrom.sizes -c /FFPE/Arima_files/Juicer/hg38_GATC_GANTC.txt -x /FFPE/Arima_files/reference/hg38/hg38 -d /FFPE/Arima_files/HiCUP/Digest_hg38_Arima.txt -I /FFPE/test_data/fastq/JB_3_5M_R1.fastq.gz,/FFPE/test_data/fastq/JB_3_5M_R2.fastq.gz -o /FFPE/test_data/test_output_docker/ -p JB_3_5M -e /FFPE/Arima_files/hic_breakfinder/intra_expect_100kb.hg38.txt -E /FFPE/Arima_files/hic_breakfinder/inter_expect_1Mb.hg38.txt -t 12 &> /FFPE/test_data/test_output_docker/log.txt
```


## Pipeline Output

FFPE pipeline generates multiple files. Main output files are:
* $OUTPUT_DIR/\*_Arima_QC_deep.txt and $OUTPUT_DIR/\*_Arima_QC_shallow.txt - QC table containing multiple key metrics
* $OUTPUT_DIR/hic_breakfinder/\*.breaks.bedpe - SV file in .bedpe format from hic_breakfinder
* $OUTPUT_DIR/juicer/aligned/inter_30.hic - heatmap from Juicer pipeline for visualization using Juicebox
* $OUTPUT_DIR/juicer/aligned/hiccups/merged_loops.bedpe - list of significant 3D interactions in .bedpe format

The Arima-FFPE Bioinformatics User Guide walks through an example of how to run the Arima-FFPE pipeline using the provided test data and provides additional information on the output files.

## Arima Pipeline Version
0.1

## Support
For Arima customer support, please contact techsupport@arimagenomics.com
