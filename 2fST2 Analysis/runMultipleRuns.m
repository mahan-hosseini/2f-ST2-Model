%%      Run 2fST2 multiple times and combine results to have more trials

function runMultipleRuns(TwoRespFeatures, Srivas3Trace, varpath, plotpath, saveplots)
%%  ***************************************************************
%   1) Running it multiple times with
%   ***************************************************************

%   ************************** IMPORTANT ***************************
%   ==> When running this, you have to make sure that SrivasRNG of
%   runModel.m is set to 0!
%   ****************************************************************

%   ************************** IMPORTANT ***************************
%   ==> Running this is not part of this function. This function is rather
%       used to combine & analyze the results of multiple runs. To run them
%       comment out the bit [1)] below and set things up as you want (name, runs,
%       path for vars) and just copy/paste it to cmd window
%   ==> Then copy over the results to varpath (the input one to this func)
%   ==> And from there use this function for the rest
%   ****************************************************************

% basepath = '/shared/home/mn361/Matlab/ST2/Chapter4/multruns_gamnoise/';
% runs = {'1','2','3','4','5'};
% name = 'key24_resp0';
% for r = 1:length(runs)
%     rng(r, 'twister') % just use value of r for seeding. make sure to seed rng in this loop (OUTSIDE model though!)
%     cd(basepath)
%     thispath = [basepath name '/' runs{r} '/'];
%     if ~exist(thispath, 'dir')
%         mkdir(thispath)
%     end
%     cd(thispath)
%     runModel(1,0,0,100,0,24,0,4,1,0,0)
%     savedata(name)
% end



%%  ***************************************************************
%   2) First run extract_responses on each individual name.mat-file and
%       then concatenate its output as well as ExPostsynBat_basic
%   ***************************************************************

% check if we had specified exp's name in varpath and if not, specify
if (contains(varpath, 'Alon') || contains(varpath, 'Srivas')) == 0 
    if TwoRespFeatures
        varpath = [varpath 'Alon/'];
        plotpath = [plotpath 'Alon/'];
    else
        varpath = [varpath 'Srivas/'];
        plotpath = [plotpath 'Srivas/'];
    end
end

if (contains(varpath, 'Alon')) && TwoRespFeatures == 0 || (contains(varpath, 'Srivas') && TwoRespFeatures == 1)
    msgbox('Wrong varpath or TwoRespFeatures flag - cancelling func.!')
    return
end

% use these infos to determine allnames - only different for chapter 4
% (gammanoise) & Alon
if contains(varpath, 'Chapter 4') && TwoRespFeatures
    allnames = {'key0_resp0', 'key9_resp0', 'key24_resp0'};
elseif contains(varpath, 'MultRuns_Final2') 
    if TwoRespFeatures % final final version (for paper) with GammaNoise shape modulations
        allnames = {'key13_resp0', 'key36_resp0'}; % Alon - compare
    else
        allnames = {'key0_resp0'}; % Srivas - just key0 for paper
    end
else
    allnames = {'key0_resp0', 'key24_resp0'};
end

runs = {'1','2','3','4','5'}; % before if statement bc code below uses it too

% Only do this after first run & save. Otherwise use the saved files.
if exist([varpath 'MR_outputstructs.mat'], 'file') ~= 2 % if it's not a matfile
    
    % so we make structs with 2 fields and empty cells to be assigned in the
    % loop below
    allmarkers = cell2struct(cell(1,length(allnames)), allnames, 2); allmarkers(length(runs)).(allnames{1}) = []; % initialize struct-length
    allfullmarkers = cell2struct(cell(1,length(allnames)), allnames, 2); allfullmarkers(length(runs)).(allnames{1}) = [];
    allkeepepochs = cell2struct(cell(1,length(allnames)), allnames, 2); allkeepepochs(length(runs)).(allnames{1}) = [];
    allExPost = cell2struct(cell(1,length(allnames)), allnames, 2); allExPost(length(runs)).(allnames{1}) = [];
    allinputstrengths = cell2struct(cell(1,length(allnames)), allnames, 2); allinputstrengths(length(runs)).(allnames{1}) = [];
    for a = 1:length(allnames)
        name = allnames{a};
        for r = 1:length(runs)
            fprintf(' \n *** EXTRACTING %s & RUN %s *** \n ', name, runs{r})
            this_varpath = [varpath name '/' runs{r} '/'];
            [marker, fullmarker, keepepochs] = extract_responses(name, this_varpath, TwoRespFeatures); %TwoRespFeatures is 1
            allmarkers(r).(allnames{a}) = marker;
            allfullmarkers(r).(allnames{a}) = fullmarker;
            allkeepepochs(r).(allnames{a}) = keepepochs;
            thisload = load([this_varpath name '.mat'], 'ExPostsynBat_basic'); % load creates a struct in which the first field is called varname and has our var
            allExPost(r).(allnames{a}) = thisload.ExPostsynBat_basic; % assign it to allExPost
            inputstrengthsload = load([this_varpath 'inputstrength_struct100ms.mat']);
            allinputstrengths(r).(allnames{a}) = inputstrengthsload.inputstrengths;
        end
    end
    % save it
    save([varpath 'MR_outputstructs.mat'], 'allmarkers', 'allfullmarkers', 'allkeepepochs', 'allExPost', 'allinputstrengths', '-v7.3')
