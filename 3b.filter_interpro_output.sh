#!/usr/bin/env bash
set -euo pipefail

# =========================
# SETTINGS
# =========================
BASE_DIR="$(pwd)"
INPUT_DIR="$BASE_DIR/interproscan_output"
MOVE_BAD=true   # change to true if you want bad TSVs moved into rejected_tsv/

if [ ! -d "$INPUT_DIR" ]; then
    echo "ERROR: Input directory not found: $INPUT_DIR"
    exit 1
fi

REJECT_DIR="$INPUT_DIR/rejected_tsv"
if [ "$MOVE_BAD" = true ]; then
    mkdir -p "$REJECT_DIR"
fi

INCLUDE_LIST="include_orthogroups.txt"
EXCLUDE_REPORT="excluded_orthogroups_with_reason.tsv"
OUT="all_go_unique.tsv"
GO_COL=14

: > "$INCLUDE_LIST"
: > "$EXCLUDE_REPORT"
: > "$OUT"

echo -e "Orthogroup\tReason\tFile" > "$EXCLUDE_REPORT"

#############################################
### PART 1 — IDENTIFY GOOD/BAD TSV FILES  ###
#############################################

total=0
excluded=0
kept=0

shopt -s nullglob
for tsv in "$INPUT_DIR"/*.tsv; do
    base=$(basename "$tsv")

    # skip output/report files if rerunning
    case "$base" in
        all_go_unique.tsv|excluded_orthogroups_with_reason.tsv)
            continue
            ;;
    esac

    og="${base%.tsv}"
    ((total+=1))

    reasons=()

    # empty file?
    if [ ! -s "$tsv" ]; then
        reasons+=("empty")
    fi

    # contains transpos?
    if grep -Iqi 'transpos' "$tsv"; then
        reasons+=("transpos")
    fi

    if [ "${#reasons[@]}" -gt 0 ]; then
        reason_str=$(IFS=,; echo "${reasons[*]}")
        echo -e "${og}\t${reason_str}\t${tsv}" >> "$EXCLUDE_REPORT"
        ((excluded+=1))

        if [ "$MOVE_BAD" = true ]; then
            mv "$tsv" "$REJECT_DIR/"
        fi
    else
        echo "$og" >> "$INCLUDE_LIST"
        ((kept+=1))
    fi
done

sort -u "$INCLUDE_LIST" -o "$INCLUDE_LIST"

# sort exclusion report but keep header on top
{
    head -n 1 "$EXCLUDE_REPORT"
    tail -n +2 "$EXCLUDE_REPORT" | sort -u
} > "${EXCLUDE_REPORT}.tmp" && mv "${EXCLUDE_REPORT}.tmp" "$EXCLUDE_REPORT"

echo "Total .tsv files checked: $total"
echo "Excluded (empty or transpos*): $excluded"
echo "Kept: $kept"

#############################################
### PART 2 — BUILD GO TABLE               ###
#############################################

echo "Building GO table using $INCLUDE_LIST ..."

while read -r og; do
    [ -n "$og" ] || continue
    tsv="$INPUT_DIR/${og}.tsv"
    [ -f "$tsv" ] || continue

    awk -v og="$og" -v c="$GO_COL" '
        BEGIN {FS=OFS="\t"}
        $0 !~ /transpos/ && $c ~ /GO:/ { print og, $c }
    ' "$tsv" >> "$OUT"
done < "$INCLUDE_LIST"

sort -u "$OUT" -o "$OUT"

echo "Created: $OUT"
echo "Created keep list: $INCLUDE_LIST"
echo "Created exclusion report: $EXCLUDE_REPORT"

if [ "$MOVE_BAD" = true ]; then
    echo "Bad TSVs were moved to: $REJECT_DIR"
fi

echo "All done!"
