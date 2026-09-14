# SLE777 RNA-seq Pipeline

**Student ID:** s224907333  
**Sequencing accessions:** SRR10551662, SRR10551661, SRR10551660, SRR10551659, SRR10551658, SRR10551657
**BioProject:** PRJNA592304

## Purpose


| Step | Process | Tool / method |
|---|---|---|
| 0 | Set directory structure | Bash (`mkdir`) |
| 1 | Download sequencing data and convert to FASTQ | SRA Toolkit (`prefetch`, `fastq-dump`) |
| 2 | Raw read quality control | FastQC |
| 3 | Trim low-quality bases and adapter sequences | Skewer |
| 3.5 | Quality control of trimmed reads | FastQC |
| 4 | Download reference genome and gene annotation | `wget` / Ensembl |
| 5 | Build reference genome index | HISAT2 (`hisat2-build`) |
| 6 | Align trimmed reads to reference genome | HISAT2 |
| 7 | Convert, sort and index alignments; generate mapping statistics | SAMtools |
| 8 | Count reads assigned to genes | HTSeq (`htseq-count`) |
| 9 | Compile QC and alignment reports | MultiQC |
| 10 | Differential expression and downstream analysis | DESeq2 *to be added* |

This Bash pipeline performs an end-to-end RNA sequencing analysis of six publicly available *Saccharomyces cerevisiae*. RNA-seq datasets obtained from the NCBI Sequence Read Archive (SRA) [7]. The selected datasets were generated as part of BioProject PRJNA592304, a study exploring gene expression across ... *Saccharomyces cerevisiae* industrial flor yeast strain at multiple stages of biofilm formation in the context of wine making to better understand ...

--- 

This section needs updating to reflect the actual study

...Description of the study [10] Nine RNA samples (three sampling points, each in three replications). The pipeline analyses six RNA-seq datasets from the study: ... strain ... (Replicates 1, 2, 3 - ...) and ... strain (Replicates 1, 2, 3 - ...). All samples were sequenced as single-end RNA-seq libraries on an Illumina HiSeq 2500 platform...

---

The pipeline downloads raw sequencing data in SRA format and converts it to FASTQ format using the NCBI SRA Toolkit v2.11.3 [9]. Sequence quality is assessed using FastQC (v0.11.9) [2] before and after quality trimming with Skewer (v0.2.2) [5]. Trimmed reads are aligned to the *Saccharomyces cerevisiae* reference genome (Ensembl assembly R64-1-1, release 112) [4] using HISAT2 (v2.2.1) [6]. SAMtools (v1.13) [8] is used to convert the aligned reads from SAM to BAM format to reduce size, before sorting reads by position on the genome and indexing the BAM files for efficient searching. SAMtools `flagstat` command performs a quick health check on the alignment by summarising read mapping statistics, before gene-level read counts are generated using HTSeq-count (v1.99.2) [1] for downstream analysis of gene expression. Finally, MultiQC (v1.12) [3] summarises quality metrics from all analysis steps in the workflow into a single report.

The pipeline is designed to run on a Linux-based system with all required software installed and available through the system PATH. All analysis steps are recorded in a timestamped log file to facilitate reproducibility and troubleshooting.

## Data

| Metadata | Description |
|---|---|
| Sequencing accessions | SRR10551662, SRR10551661, SRR10551660, SRR10551659, SRR10551658, SRR10551657 |
| BioProject | PRJNA592304 |
| Download database | NCBI Sequence Read Archive |
| Access date | ... 2026 |
| Data-sharing terms | Publicly available through the NCBI SRA under the International Nucleotide Sequence Database Collaboration (INSDC) data-sharing framework |

## Reference genome

| Feature | Description |
|---|---|
| Species | *Saccharomyces cerevisiae* |
| Genome source | Ensembl |
| Assembly version | R64-1-1 |
| Annotation release | Release 112 GTF |

## Software

| Software | Version |
|---|---|
| Bash | 5.1.16 |
| SRA Toolkit | 2.11.3 |
| FastQC | 0.11.9 |
| Skewer | 0.2.2 |
| HISAT2 | 2.2.1 |
| SAMtools | 1.13 |
| HTSeq-count | 1.99.2 |
| MultiQC | 1.12 |