else % load it
    fprintf(' \n *** LOADING MR_outputstructs.mat *** \n ')
    MR_outputstructs = load([varpath 'MR_outputstructs']);
    allmarkers = MR_outputstructs.allmarkers;
    allfullmarkers = MR_outputstructs.allfullmarkers;
    allkeepepochs = MR_outputstructs.allkeepepochs;
    allExPost = MR_outputstructs.allExPost;
end

%%  ***************************************************************
%   3) Get ExPostsyn in the correct shape for each analysis. Concatenate
%       trials and marker afterwards and finally use marker to extract relevant
%       trials
%   ***************************************************************

% Initialize clean (i.e. without misses) actarray-structs
%   note - this is a bit unelegant since we create key0&24 fields
%          hard-coded-ly and then if we should have a different name (eg. key13)
%          it just creates a new field later on and uses that (correctly) instead
%          of the empty key0&24 ones. it does the job.
BlasterOut_Clean = struct('key0_resp0', [], 'key24_resp0', []); BlasterOut_Clean(length(runs)).key0_resp0 = [];
vP3_Clean = struct('key0_resp0', [], 'key24_resp0', []); vP3_Clean(length(runs)).key0_resp0 = [];


% add retina delay & create PadExPostSyn (based on st2data2eeglab)
retinadelay = 14;
onset_time = 900;
numtimepoints = size(allExPost(1).(allnames{1}),3); %which name we take here is not important, since these are fixed across cfgs
numtimepoints = numtimepoints + retinadelay; % add retina delay only once (not inside loop below)
samprate = 200;
% number of things
numtrials = size(allExPost(1).(allnames{1}),1);
numlags = size(allExPost(1).(allnames{1}),2);
numlayers = size(allExPost(1).(allnames{1}),4);

%% Loop over all runs & names
for a = 1:length(allnames)
    name = allnames{a};
    for r = 1:length(allExPost)
        
        % Assign this current array (of this run) to this array
        ThisArray = allExPost(r).(allnames{a});
        
        %   ********** OLD CODE WE ARE FAMILIAR WITH ***************
        %add retina delay to vERP traces
        %ExPostSyn is trials, lags, timepoints, layers
