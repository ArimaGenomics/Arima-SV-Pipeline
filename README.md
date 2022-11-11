![alt text](https://arimagenomics.com/wp-content/files/2021/08/Arima-Genomics-logo.png "Celebrating Science and Scientist")

# Arima SV Pipeline for Mapping, SV Detection and QC

To order Arima kits, please visit our website:
https://arimagenomics.com/

## Getting Started
We provide both Docker and Singularity container implementations of the pipeline for users to run Arima SV pipeline out of the box. You can mount the necessary input and output locations and run Arima SV pipeline in two ways.

For advanced user, we also provide a non-containerized version of the pipeline in this repository. You will need to install all the tools and dependencies yourself.

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
wget ftp://ftp-arimagenomics.sdsc.edu/pub/singularity/Arima-SV-Pipeline-singularity-v1.sif
```

* Run the pipeline with Singularity (Adjust this as necessary)
```
singularity exec -B YOUR_HOST_OUTPUT_DIR:/FFPE/mydata/ Arima-SV-Pipeline-singularity-v1.sif bash /FFPE/Arima-SV-Pipeline-v1.sh -W 1 -B 1 -J 1 -H 0 -a /root/anaconda3/bin/bowtie2 -b /usr/local/bin/ -w /FFPE/HiCUP-0.8.0/ -j /FFPE/juicer-1.6/ -r /FFPE/Arima_files/reference/hg38/hg38.fa -s /FFPE/Arima_files/Juicer/hg38.chrom.sizes -c /FFPE/Arima_files/Juicer/hg38_GATC_GANTC.txt -x /FFPE/Arima_files/reference/hg38/hg38 -d /FFPE/Arima_files/HiCUP/Digest_hg38_Arima.txt -I /FFPE/test_data/fastq/JB_3_5M_R1.fastq.gz,/FFPE/test_data/fastq/JB_3_5M_R2.fastq.gz -o /FFPE/mydata/ -p JB_3_5M -e /FFPE/Arima_files/hic_breakfinder/intra_expect_100kb.hg38.txt -E /FFPE/Arima_files/hic_breakfinder/inter_expect_1Mb.hg38.txt -t 12 &> log.txt
```


## Usage (Command line options)
Arima-SV-Pipeline-v1.sh [-W run_hicup] [-B run_hic_breakfinder] [-J run_juicer]
              [-H run_hiccups] [-r reference_file] [-s chrom_sizes_file] [-c cut_site_file]
              [-a bowtie2] [-x bowtie2_index_basename] [-d digest] [-w hicup_dir]
              [-b hic_breakfinder_dir] [-j juicer_dir] [-I FASTQ_string] [-o out_dir]
              [-p output_prefix] [-e exp_file_intra] [-E exp_file_inter] [-t threads] [-v] [-h]

* [-W run_hicup]: "1" (default) to run HiCUP pipeline, "0" to skip. If skipping,
    HiCUP_summary_report_*.txt and *R1_2*.hicup.bam need to be in the HiCUP output folder.
* [-B run_hic_breakfinder]: "1" (default) to run hic_breakfinder, "0" to skip
* [-J run_juicer]: "1" (default) to run Juicer, "0" to skip
* [-H run_hiccups]: "1" to run HiCCUPS, "0" (default) to skip
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
bash /FFPE/Arima-SV-Pipeline-v1.sh -W 1 -B 1 -J 1 -H 0 -a /root/anaconda3/bin/bowtie2 -b /usr/local/bin/ -w /FFPE/HiCUP-0.8.0/ -j /FFPE/juicer-1.6/ -r /FFPE/Arima_files/reference/hg38/hg38.fa -s /FFPE/Arima_files/Juicer/hg38.chrom.sizes -c /FFPE/Arima_files/Juicer/hg38_GATC_GANTC.txt -x /FFPE/Arima_files/reference/hg38/hg38 -d /FFPE/Arima_files/HiCUP/Digest_hg38_Arima.txt -I /FFPE/test_data/fastq/JB_3_5M_R1.fastq.gz,/FFPE/test_data/fastq/JB_3_5M_R2.fastq.gz -o /FFPE/test_data/test_output_docker/ -p JB_3_5M -e /FFPE/Arima_files/hic_breakfinder/intra_expect_100kb.hg38.txt -E /FFPE/Arima_files/hic_breakfinder/inter_expect_1Mb.hg38.txt -t 12 &> /FFPE/test_data/test_output_docker/log.txt
```

## Pipeline Outputs
***The Arima SV pipeline Bioinformatics User Guide walks through an example of how to run the Arima SV pipeline using the provided test data and provides additional information on the output files. The Arima SV pipeline generates multiple files. Main output files are:***

### Arima Shallow Sequencing QC

#### [output_directory]/[output_prefix]_Arima_QC_shallow.txt
Contents: This file includes QC metrics for assessing the shallow sequencing data for each CHiC library.
- Break down of the number of read pairs
- The target sequencing depth for deep sequencing
- The percentage of long-range cis interactions that overlap the probe regions

### Arima Deep Sequencing QC

#### [output_directory]/[output_prefix]_Arima_QC_deep.txt
Contents: This file includes QC metrics for assessing the deep sequencing data for each CHiC library.
- Break down of the number of read pairs
- The number of loops called
- The percentage of long-range cis interactions that overlap the probe regions

### SV file in .bedpe format from hic_breakfinder

#### [output_directory]/hic_breakfinder/[output_prefix].breaks.bedpe

### Arima HiC heatmap for visualization using Juicebox

#### [output_directory]/juicer/aligned/inter_30.hic


## Arima Pipeline Version
1.0

## Support
For Arima customer support, please contact techsupport@arimagenomics.com
