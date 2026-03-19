#!/usr/bin/env bash
set -euo pipefail

# =========================
# SETTINGS
# =========================
CAFE_BIN="$HOME/miniconda3/envs/cafe5/bin/cafe5"

INPUT_TSV="cafe_gene_families.tsv"
TREE_FILE="SpeciesTree_ultrametric.txt"

# Optional helper scripts for your filtering workflow
RANK_SCRIPT="./5a.rank_families_to_drop.sh"
FILTER_SCRIPT="./5b.make_filtered_cafe_input.sh"

# Output names
FILTERED_INPUT="cafe_gene_families.filtered.tsv"
OUT_PREFIX="cafe5_k2"

# =========================
# CHECKS
# =========================
if [ ! -x "$CAFE_BIN" ]; then
    echo "ERROR: CAFE5 executable not found at:"
    echo "  $CAFE_BIN"
    exit 1
fi

if [ ! -f "$INPUT_TSV" ]; then
    echo "ERROR: Missing input table: $INPUT_TSV"
    exit 1
fi

if [ ! -f "$TREE_FILE" ]; then
    echo "ERROR: Missing tree file: $TREE_FILE"
    exit 1
fi

# =========================
# STEP 1: rank/drop families
# =========================
echo "[1/4] Rank families by (max-min) and select top 40 to drop..."

if [ -x "$RANK_SCRIPT" ]; then
    "$RANK_SCRIPT"
else
    echo "  Skipping: $RANK_SCRIPT not found or not executable"
fi

# =========================
# STEP 2: make filtered input
# =========================
echo "[2/4] Create filtered input..."

if [ -x "$FILTER_SCRIPT" ]; then
    "$FILTER_SCRIPT"
else
    echo "  No filtering helper script found; copying original input"
    cp "$INPUT_TSV" "$FILTERED_INPUT"
fi

# If helper script exists but writes a different filename, edit this section
if [ ! -f "$FILTERED_INPUT" ]; then
    echo "ERROR: Expected filtered input not found: $FILTERED_INPUT"
    echo "Edit FILTERED_INPUT in 5.cafe.sh to match your actual file."
    exit 1
fi

# =========================
# STEP 3: run CAFE5
# =========================
echo "[3/4] Run CAFE5 (k=2, Poisson root, I=1000)..."

"$CAFE_BIN" \
    -i "$FILTERED_INPUT" \
    -t "$TREE_FILE" \
    -o "$OUT_PREFIX" \
    -k 2 \

# =========================
# STEP 4: done
# =========================
echo "[4/4] Done."
echo "CAFE output prefix: $OUT_PREFIX"
