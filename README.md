# Gene Family Evolution Pipeline  
### Pawpaw-Focused Comparative Genomics

This repository contains scripts used to analyze **gene family evolution across Annonaceae and related magnoliid taxa**, with a primary focus on identifying **gene family expansions and contractions associated with pawpaw (*Asimina triloba*) and the Annonaceae family as a whole**.

The pipeline integrates genome quality assessment, orthogroup inference, functional annotation, gene family evolution modeling, phylogenetic dating, and GO enrichment analyses to functionally interpret **pawpaw-specific gene family expansions and candidate metabolic pathways**.

The workflow integrates the following tools:

- **BUSCO** — genome/proteome completeness assessment  
- **OrthoFinder** — orthogroup inference  
- **InterProScan** — protein functional annotation and GO assignment  
- **CAFE5** — gene family expansion/contraction modeling  
- **treePL** — divergence time estimation  
- **topGO** — Gene Ontology enrichment analysis  


---

# Installation

Create the Conda environment containing all required software:

```bash
conda env create -f environment.yml
conda activate gene_family_pipeline
```

This installs:

- OrthoFinder  
- InterProScan  
- CAFE5  
- treePL  
- R and required packages (`topGO`, `ape`, `phytools`, `dplyr`, etc.)

---

# Running the Pipeline

Run the full workflow using the automated pipeline script:

```bash
./scripts/automate.sh
```

The automate script prints **step-by-step messages explaining each stage of the analysis**.

---

# Repository Structure

```

scripts included: 
  automate.sh
  0.download_accessions.sh
  1a.busco.sh
  1b.busco_summaries.sh
  2a.orthofinder.sh
  2b.prepare_interproscan_input.sh
  3a.interproscan.sh
  3b.filter_interpro_output.sh
  4a.UpsetPrepCafe.R
  cafe2.sh
  6a.makeultrametric.R
  6b.config.cfg
  6c.plottree.R
  7a.topgoprep.sh
  7b.topgo.R

```

---

# Species and Data Sources

| Species | File Name | Source | Year |
|------|----------|------------|------|
| *Annona cherimola* | `Annona_cherimola.fa` | CNCB / UMA proteins | 2023 |
| *Annona montana* | `Annona_montana.fa` | CNCB–GWH | 2023 |
| *Annona muricata* | `Annona_muricata_annotated.fasta` | DOI:10.1111/1755-0998.13353 | 2021 |
| *Asimina triloba* | `Asimina_triloba_annotated.fasta` | Local assembly | 2023 |
| *Cinnamomum micranthum* | `Cinnamomum_micranthum.fa` | NCBI Datasets | 2019 |
| *Lindera megaphylla* | `Lindera_megaphylla.fa` | CNCB–GWH | 2023 |
| *Magnolia kwangsiensis* | `Magnolia_kwangsiensis.fa` | CNCB–GWH | 2025 |
| *Persea americana* | `Persea_americana.fa` | CoGe / Science Data Bank | 2025 |

---

# Workflow Overview

Scripts are numbered in the recommended execution order.

---

## 0. Data Preparation

Script:

```
0.download_accessions.sh
```

Downloads or prepares protein FASTA files for all species.

Output:

```
protein_sequences/*.fa
```

---

## 1. Genome Completeness

Scripts:

```
1a.busco.sh
1b.busco_summaries.sh
```

BUSCO evaluates genome/proteome completeness based on conserved single-copy orthologs.

Output:

```
busco_results/
busco_summary_table.tsv
```

---

## 2. Orthogroup Inference

Scripts:

```
2a.orthofinder.sh
2b.prepare_interproscan_input.sh
```

OrthoFinder clusters proteins into **gene families (orthogroups)** across all species.

The preparation script cleans orthogroup FASTA files for functional annotation.

Output:

```
orthofinder/Results_*/
Orthogroups.GeneCount.tsv
SpeciesTree_rooted.txt
interproscan_input/
```

---

## 3. Functional Annotation

Scripts:

```
3a.interproscan.sh
3b.filter_interpro_output.sh
```

InterProScan identifies protein domains and assigns GO annotations.

The filtering step removes:

- Empty annotation files  
- Transposable-element-associated annotations  

Output:

```
include_orthogroups.txt
all_go_unique.tsv
```

---

## 4. Gene Family Overlap Visualization and CAFE Preparation

Script:

```
4a.UpsetPrepCafe.R
```

This script:

- Generates an **UpSet plot** showing orthogroup overlap across species  
- Builds the **CAFE gene family count table**  
- Produces an **ultrametric species tree**

Output:

```
upset_plot.pdf
cafe_gene_families.tsv
SpeciesTree_ultrametric.txt
```

---

## 5. Gene Family Evolution Modeling

Script:

```
cafe2.sh
```

CAFE5 models gene family expansions and contractions across the species tree.

Output:

```
Gamma_change.tab
Gamma_family_results.txt
Gamma_report.cafe
```

These results identify **gene families significantly expanded in pawpaw and related taxa**.

---

## 6. Phylogenetic Dating

Scripts:

```
6a.makeultrametric.R
6b.config.cfg
6c.plottree.R
```

treePL estimates divergence times across the species tree using fossil calibration constraints.

Output:

```
SpeciesTree_treepl_dated_TEST.tre
SpeciesTree_treepl_dated_TEST.pdf
```

---

## 7. GO Enrichment Analysis

Scripts:

```
7a.topgoprep.sh
7b.topgo.R
```

This stage performs **Gene Ontology enrichment analysis** on gene families identified by CAFE.

Output:

```
annonaceae_ALL_topgo.tsv
candidate_acetogenin_annonaceae.tsv
candidate_acetogenin_summary.tsv
candidate_acetogenin_topgo_terms.tsv
```

These results help identify **candidate pathways related to specialized metabolism (e.g., acetogenins)**.

---

# Figures Generated by the Pipeline

| Figure | Description |
|------|-------------|
| `upset_plot.pdf` | Orthogroup overlap among Annonaceae and outgroups |
| `SpeciesTree_treepl_dated_TEST.pdf` | Divergence-dated species tree |

---

# Important Notes

- InterProScan must be run on **cleaned orthogroup FASTA files** produced by OrthoFinder.  
- `filter_interpro_output.sh` must be executed before CAFE preparation.  
- Transposable-element annotations are removed to avoid false signals in gene family expansion analyses.

---

# Software Versions

Recommended versions:

```
OrthoFinder ≥ 2.5
InterProScan ≥ 5.75
CAFE5
treePL
R ≥ 4.3
```

---

# Pipeline Summary

```
Protein sequences
      ↓
BUSCO
      ↓
OrthoFinder
      ↓
InterProScan
      ↓
GO filtering
      ↓
CAFE5
      ↓
treePL
      ↓
topGO
```

---

# Contact

Pipeline developed for comparative genomic analysis of **pawpaw (*Asimina triloba*) gene family evolution**.

For questions or collaboration inquiries, please open an issue in this repository.
