



# In our Bash pipeline, we used the command line to process RNA-seq data
# We downloaded the raw FASTQ files, checked their quality, aligned reads to a reference genome
# ...converted alignment files into BAM format, sorted and indexed them
# ...and finally counted how many reads mapped to each gene
# The output of the read-counting step is a gene count file, containing gene ID and n of reads assigned to that gene in one sample per row


# ======= Step 0 Libraries =======

# Load ggplot2 package for plotting
library(ggplot2)


# ======= Step 0.5 Set directory structure =======
# These would have already been set from the Bash pipeline, but we will repeat here for clarity
echo "[Step 0] Set directory structure if not already created"

# Setting directory structure for the RNAseq analysis project
mkdir -p RNAseq_Analysis/{Data/{Raw,Trimmed,Aligned},QC_Reports/{Raw,Trimmed},Reference_Genome,Counts,Scripts,Reports}

# Enter the main project directory
cd RNAseq_Analysis

####################################
# Week 6
####################################

# ======= Inspecting our count files =======

# Set the count file directory
counts_dir <- "/home/shared/counts"

# List the files in the directory
count_files <- list.files(counts_dir)
count_files

# Checking type
str(count_files)
class(count_files)
length(count_files)

####################################
# Reading and inspecting count files
####################################

# Create an empty list to store one data frame per sample
gene_counts_list <- list()

# Loop through each count file
for (file_name in count_files) {

    # Create full file path
    file_path <- file.path(counts_dir, file_name)

    # Remove .txt extension for sample naming
    base <- sub("\\.txt$", "", file_name)

    # Identify current sample in console output
    message("\n===== Reading count file: ", base, " =====")

    # Read the count file into R
    # Files do not contain column headers
    gene_counts <- read.table(
        file_path,
        header = FALSE,
        col.names = c("gene_id", "count")
    )

    # Inspect first few rows
    message("First few rows: ")
    print(head(gene_counts))

    # Inspect structure
    message("Structure of the data frame: ")
    str(gene_counts)

    # Inspect dimensions
    message(
        "Dimensions: ",
        nrow(gene_counts),
        " rows x ",
        ncol(gene_counts),
        " columns"
    )

    # Inspect first few gene IDs and count values
    message("First few gene IDs and counts: ")
    print(head(gene_counts$gene_id))
    print(head(gene_counts$count))

    # Check class of each column
    message("gene_id class: ", class(gene_counts$gene_id))
    message("count class: ", class(gene_counts$count))

    # Store this sample's data frame in the list
    gene_counts_list[[base]] <- gene_counts
}

# Check that all six sample count files were stored
message("\n===== Import complete =====")
message("Number of count files imported: ", length(gene_counts_list))
print(names(gene_counts_list))

# Sanity check to ensure we have six count files in the list for six samples
stopifnot(length(gene_counts_list) == 6)


####################################
# Removing HTSeq-count summary rows
####################################

# HTSeq-count files usually contain several summary rows at the bottom
# These rows begin with double underscores
# Useful for quality checks but they are not genes, so we remove

# Create empty lists to store the gene counts and HTSeq summary rows for each sample
gene_counts_only_list <- list()
htseq_summary_list <- list()

for (sample_id in names(gene_counts_list)) {

    # Identify current sample in console output
    message("\n===== Removing HTSeq summary rows: ", sample_id, " =====")

    # Pull current sample from the list
    gene_counts <- gene_counts_list[[sample_id]]

    # Identify HTSeq summary rows
    summary_rows <- grepl("^__", gene_counts$gene_id)
    message("First few summary rows: ")
    print(head(summary_rows))
    message("Last few summary rows: ")
    print(tail(summary_rows))
    message("Number of HTSeq summary rows: ", sum(summary_rows))

    # Separate gene rows from summary rows
    gene_counts_only <- gene_counts[!summary_rows, ]
    htseq_summary <- gene_counts[summary_rows, ]

    # Store results for this sample
    gene_counts_only_list[[sample_id]] <- gene_counts_only
    htseq_summary_list[[sample_id]] <- htseq_summary

    # Inspect
    message("Gene counts (excluding summary rows): ")
    print(head(gene_counts_only))
    message("HTSeq summary rows: ")
    print(htseq_summary)
}

