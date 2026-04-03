#!/usr/bin/env bash
set -euo pipefail

# Load conda
source ~/miniconda3/etc/profile.d/conda.sh

echo "Starting Gene Family Evolution Pipeline"
echo

# Activate core environment
echo "Activating core environment"
conda activate /opt/conda_envs/gene_family_core
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

# Switch to R environment
echo "Switching to R environment"
conda activate /opt/conda_envs/gene_family_R

# 4) UpSet + CAFE prep
echo "Step 4: UpSet + CAFE prep"
# Rscript 4a.UpsetPrepCafe.R
echo

# Switch back to core environment
echo "Switching back to core environment"
conda activate /opt/conda_envs/gene_family_core

# 5) Gene family evolution modeling
echo "Step 5: CAFE"
./5a.cafe.sh
echo

# 6) Phylogenetic dating
echo "Step 6: treePL"
echo "Making ultrametric tree"

# Switch to R for ultrametric tree
conda activate /opt/conda_envs/gene_family_R
Rscript 6a.makeultrametric.R

# Back to core for treePL
conda activate /opt/conda_envs/gene_family_core
echo "Running treePL"
treePL 6b.config.cfg

# Back to R to plot tree
conda activate /opt/conda_envs/gene_family_R
echo "Creating tree pdf"
Rscript 6c.plottree.R
echo

# 7) GO enrichment analysis
echo "Step 7a: topGO prep"
# conda activate /opt/conda_envs/gene_family_core
# ./7a.topgoprep.sh
echo

echo "Step 7b: topGO"
# conda activate /opt/conda_envs/gene_family_R
# Rscript 7b.topgo.R
echo

echo "Pipeline complete"