%         disp('Adding retina delay to vERP traces..');
        
        PadExPostSyn = zeros(numtrials,numlags,numtimepoints,numlayers);
        %no retina delay for input layer
        PadExPostSyn(:,:,1:(end-retinadelay),1) = ThisArray(:,1:numlags,:,1);
        %retina delay for other layers
        PadExPostSyn(:,:,retinadelay+1:end,2:end) = ThisArray(:,1:numlags,:,2:end);
        
        %   ---------------------------------------------------------------------
        %                           IMPORTANT
        %   This next line does not seem important but it REALLY IS!
        %   Any multi-dimensional array of PostSynaptic Activation (whether
        %   ThisArray or ExPostsynFull_basic or PadExPostSyn, which we
        %   create to implement retina-delay ...
        %       ... HAS TO BE OF SIZE LAGS x TRIALS x TIMEPOINTS x LAYERS (x NEURON)
        %
        %   OTHERWISE THE RESHAPING WE USE TO COMBINE LAGS / TRIALS INTO TRIALS
        %   DOES NOT CORRESPOND TO THE RESPONSES WE EXTRACT WITH
        %   extract_responses.m
        %   ---------------------------------------------------------------------
        PadExPostSyn = permute(PadExPostSyn, [2 1 3 4]);
        check_PadExPostSyn(PadExPostSyn,4) % sanity checking if 1st dimension has length = 4
        
        %   ********** NEW CODE FROM HERE ON AGAIN ***************
        This_BlasterOut_Full = zeros(numtrials*numlags,numtimepoints);
        This_BlasterOut_Full = reshape(squeeze(PadExPostSyn(:,:,:,13)), [size(PadExPostSyn,1) * size(PadExPostSyn,2), size(PadExPostSyn,3)]);
        This_vP3_Full = compute_vP3(PadExPostSyn, 'sum');
        This_BindPool_Full = zeros(numtrials*numlags,numtimepoints);
        bindlayer = 9;
        This_BindPool_Full = reshape(squeeze(PadExPostSyn(:,:,:,bindlayer)), [size(PadExPostSyn,1) * size(PadExPostSyn,2), size(PadExPostSyn,3)]);
        
        this_keepepochs = allkeepepochs(r).(allnames{a}); % for sanity checks, we really need to be careful with this stuff.
        this_fullmarker = allfullmarkers(r).(allnames{a});
        this_marker = allmarkers(r).(allnames{a});
        
        if size(This_BlasterOut_Full, 1) ~= length(this_fullmarker)
            msgbox('SOMETHING WRONG WITH MARKERS - CANCELLING!')
            return
        end
        This_BlasterOut = This_BlasterOut_Full(this_keepepochs, :);
        This_vP3 = This_vP3_Full(this_keepepochs, :);
        This_BindPool = This_BindPool_Full(this_keepepochs, :);
        
        if size(This_BlasterOut, 1) ~= length(this_marker)
            msgbox('SOMETHING WRONG WITH MARKERS - CANCELLING!')
            return
        end
        
        % if all sanity checks are passed, assign it to clean-structs
        BlasterOut_Clean(r).(allnames{a}) = This_BlasterOut;
        vP3_Clean(r).(allnames{a}) = This_vP3;
        BindPool_Clean(r).(allnames{a}) = This_BindPool;
    end
    % NEXT UP - concatenate first dimension (trials) of act-arrays and
    % marker. Use both to run plotit funciton (copied from
    % plotAvActs_mahan) once for vN2pc once for vP3 and use marker
    % (concatenated) to run plot_respdists (or just copy and modify a short
    % local function like u will do with plotAvActs)
    
    %   ***************************************************************
    %   Concatenate vERPs and markers/BP
    %   ***************************************************************
    vP3s = cat(1,vP3_Clean.(allnames{a}));
    vN2pcs = cat(1,BlasterOut_Clean.(allnames{a}));
    Markers = cat(2,allmarkers.(allnames{a}));
    BindPool = cat(1,BindPool_Clean.(allnames{a}));
    
    %%  ***************************************************************
    %   Run MR function-versions of plotting Response Distributions, vERPs,
    %   BlasterDistributions, RTs & Key9Key24ComparisonvERPs
    %   ***************************************************************
    
    %   Response Distributions
    marker = Markers; % this overwrites the last run's marker, but that's ok
    MR_plot_respdists(name, marker, plotpath, saveplots, TwoRespFeatures)
    
    %%   vERPs (using plotAvAct_mahan's plotit-function)
    VM = 0;
    marker = Markers;
    iscond = unique(marker);
    num_conds = length(unique(marker));
    layer = 13;
    BlasterOut = vN2pcs;
    thisplotpath = plotpath;
    name = name;
    plotSE = 1;
    zoomXAx = 1;
    
    % do vERPs unsmoothed & smoothed each
    smoothings = {'yes', 'no'};
    for s = 1:length(smoothings)
        smooth = smoothings{s};
        
        % vP3
        doP3 = 1;
        doN2pc = 0;
        ActArray = vP3s;
        MR_plotit(VM, num_conds, smooth, Srivas3Trace, marker, iscond, ActArray, layer, saveplots, BlasterOut, thisplotpath, name, doP3, doN2pc, plotSE, zoomXAx, TwoRespFeatures)
        
        % vN2pc
        doP3 = 0;
        doN2pc = 1;
        ActArray = vN2pcs;
        MR_plotit(VM, num_conds, smooth, Srivas3Trace, marker, iscond, ActArray, layer, saveplots, BlasterOut, thisplotpath, name, doP3, doN2pc, plotSE, zoomXAx, TwoRespFeatures)
    end
    
    %% BlasterDistributions
    name = name;
    marker = Markers;
    BlasterOut = vN2pcs;
    MR_plot_blasterdistributions(name, marker, BlasterOut, plotpath, saveplots, TwoRespFeatures)
    
    %% Reaction Times (only if key0_resp0 + Srivas)
    if strcmp(name, 'key0_resp0') && (TwoRespFeatures == 0)
        marker = Markers;
        MR_calcRT(BindPool, marker, plotpath, saveplots)
    end

end

% vERP Comparison Plots (key9 vs key24) (outside names loop bc we are comparing names (i.e. delaycfgs)
smoothings = {'yes', 'no'}; % again - do vERPs unsmoothed & smoothed each

% Get separate vP3 & vN2pc arrays (&markers) for comparisons
%   NOTE! - MultRuns_Final2 is the finalfinal version of the model in
%       which the shape parameter of GammaNoise distributions is modulated
%       by tau(k) too. In these we have different values for tau(k) to
%       replicate the experiments of Alon & Martin. But instead of
%       re-naming all the variables and stuff we just keep the logic the
%       same and make sure the correct fields are assigned to the _9 & _24 
%       variables here!
%       ==> Ie. allnames{1} is key13 and {2} is key36
%       ==> This works because we always only compare 2 delay conditions
%           with this!

vP3s_9 = cat(1,vP3_Clean.(allnames{1}));
vP3s_24 = cat(1,vP3_Clean.(allnames{2}));
vN2pcs_9 = cat(1,BlasterOut_Clean.(allnames{1}));
vN2pcs_24 = cat(1,BlasterOut_Clean.(allnames{2}));
marker_9 = cat(2,allmarkers.(allnames{1}));
marker_24 = cat(2,allmarkers.(allnames{2}));
BlasterOut_9 = vN2pcs_9;
BlasterOut_24 = vN2pcs_24;
layer = 13; % won't be used

for s = 1:length(smoothings)
    smooth = smoothings{s};
    
%     vP3
    vERP = 'P3';
    ActArray_9 = vP3s_9;
    ActArray_24 = vP3s_24;
    MR_plot_AvAct_Comparisons(vERP, ActArray_9, ActArray_24, BlasterOut_9, BlasterOut_24, marker_9, marker_24, smooth, layer, plotpath, saveplots, TwoRespFeatures)

%     vN2pc
    vERP = 'N2pc';
    ActArray_9 = vN2pcs_9;
    ActArray_24 = vN2pcs_24;
    MR_plot_AvAct_Comparisons(vERP, ActArray_9, ActArray_24, BlasterOut_9, BlasterOut_24, marker_9, marker_24, smooth, layer, plotpath, saveplots, TwoRespFeatures)
end
end

%%              OLD STUFF THAT MIGHT BE USEFUL LATER
%
%       ==> Cd through analyses and only run savedata <==
%
% basepath = '/shared/home/mn361/Matlab/ST2/Chapter4/multruns_gamnoise/';
% runs = {'1','2','3','4','5'};
% allnames = {'key0_resp0','key24_resp0'};
%
% for a = 1:2
%     name = allnames{a};
%     for r = 1:4
%         %     rng('shuffle', 'twister') % make sure to seed rng in this loop (OUTSIDE model though!)
%         %     cd(basepath)
%         thispath = [basepath name '/' runs{r} '/'];
%         fprintf('\n *** SAVING %s %s *** \n', name, runs{r})
%         cd(thispath)
%         load([thispath 'STSTerp_1targ_100ms.mat'])
%         load([thispath 'STSToutput_1targ_100ms.mat'])
%         %     runModel(1,0,0,100,0,0,0,4,1,0)
%         savedata(name)
%         clearvars -except basepath runs allnames name
%     end
% end