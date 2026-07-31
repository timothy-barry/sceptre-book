# data-raw/make-rd7-trans-fixtures.R
#
# Regenerate the two rd7 trans-analysis result tables shown in
# pipeline-details.qmd ("Massive-scale trans analysis").
#
# These are REPORTED RESULTS from a real genome-scale dataset, not a demo on the
# packaged example data, so they cannot be reproduced during `quarto render`.
# We snapshot them to plain CSV and commit the CSVs; this script records exactly
# how those CSVs were produced.
#
# Source: the "rd7" dataset from Replogle et al. 2022 (Cell) -- a genome-scale
# Perturb-seq screen with 616,184 cells, 36,601 genes, and 5,086 targeting gRNAs
# across 2,384 targets. The trans analysis was run with the sceptre Nextflow
# pipeline (trans interface); its parquet output is large, lives outside this
# repo (e.g. on HPC), and is NOT bundled here.
#
# Why CSV, not RDS: the originals were saveRDS()'d straight from arrow::collect(),
# so the ID column was an Arrow ALTREP/dictionary vector that a later arrow could
# not unserialize ("malformed factor" when printed). `collect() |> head()`
# materializes to a plain data frame and `write.csv()` writes text -- no Arrow
# objects survive, so the fixtures cannot rot again.
#
# Usage: pull the pipeline output from HPC with
#     hpcc pull SCEPTRE3 nf_pipelines/rd7_trans/
# (source: hpc3.wharton.upenn.edu:~/data/projects/sceptre3/nf_pipelines/rd7_trans/),
# then run this script from the repository root. It writes the two CSVs next to
# the .qmd files.

library(arrow)
library(dplyr)

# Local copy of the rd7 trans_results parquet (pulled via `hpcc pull`, above).
trans_results_dir <- path.expand(
  "~/data/projects/sceptre3/nf_pipelines/rd7_trans/sceptre_outputs/trans_results/"
)

ds <- arrow::open_dataset(trans_results_dir)

# The pipeline writes the ID columns as Arrow dictionary<string> (like factors).
# Decode them to plain strings so (a) the per-file dictionaries don't have to be
# unified at collect() -- which overflows the integer index type across the 437
# result files -- and (b) the saved CSV holds plain text, not a dictionary/factor.
ds <- ds |>
  mutate(response_id = as.character(response_id),
         grna_target = as.character(grna_target))

# Given a target, the most strongly associated responses.
ds |>
  filter(grna_target == "ENSG00000094914") |>
  select(p_value, log_2_fold_change, response_id) |>
  arrange(p_value) |>
  collect() |>
  head() |>
  write.csv("rd7_result_for_given_target.csv", row.names = FALSE)

# Given a response, the most strongly associated targets.
ds |>
  filter(response_id == "ENSG00000130024") |>
  select(p_value, log_2_fold_change, grna_target) |>
  arrange(p_value) |>
  collect() |>
  head() |>
  write.csv("rd7_result_for_given_response.csv", row.names = FALSE)

message("Wrote rd7_result_for_given_target.csv and rd7_result_for_given_response.csv")
