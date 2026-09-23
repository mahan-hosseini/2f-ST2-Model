%%                  MASTERSCRIPT - 2fST2
%
%                                   NOTE
%   This is the masterscript for running the 2fst2 after me (Mahan) worked
%       on it.
%   It's full with fun stuff. The main thing you want to do is getting
%       familiar with runModel and the different ways of plotting the model's
%       results (plot_respdists / plot_AvActs or how to plot individual neurons
%   ==> See plot_mainresults for a start
%                                 IMPORTANT
%   If you want to present ANY results of this model and DON'T care about
%       how it compares to previous presentations, use runMultipleRuns to get
%       more trials and reduce variability!
%       (It's at the very bottom of this script)



%    0) What name do you want for it, which version and should neuron-acts
%       be saved?
name = 'key24_resp0';

NeurExPostsyn = 0;
% varpath = 'D:\Kent\Research\Final_ST2\Model\Variables\Alon_finalmodel\';
% plotpath = 'D:\Kent\Research\Final_ST2\Model\Plots\Alon_finalmodel\';
varpath = 'D:\Kent\Research\Final_ST2\Model\Variables\MultRuns_Final2/Srivas\'; % some paths (used from step 3) onwards)
plotpath = 'D:\Kent\Research\Final_ST2\Model\Plots\MultRunsFinal2/Srivas/';
if contains(varpath, 'Alon')
    TwoRespFeatures = 1;
elseif contains(varpath, 'Srivas')
    TwoRespFeatures = 0;
else
    answer = questdlg('TwoRespFeatures is?', 'Qs', 'Zero', 'One', 'Zero');
    switch answer
        case 'One'
            TwoRespFeatures = 1;
        case 'Zero'
            TwoRespFeatures = 0;
    end
end
saveplots = 1;
%       NOTE - We currently don't have a way of printing the exact
%          proportion of responses. I used our extract_responses function for
%          this
%       NOTE - No way of getting APIs in my code. Used Srivas' plotdist
%          function for it, it prints it to cmd window
%% INTERMEZZO/BATCHPLOT -- plot main results (respdist, av_acts, blasterfire-lat)
% allnames = {'key0_resp0', 'key24_resp0'};
% allnames = {'key24_resp0', 'key0_resp2', 'key-8_resp0'};
allnames = {'key0_resp0', 'key24_resp0'};
% allnames = {'key0_resp0', 'key0_resp2', 'key8_resp0', 'key-8_resp0', 'key24_resp0'};
blastdisttoo = 1;
for a = 1:length(allnames)
    name = allnames{a};
    plot_mainresults(name,varpath,plotpath,saveplots,TwoRespFeatures, blastdisttoo)
end

%%  DEFAULT SETTINGS (i.e. key0_resp0)
singletarg = 1; % we want only single-target trials for 2f
skeletal = 0;   % no skel-version, but 'real' RSVP
blank = 0;      % no blank condiitons either
soarate = 100;  % standard soa of 100
ExPostSynOnly = 0; % save everything, not just post-syn potentials
keyd = 0;          % key-delay
respd = 0;         % resp-delay
randd = 4;         % random delay of item-presentations
TwoRespFeatures = TwoRespFeatures;  % 1 == Run Alon's version, 0 == Run Srivas' version
NeurExPostsyn     = NeurExPostsyn; % 1 == Save individual Neuron's activations, 0 == Sum them over each layer, 2 = save VMs, 3:5 = save inhib, leak & excitatory channel inputs
SrivasRNG = 1; % 1 == Srivas' original RNG Seed (for comparability), 0 == Random reshufflings - important for runMultipleRuns.m!

%%   1) Run the model
% IF YOU WANT TO PLAY WITH PARAMETERS INSERT DIRECTLY IN LINE
% note -- saves to cd
%runModel(singletarg, skeletal, blank, soarate, ExPostSynOnly, keyd, respd, randd, TwoRespFeatures, SrivasRNG)
runModel(1, 0, 0, 100, 0, 0, 0, 4, TwoRespFeatures, NeurExPostsyn, SrivasRNG);
%%   2) Save the model
savedata(name); % You have to be in the directory where the runModel output was saved to


%%   3) Plot behavioural distribution (response-histogram)
% plotdist({name}); -- O
allnames = {'key0_resp0', 'key24_resp0'};
%allnames = {'key24_resp0'};
allresps = [0 1];
saveplots = 1;
for t = 2
    TwoRespFeatures = allresps(t);
%     for a = 1:length(allnames)
    for a = 2
        name = allnames{a};
        plot_respdists(name, varpath, plotpath, saveplots, TwoRespFeatures)
    end
end

%%   4) Replicating Srivas' CogSci Paper's Figures
% (plotdist)
%   NOTE:
%       plotdist function needs cell array of condition names because it is
%       able to automatically do grouped bar-plots when you have more than
%       1 condition name
%   ALSO:
%       plotdist needs to be in cd in which all name.mat files are (i.e.
%       not being in separate folders!)
%
%
%       FIGURE 2C - MODEL
condname = {'key0_resp0', 'key8_resp0'};
% varpath = '/Users/mn361/Kent/Research/Final_ST2/';
params.legendstrings = {'High Frequency', 'Low Frequency'}; % for legends in bar-plots
% plotdist(condname, varpath, params)
plotdist(condname, params)

