#!/usr/bin/env bash
# ============================================================
# Script: convert_ons_income.sh
# Purpose: Download and convert ONS income Excel data into Parquet files
# ============================================================

set -euo pipefail  # Exit on error, undefined var, or failed pipe instead of continuing silently.

# ------------------------------------------------------------
# Configuration
# ------------------------------------------------------------
DATA_DIR="data/ons-income"
EXCEL_FILE="ons-income.xlsx"
EXCEL_URL="https://www.ons.gov.uk/file?uri=/employmentandlabourmarket/peopleinwork/earningsandworkinghours/datasets/smallareaincomeestimatesformiddlelayersuperoutputareasenglandandwales/financialyearending2020/saiefy1920finalqaddownload280923.xlsx"
CELL_RANGE="A5:I"

SHEETS=(
  "Total annual income"
  "Net annual income"
  "Net income before housing costs"
  "Net income after housing costs"
)

# ------------------------------------------------------------
# Setup
# ------------------------------------------------------------
mkdir -p "$DATA_DIR"
cd "$DATA_DIR"

# Verify DuckDB is installed
if ! command -v duckdb &>/dev/null; then
  echo "Error: DuckDB is not installed or not in PATH."
  echo "Please install it first: https://duckdb.org/docs/installation"
  exit 1
fi

# ------------------------------------------------------------
# Download source data
# ------------------------------------------------------------
echo "Downloading ONS Income dataset..."
curl -sSL "$EXCEL_URL" -o "$EXCEL_FILE"
echo

# ------------------------------------------------------------
# Conversion Loop
# ------------------------------------------------------------
echo "Converting Excel sheets to Parquet format..."
for SHEET in "${SHEETS[@]}"; do
  SAFE_NAME=$(echo "$SHEET" | tr '[:upper:]' '[:lower:]' | tr ' ' '_' | tr -cd '[:alnum:]_')
  OUTPUT_FILE="${SAFE_NAME}.parquet"

  echo "  Processing sheet: '$SHEET' → ${OUTPUT_FILE}"

  duckdb -c "
    COPY (
      SELECT *
      FROM read_xlsx(
        '${EXCEL_FILE}',
        sheet='${SHEET}',
        header=true,
        range='${CELL_RANGE}',
        stop_at_empty=True,
        normalize_names=True
      )
    ) TO '${OUTPUT_FILE}' (FORMAT PARQUET);
  "
done

# ------------------------------------------------------------
# Completion message
# ------------------------------------------------------------
echo
echo "All sheets converted successfully."
echo

ls -lh
cd ../../
