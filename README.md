![alt text](https://arimagenomics.com/wp-content/files/2021/08/Arima-Genomics-logo.png "Celebrating Science and Scientist")

# Arima SV Pipeline for Mapping, SV Detection and QC

To order Arima kits, please visit our website:
https://arimagenomics.com/

## Getting Started
We provide both Docker and Singularity container implementations of the pipeline for users to run Arima SV pipeline out of the box. You can mount the necessary input and output locations and run Arima SV pipeline in two ways.

For advanced users, we also provide a non-containerized version of the pipeline in this repository. You will need to install all the tools and dependencies yourself.

### Using Docker image
Please refer to the manual on Arima's DockerHub: https://hub.docker.com/repository/docker/arimaxiang/arima_sv

### Using Singularity image
* How to run Singularity on HPC when it is pre-installed
```
module load singularity
```

* How to install on Ubuntu systems. Note: not needed for use on TSCC, see above.
Source: https://apptainer.org/user-docs/master/quick_start.html
```
sudo apt-get update && sudo apt-get install -y build-essential libssl-dev uuid-dev libgpgme11-dev squashfs-tools libseccomp-dev wget pkg-config git cryptsetup
```

* Install Go
Download Go installer for Linux
```
wget https://go.dev/dl/go1.17.6.linux-amd64.tar.gz
```

* Remove any previous installation of Go
```
sudo rm -rf /usr/local/go
```

* Extract Go and put it in the directory '/usr/local'
```
sudo tar -C /usr/local -xzf go1.17.6.linux-amd64.tar.gz
```

* Add Go to the $PATH variable
```
export PATH=$PATH:/usr/local/go/bin
echo 'export PATH=/usr/local/go/bin:$PATH' >> ~/.bashrc && source ~/.bashrc
```

* Verify Go installation
```
go version  # Expected: 'go version go1.17.6 linux/amd64'
```

* Create a variable with the version of Singularity to be downloaded
```
export VERSION=3.8.5  # Adjust this as necessary
```

* Download the Singularity source code
```
wget https://github.com/hpcng/singularity/releases/download/v${VERSION}/singularity-${VERSION}.tar.gz
```

* Extract the Singularity code
```
tar -xzf singularity-${VERSION}.tar.gz
```

* Change directory into the Singularity directory
```
cd singularity-${VERSION}
```

* Compile the Singularity source code
```
./mconfig
make -C builddir
sudo make -C builddir install
```

* Verify Singularity Installation
```
singularity version  # '3.8.5'
```

* Download Arima's Singularity container for SV pipeline
```
wget ftp://ftp-arimagenomics.sdsc.edu/pub/singularity/Arima-SV-Pipeline-singularity-v1.3.sif
```

* Run the pipeline with Singularity (Adjust this as necessary)
```
singularity exec -B YOUR_HOST_OUTPUT_DIR:/FFPE/mydata/ Arima-SV-Pipeline-singularity-v1.3.sif bash /FFPE/Arima-SV-Pipeline-v1.3.sh -W 1 -B 1 -J 1 -H 0 -a /root/anaconda3/bin/bowtie2 -b /usr/local/bin/ -w /FFPE/HiCUP-0.8.0/ -j /FFPE/juicer-1.6/ -r /FFPE/Arima_files/reference/hg38/hg38.fa -s /FFPE/Arima_files/Juicer/hg38.chrom.sizes -c /FFPE/Arima_files/Juicer/hg38_GATC_GANTC.txt -x /FFPE/Arima_files/reference/hg38/hg38 -d /FFPE/Arima_files/HiCUP/Digest_hg38_Arima.txt -I /FFPE/test_data/fastq/JB_3_5M_R1.fastq.gz,/FFPE/test_data/fastq/JB_3_5M_R2.fastq.gz -o /FFPE/mydata/ -p JB_3_5M -e /FFPE/Arima_files/hic_breakfinder/intra_expect_100kb.hg38.txt -E /FFPE/Arima_files/hic_breakfinder/inter_expect_1Mb.hg38.txt -t 12
```


## Usage (Command line options)
Arima-SV-Pipeline-v1.3.sh [-W run_hicup] [-B run_hic_breakfinder] [-J run_juicer]
              [-H run_hiccups] [-r reference_file] [-s chrom_sizes_file] [-c cut_site_file]
              [-a bowtie2] [-x bowtie2_index_basename] [-d digest] [-w hicup_dir]
              [-b hic_breakfinder_dir] [-j juicer_dir] [-I FASTQ_string] [-S sample_size]
              [-o out_dir] [-p output_prefix] [-e exp_file_intra] [-E exp_file_inter]
              [-t threads] [-C] [-v] [-h]

* [-W run_hicup]: "1" (default) to run HiCUP pipeline, "0" to skip. If skipping,
    HiCUP_summary_report_\*.txt and \*R1_2\*.hicup.bam need to be in the HiCUP output folder.
* [-B run_hic_breakfinder]: "1" (default) to run hic_breakfinder, "0" to skip
* [-J run_juicer]: "1" (default) to run Juicer, "0" to skip
* [-H run_hiccups]: "1" to run HiCCUPS, "0" (default) to skip
* [-r reference_file]: reference FASTA file
* [-s chrom_sizes_file]: chrom.sizes file generated from the reference file
* [-c cut_site_file]: cut site file used by Juicer
* [-a bowtie2]: bowtie2 tool location
* [-x bowtie2_index_basename]: bowtie2 index file prefix
* [-d digest]: genome digest file produced by hicup_digester
* [-w hicup_dir]: directory of the HiCUP tool
* [-b hic_breakfinder_dir]: directory of the hic_breakfinder tool
* [-j juicer_dir]: directory of the Juicer tool
* [-I FASTQ_string]: a pair of FASTQ files separated by "," (no space is allowed)
* [-S sample_size]: (Optional) subsample the input FASTQ files (default: no subsample)
* [-o out_dir]: output directory
* [-p output_prefix]: output file prefix (filename only, not including the path)
* [-e exp_file_intra]: intra-chromosomal background model file for normalization
* [-E exp_file_inter]: inter-chromosomal background model file for normalization
* [-t threads]: number of threads to run HiCUP and Juicer
* [-C]: clean up intermediate files to reduce space
* [-v]: print version number and exit
* [-h]: print this help and exit

### Example

```
bash /FFPE/Arima-SV-Pipeline-v1.3.sh -W 1 -B 1 -J 1 -H 0 -a /root/anaconda3/bin/bowtie2 -b /usr/local/bin/ -w /FFPE/HiCUP-0.8.0/ -j /FFPE/juicer-1.6/ -r /FFPE/Arima_files/reference/hg38/hg38.fa -s /FFPE/Arima_files/Juicer/hg38.chrom.sizes -c /FFPE/Arima_files/Juicer/hg38_GATC_GANTC.txt -x /FFPE/Arima_files/reference/hg38/hg38 -d /FFPE/Arima_files/HiCUP/Digest_hg38_Arima.txt -I /FFPE/test_data/fastq/JB_3_5M_R1.fastq.gz,/FFPE/test_data/fastq/JB_3_5M_R2.fastq.gz -o /FFPE/test_data/test_output_docker/ -p JB_3_5M -e /FFPE/Arima_files/hic_breakfinder/intra_expect_100kb.hg38.txt -E /FFPE/Arima_files/hic_breakfinder/inter_expect_1Mb.hg38.txt -t 12
```

### Test datasets
```
ftp://ftp-arimagenomics.sdsc.edu/pub/Arima_FFPE/fastq/JB_3_5M_R1.fastq.gz
ftp://ftp-arimagenomics.sdsc.edu/pub/Arima_FFPE/fastq/JB_3_5M_R2.fastq.gz
ftp://ftp-arimagenomics.sdsc.edu/pub/ARIMA_TEST_DATASET/K562_HiC/K562_100M_R1.fastq.gz
ftp://ftp-arimagenomics.sdsc.edu/pub/ARIMA_TEST_DATASET/K562_HiC/K562_100M_R2.fastq.gz
```

## Pipeline Outputs
***The Arima SV pipeline Bioinformatics User Guide walks through an example of how to run the Arima SV pipeline using the provided test data and provides additional information on the output files. The Arima SV pipeline generates multiple files. Main output files are:***

### Arima Shallow Sequencing QC
**[output_directory]/[output_prefix]_[version_\#]_Arima_QC_shallow.txt**

Contents: This file includes QC metrics for assessing the shallow sequencing data for each CHiC library.
- Break down of the number of read pairs
- The target sequencing depth for deep sequencing
- The percentage of long-range cis interactions that overlap the probe regions

### Arima Deep Sequencing QC
**[output_directory]/[output_prefix]_[version_\#]_Arima_QC_deep.txt**

Contents: This file includes QC metrics for assessing the deep sequencing data for each CHiC library.
- Break down of the number of read pairs
- The number of loops called
- The percentage of long-range cis interactions that overlap the probe regions

### SV file in .bedpe format from hic_breakfinder
**[output_directory]/hic_breakfinder/[output_prefix].breaks.bedpe**

### HiC heatmap for visualization using Juicebox
**[output_directory]/juicer/aligned/[output_prefix]_inter_30.hic**

## Definition of QC Metrics
- Raw_pairs:	Raw # of read pairs
- Mapped_SE_reads:	# of single-end reads that can be mapped to the reference
- %_Mapped_SE_reads:	% of single-end reads that can be mapped to the reference, out of total # of single-end reads
- %_Truncated:	% of truncated single-end reads, out of all single-end reads
- Duplicated_pairs:	# of duplicated read pairs
- %_Duplicated_pairs:	% of duplicated read pairs, out of all read pairs
- Unique_valid_pairs:	HiC read pairs which are not derived from artifacts such as self-circles and dangling-ends, and which contain spatial proximity information
- %_Unique_valid_pairs:	% of unique valid read pairs, out of all read pairs
- [Obsolete] Library Complexity:	Theoretical # of unique molecules in a Hi-C library.
- Intra_pairs:	All unique pairs where both read-ends align to the same chromosome
- %_Intra_pairs:	% of all unique total pairs that have both read-ends aligning to the same chromosome
- Intra_ge_15kb_pairs:	All unique pairs where both read-ends align to the same chromosome and have an insert size >=15kb
- %_Intra_ge_15kb_pairs:	% of all unique total pairs that have both read-ends aligning to the same chromosome and have an insert size >=15kb
- Inter_pairs:	All unique pairs where each read-end aligns to a different chromosome
- %_Inter_pairs:	% of all unique total pairs where each read-end aligns to a different chromosome
- Invalid_pairs:	# of invalid read pairs
- %_Invalid_pairs:	% of invalid read pairs, out of all read pairs
- Same_circularised_pairs:	# of same-circularised pairs
- %_Same_circularised_pairs:	% of same-circularised pairs, out of all read pairs
- Same_dangling_ends_pairs:	# of same dangling-ends pairs
- %_Same_dangling_ends_pairs:	% of same dangling-ends pairs, out of all read pairs
- Same_fragment_internal_pairs:	# of same-fragment-internal pairs
- %_Same_fragment_internal_pairs:	% of same-fragment-internal pairs, out of all read pairs
- Re_ligation_pairs:	# of re-ligation pairs
- %_Re_ligation_pairs:	% of re-ligation pairs, out of all read pairs
- Contiguous_sequence_pairs:	# of contiguous-sequence pairs
- %_Contiguous_sequence_pairs:	% of contiguous-sequence pairs, out of all read pairs
- Wrong_size_pairs:	# of wrong-size pairs
- %_Wrong_size_pairs:	% of wrong-size pairs, out of all read pairs
- Mean_lib_length:	Mean library length
- Lcis_trans_ratio:	The ratio of Lcis to Trans data.  This is the signal to noise ratio for translocation calling.
- Target Raw Reads for Deep Seq:	# of Raw PE Reads to obtain high sensitivity SV calls  Based on bench marking against ground truth datasets. This value is calibrated to balance Sensitivity and Specificity of the SV calls from hic_breakfinder. This value uses conservative values for the mapping rate at 80% and the duplicate rate at 30%.
- SVs:	# of SV calls made by the Arima SV Pipeline.

## Current Pipeline Version
1.3

## Release Note
### v1.1
- Previously, the %Lcis, %Scis and %Trans (%inter) were calculated based on the total number of unique valid pairs. We changed the calculation in this version in order to make it consistent with Juicer pipeline's calculation (%Lcis = Lcis / uniquely mapped reads). We now use all unique pairs (no matter valid or invalid) as the denominator instead of the unique valid pairs. Please do not directly compare those percentage values generated by this version and the previous version. Note that users should not rely solely on %Lcis value to evaluate sample quality. This value should not be treated as a hard cut off. Instead, please use Lcis/Trans ratio to evaluate sample quality. Even with %Lcis less than 25% or Lcis/Trans ratio close to 1, we can still identify meaningful and real SVs out of the sample.
- Changed the calculation of the "intra pairs" to make it closer to Juicer pipeline's calculation. The new estimated value is coming from all unique pairs, instead of unique valid pairs.
- Other minor fixes

### v1.2
- The name of the output QC metrics files now contains the pipeline version #
- You can now skip any modules in the pipeline and still get the final QC table
- Other minor fixes

### v1.3
- HiC heatmap is generated from BAM file directly, instead of running the entire Juicer pipeline
- Added detailed breakdown list of invalid read pairs categories to the final QC table
- Added insert size calculation to the final QC table
- Added an option to remove intermediate files to reduce space
- Added an option for sub-sampling input FASTQ files (default: no subsampling)
- Renamed inter_30.hic and merged_loops.bedpe files to include the sample name
- The chromosomes in the HiC heatmap are now sorted by name instead of sorted by length
- Fixed HiC heatmap with desktop version of Juicebox compatibility issue
- Removed library complexity calculation from the pipeline
- A log file (Arima_SV_v1.3_\*.log) will be automatically generated in the output folder

## Support
For Arima customer support, please contact techsupport@arimagenomics.com

## Acknowledgments

#### Authors of HiCUP: https://www.bioinformatics.babraham.ac.uk/projects/hicup/

- Wingett S, et al. (2015) HiCUP: pipeline for mapping and processing Hi-C data F1000Research, 4:1310 (doi: 10.12688/f1000research.7334.1)

#### Authors of HiC_breakfinder: https://github.com/dixonlab/hic_breakfinder

- Dixon, J. R., Xu, J., Dileep, V., Zhan, Y., Song, F., Le, V. T., ... & Yue, F. (2018). Integrative detection and analysis of structural variation in cancer genomes. Nature genetics, 50(10), 1388-1398.

#### Authors of Juicer: https://github.com/aidenlab/juicer

- Neva C. Durand, Muhammad S. Shamim, Ido Machol, Suhas S. P. Rao, Miriam H. Huntley, Eric S. Lander, and Erez Lieberman Aiden. "Juicer provides a one-click system for analyzing loop-resolution Hi-C experiments." Cell Systems 3(1), 2016.
