
#!/usr/bin/env bash
set -eo pipefail

echo "Starting dependency installation..."
echo

# Directory where this script lives
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Load config
source "$SCRIPT_DIR/config.sh"

# Paths
CAFE_YML="$SCRIPT_DIR/cafe5_env.yml"
CAFE_ENV="$PIPELINE_HOME/envs/cafe5"

mkdir -p "$PIPELINE_HOME"
mkdir -p "$PIPELINE_HOME/envs"
mkdir -p "$TOOLS_DIR"
mkdir -p "$TOOLS_DIR/bin"

echo "Pipeline home: $PIPELINE_HOME"
echo "Conda base: $CONDA_BASE"
echo "Core env: $CORE_ENV"
echo "Tools dir: $TOOLS_DIR"
echo

# -----------------------------
# 1) Install Miniconda locally if missing
# -----------------------------
if [ ! -x "$CONDA_BASE/bin/conda" ]; then
    echo "Miniconda not found. Installing locally..."
    cd "$PIPELINE_HOME"

    if command -v wget >/dev/null 2>&1; then
        wget https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh -O miniconda.sh
    elif command -v curl >/dev/null 2>&1; then
        curl -L https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh -o miniconda.sh
    else
        echo "Error: need wget or curl to download Miniconda."
        exit 1
    fi

    bash miniconda.sh -b -p "$CONDA_BASE"
    rm -f miniconda.sh
else
    echo "Miniconda already found."
fi
echo

# -----------------------------
# 2) Load conda
# -----------------------------
source "$CONDA_BASE/etc/profile.d/conda.sh"

# Accept ToS if needed
conda tos accept --override-channels --channel https://repo.anaconda.com/pkgs/main || true
conda tos accept --override-channels --channel https://repo.anaconda.com/pkgs/r || true

# -----------------------------
# 3) Create core env if missing
# -----------------------------
if [ ! -d "$CORE_ENV" ]; then
    echo "Creating core conda environment..."
    conda create -y -p "$CORE_ENV" python=3.11
else
    echo "Core environment already exists."
fi
echo

# -----------------------------
# 4) Activate core env
# -----------------------------
conda activate "$CORE_ENV"

export LD_LIBRARY_PATH="${LD_LIBRARY_PATH:-}"
export PATH="$CORE_ENV/bin:$TOOLS_DIR/bin:$PATH"
hash -r

# -----------------------------
# 5) Install core conda dependencies
# -----------------------------
echo "Installing conda packages..."
conda install -y -p "$CORE_ENV" -c conda-forge -c bioconda \
    orthofinder \
    blast \
    diamond \
    mmseqs2 \
    mafft \
    iqtree \
    fasttree \
    raxml \
    raxml-ng \
    fastme \
    famsa \
    mcl \
    entrez-direct \
    aria2 \
    wget \
    curl \
    biopython \
    ete4 \
    scikit-learn \
    scipy \
    numpy \
    r-base \
    r-ape \
    r-phytools \
    r-dplyr \
    bioconductor-topgo
echo

# -----------------------------
# 6) Check for treePL
# -----------------------------
if command -v treePL >/dev/null 2>&1; then
    echo "Found treePL -> $(command -v treePL)"
else
    echo "treePL not found in PATH."
    echo "If running on Curie, load or add the shared treePL installation before running the pipeline."
fi
echo

# -----------------------------
# 7) Create CAFE5 env from repo YAML
# -----------------------------
if [ -f "$CAFE_YML" ]; then
    echo "Found CAFE5 environment file: $CAFE_YML"

    if [ ! -d "$CAFE_ENV" ]; then
        echo "Creating CAFE5 environment..."
        conda env create -p "$CAFE_ENV" -f "$CAFE_YML"
    else
        echo "CAFE5 environment already exists."
    fi

    echo "Testing CAFE5 environment..."
    conda activate "$CAFE_ENV"
    export PATH="$CAFE_ENV/bin:$CORE_ENV/bin:$TOOLS_DIR/bin:$PATH"
    hash -r

    if command -v cafe >/dev/null 2>&1; then
        echo "Found cafe -> $(command -v cafe)"
    elif command -v cafe5 >/dev/null 2>&1; then
        echo "Found cafe5 -> $(command -v cafe5)"
    else
        echo "WARNING: CAFE executable not found even though env was created."
    fi

    conda activate "$CORE_ENV"
    export PATH="$CORE_ENV/bin:$TOOLS_DIR/bin:$PATH"
    hash -r
else
    echo "CAFE5 environment file not found: $CAFE_YML"
    echo "Skipping CAFE5 installation."
fi
echo

# -----------------------------
# 8) Check installed executables
# -----------------------------
echo "Checking installed executables..."
for prog in python orthofinder Rscript; do
    if command -v "$prog" >/dev/null 2>&1; then
        echo "Found $prog -> $(command -v "$prog")"
    else
        echo "Missing $prog"
    fi
done
echo

# -----------------------------
# 9) Test R packages
# -----------------------------
echo "Testing R packages..."
Rscript -e "library(ape); library(phytools); library(dplyr); library(topGO)"
echo "R package test passed."
echo

echo "Installation complete."
echo
echo "To use this pipeline in future shells, run:"
echo "source \"$CONDA_BASE/etc/profile.d/conda.sh\""
echo "conda activate \"$CORE_ENV\""