## Running the pipeline

The Bash pipeline can be run by executing the following commands in a Bash terminal:

```{bash, eval=FALSE}
# Make the script executable
chmod +x s224907333_pipeline_assessment_4.sh

# Run the script
bash s224907333_pipeline_assessment_4.sh |& tee s224907333_assessment_4_log.txt
```

The pipeline requires the following dependencies: SRA Toolkit, FastQC, Skewer, MultiQC, HISAT2, SAMtools, and HTSeq-count (see [Software](#software) for version numbers).

The entire pipeline workflow takes approximately ... minutes on the Deakin Linux bioinformatics server using the datasets analysed in this report. Runtime will vary depending on hardware specifications and internet download speed.

The expected core directory structure after running the pipeline is as follows:

RNAseq_Analysis/
├── Counts/                     # Final gene-level read counts
├── Data/                       # Raw and processed sequencing data files
│   ├── Aligned/                # SAM/BAM alignment files, BAM indexes, and alignment statistics
│   ├── Raw/                    # Raw FASTQ files downloaded from SRA
│   └── Trimmed/                # Trimmed FASTQ files after quality control
├── QC_Reports/                 
│   ├── Raw/                    # FastQC reports for raw FASTQ files
│   └── Trimmed/                # FastQC reports for trimmed FASTQ files
├── Reference_Genome/           # Reference genome files (FASTA and GTF) and HISAT2 index files
├── Reports/                    # MultiQC report dir and HTML plus any additional summary reports
├── Scripts/                    # Directory reserved for analysis scripts


... Need to add extra to reflect the R analysis

The log produced by the pipeline will be saved in the file `s224907333_assessment_4_log.txt` in the directory from which the pipeline is executed. This log will contain detailed information about each step of the analysis, including any errors or warnings encountered when running the pipeline.

## References and attribution

1. Anders S, Pyl PT and Huber W (2015) ‘HTSeq—a Python framework to work with high-throughput sequencing data’, *Bioinformatics*, 31(2):166–169, [https://doi.org/10.1093/bioinformatics/btu638](https://doi.org/10.1093/bioinformatics/btu638)

2. Andrews S (8 January 2019) *[FastQC: a quality control tool for high throughput sequence data](https://www.bioinformatics.babraham.ac.uk/projects/fastqc/)* [computer software], v0.11.9, Babraham Bioinformatics, accessed 19 August 2026.

3. Ewels P, Magnusson M, Lundin S and Käller M (2016) ‘MultiQC: summarize analysis results for multiple tools and samples in a single report’, *Bioinformatics*, 32(19):3047–3048, [https://doi.org/10.1093/bioinformatics/btw354](https://doi.org/10.1093/bioinformatics/btw354)

4. Harrison PW, Amode MR, Austine-Orimoloye O, Azov AG, Barba M, Barnes I, Becker A, Bennett R, Berry A, Bhai J, Bhurji SK, Boddu S, Branco Lins PR, Brooks L, Ramaraju SB, Campbell LI, Martinez MC, Charkhchi M, Chougule K, Cockburn A, Davidson C, De Silva NH, Dodiya K, Donaldson S, El Houdaigui B, Naboulsi TE, Fatima R, Giron CG, Genez T, Grigoriadis D, Ghattaoraya GS, Martinez JG, Gurbich TA, Hardy M, Hollis Z, Hourlier T, Hunt T, Kay M, Kaykala V, Le T, Lemos D, Lodha D, Marques-Coelho D, Maslen G, Merino GA, Mirabueno LP, Mushtaq A, Hossain SN, Ogeh DN, Sakthivel MP, Parker A, Perry M, Piližota I, Poppleton D, Prosovetskaia I, Raj S, Pérez-Silva JG, Salam AIA, Saraf S, Saraiva-Agostinho N, Sheppard D, Sinha S, Sipos B, Sitnik V, Stark W, Steed E, Suner MM, Surapaneni L, Sutinen K, Tricomi FF, Urbina-Gómez D, Veidenberg A, Walsh TA, Ware D, Wass E, Willhoft NL, Allen J, Alvarez-Jarreta J, Chakiachvili M, Flint B, Giorgetti S, Haggerty L, Ilsley GR, Keatley J, Loveland JE, Moore B, Mudge JM, Naamati G, Tate J, Trevanion SJ, Winterbottom A, Frankish A, Hunt SE, Cunningham F, Dyer S, Finn RD, Martin FJ, and Yates AD (2024) 'Ensembl 2024', *Nucleic Acids Research*, 52(D1):D891-D899, [https://doi.org/10.1093/nar/gkad1049](https://doi.org/10.1093/nar/gkad1049)

5. Jiang H, Lei R, Ding SW and Zhu S (2014) 'Skewer: a fast and accurate adapter trimmer for next-generation sequencing paired-end reads', *BMC Bioinformatics*, 15:article no. 182, [https://doi.org/10.1186/1471-2105-15-182](https://doi.org/10.1186/1471-2105-15-182)

6. Kim D, Paggi JM, Park C, Bennett C and Salzberg SL (2019) ‘Graph-based genome alignment and genotyping with HISAT2 and HISAT-genotype’, *Nature Biotechnology*, 37(8):907–915, [https://doi.org/10.1038/s41587-019-0201-4](https://doi.org/10.1038/s41587-019-0201-4)

7. Leinonen R, Sugawara H and Shumway M on behalf of the International Nucleotide Sequence Database Collaboration (2011) ‘The Sequence Read Archive’, *Nucleic Acids Research*, 39:D19–D21, [https://doi.org/10.1093/nar/gkq1019](https://doi.org/10.1093/nar/gkq1019)

8. Li H, Handsaker B, Wysoker A, Fennell T, Ruan J, Homer N, Marth G, Abecasis G and Durbin R (2009) ‘The Sequence Alignment/Map format and SAMtools’, *Bioinformatics*, 25(16):2078–2079, [https://doi.org/10.1093/bioinformatics/btp352](https://doi.org/10.1093/bioinformatics/btp352)

9. National Center for Biotechnology Information (NCBI) (2021) [SRA Toolkit](https://github.com/ncbi/sra-tools) [computer software], version 2.11.3, National Center for Biotechnology Information, accessed 19 August 2026.

10. Mardanov AV, Eldarov MA, Beletsky AV, Tanashchuk TN, Kishkovskaya SA and Ravin NV (2020) 'Transcriptome Profile of Yeast Strain Used for Biological Wine Aging Revealed Dynamic Changes of Gene Expression in Course of Flor Development', *Front. Microbiol*, 3(11):538, [https://doi.org/10.3389/fmicb.2020.00538](https://doi.org/10.3389/fmicb.2020.00538)

The RNA-seq datasets analysed in this pipeline were generated by ... et al. [10] (BioProject PRJNA592304) and were accessed through the NCBI Sequence Read Archive. We acknowledge the authors of the original study and the ... for generating and publicly sharing these data.

### Acknowledgements

This assessment was completed with the assistance of ChatGPT (accessed August-October 2026) and Copilot suggested code completion (accessed June-October 2026). With the permission of my Unit Chair, I have used these tools to help develop the purpose description, acknowledgements, and data reuse statement that provide the background for the README markdown component of the assessment. I also used it to quality assure my Bash pipeline and README to identify syntax errors, citation issues, or typos. Finally, ChatGPT suggested the use of SAMtools view and flagstat to identify the primary reads against a locus assigned to me for the assessment, however the code written was based on the Deakin unit content and my own understanding. All other writing and analysis in this assessment is my own.

## Data reuse statement

The RNA-seq datasets analysed in this pipeline were generated by ... (BioProject PRJNA592304) and made publicly available through the NCBI Sequence Read Archive under the International Nucleotide Sequence Database Collaboration (INSDC) data-sharing framework. These data are reused in this assignment solely for educational purposes.

Reuse of these data requires acknowledgement of the original study, preservation of associated metadata, and compliance with the repository's terms of use.