%       FIGURE 3C - MODEL
condname = {'key0_resp0', 'key0_resp2'};
% plotdist(condname, varpath, params)
plotdist(condname, params)

%       FIGURE 5 
condname = {'key-8_resp0', 'key0_resp0'};
params.legendstrings = {'EK', 'LK'};
% plotdist(condname, varpath, params)
plotdist(condname, params)
%   Change bar colours to make them look like Srivas paper changing fig =
%   gcf; 
%   fig.Children(2).Children(1).FaceColor = '#830000';
%   fig.Children(2).Children(2).FaceColor = '#0504AA';

%       RT - FIGURE
calcRT_mahan(name, varpath, plotpath, saveplots, TwoRespFeatures)

%       FOR THESIS - PLOTRESPDIST WITH SAME STRUCTURE AS BOTELLA 2001 
plotdist_thesisversion

%%   ******************************************************************
%   ******************************************************************
%   ******************************************************************
%   ******************************************************************

%           WE NOW MOVE ONTO PLOTTING THE MODEL'S ACTIVATIONS 
%   ==> Either averaged across a whole layer or for individual neurons 

%   ******************************************************************
%   ******************************************************************
%   ******************************************************************
%   ******************************************************************

%   ==> Here we can plot Postsynaptic Activations, Membrane Potentials or
%       even individual input channel's time-series
%   ==> However, we have two approaches based on whether we want to plot
%       the whole layer or individual neurons
%   ==> If we plot the whole layer, we just use the model's .mat-files,
%       generated by savedata
%   ==> However, the model's mat-files are big if we saved individual neurons, so
%       for that we first extract individual layers and then load the
%       resulting files to plot
%   ==> NOTE - FEB 2021 THIS IS NOT IMPLEMENTED YET FOR 1plot-FUNC!
  


%%                  PLOTTING AVERAGES ACROSS LAYER
%%   4) Plot vERPs
allnames = {'key0_resp0', 'key24_resp0'};
vERPs = {'N2pc', 'P3'};
allresps = [0 1];
smooth = 'yes'; % smooth taking the derivative wave
VM = 0; % 1 if we plot VMs, 0 if we plot Excitatory Activation
Srivas3Trace = 1;

saveplots = 0;
for t = 2
    TwoRespFeatures = allresps(t);
    for v = 1:2
        vERP = vERPs{v};
        for a = 1:length(allnames)
%         for a = 2
            name = allnames{a};
            layer = 13; % only used if vERP = 'Layer'!!!
            plotAvActs_mahan(VM, name, vERP, smooth, layer, varpath, plotpath, saveplots, TwoRespFeatures, Srivas3Trace)
        end
    end
end

%%  5) Plot Average Activation Traces for different layers using plotAvActs_mahan as well
allnames = {'key0_resp0', 'key24_resp0'};
varpath = '/Users/mn361/Kent/Research/Final_ST2/Model/Variables/';
fullplotpath = '/Users/mn361/Kent/Research/Final_ST2/Model/Plots/LayActTraces/';
%alllayers = [3 4 6 17 18 21];
alllayers = [1 2 15 16];
plotmisses = 0;
%zoomXAxes = [0 1];
zoomXAx = 0;
plotSE = 1;
saveplots = 1;
for e = 1:2 % srivas/alon
    switch e
        case 1
            TwoRespFeatures = 0;
          %  varpath = [basepath 'Srivas/'];
        case 2
            TwoRespFeatures = 1;
           % varpath = [basepath 'Alon/'];
    end
  %  for zXAx = 1:2
  %      zoomXAx = zoomXAxes(zXAx);
        if zoomXAx == 0
            this_plotpath = [fullplotpath 'zoomed_out/'];
        else
            this_plotpath = fullplotpath;
        end
        for n = 1:length(allnames)
            for l = 1:length(alllayers)
                name = allnames{n};
                layer = alllayers(l);
                plotAvActs_mahan(name, 'Layer', layer, plotSE, plotmisses, zoomXAx, varpath, this_plotpath, saveplots, TwoRespFeatures)
            end
        end
  %  end
end




%%                  PLOTTING INDIVIDUAL NEURONS
%%  6) Run transfermodelmat2ArrayLayer 
transfer_modelmat2ArrayLayer(varpath, name, whichlayers);

%%  7) Run plotActs2_mahan to plot individual neurons' Act/VM/etc 
%   ==> Avoids running plot_Acts(1)-version of functions that take those huge .mat-files and load them twice)
plotActs2_mahan(name, VM, vERP, layer, zoomXAx, varpath, plotpath, saveplots, TwoRespFeatures) % varpath has to lead to output of transfer_function

%   ==> NOTE TO MYSELF
%   Still have to do this for 1plot-version

