#!/usr/bin/env Rscript

# ---- Load packages ----
#setwd("C:/Users/vicme/OneDrive/Desktop/Streamlined_github_pawpaw")

suppressPackageStartupMessages({
  library(topGO)
  library(Rgraphviz)
  library(readr)
  library(dplyr)
  library(tidyr)
  library(stringr)
})

# =========================
# 0. Read and collapse GO mapping
# =========================
all_tsv <- read.delim(
  "all_go_unique_clean.tsv",
  sep = "\t",
  header = FALSE,
  stringsAsFactors = FALSE
)

colnames(all_tsv) <- c("Orthogroup", "GO")

collapsed <- all_tsv %>%
  separate_rows(GO, sep = "[;,]") %>%
  mutate(GO = str_trim(GO)) %>%
  filter(!is.na(GO), GO != "") %>%
  distinct(Orthogroup, GO) %>%
  arrange(Orthogroup, GO) %>%
  group_by(Orthogroup) %>%
  summarise(GO = paste(GO, collapse = ","), .groups = "drop")

write.table(
  collapsed,
  "all_go_collapsed.tsv",
  sep = "\t",
  quote = FALSE,
  row.names = FALSE,
  col.names = FALSE
)

# =========================
# 1. Define gene universe
# =========================
geneID2GO <- readMappings(file = "all_go_collapsed.tsv")
geneUniverse <- names(geneID2GO)

# =========================
# 2. Read CAFE outputs
# =========================
# =========================
# 2. Read CAFE outputs
# =========================
# =========================
# 2. Read CAFE outputs
# =========================
cafe_dir <- "cafe5_k2"
gamma_change_file <- file.path(cafe_dir, "Gamma_change.tab")
gamma_sig_file    <- file.path(cafe_dir, "Gamma_family_results.txt")

cat("\nReading CAFE outputs from:\n")
cat(gamma_change_file, "\n")
cat(gamma_sig_file, "\n")

chg <- read_tsv(gamma_change_file, show_col_types = FALSE) %>%
  rename(Orthogroup = FamilyID)

names(chg) <- names(chg) %>%
  str_replace("<[0-9]+>", "")

chg <- chg[, !(is.na(names(chg)) | names(chg) == "")]

fam_sig <- read_tsv(
  gamma_sig_file,
  comment = "#",
  col_names = c("Orthogroup", "pvalue", "Significant"),
  show_col_types = FALSE
)
gamma_change_file <- file.path(cafe_dir, "Gamma_change.tab")
gamma_sig_file    <- file.path(cafe_dir, "Gamma_family_results.txt")

cat("\nReading CAFE outputs from:\n")
cat(gamma_change_file, "\n")
cat(gamma_sig_file, "\n")

chg <- read_tsv(gamma_change_file, show_col_types = FALSE) %>%
  rename(Orthogroup = FamilyID)

names(chg) <- names(chg) %>%
  str_replace("<[0-9]+>", "")

chg <- chg[, !(is.na(names(chg)) | names(chg) == "")]

fam_sig <- read_tsv(
  gamma_sig_file,
  comment = "#",
  col_names = c("Orthogroup", "pvalue", "Significant"),
  show_col_types = FALSE
)

chg2 <- chg %>%
  left_join(fam_sig, by = "Orthogroup")

cat("\nSignificance counts:\n")
print(table(chg2$Significant, useNA = "ifany"))

# =========================
# 3. Define taxon groups flexibly
# =========================
annonaceae_species_all <- c(
  "Asimina_triloba",
  "Annona_cherimola",
  "Annona_montana",
  "Annona_muricata"
)

outgroup_species_all <- c(
  "Magnolia_kwangsiensis",
  "Lindera_megaphylla",
  "Cinnamomum_micranthum"
)

annonaceae_species <- intersect(annonaceae_species_all, names(chg2))
outgroup_species   <- intersect(outgroup_species_all, names(chg2))

cat("\nAnnonaceae species present in this dataset:\n")
print(annonaceae_species)

cat("\nOutgroup species present in this dataset:\n")
print(outgroup_species)

if (length(annonaceae_species) == 0) {
  stop("No Annonaceae species columns found in chg2.")
}

if (length(outgroup_species) == 0) {
  warning("No outgroup species columns found in chg2. Outgroup comparison will be limited.")
}

