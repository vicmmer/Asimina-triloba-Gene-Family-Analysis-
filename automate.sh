#!/usr/bin/env bash
set -eo pipefail

# Load conda
source ~/.gene_family_pipeline/miniconda3/etc/profile.d/conda.sh

# Activate core environment
conda activate ~/.gene_family_pipeline/envs/gene_family_core

# Load config
source "$(dirname "$0")/config.sh"

# Avoid unbound variable issues
export LD_LIBRARY_PATH="${LD_LIBRARY_PATH:-}"

# Load conda
source "$CONDA_BASE/etc/profile.d/conda.sh"
conda activate "$CORE_ENV"

# Ensure env tools come first
export PATH="$CORE_ENV/bin:$TOOLS_DIR/bin:$PATH"
hash -r

echo "Starting Gene Family Evolution Pipeline"
echo

echo "Using environment: $CORE_ENV"
echo "Using tools directory: $TOOLS_DIR"
echo

# 0) Data preparation
echo "Step 0: Download accessions"
./0.download_accessions.sh
echo

# 1) Genome completeness
echo "Step 1a: BUSCO"
./1a.busco.sh
echo

echo "Step 1b: BUSCO summaries"
./1b.busco_summaries.sh
echo

# 2) Orthogroup inference
echo "Step 2: OrthoFinder"
./2a.orthofinder.sh
echo

echo "Step 2b: Prepare InterProScan input"
./2b.prepare_interproscan_input.sh
echo

# 3) Functional annotation
echo "Step 3: InterProScan"
./3a.interproscan.sh
echo "InterProScan finished"
echo

echo "Step 3b: Filter InterProScan output"
./3b.filter_interpro_output.sh
echo "Filtering done"
echo

# 4) UpSet + CAFE prep
echo "Step 4: UpSet + CAFE prep"
Rscript 4a.UpsetPrepCafe.R
echo

# 5) Gene family evolution modeling
echo "Step 5: CAFE"
if [ -x "$CAFE5_BIN" ]; then
    ./5a.cafe.sh
else
    echo "Skipping CAFE: CAFE5 not found at $CAFE5_BIN"
fi
echo

# 6) Phylogenetic dating
echo "Step 6: treePL"
echo "Making ultrametric tree"
Rscript 6a.makeultrametric.R

echo "Running treePL"
treePL 6b.config.cfg

echo "Creating tree pdf"
Rscript 6c.plottree.R
echo

# 7) GO enrichment analysis
echo "Step 7a: topGO prep"
./7a.topgoprep.sh
echo

echo "Step 7b: topGO"
Rscript 7b.topgo.R
echo

echo "Pipeline complete"