####################################
# Saving cleaned gene count tables
####################################

for (sample_id in names(gene_counts_only_list)) {

    # Pull current cleaned sample from list
    gene_counts_only <- gene_counts_only_list[[sample_id]]

    # Save cleaned gene count table
    write.csv(
        gene_counts_only,
        file = paste0(
            "sle777repo/Week6_results/",
            sample_id,
            "_cleaned_gene_counts.csv"
        ),
        row.names = FALSE
    )
}

####################################
# Summarising the count data
####################################

# The mean and median are often quite different in RNA-seq data
# Many genes have low counts
# ...while a smaller n of genes can be very highly expressed

for (sample_id in names(gene_counts_only_list)) {

    # Pull current sample from list
    gene_counts_only <- gene_counts_only_list[[sample_id]]

    # Identify current sample in console output
    message("\n===== Sample: ", sample_id, " =====")

    # Quick summary of count distribution
    print(summary(gene_counts_only$count))

    # How many genes are present?
    message("Number of genes: ", nrow(gene_counts_only))

    # What is the total number of reads assigned to genes?
    message("Total reads assigned to genes: ", sum(gene_counts_only$count))

    # A gene with zero counts has no reads assigned to it in this sample
    message("Genes with zero counts: ", sum(gene_counts_only$count == 0))

    # Genes with at least ten reads
    message("Genes with >= 10 reads: ", sum(gene_counts_only$count >= 10))

    # Genes with at least 100 reads
    message("Genes with >= 100 reads: ", sum(gene_counts_only$count >= 100))
}

####################################
# Counting genes with zero, low and high expression
####################################

# Subsettings means selecting part of a data frame
# Subsetting is very common in bioinformatics
# We subset genes by count, by gene ID, by fold change
# ...or by functional category

for (sample_id in names(gene_counts_only_list)) {
    
    # Pull current sample from list
    gene_counts_only <- gene_counts_only_list[[sample_id]]

    # Identify current sample in console output
    message("\n===== Sample: ", sample_id, " =====")

    # Create a data frame containing genes with at least ten reads
    expressed_genes <- gene_counts_only[gene_counts_only$count >= 10, ]
    message("Genes with >= 10 reads: ", nrow(expressed_genes))
    message("Quick look at a few expressed genes: ")
    print(head(expressed_genes))

    # Genes with zero reads
    zero_count_genes <- gene_counts_only[gene_counts_only$count == 0, ]
    message("Genes with zero counts: ", nrow(zero_count_genes))
    message("Quick look at a few zero count genes: ")
    print(head(zero_count_genes))

    # Genes with at least 1000 reads
    high_count_genes <- gene_counts_only[gene_counts_only$count >= 1000, ]
    message("Genes with >= 1000 reads: ", nrow(high_count_genes))
    message("Quick look at a few high count genes: ")
    print(head(high_count_genes))

}

####################################
# Sorting genes by read count
####################################

# Sort to identify the most highly expressed genes in sample
for (sample_id in names(gene_counts_only_list)) {

    gene_counts_only <- gene_counts_only_list[[sample_id]]

    message("\n===== Sorting genes: ", sample_id, " =====")

    ordered_genes <- gene_counts_only[
        order(gene_counts_only$count, decreasing = TRUE),
    ]
    message("Check first few ordered genes: ")
    print(head(ordered_genes))

    top10_genes <- ordered_genes[1:10, ]
    top20_genes <- ordered_genes[1:20, ]

    message("Top 10 genes:")
    print(top10_genes)

    message("Top 20 genes:")
    print(top20_genes)

    # Save top 20 genes for this sample
    write.csv(
        top20_genes,
        file = paste0(
            "sle777repo/Week6_results/",
            sample_id,
            "_top20_genes.csv"
        ),
        row.names = FALSE
    )
}

