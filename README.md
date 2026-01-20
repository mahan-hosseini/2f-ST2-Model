# 2f-ST2-Model
Architecture and Analysis Codes of 2-feature Simultaneous Type/ Serial Token Model

# Note for Editors & Reviewers
Please email me at m.hosseini@fz-juelich.de if you would like to get the code files.

# Folder Overview
## 2fST2 (main model architecture here)
- Architecture and some basic/legacy readout functions
- runModel.m and readme_mahan.m have some important comments
## not final 2fST2 (architectures)
- initial_2fST2 - 2fST2 as published in Chennu et al. (2011)
- intermediate_2fST2 - 2fST2 as presented in Appendix 4 (Loss of Responsiveness)
## 2fST2 Analysis 
- All scripts required to replicate the analyses & figures generated with the model
- masterscript_2fST2.m contains important information and can itself be used to run analyses (via running its cells)
 
# Figure Overview
This overview lists which scripts are required to replicate all figures given that the respective model-configuration has been run correctly.
## Botella & Chennu
- Figure 9 (replicating Botella)
- Figure 10 (replicating Chennu)
- Figure 11 (counterintuitive RTs)
- Figure 12 (vERPs for Fig. 11)
## Alon & Martin
- Figure 14 (replicating Alon & Martin)
- Figure 15 (human ERPs of A/M)
  - batchplot_ERPs & plot_ERPs
- Figure 16 (vN2pcs)
- Figure 17 (vP3s)
## Vul et al.
- Figure 18 (Lat-Inhib Response Proportions)
- Figure 19 (Guess 1 Response Proportions)
- Figure 20 (Replicating Vul's Conditional Proportions)
## Loss of Responsiveness (Appendix 4)
- Figure 22 (Responses & vP3s)
- Figure 23 (Response TFL VMs w. task-filtering)
- Figure 24 (Response TFL WMs without task-filtering explaining RTs)
## Gamma Noise (Appendix 5)
- Figure 26 (τK-dependent Gamma Noise Distributions)
