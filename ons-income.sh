#!/usr/bin/env bash
set -euo pipefail

DATA_DIR="data/ons-income"
EXCEL_FILE="ons-income.xlsx"
mkdir -p "$DATA_DIR"
cd $_

curl https://www.ons.gov.uk/file?uri=/employmentandlabourmarket/peopleinwork/earningsandworkinghours/datasets/smallareaincomeestimatesformiddlelayersuperoutputareasenglandandwales/financialyearending2020/saiefy1920finalqaddownload280923.xlsx -o "$EXCEL_FILE"

# ============================================
# Configuration
# ============================================
CELL_RANGE="A5:I"
SHEETS=(
  "Total annual income"
  "Net annual income"
  "Net income before housing costs"
  "Net income after housing costs"
)

# ============================================
# Setup
# ============================================

# Check that duckdb is installed
if ! command -v duckdb &>/dev/null; then
  echo "Error: duckdb not found in PATH. Please install DuckDB first."
  exit 1
fi
echo

# ============================================
# Conversion loop
# ============================================
for SHEET in "${SHEETS[@]}"; do
  # Create a filename-safe version of the sheet name
  SAFE_NAME=$(echo "$SHEET" | tr '[:upper:]' '[:lower:]' | tr ' ' '_' | tr -cd '[:alnum:]_')
  OUTPUT_FILE="${SAFE_NAME}.parquet"

  echo "Converting sheet: '$SHEET' → $OUTPUT_FILE"

  duckdb -c "
  COPY (
    SELECT *
    FROM read_xlsx(
      '${EXCEL_FILE}',
      sheet='${SHEET}',
      header=true,
      range='${CELL_RANGE}',
      stop_at_empty=true
    )
  ) TO '${OUTPUT_FILE}' (FORMAT PARQUET);
  "
done
echo
echo "All sheets converted successfully!"

