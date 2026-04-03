#!/usr/bin/env bash

export PIPELINE_HOME="${PIPELINE_HOME:-$HOME/.gene_family_pipeline}"
export CONDA_BASE="$PIPELINE_HOME/miniconda3"
export CORE_ENV="$PIPELINE_HOME/envs/gene_family_core"
export TOOLS_DIR="$PIPELINE_HOME/tools"
export CAFE_ENV="$PIPELINE_HOME/envs/cafe5"

export PATH="$CORE_ENV/bin:$TOOLS_DIR/bin:$PATH"
