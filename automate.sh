#!/usr/bin/env bash
set -euo pipefail

# Purpose:
#   Run the gene family evolution pipeline sequentially.

echo "Starting Gene Family Evolution Pipeline"
echo

# 0) Data preparation
echo "Step 0: Download accessions"
# ./0.download_accessions.sh
echo

# 1) Genome completeness
echo "Step 1a: BUSCO"
# ./1a.busco.sh
echo

echo "Step 1b: BUSCO summaries"
# ./1b.busco_summaries.sh
echo

# 2) Orthogroup inference
echo "Step 2: OrthoFinder"
# ./2a.orthofinder.sh
echo

echo "Step 2b: Prepare InterProScan input"
# ./2b.prepare_interproscan_input.sh
echo

# 3) Functional annotation
echo "Step 3: InterProScan"
# ./3a.interproscan.sh
echo "InterProScan finished"
echo

echo "Step 3b: Filter InterProScan output"
# ./3b.filter_interpro_output.sh
echo "Filtering done"
echo

# 4) UpSet + CAFE prep
echo "Step 4: UpSet + CAFE prep"
#./4a.UpsetPrepCafe.R
echo

# 5) Gene family evolution modeling
echo "Step 5: CAFE"
./5a.cafe.sh
echo

# 6) Phylogenetic dating

echo "Step 6: treePL"
echo "Making ultrametric tree" 
./6a.makeultrametric.R
echo "Running treePL "
treePL 6b.config.cfg
echo "Creating tree pdf" 
./6c.plottree.R

# 7) GO enrichment analysis
echo "Step 7a: topGO prep"
#./7a.topgoprep.sh
echo

echo "Step 7b: topGO"
# Rscript 7b.topgo.R
echo

echo "Pipeline complete"
