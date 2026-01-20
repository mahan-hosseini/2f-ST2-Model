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
- This folder probably contains some scripts that are not used in the paper but generate some stuff I had in my thesis
- Still, if you feel like something is missing send me an email at m.hosseini@fz-juelich.de
 
# Figure Overview
This overview lists which scripts are required to replicate all figures given that the respective model-configuration has been run correctly. 
A lot of this is explained / demonstrated in masterscript_2fST2.m
Also note that for most results shown in the paper we ran the model five times using runMultipleRuns.m 

## Botella & Chennu
- Figure 9 (replicating Botella)
  - plot_respdists 
- Figure 10 (replicating Chennu)
  - plot_dist
  - calcRT_mahan
- Figure 11 (counterintuitive RTs)
  - calcRT_mahan
- Figure 12 (vERPs for Fig. 11)
  - plotAvActs_mahan
## Alon & Martin
- Figure 14 (replicating Alon & Martin)
  - plot_respdists
- Figure 15 (human ERPs of A/M)
  - batchplot_ERPs & plot_ERPs
- Figure 16 (vN2pcs)
  - plotAvActs_mahan 
- Figure 17 (vP3s)
  - plotAvActs_mahan 
## Vul et al.
Note that for Figure 18 we use a different script than for the other figures, since for 18 we do single runs of the model for different values of lateral inhibition (which have to be set manually in the model architecture - see architecture.m's line 300-307). For the other ones we do 20 runs of the model with different RNG seeds. See the note in ReplicatingVul_RunAndPlotMultRuns.m 
- Figure 18 (Lat-Inhib Response Proportions)
  - plot_VulFigures_SingleRun
- Figure 19 (Guess 1 Response Proportions)
  - ReplicatingVul_RunAndPlotMultRuns 
- Figure 20 (Replicating Vul's Conditional Proportions)
  - ReplicatingVul_RunAndPlotMultRuns
## Loss of Responsiveness (Appendix 4)
- Figure 22 (Responses & vP3s)
  - plot_respdists
  - plotAvActs_mahan
- Figure 23 (Response TFL VMs w. task-filtering)
  - plotActs2_mahan
- Figure 24 (Response TFL VMs without task-filtering explaining RTs)
  - plotActs2_mahan
## Gamma Noise (Appendix 5)
- Figure 26 (τK-dependent Gamma Noise Distributions)
  - No specific script. Get the distributions with a breakpoint in runModel.m line 222 
