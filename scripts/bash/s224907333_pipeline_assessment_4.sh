#!/bin/bash
set -e
################################################################################
# Script: s224907333_pipeline_assessment_4.sh
# Author: Ivy - s224907333
# Purpose: Complete RNA-seq analysis pipeline from raw reads to gene counts

# Dependencies: fastqc, skewer, multiqc, hisat2, samtools, htseq-count
# Usage: chmod +x s224907333_pipeline_assessment_4.sh
#        bash s224907333_pipeline_assessment_4.sh |& tee s224907333_assessment_4_log.txt
# or     time ./s224907333_pipeline_assessment_4.sh |& tee s224907333_assessment_4_log.txt
################################################################################

# ======= Step 0 Set directory structure =======

echo "[Step 0] Set directory structure: create RNAseq_Analysis project folders"

# Setting directory structure for the RNAseq analysis project
mkdir -p RNAseq_Analysis/{Data/{Raw,Trimmed,Aligned},QC_Reports/{Raw,Trimmed},Reference_Genome,Counts,Scripts,Reports}

# Enter the main project directory
cd RNAseq_Analysis

# ======= Step 1 Download sequencing files =======
# Download the six sequence files from the flor yeast study and convert to FASTQ format

echo "[Step 1] Download sequencing files: fetch SRA and convert to FASTQ"

# Download the sequencing data for six accession IDs from SRA
# Loop through each sequence accession ID and convert to FASTQ using SRA toolkit
for id in SRR10551662 SRR10551661 SRR10551660 SRR10551659 SRR10551658 SRR10551657; do
    # Fetch the SRA file/s and save to Data/Raw directory
    prefetch --output-directory Data/Raw "$id"

    # Convert to FASTQ format and specify output directory
    fastq-dump \
        --outdir Data/Raw \
        "Data/Raw/${id}/${id}.sra"
done


# ======= Step 2 Raw data quality control =======
# *** Check the quality of all raw sequencing files ***

echo "[Step 2] Raw data quality control: run FastQC on raw FASTQ files"

# Analyse all FASTQ files and output to QC reports
for file in Data/Raw/*.fastq; do
    fastqc "$file" -o QC_Reports/Raw
done
# *** We get a zip and an html static summary report for each sample with _fastqc suffix ***

# Unzip the FastQC reports
for file in QC_Reports/Raw/*.zip; do
    unzip "$file" -d QC_Reports/Raw
done

# Combine all summary.txt files into one file for easier inspection
cat QC_Reports/Raw/*/summary.txt > QC_Reports/Raw/all_summary.txt


# ======= Step 3 Trimming =======
# *** Trim the reads and check the quality of the trimmed files ***

echo "[Step 3] Trimming: remove low-quality bases and adapter sequences using skewer"

# *** We are trimming our raw data using Skewer to remove low-quality bases and adapter sequences
# *** A higher Q score means more trustworthy base calls. Below Q20 is worse than a 1-in-100 error rate ***

# *** Before trimming, expect to see quality tailing off at the ends of reads
# *** as well as some adapter content and possibly a warning on read-length uniformity

# Loop through each FASTQ file and trim using Skewer
for file in Data/Raw/*.fastq; do
    # Remove the .fastq extension to create the output prefix
    base=$(basename "$file" .fastq)

    # Trim bases below Q20 and write output to Data/Trimmed
    skewer \
        -q 20 \
        -o "Data/Trimmed/${base}" \
        "$file"
done

# Now our per-base quality should be higher (green) for more of the read
# Adapter content (contamination) should drop
# Also expecting read lengths to become more variable as trimming shortened some reads


# ======= Step 3.5 FastQC on trimmed data =======
# *** Rerun QC and check quality of trimmed data ***

echo "[Step 3.5] FastQC on trimmed data: rerun QC and summarise trimmed metrics"

# Run FastQC on trimmed files and output to QC_Reports/Trimmed
for file in Data/Trimmed/*.fastq; do
    fastqc "$file" -o QC_Reports/Trimmed
done

# Unzip reports
for file in QC_Reports/Trimmed/*.zip; do
    unzip "$file" -d QC_Reports/Trimmed
done

# Combine all summaries
cat QC_Reports/Trimmed/*/summary.txt > QC_Reports/Trimmed/all_summary_trimmed.txt


# ======= Step 4 Download reference genome and annotation =======
# *** Download Saccharomyces cerevisiae genome assembly R64-1-1 and Ensembl annotation release 112 using wget ***

echo "[Step 4] Download reference genome and annotation: download R64-1-1 release 112 reference"

# Don't overwrite if the file already exists
# Save to Reference_Genome folder
wget \
    -nc \
    -P Reference_Genome \
    https://ftp.ensembl.org/pub/release-112/fasta/saccharomyces_cerevisiae/dna/Saccharomyces_cerevisiae.R64-1-1.dna.toplevel.fa.gz
    
# unzip the genome
gunzip Reference_Genome/Saccharomyces_cerevisiae.R64-1-1.dna.toplevel.fa.gz

