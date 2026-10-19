#!/usr/bin/env bash
#
# Rebuild the income distributions and the methodology note's numbers from the
# INE sources:
#   ADRH + AEAT  ->  data/*.fst  ->  output/ (figures, tables), tex/numbers.tex
# Inside the web app's repository (where this folder is methodology/), the FST
# files are also converted to the app's data, ../public/data/.
#
# Usage (from anywhere):   bash run_pipeline.sh
#
# Optional steps:
#   RUN_GINI_MODEL=1        also re-fit the Gini imputation model (1.)
#   RUN_HOLDOUT=1           also re-run the leave-one-share-out validation of the
#                           tract GB2 fits (1c., nine refits)
#   CENSUS_REFRESH=1        re-download the INE census tables behind the
#                           municipal education and place-of-birth shares (3a.);
#                           otherwise their cached municipal rows are used
#   BUILD_NOTE=1            also rebuild tex/note.pdf (needs a TeX distribution)
set -euo pipefail

cd "$(dirname "$0")"                      # methodology/
mkdir -p data data-raw output

run() { echo; echo "==> $1"; Rscript "code/$1"; }

run "0d. nowcast.r"
if [[ "${RUN_GINI_MODEL:-0}" == "1" ]]; then run "1. predict_gini_ml.r"; fi
run "1b. fit_gb2.r"
if [[ "${RUN_HOLDOUT:-0}" == "1" ]]; then run "1c. gb2_holdout.r"; fi
run "2. prep_distributions.r"
run "3a. mun_stats.r"
run "3c. apply_nowcast_mun_stats.r"

if [[ -f ../scripts/convert-data.R ]]; then
  echo; echo "==> scripts/convert-data.R (the web app's data)"
  (cd .. && Rscript scripts/convert-data.R)
fi

run "5. note_figures.r"
run "6. note_numbers.r"

if [[ "${BUILD_NOTE:-0}" == "1" ]]; then echo; echo "==> tex/build_note.sh"; bash tex/build_note.sh; fi