####################################
# Plotting count distributions
####################################

# RNA-seq counts often have a skewed distribution
# Many genes have low counts
# ...while a smaller number of genes have very high counts
# It is common to plot transformed counts

for (sample_id in names(gene_counts_only_list)) {

    # Pull current sample from list
    gene_counts_only <- gene_counts_only_list[[sample_id]]

    # Log transform counts for visualisation
    # Add 1 because some genes have zero counts
    # The logarithm of zero is not defined
    gene_counts_only$log10_count <- log10(gene_counts_only$count + 1)

    # Save to output file for current sample id histogram
    png(
        paste0(
            "sle777repo/Week6_results/",
            sample_id,
            "_log10_count_distribution.png"
        )
    )
    # Plot transformed values
    hist(
        gene_counts_only$log10_count,
        xlab = "log10(count + 1)",
        ylab = "Number of genes",
        main = paste("Distribution of gene expression counts:", sample_id)
    )

    # Close the PNG device
    dev.off()  
}

message(
    "Raw RNA-seq counts can span a wide range. Log transformation is useful ",
    "for visualisation because it allows low-count and high-count genes to ",
    "be shown more clearly on the same plot."
)

####################################
# Intro to ggplot2
####################################

# Base R plots are useful but many researches use ggplot2 for data vis
# It provides a conistent and flexible plotting system

### data visualisation basics
#       data
#       mapping (aesthetics)
#       geometric representation
#       statistics
#       facet
#       coordinate space
#       labels

# Basic structure is...
# ggplot(data, aes(x = column_name)) + geom_function()

# ggplot() starts the plot
# data is the data frame
# aes() tells R which columns to plot.
# geom_ tells R what type of plot to draw.

for (sample_id in names(gene_counts_only_list)) {

    # Pull current sample from list and reset gene_counts_only
    gene_counts_only <- gene_counts_only_list[[sample_id]]

    # Log transform counts for visualisation
    # Add 1 because some genes have zero counts
    # This was done in previous loop but again for clarity
    gene_counts_only$log10_count <- log10(gene_counts_only$count + 1)

    # Make a hist using ggplot2
    p <- ggplot(gene_counts_only, aes(x = log10_count)) +
        geom_histogram(bins = 50) +
        labs(
            title = paste("Distribution of gene expression counts:", sample_id),
            x = "log10(count + 1)",
            y = "Number of genes"
        )

    # Save to output file for current sample id histogram
    ggsave(
        filename = paste0(
            "sle777repo/Week6_results/",
            sample_id,
            "_log10_count_distribution_ggplot2.png"
        ),
        plot = p,
        width = 7,
        height = 5
    )
}


####################################
# Plotting the most highly expressed genes
####################################

for (sample_id in names(gene_counts_only_list)) {

    # Pull current sample from list
    gene_counts_only <- gene_counts_only_list[[sample_id]]

    # Sort genes by read count
    ordered_genes <- gene_counts_only[
        order(gene_counts_only$count, decreasing = TRUE),
    ]

    # Select top 20 genes
    top20_genes <- ordered_genes[1:20, ]

    # Make a bar plot
    p <- ggplot(top20_genes, aes(x = reorder(gene_id, count), y = count)) +
        geom_col() +
        coord_flip() +
        labs(
            title = paste("Top 20 most highly expressed genes:", sample_id),
            x = "Gene ID",
            y = "Read count"
        )
    
    # Save plot
    ggsave(
        filename = paste0(
            "sle777repo/Week6_results/",
            sample_id,
            "_top20_gene_expression_plot.png"
        ),
        plot = p,
        width = 7,
        height = 5,
        dpi = 300
    )
}

####################################
# Week 6: Summary
####################################

# We read a single HTSeq-count file into R
# We inspected it, removed summary rows, and counted how many genes were expressed
# and drew our first gene expression plots

# But a single sample cannot tell us anything about differential expression

# Record the R session info
sessionInfo()