# =========================
# 4. Define orthogroup sets dynamically
# =========================
chg2 <- chg2 %>%
  mutate(
    annon_present_any = apply(
      select(., all_of(annonaceae_species)),
      1,
      function(x) any(x > 0, na.rm = TRUE)
    )
  )

annon_any <- chg2 %>%
  filter(annon_present_any) %>%
  pull(Orthogroup) %>%
  unique()

annon_sig <- chg2 %>%
  filter(Significant == "y", annon_present_any) %>%
  pull(Orthogroup) %>%
  unique()

annon_flag <- factor(
  as.integer(geneUniverse %in% annon_sig),
  levels = c(0, 1)
)
names(annon_flag) <- geneUniverse

# =========================
# 5. Helper function to run topGO
# =========================
run_topgo_one <- function(flag_vector, label, ontology_code) {
  go_obj <- new(
    "topGOdata",
    description = paste("IC unique OGs -", label, ontology_code),
    ontology = ontology_code,
    allGenes = flag_vector,
    annot = annFUN.gene2GO,
    gene2GO = geneID2GO
  )
  
  result_fisher <- runTest(go_obj, algorithm = "classic", statistic = "fisher")
  scores <- score(result_fisher)
  n_all  <- sum(!is.na(scores))
  
  if (n_all > 0) {
    out_df <- GenTable(
      go_obj,
      classicFisher = result_fisher,
      orderBy = "classicFisher",
      ranksOf = "classicFisher",
      topNodes = n_all
    )
    
    out_df$P_Value <- scores[out_df$GO.ID]
    out_df$FDR_BH  <- p.adjust(scores, method = "BH")[out_df$GO.ID]
    
    names(out_df)[names(out_df) == "GO.ID"]       <- "GO_ID"
    names(out_df)[names(out_df) == "Term"]        <- "GO_Term"
    names(out_df)[names(out_df) == "Annotated"]   <- "N_Annotated_Universe"
    names(out_df)[names(out_df) == "Significant"] <- "N_Significant_Selected"
    names(out_df)[names(out_df) == "Expected"]    <- "Expected_Significant"
    
    out_df$classicFisher <- NULL
    out_df$Label    <- label
    out_df$Category <- ontology_code
    
    out_df <- out_df[, c(
      "Label", "Category", "GO_ID", "GO_Term",
      "N_Annotated_Universe", "N_Significant_Selected",
      "Expected_Significant", "P_Value", "FDR_BH"
    ), drop = FALSE]
  } else {
    out_df <- data.frame(
      Label = character(),
      Category = character(),
      GO_ID = character(),
      GO_Term = character(),
      N_Annotated_Universe = integer(),
      N_Significant_Selected = integer(),
      Expected_Significant = numeric(),
      P_Value = numeric(),
      FDR_BH = numeric()
    )
  }
  
  out_csv <- paste0(label, "_", ontology_code, "_topgo.csv")
  write.csv(out_df, out_csv, row.names = FALSE)
  
  if (n_all > 0) {
    showSigOfNodes(go_obj, scores, firstSigNodes = min(10, max(1, n_all)), useInfo = "all")
    printGraph(
      go_obj,
      result_fisher,
      firstSigNodes = min(10, max(1, n_all)),
      fn.prefix = paste0("tGO_", label, "_", ontology_code),
      useInfo = "all",
      pdfSW = TRUE
    )
  }
  
  message("Wrote ", out_csv, " with ", nrow(out_df), " rows")
  invisible(out_df)
}

# =========================
# 6. Run topGO for Annonaceae
# =========================
cat("\nRunning topGO for Annonaceae...\n")

annon_BP <- run_topgo_one(annon_flag, "annonaceae", "BP")
annon_MF <- run_topgo_one(annon_flag, "annonaceae", "MF")
annon_CC <- run_topgo_one(annon_flag, "annonaceae", "CC")

