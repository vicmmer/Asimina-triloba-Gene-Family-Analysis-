#!/usr/bin/env Rscript

library(ape)
library(phytools)

# Find newest OrthoFinder results
results_dir <- list.dirs("orthofinder", recursive = FALSE, full.names = TRUE)
results_dir <- results_dir[grepl("Results_", basename(results_dir))]
results_dir <- results_dir[order(file.info(results_dir)$mtime, decreasing = TRUE)]

OF_DIR <- results_dir[1]

cat("Using OrthoFinder results directory:", OF_DIR, "\n")

tree_file <- file.path(OF_DIR, "Species_Tree", "SpeciesTree_rooted.txt")

# Read tree
tree <- read.tree(tree_file)

# Force ultrametric
ult.tree <- force.ultrametric(tree, method="extend")

# Check
cat("Is ultrametric:", is.ultrametric(ult.tree), "\n")

# Save tree
write.tree(ult.tree, "SpeciesTree_ultrametric.txt")

cat("Ultrametric tree written to: SpeciesTree_ultrametric.txt\n")
