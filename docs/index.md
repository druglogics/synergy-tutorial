---
title: "Tutorial for synergy prediction using the DrugLogics software pipeline"
author: "[John Zobolas](https://github.com/bblodfon)"
date: "Last updated: 15 November, 2021"
description: "A software tutorial"
url: 'https\://druglogics.github.io/synergy-tutorial/'
github-repo: "druglogics/synergy-tutorial"
bibliography: references.bib
link-citations: true
site: bookdown::bookdown_site
---

# Intro {-}

The purpose of the present tutorial is to provide guidance for the installation, execution, visualization and interpretation of output simulation results for the DrugLogics software pipeline module [druglogics-synergy](https://github.com/druglogics/druglogics-synergy).

The `druglogics-synergy` module runs sequentially two software modules.
Firstly, [gitsbe](https://github.com/druglogics/gitsbe) is used to create an ensemble of Boolean models fit to a specific steady state or perturbation data using a genetic parameterization algorithm.
Then [drabme](https://github.com/druglogics/drabme) uses the output models from gitsbe to perform a drug response analysis of a given drug panel and produces predicted synergy scores for each respective drug combination.

You can find the full documentation for these two modules in the following link: https://druglogics.github.io/druglogics-doc/.

# Install {-}

:::{.green-box}
Firstly, make sure you have installed [Maven](https://maven.apache.org/install.html) `3.6.0` and `Java 8` (minimum working versions).
For the rest of the tutorial we are going to use the `druglogics-synergy` at version `1.2.1`, which includes `gitsbe` at `1.3.1` version and `drabme` at `1.2.1` version.
:::

There are **two ways** to install `druglogics-synergy`.

1. **The easiest option** is to download the latest released package from GitHub: https://github.com/druglogics/druglogics-synergy/packages/.
The file of interest is `synergy-1.2.1-jar-with-dependencies.jar`, which includes all dependencies and does not require any manual installation whatsoever.

2. **The other option** is to clone the repositories ^[Sorry, but due to GitHub not allowing users to download a public package without a token, you have to install each dependency repository (gitsbe, drabme) separately!] and install them manually using Maven:

```
git clone https://github.com/druglogics/gitsbe.git
cd gitsbe
git checkout v1.3.1
mvn clean install
cd ../

git clone https://github.com/druglogics/drabme.git
cd drabme
git checkout v1.2.1
mvn clean install
cd ../

git clone https://github.com/druglogics/druglogics-synergy
cd druglogics-synergy
git checkout v1.2.1
mvn clean install
```

After executing the above commands, the `synergy-1.2.1-jar-with-dependencies.jar` file will be created inside the `druglogics-synergy/target` directory.

:::{.note}
Even if you choose the 1st option, make sure you clone the `druglogics-synergy` repo and put the `synergy-1.2.1-jar-with-dependencies.jar` file inside the `druglogics-synergy/target` directory (as `mvn clean install` command does) to be inline with the next instructions in this tutorial.
:::

# Run CASCADE 1.0 example {-}

We are going to use the [`ags_cascade_1.0`](https://github.com/druglogics/druglogics-synergy/tree/v1.2.1/ags_cascade_1.0) directory that resides in the `druglogics-synergy` directory as an input to the `Launcher` class to run the CASCADE 1.0 example.

The command to execute from the root of the `druglogics-synergy` directory is the following:

```
java -cp target/synergy-1.2.1-jar-with-dependencies.jar eu.druglogics.synergy.Launcher --inputDir=ags_cascade_1.0/
```

Given that the simulations use all available cores, the above command shouldn't take more than 30sec to 1min to finish on a decent computer.

## Inputs {-}

A brief description of the input files included in the [`ags_cascade_1.0`](https://github.com/druglogics/druglogics-synergy/tree/v1.2.1/ags_cascade_1.0) directory are:

1. [`network.sif`](https://github.com/druglogics/druglogics-synergy/tree/v1.2.1/ags_cascade_1.0/network.sif): a single-interactions network file in Cytoscape's .sif tab-delimited format.
This file defines the CASCADE 1.0 topology.
2. [`training`](https://github.com/druglogics/druglogics-synergy/tree/v1.2.1/ags_cascade_1.0/training): this file has the training data for gitsbe's algorithm in one of the formats specified in the respective [documentation](https://druglogics.github.io/druglogics-doc/training-data.html).
Here, we train to an unperturbed condition, with a steady state observation response as curated from many publications for the AGS cell line [@Flobak2015].
3. [`modeloutputs`](https://github.com/druglogics/druglogics-synergy/tree/v1.2.1/ags_cascade_1.0/modeloutputs): this is a file that is used to calculate the output growth response of a Boolean model after its attractors are computed.
See more information in the respective [documentation](https://druglogics.github.io/druglogics-doc/modeloutputs.html).
Here, we define 3 nodes that signal cell proliferation when active (`RSK_f`, `MYC` and `TCF7_f`) and 3 that signal apoptosis (`CASP8`, `CASP9` and `FOXO_f`).
4. [`drugpanel`](https://github.com/druglogics/druglogics-synergy/tree/v1.2.1/ags_cascade_1.0/drugpanel): this file has the drugs and their respective targets, which are going to be analyzed by drabme using gitsbe's output Boolean models.
More info can be found [here](https://druglogics.github.io/druglogics-doc/drug-panel.html).
5. [`config`](https://github.com/druglogics/druglogics-synergy/tree/v1.2.1/ags_cascade_1.0/config): configuration file that defines several parameters used by gitsbe and drabme.
Apart from the short description for each parameter provided in the `config` file, there is a more complete documentation of each option [available here](https://druglogics.github.io/druglogics-doc/gitsbe-config.html).
The most important options for [gitsbe](https://github.com/druglogics/druglogics-synergy/blob/v1.2.1/ags_cascade_1.0/config#L27) are the tool used to calculate the models' attractors (bioLQM [@Naldi2018]), the number of simulations (50), number of generations per simulation (20), number of models per generation (20), number of best-fit models to save after each simulation is finished (3) and the type of [model mutations](https://druglogics.github.io/druglogics-doc/gitsbe-config.html#mutation-types) used (*balance* or *link operator* mutations).
For [drabme](https://github.com/druglogics/druglogics-synergy/blob/v1.2.1/ags_cascade_1.0/config#L96), the two most important configuration parameters are the maximum drug set size to test (2, i.e. up to drug pairs) and the method used for the calculation of drug synergies (we use HSA [@gaddum1940pharmacology] in the `config` file, but also Bliss [@Bliss1939] is available).

## Outputs {-}



# Get predictions {-}

# Visualize performance (ROC, PR) {-}

# Miscellanious {-}

# R session info {-}


```{.r .fold-show}
xfun::session_info()
```

```
R version 3.6.3 (2020-02-29)
Platform: x86_64-pc-linux-gnu (64-bit)
Running under: Ubuntu 20.04.3 LTS

Locale:
  LC_CTYPE=en_US.UTF-8       LC_NUMERIC=C              
  LC_TIME=en_US.UTF-8        LC_COLLATE=en_US.UTF-8    
  LC_MONETARY=en_US.UTF-8    LC_MESSAGES=en_US.UTF-8   
  LC_PAPER=en_US.UTF-8       LC_NAME=C                 
  LC_ADDRESS=C               LC_TELEPHONE=C            
  LC_MEASUREMENT=en_US.UTF-8 LC_IDENTIFICATION=C       

Package version:
  base64enc_0.1.3 bookdown_0.24   bslib_0.3.1     compiler_3.6.3 
  digest_0.6.28   evaluate_0.14   fastmap_1.1.0   fs_1.5.0       
  glue_1.4.2      graphics_3.6.3  grDevices_3.6.3 highr_0.9      
  htmltools_0.5.2 jquerylib_0.1.4 jsonlite_1.7.2  knitr_1.36     
  magrittr_2.0.1  methods_3.6.3   R6_2.5.1        rappdirs_0.3.3 
  rlang_0.4.11    rmarkdown_2.11  sass_0.4.0      stats_3.6.3    
  stringi_1.7.5   stringr_1.4.0   tinytex_0.34    tools_3.6.3    
  utils_3.6.3     xfun_0.26       yaml_2.2.1     
```

# References {-}