%%  8) Plot activation traces of individual nodes for all layers going in to P3 as well as overall vP3
varpath = []; plotpath = [];
%varpath = '/Users/mn361/Kent/Research/Final_ST2/Model/Variables/save_acts/';
varpath = 'shared/home/mn361/Matlab/ST2/correct_Alon/';
plotpath = '/Users/mn361/Kent/Research/Final_ST2/Model/Plots/NeurActTraces/';
VM = 0; % if VM, we are plotting membrane potentials and not output activation
if VM
    varpath = [varpath 'save_VMs/'];
    plotpath = [plotpath 'VMs/'];
end
TwoRespFeatures = 1;
allnames = {'key0_resp0', 'key10_resp0', 'key24_resp0'};
oneplot = 1; % 1 if both conditions' act-traces in the same subplot (only for my version of the model)

batchplot_acttraces(varpath, plotpath, TwoRespFeatures, allnames, oneplot, VM)


%%   ******************************************************************
%   ******************************************************************
%   ******************************************************************
%   ******************************************************************

%           FINALLY WE MOVE ON TO SOME SPECIAL CASES & PLOTS

%   ******************************************************************
%   ******************************************************************
%   ******************************************************************
%   ******************************************************************


%%  9) Plot each condition's blasterfiring-latency distributions 
%   ==> Needs BlasterOut ActArray, so you might need to run the next line first
% transfer_modelmat2ArrayLayer(varpath, name, 13);

plot_blasterdistributions(name, varpath, plotpath, saveplots, TwoRespFeatures)

%%  10) Plot the loss of responsiveness plots of TwoRespFeature's vP3s
varpath = 'D:\Kent\Research\Final_ST2\Model\Variables\loss_of_respness_finalmodel\';
extract_1NeurDiffDelays(VM, layer, keydelays, neuron, response, varpath, TwoRespFeatures)
masterplot_LossOfResponsiveness(plotpath, varpath, saveplots)

%% 11) Replicating Vul et al. 
% The first function is used to investigate the effects of 
%   lateral inhibition on multibindings and stuff, change its value 
%   manually in architecture.m
% Save the range from 0 to -.05 according to lat inhib value 
%   (without task filtering & delays to processing) 
plot_VulFigures_SingleRun

% This is the code we use to replicate Vul's Figure 9 
%   It runs 20 runs of the model & replicates Vul's Figure 9 (inputvar
%   determines whether model is ran 20 times or not [i.e. it was done
%   previously])
ReplicatingVul_RunAndPlotMultRuns(runModel20x)

% Note that MultRuns version has interpolation to make grey line comparable 
%   to coloured ones and SingleRun does not!
%   ==> This is fine because SingleRun should not be used for presenting
%       Figure9 anyways, just for getting a feeling of how lat inhib affects
%       things, which you get without interpolating, too
%%  12) Run multiple runs of the model to get more trials 
Srivas3Trace = 1;
varpath = 'D:\Kent\Research\Final_ST2\Model\Variables\MultRuns_Final\Chapter 4\';
plotpath = 'D:\Kent\Research\Final_ST2\Model\Plots\MultRuns_Final\Chapter 4\';
saveplots = 1;
TwoRespFeatures = 1;
runMultipleRuns(TwoRespFeatures, Srivas3Trace, varpath, plotpath, saveplots) % note running multiple runs has to be done manually, this function is rather used to get the main results

%%              OVERVIEW OF UTIL FUNCTIONS
%   blasterfiring           -- computes 50% vN2pc AUC measure of blasterfiring-latency
%   compute_vP3             -- computes vP3 with TFLs & BPs contributing equally to it
%   transfertime_steps2ms   -- translates data-points to time-points in ms-equivalents
%   extract_responses       -- extracts which responses were given by the model 
%   getLayerName            -- translates layer number to a string with its name
%   check_PadExPostSyn      -- checks if PadExPostSyn was computed correctly 
%   marker2respnums         -- translates response-strings to numbers (-2 to +2)
%















%%              SOME OLD THINGS




%%   X) Extract Corrects & Intrusions (or corrects, pre & post-targets for
%   Srivas original model) and save them as separate EEGLAB .set files
% Again, TwoRespFeatures: 1 == Run Alon's version, 0 == Run Srivas' version
%   Note that if we are working with Srivas' model, -2 and -1s are both
%   included as pre-targets and similarly for +2, +1 and post-targets!
extract_EEGLABconds(name, TwoRespFeatures)
%%   X) Transform to EEGLAB .set format
st2data2eeglab(name, 0) % 0 == response locked

%           Note
% MAHAN: Changed a bit that implements info about markers (i.e. condition)
% to EEG.event.type structure so we can split it up into multiple .set
% files in the next step.

%%  X) Plot AUC-latency distributions of individual trials & neurons for different key-delays
varpath = '/Users/mn361/Kent/Research/Final_ST2/Model/Variables/save_acts/';
plotpath = '/Users/mn361/Kent/Research/Final_ST2/Model/Plots/NeurLatencyDistributions/';
TwoRespFeatures = 1;
allnames = {'key0_resp0', 'key24_resp0'};
batchplot_latdists(varpath, plotpath, TwoRespFeatures, allnames)