# =========================
# 7. Combine ontology outputs
# =========================
combine_topgo <- function(label) {
  files <- list.files(
    pattern = paste0("^", label, "_(BP|MF|CC)_topgo\\.csv$"),
    ignore.case = TRUE
  )
  
  if (!length(files)) {
    message("No files for ", label)
    return(invisible(NULL))
  }
  
  dfs <- lapply(files, function(f) {
    d <- read.csv(f, check.names = FALSE)
    if (nrow(d) == 0) return(NULL)
    d
  })
  
  keep <- !vapply(dfs, is.null, logical(1))
  if (!any(keep)) {
    message("All files empty for ", label)
    return(invisible(NULL))
  }
  
  dfs <- dfs[keep]
  all_cols <- Reduce(union, lapply(dfs, names))
  
  dfs <- lapply(dfs, function(d) {
    miss <- setdiff(all_cols, names(d))
    if (length(miss)) for (m in miss) d[[m]] <- NA
    d[all_cols]
  })
  
  out <- do.call(rbind, dfs)
  
  front <- c(
    "Label", "Category", "GO_ID", "GO_Term",
    "N_Annotated_Universe", "N_Significant_Selected",
    "Expected_Significant", "P_Value", "FDR_BH"
  )
  front <- front[front %in% names(out)]
  
  out <- out[, c(front, setdiff(names(out), front)), drop = FALSE]
  
  write.table(
    out,
    paste0(label, "_ALL_topgo.tsv"),
    sep = "\t",
    quote = FALSE,
    row.names = FALSE
  )
  
  message("Wrote ", label, "_ALL_topgo.tsv with ", nrow(out), " rows")
  invisible(out)
}

combine_topgo("annonaceae")

annonaceae_topgo <- read.delim(
  "annonaceae_ALL_topgo.tsv",
  sep = "\t",
  stringsAsFactors = FALSE,
  check.names = FALSE
)

# =========================
# 8. Candidate acetogenin-like orthogroups
# =========================
acetogenin_keywords <- c(
  "oxidoreductase",
  "dehydrogenase",
  "reductase",
  "monooxygenase",
  "oxygenase",
  "cytochrome",
  "fatty acid",
  "lipid",
  "acyl",
  "acetyl",
  "transferase",
  "elongase",
  "desaturase",
  "NAD",
  "NADP",
  "FAD",
  "secondary metabolite",
  "biosynthetic process"
)

keyword_pattern <- paste(acetogenin_keywords, collapse = "|")

og_go <- collapsed %>%
  mutate(
    Acetogenin_like_GO = grepl(keyword_pattern, GO, ignore.case = TRUE)
  )

chg_go <- chg2 %>%
  left_join(og_go, by = "Orthogroup")

chg_go <- chg_go %>%
  mutate(
    annon_positive = apply(
      select(., all_of(annonaceae_species)),
      1,
      function(x) any(x > 0, na.rm = TRUE)
    ),
    outgroup_absent = if (length(outgroup_species) > 0) {
      apply(
        select(., all_of(outgroup_species)),
        1,
        function(x) all(x <= 0 | is.na(x))
      )
    } else {
      TRUE
    }
  )

annonaceae_candidates <- chg_go %>%
  filter(
    Significant == "y",
    Acetogenin_like_GO == TRUE,
    annon_positive,
    outgroup_absent
  ) %>%
  distinct()

write.table(
  annonaceae_candidates,
  "candidate_acetogenin_annonaceae.tsv",
  sep = "\t",
  quote = FALSE,
  row.names = FALSE
)

# =========================
# 9. Candidate summary table
# =========================
candidate_summary <- data.frame(
  Comparison = "Annonaceae candidate orthogroups absent from sampled outgroups",
  N_Orthogroups = nrow(annonaceae_candidates)
)

write.table(
  candidate_summary,
  "candidate_acetogenin_summary.tsv",
  sep = "\t",
  quote = FALSE,
  row.names = FALSE
)

cat("\nCandidate acetogenin-related summary:\n")
print(candidate_summary)

# =========================
# 10. Optional keyword-hit table from topGO output
# =========================
annonaceae_aceto_terms <- annonaceae_topgo %>%
  filter(Category %in% c("MF", "BP")) %>%
  filter(grepl(keyword_pattern, GO_Term, ignore.case = TRUE))

write.table(
  annonaceae_aceto_terms,
  "candidate_acetogenin_topgo_terms.tsv",
  sep = "\t",
  quote = FALSE,
  row.names = FALSE
)

cat("\nTopGO candidate acetogenin-like terms found:\n")
cat(nrow(annonaceae_aceto_terms), "rows\n")

# =========================
# 11. Pawpaw-specific block
# =========================
# Leave this commented out for subset runs.
# Turn back on later for the full dataset.

# if ("Asimina_triloba" %in% names(chg_go)) {
#   message("Asimina_triloba detected. Add pawpaw-specific comparison here for full dataset.")
# }

cat("\nAll done.\n")

