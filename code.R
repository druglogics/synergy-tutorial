# Load the appropriate libraries
library(dplyr)
library(tibble)
library(emba)
library(usefun)
library(PRROC)
library(DT)

# Read ensemble-wise synergies file
# `ss` => models trained to steady state
ss_hsa_file = "ags_cascade_1.0_20211121_150114/ags_cascade_1.0_ensemblewise_synergies.tab"
ss_hsa_ensemblewise_synergies = emba::get_synergy_scores(ss_hsa_file)

# Read observed synergies file
observed_synergies_file = 'observed_synergies_cascade_1.0'
observed_synergies = emba::get_observed_synergies(observed_synergies_file)
# 1 (positive/observed synergy) or 0 (negative/not observed) for all tested drug combinations
observed = sapply(ss_hsa_ensemblewise_synergies$perturbation %in% observed_synergies, as.integer)

# Make a data table
pred_hsa = dplyr::bind_cols(ss_hsa_ensemblewise_synergies %>% rename(ss_score = score),
  tibble::as_tibble_col(observed, column_name = "observed"))

# Visualize our prediction results in a table format
DT::datatable(data = pred_hsa, options =
    list(pageLength = 7, lengthMenu = c(7, 14, 21), searching = FALSE,
      order = list(list(2, 'asc')))) %>%
  DT::formatRound(columns = 2, digits = 5) %>%
  DT::formatStyle(columns = 'observed',
    backgroundColor = styleEqual(c(0, 1), c('white', '#ffffa1')))

# Get ROC statistics (`roc_res$AUC` holds the ROC AUC)
roc_res = usefun::get_roc_stats(df = pred_hsa, pred_col = "ss_score", label_col = "observed")

# Plot ROC
my_palette = RColorBrewer::brewer.pal(n = 9, name = "Set1")

cairo_pdf(filename = 'figure_ROC.pdf', width = 5, height = 5)
plot(x = roc_res$roc_stats$FPR, y = roc_res$roc_stats$TPR,
  type = 'l', lwd = 3, col = my_palette[1], main = 'ROC curve, Ensemble-wise synergies (HSA)',
  xlab = 'False Positive Rate (FPR)', ylab = 'True Positive Rate (TPR)')
legend('bottomright', title = 'AUC', col = my_palette[1], pch = 19,
  legend = paste(round(roc_res$AUC, digits = 2), "Calibrated"), cex = 1.3)
grid(lwd = 0.5)
abline(a = 0, b = 1, col = 'lightgrey', lty = 'dotdash', lwd = 1.2)
dev.off()

# Get PR statistics (`pr_res$auc.davis.goadrich` holds the PR AUC)
# NOTE: PRROC considers by default that larger prediction values indicate the
# positive class labeling. For us, the synergy scores belonging to the positive
# or synergy class (observed = 1) are the lower ones, so we need to
# reverse the scores to correctly calculate the PR curve
pr_res = PRROC::pr.curve(scores.class0 = pred_hsa %>% pull(ss_score) %>% (function(x) {-x}),
  weights.class0 = pred_hsa %>% pull(observed), curve = TRUE, rand.compute = TRUE)

cairo_pdf(filename = 'figure_PR.pdf', width = 5, height = 5)
plot(pr_res, main = 'PR curve, Ensemble-wise synergies (HSA)',
  auc.main = FALSE, color = my_palette[1], rand.plot = TRUE)
legend('topright', title = 'AUC', col = my_palette[1], pch = 19,
  legend = paste(round(pr_res$auc.davis.goadrich, digits = 2), "Calibrated"))
grid(lwd = 0.5)
dev.off()

# Read ensemble-wise synergies file
# `prolif` => models trained to random proliferative profile
prolif_hsa_file = "ags_cascade_1.0_20211128_143028/ags_cascade_1.0_ensemblewise_synergies.tab"
prolif_hsa_ensemblewise_synergies = emba::get_synergy_scores(prolif_hsa_file)

# check: predictions for the same perturbations
stopifnot(all(prolif_hsa_ensemblewise_synergies$perturbation == ss_hsa_ensemblewise_synergies$perturbation))

# Add random predictions column to the predictions table
pred_hsa = pred_hsa %>%
  tibble::add_column(prolif_score = prolif_hsa_ensemblewise_synergies$score, .before = 'observed')

# Add normalized score
pred_hsa = pred_hsa %>%
  mutate(norm_score = ss_score - prolif_score, .before = 'observed')

# Synergy prediction results from all simulations
DT::datatable(data = pred_hsa, options =
    list(pageLength = 7, lengthMenu = c(7, 14, 21), searching = FALSE,
      order = list(list(2, 'asc')))) %>%
  DT::formatRound(columns = c(2, 3, 4), digits = 5) %>%
  DT::formatStyle(columns = 'observed',
    backgroundColor = styleEqual(c(0, 1), c('white', '#ffffa1'))) %>%
  DT::formatStyle(columns = 'perturbation', target = 'row',
    backgroundColor = styleEqual(c('BI-PK'), c('#ade2e6')))

# Get ROC statistics (`roc_res_norm$AUC` holds the ROC AUC)
roc_res_norm = usefun::get_roc_stats(df = pred_hsa, pred_col = "norm_score", label_col = "observed")

# Get PR statistics (`pr_res$auc.davis.goadrich` holds the PR AUC)
pr_res_norm = PRROC::pr.curve(scores.class0 = pred_hsa %>% pull(norm_score) %>% (function(x) {-x}),
  weights.class0 = pred_hsa %>% pull(observed), curve = TRUE, rand.compute = TRUE)

# ROC figure
cairo_pdf(filename = 'figure_norm_ROC.pdf', width = 5, height = 5)
plot(x = roc_res_norm$roc_stats$FPR, y = roc_res_norm$roc_stats$TPR,
  type = 'l', lwd = 4, col = my_palette[2], main = 'ROC curve, Ensemble-wise synergies (HSA)',
  xlab = 'False Positive Rate (FPR)', ylab = 'True Positive Rate (TPR)')
lines(x = roc_res$roc_stats$FPR, y = roc_res$roc_stats$TPR,
  lwd = 3, col = my_palette[1])
legend('bottomright', title = 'AUC', col = my_palette[2:1], pch = 19,
  legend = c(paste(round(roc_res_norm$AUC, digits = 2), "Calibrated Normalized"),
    paste(round(roc_res$AUC, digits = 2), "Calibrated")), cex = 1.3)
grid(lwd = 0.5)
abline(a = 0, b = 1, col = 'lightgrey', lty = 'dotdash', lwd = 1.2)
dev.off()

# PR figure
cairo_pdf(filename = 'figure_norm_PR.pdf', width = 5, height = 5)
plot(pr_res_norm, main = 'PR curve, Ensemble-wise synergies (HSA)',
  auc.main = FALSE, color = my_palette[2], rand.plot = TRUE, lwd = 4)
plot(pr_res, add = TRUE, color = my_palette[1])
legend('bottomleft', title = 'AUC', col = my_palette[2:1], pch = 19,
  legend = c(paste(round(pr_res_norm$auc.davis.goadrich, digits = 2), "Calibrated Normalized"),
    paste(round(pr_res$auc.davis.goadrich, digits = 2), "Calibrated")), cex = 0.8)
grid(lwd = 0.5)
dev.off()
