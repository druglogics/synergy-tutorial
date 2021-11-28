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
    backgroundColor = styleEqual(c(0, 1), c('white', 'yellow')))

# Get ROC statistics (`res_ss_ew$AUC` holds the ROC AUC)
res_ss_ew = usefun::get_roc_stats(df = pred_hsa, pred_col = "ss_score", label_col = "observed")

# Plot ROC
my_palette = RColorBrewer::brewer.pal(n = 9, name = "Set1")

plot(x = res_ss_ew$roc_stats$FPR, y = res_ss_ew$roc_stats$TPR,
  type = 'l', lwd = 3, col = my_palette[1], main = 'ROC curve, Ensemble-wise synergies (HSA)',
  xlab = 'False Positive Rate (FPR)', ylab = 'True Positive Rate (TPR)')
legend('bottomright', title = 'AUC', col = my_palette[1:2], pch = 19,
  legend = paste(round(res_ss_ew$AUC, digits = 2), "Calibrated"), cex = 1.3)
grid(lwd = 0.5)
abline(a = 0, b = 1, col = 'lightgrey', lty = 'dotdash', lwd = 1.2)

# NOTE: PRROC considers by default that larger prediction values indicate the
# positive class labeling. For us, the synergy scores belonging to the positive
# or synergy class (observed = 1) are the lower ones, so we need to
# reverse the scores to correctly calculate the PR curve
pr_ss_hsa = PRROC::pr.curve(scores.class0 = pred_hsa %>% pull(ss_score) %>% (function(x) {-x}),
  weights.class0 = pred_hsa %>% pull(observed), curve = TRUE, rand.compute = TRUE)

plot(pr_ss_hsa, main = 'PR curve, Ensemble-wise synergies (HSA)',
  auc.main = FALSE, color = my_palette[1], rand.plot = TRUE)
legend('topright', title = 'AUC', col = my_palette[1:2], pch = 19,
  legend = paste(round(pr_ss_hsa$auc.davis.goadrich, digits = 2), "Calibrated"))
grid(lwd = 0.5)
