#!/usr/bin/env Rscript

library(ape)

# read tree
tr <- read.tree("SpeciesTree_treepl_dated_TEST.tre")

# save as PDF
pdf("SpeciesTree_treepl_dated_TEST.pdf", width = 8, height = 6)

plot(
  tr,
  main = "Dated Species Tree",
  cex = 1.1
)

axisPhylo()
dev.off()

cat("Wrote: SpeciesTree_treepl_dated_TEST.pdf\n")