# Download the GTF annotation file from release 112
wget \
    -nc \
    -P Reference_Genome \
    https://ftp.ensembl.org/pub/release-112/gtf/saccharomyces_cerevisiae/Saccharomyces_cerevisiae.R64-1-1.112.gtf.gz

# unzip the annotation file
gunzip Reference_Genome/Saccharomyces_cerevisiae.R64-1-1.112.gtf.gz


# ======= Step 5 Build genome index =======
# *** We are building a searchable HISAT2 index from the reference genome ***
# *** For each short read, we want to find the place it most likely came from ***
# *** Reference is fixed, so we prepare once and reuse for all samples ***

# *** A read from mRNA can span two exons that sit far apart on the genome with a gap between them from introns ***
# *** HISAT2 is splice-aware and can align reads that span these junctions ***
# *** A DNA aligner that can't do this would misplace or discard those junction reads ***

echo "[Step 5] Build genome index: create HISAT2 index from reference genome"

# Build the HISAT2 index from the reference genome FASTA file with specified output prefix
hisat2-build \
    Reference_Genome/Saccharomyces_cerevisiae.R64-1-1.dna.toplevel.fa \
    Reference_Genome/saccharomyces_hisat2_index


# ======= Step 6 Alignment =======
# *** Align reads to reference genome ***

echo "[Step 6] Alignment: align trimmed single-end reads to the HISAT2 genome index"

# Take each trimmed FASTQ file and align to the HISAT2 index
for file in Data/Trimmed/*-trimmed.fastq; do
    base=$(basename "$file" -trimmed.fastq)

    # Align the reads to the reference genome index using trimmed FASTQ files
    # The -S option specifies the output SAM file with one line per read and where it landed on the genome
    hisat2 \
        -x Reference_Genome/saccharomyces_hisat2_index \
        -U "$file" \
        -S "Data/Aligned/${base}.sam"
done

# ======= Step 7 Tidy the alignments: Process =======
# *** Now we need to convert the SAM to BAM, sort, and index it for downstream analysis ***
# *** SAM is big and unordered. Samtools compresses it to BAM and sorts reads by position, indexes, and reports ***

# *** Index is built using .bai, a tidy companion file so software can quickly find reads in the BAM without reading the whole file ***
# *** Summarise using flagstat to get a quick overview of how many reads mapped, unmapped, duplicated - health check on alignment ***

echo "[Step 7] Process alignments: convert SAM to BAM, sort, index, and save flagstat summaries"

# Loop through each SAM file and convert to BAM, sort, index, and summarise
for file in Data/Aligned/*.sam; do
    base=$(basename "$file" .sam)

    # Convert SAM to BAM and output to Aligned folder
    samtools view \
        -b "$file" \
        -o "Data/Aligned/${base}.bam"

    # Sort reads by position on the genome
    samtools sort \
        "Data/Aligned/${base}.bam" \
        -o "Data/Aligned/${base}_sorted.bam"

    # Build the .bai index
    samtools index "Data/Aligned/${base}_sorted.bam"

    # Write mapping summary of sorted BAM to a text file
    samtools flagstat \
        "Data/Aligned/${base}_sorted.bam" \
        > "Data/Aligned/${base}_flagstat.txt"
done

# *** You want to see high mapping rate for a healthy alignment ***
# *** The paired lines read zero simply because our data is single-end so no read pairs to report ***


# ======= Step 8 Read counting =======
# *** Alignment told us where each read is mapped but not the gene name yet ***
# *** The GTF annotation file is the missing map listing every gene's coordinates ***
# *** HTSeq overlaps each read's position with the GTF to assign and adds a count to a gene's tally ***
# *** Reads overlapping annotated exons are assigned to genes using the gene_id attribute ***
# *** The result is the count table - the direct measure of expression we set out to get ***

echo "[Step 8] Read counting: count reads mapping to each gene using HTSeq and the release 112 GTF"

# Counting reads for each gene using HTSeq-count
for file in Data/Aligned/*_sorted.bam; do
    base=$(basename "$file" _sorted.bam)

    # HTSeq-count arguments: input format, sort order, strandedness, BAM file, GTF annotation, then output counts
    htseq-count \
        -f bam \
        -r pos \
        -s no \
        "$file" \
        Reference_Genome/Saccharomyces_cerevisiae.R64-1-1.112.gtf \
        > "Counts/${base}_counts.txt"
done


# ======= Step 9 Run MultiQC =======
# *** MultiQC compiles all QC reports into one ***
# *** Does not re-analyse the reads. Uses FastQC reports to create a summary report for all samples ***
# *** Every sample sits on the same axis and can be compared ***

echo "[Step 9] MultiQC: compile all QC and alignment reports across the project directory"

# Run MultiQC in the project directory to generate a summary report
# Save to Reports folder
multiqc . \
    -o "Reports"

# ======= Print pipeline complete =======
echo "=============================================="
echo " PIPELINE COMPLETE"
echo " finished: $(date '+%Y-%m-%d %H:%M:%S')"
echo "=============================================="

