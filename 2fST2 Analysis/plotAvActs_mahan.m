%%  Plot vERPs for our different models & experiments (i.e. tau settings)
function plotAvActs_mahan(VM, name, vERP, smooth, layer, varpath, plotpath, saveplots, TwoRespFeatures, Srivas3Trace)
%%                      PREPARATION

% Determine what to do
% quick sanity check
% if (strcmp(vERP, 'P3') || strcmp(vERP, 'N2pc') || strcmp(vERP, 'Layer')) == 0
%     msgbox('CHECK vERP INPUT! HAS TO BE EITHER P3, N2pc or Layer! STOPPING FUNC.!')
%     return
% end
dummylayer = 13; % dummy layer used if we are not interested in a specific layer's act, but vERP instead
if strcmp(vERP, 'P3')
    doP3 = 1; doN2pc = 0; layer = dummylayer;
elseif strcmp(vERP, 'N2pc')
    doP3 = 0; doN2pc = 1; layer = dummylayer;
elseif strcmp(vERP, 'Layer')
    doP3 = 0; doN2pc = 0; layer = layer;
end

%   code below uses cd, so just change cd (even though this is not the most elegant)
cdOld = cd; % so we can set cd back to what it was originally in the end

% some old function inputs we made constant
plotSE = 1;
zoomXAx = 1;

% set paths
if TwoRespFeatures == 0
    basepath = [varpath 'Srivas/' name '/']; %varpath has to be the dir where the, e.g., /key0_resp0/ subfolder is in!
    thisplotpath = [plotpath 'Srivas/' name '/'];
elseif TwoRespFeatures == 1
    basepath = [varpath 'Alon/' name '/'];
    thisplotpath = [plotpath 'Alon/' name '/'];
end

% cd to path & load vars
cd(basepath)
loadpath = [cd '/'];
disp(['Loading ' basepath name '..']);
if VM == 0
    load(name, 'ExPostsynBat_basic');
else
    load(name)
end

% use VM or ExPostsynBat
if VM
    TheArray = MembPotBat_basic;
else
    TheArray = ExPostsynBat_basic;
end

% add retina delay & create PadExPostSyn (based on st2data2eeglab)
retinadelay = 14;
onset_time = 900;
numtimepoints = size(TheArray,3);
samprate = 200;
% number of things
numtrials = size(TheArray,1);
numlags = size(TheArray,2);
numlayers = size(TheArray,4);

%add retina delay to vERP traces
%ExPostSyn is trials, lags, timepoints, layers
disp('Adding retina delay to vERP traces..');
numtimepoints = numtimepoints + retinadelay;
PadExPostSyn = zeros(numtrials,numlags,numtimepoints,numlayers);
%no retina delay for input layer
PadExPostSyn(:,:,1:(end-retinadelay),1) = TheArray(:,1:numlags,:,1);
%retina delay for other layers
PadExPostSyn(:,:,retinadelay+1:end,2:end) = TheArray(:,1:numlags,:,2:end);

%   ---------------------------------------------------------------------
%                           IMPORTANT
%   This next line does not seem important but it REALLY IS!
%   Any multi-dimensional array of PostSynaptic Activation (whether
%   TheArray or ExPostsynFull_basic or PadExPostSyn, which we
%   create to implement retina-delay ...
%       ... HAS TO BE OF SIZE LAGS x TRIALS x TIMEPOINTS x LAYERS (x NEURON)
%
%   OTHERWISE THE RESHAPING WE USE TO COMBINE LAGS / TRIALS INTO TRIALS
%   DOES NOT CORRESPOND TO THE RESPONSES WE EXTRACT WITH
%   extract_responses.m
%   ---------------------------------------------------------------------
PadExPostSyn = permute(PadExPostSyn, [2 1 3 4]);
check_PadExPostSyn(PadExPostSyn,4) % sanity checking if 1st dimension has length = 4

% Save blaster's activation trace
BlasterOut = zeros(numtrials*numlags,numtimepoints);
BlasterOut = reshape(squeeze(PadExPostSyn(:,:,:,13)), [size(PadExPostSyn,1) * size(PadExPostSyn,2), size(PadExPostSyn,3)]);

% Extract activation traces of layer of interest
if doP3
    vP3 = compute_vP3(PadExPostSyn, 'sum');
    ActArrayFull = vP3;
elseif doN2pc
    ActArrayFull = BlasterOut;
else % this else means that the function's vERP input was 'Layer'!
    if length(layer) > 1 % if more than 1 layer provided, sum activations of those layers
        ActArrayFull = reshape(squeeze(sum(PadExPostSyn(:,:,:,layer),4)), ...
            [size(PadExPostSyn,1) * size(PadExPostSyn,2), size(PadExPostSyn,3)]);
    else
        ActArrayFull = reshape(squeeze(PadExPostSyn(:,:,:,layer)), ...
            [size(PadExPostSyn,1) * size(PadExPostSyn,2), size(PadExPostSyn,3)]);
    end
end



%           --- IMPORTANT! ---
if size(BlasterOut,1) ~= size(ActArrayFull,1)
    fprintf('\n SOMETHING IS WRONG WITH ACTARRAYFULL & BLASTEROUT - CANCELLING FUNCTION! \n')
    return
end

%MAHAN: Extract epochs we want to keep & assign their conditions. Also,
%don't worry about response-locking - we won't ever.
varpath = loadpath;
[marker, fullmarker, keepepochs] = extract_responses(name, varpath, TwoRespFeatures);

% We never plot misses
% correct ActArrayFull & call it ActArray for no reason
ActArray = ActArrayFull(keepepochs, :);
% if we dont want misses, update marker cell-array, too
% correct BlasterOut, too
BlasterOut = BlasterOut(keepepochs,:);
% quick sanity check (bit unnecessary tbh..)
tmpmarker = [];
for i = 1:length(keepepochs)
    tmpmarker{i} = fullmarker{keepepochs(i)};
end
if ~isequal(tmpmarker, marker)
    msgbox('SOMETHING IS WRONG WITH YOUR MARKER, STOPPING FUNCTION!')
    return
end

%%  ACTIVATION TRACES - SRIVAS & ALON VERSION DIFFER IN NUMBER OF CONDITIONS!
% Find number of conditions in this dataset to know how many subplots we need
if TwoRespFeatures == 0
    conditions = {'pre2', 'pre1', 'correct', 'post1', 'post2'};
elseif TwoRespFeatures == 1
    conditions = {'correct', 'post1'};
else
    % quick sanity check
    msgbox('TwoRespFeatures can either be 0 (Srivas) or 1 (Alon), cancelling function!')
    return
end
%%  INITIALIZE VALID CONDITIONS (i.e. having trials) AND PLOT IT
iscond = cell(1);
for c = 1:length(conditions)
    if sum(strcmp(marker, conditions{c})) >= 1 % if we have this condition in at least one trial
        if isempty(iscond{end})
            iscond{end} = conditions{c};
        else
            iscond{end+1} = conditions{c};
        end
    end
end
num_conds = length(iscond);
% Plot it
plotit(VM, num_conds, smooth, Srivas3Trace, marker, iscond, ActArray, layer, saveplots, BlasterOut, thisplotpath, name, doP3, doN2pc, plotSE, zoomXAx, TwoRespFeatures)
% set cd to what it was originally
cd(cdOld)
end

%%      FUNCTION plotit - does the plotting
function plotit(VM, num_conds, smooth, Srivas3Trace, marker, iscond, ActArray, layer, saveplots, BlasterOut, thisplotpath, name, doP3, doN2pc, plotSE, zoomXAx, TwoRespFeatures)
f = figure;
% set(f, 'Position', [636         961        1575         377])
set(f, 'Position', [3         239        1360         428]) % laptop
ylimmax = -inf; ylimmin = inf;
numtrials = size(ActArray,1); % number of all trials
trialthresh = .05; % 5% threshold for a condition to be plotted
if Srivas3Trace == 0
    num_conds = num_conds;
    for c = 1:num_conds
        this_indices = [];
        this_indices = strcmp(marker, iscond{c});
        cur_act = ActArray(this_indices, :); % note - structure of this is trials x timepoints
        if size(cur_act,1) > numtrials*trialthresh % if at least 5% of all trials had this response, plot it. if not, too noisy.
            av_act = mean(cur_act,1);
            hold on
            p = [];
            % update ylims (don't include very beginning for this because it
            % will lead to ugly ylims for plotting VMs [we are not interested in that timeframe for AvActs anyways])
            if max(av_act(100:end)) > ylimmax
                ylimmax = max(av_act(100:end));
            end
            if min(av_act(100:end)) < ylimmin
                ylimmin = min(av_act(100:end));
            end
            % smooth vERPs with derivative
            if strcmp(smooth, 'yes') % if u wanna smooth, do it
                [av_act] = smooth_vERPs(av_act, doN2pc, doP3);
            end
            p = plot(av_act);
            if strcmp(iscond{c}, 'pre2')
                p.Color = rgb('light green');
            elseif strcmp(iscond{c}, 'pre1')
                p.Color = 'g';
            elseif strcmp(iscond{c}, 'correct')
                p.Color = 'k';
            elseif strcmp(iscond{c}, 'post1')
                p.Color = 'r';
            elseif strcmp(iscond{c}, 'post2')
                p.Color = rgb('rose');
            end
            if plotSE
                plotSEtoo(cur_act, smooth, p.Color, doN2pc, doP3)
            end
            p.LineWidth = 2;
            hold off
        end
    end
elseif Srivas3Trace == 1 % adding -2 to -1s and +2s to +1s
    num_conds = 3;
    for c = 1:num_conds
        clear this_indices
        switch c
            case 1
                this_indices = strcmp(marker, 'pre2');
                this_indices = this_indices + strcmp(marker, 'pre1');
                this_indices = logical(this_indices);
            case 2
                this_indices = strcmp(marker, 'correct');
            case 3
                this_indices = strcmp(marker, 'post1');
                this_indices = this_indices + strcmp(marker, 'post2');
                this_indices = logical(this_indices);
        end
        cur_act = ActArray(this_indices, :); % note - structure of this is trials x timepoints
        if size(cur_act,1) > numtrials*trialthresh % again, if at least 5% of trials had this response
            av_act = mean(cur_act,1);
            hold on
            p = [];
            if max(av_act(100:end)) > ylimmax % update ylims (see note above about indexing)
                ylimmax = max(av_act(100:end));
            end
            if min(av_act(100:end)) < ylimmin
                ylimmin = min(av_act(100:end));
            end
            % smooth vERPs with derivative
            if strcmp(smooth, 'yes') % if u wanna smooth, do it
                [av_act] = smooth_vERPs(av_act, doN2pc, doP3);
            end
            p = plot(av_act);
            switch c
                case 1
                    p.Color = 'g';
                case 2
                    p.Color = 'k';
                case 3
                    p.Color = 'r';
            end
            if plotSE
               plotSEtoo(cur_act, smooth, p.Color, doN2pc, doP3)
            end
            p.LineWidth = 2;
            hold off
        end
    end
end
if zoomXAx
    if doN2pc
        %         if strcmp(name, 'key0_resp0')
        %             xlim([200 300])
        %         else
        %             xlim([220 320])
        %         end
        if strcmp(name, 'key0_resp0')
            xlim([200 320])
        elseif strcmp(name, 'key9_resp0')
            xlim([200 340])
        else
            xlim([200 380])
        end
    else
        xlim([200 400])
    end
end
% ylim([ylimmin ylimmax])
hold off

% Blaster
if Srivas3Trace == 0
    for c = 1:num_conds
        hold on
        this_indices = [];
        this_indices = strcmp(marker, iscond{c});
        if sum(this_indices) > numtrials*trialthresh
            if strcmp(iscond{c}, 'pre2')
                blast_col = rgb('light green');
            elseif strcmp(iscond{c}, 'pre1')
                blast_col = 'g';
            elseif strcmp(iscond{c}, 'correct')
                blast_col = 'k';
            elseif strcmp(iscond{c}, 'post1')
                blast_col = 'r';
            elseif strcmp(iscond{c}, 'post2')
                blast_col = rgb('rose');
            end
            % Indicate blaster firing timing, too, always, even in N2pc, why not
            this_blaster = squeeze(BlasterOut(this_indices, :)); % extract blaster of this condition's trials
            this_vERP = mean(this_blaster,1); % average across all trials
            this_blasterfire = blasterfiring(this_vERP); % define blasterfiring as 50% AUC under 'this' vN2pc
            blast = vline2(this_blasterfire, 'color', blast_col);
            blast.LineWidth = 2.5;
            blast.LineStyle = ':';
            hold off
        end
    end
elseif Srivas3Trace == 1
    num_conds = 3;
    for c = 1:num_conds
        clear this_indices
        switch c
            case 1
                this_indices = strcmp(marker, 'pre2');
                this_indices = this_indices + strcmp(marker, 'pre1');
                this_indices = logical(this_indices);
                blast_col = 'g';
            case 2
                this_indices = strcmp(marker, 'correct');
                blast_col = 'k';
            case 3
                this_indices = strcmp(marker, 'post1');
                this_indices = this_indices + strcmp(marker, 'post2');
                this_indices = logical(this_indices);
                blast_col = 'r';
        end
        if sum(this_indices) > numtrials*trialthresh
            % Indicate blaster firing timing, too, always, even in N2pc, why not
            hold on
            this_blaster = squeeze(BlasterOut(this_indices, :)); % extract blaster of this condition's trials
            this_vERP = mean(this_blaster,1); % average across all trials
            this_blasterfire = blasterfiring(this_vERP); % define blasterfiring as 50% AUC under 'this' vN2pc
            blast = vline2(this_blasterfire, 'color', blast_col);
            blast.LineWidth = 2.5;
            blast.LineStyle = ':';
            hold off
        end
    end
end

hold on
% Axis-fontsize & plot ms-equivalents
ax = gca;
ax.FontSize = 18;
% fix x-axis to show time in ms-equivalents, not timesteps
for x = 1:length(ax.XTick)
    if str2double(ax.XTickLabels{x}) > length(av_act)
        ax.XTickLabels{x} = ''; 
    else
        this_xticklabel = transfertime_steps2ms(ax.XTick(x));
        ax.XTickLabels{x} = this_xticklabel;
    end
end
ax.XLabel.String = 'Time (ms-equivalent)';
if VM
    ax.YLabel.String = 'Membrane Potential';
else
    ax.YLabel.String = 'Postsynaptic Activation';
end
ax.XLabel.FontSize = 16; ax.YLabel.FontSize = 16;

% indicate if VM for suptitle & save
if VM
    analysis = 'VM ';
else
    analysis = '';
end

% indicate if smoothed and if so with sine or deriv
if strcmp(smooth, 'yes')
    smoothstr = '';
else
    smoothstr = ' (unsmoothed) ';
end

% super-title
LayerName = getLayerName(layer);
if doP3
    [~, h1] = suplabel([analysis 'vP3' smoothstr], 't');
elseif doN2pc
    [~, h1] = suplabel([analysis 'vN2pc' smoothstr], 't');
else
    [~, h1] = suplabel([analysis 'Av. Act. Levels at ' LayerName ' Layer' smoothstr], 't');
end
h1.FontSize = 22;
hold off
% save it
if saveplots
    % save it (might need to create the dir first)
    if ~exist(thisplotpath, 'dir')
        mkdir(thisplotpath)
    end
    if TwoRespFeatures == 1 || Srivas3Trace
        S3T_str = ''; % if we did 3 traces for srivas, indicate it in filename
    else
        S3T_str = '5_Trace ';
    end
    if doP3
        plotfile = [analysis 'vP3s' smoothstr 'for ' name '.jpg'];
    elseif doN2pc
        plotfile = [analysis 'vN2pcs' smoothstr 'for ' name '.jpg'];
    else
        plotfile = [analysis 'Act. levels' smoothstr 'for ' name ' at ' LayerName '.jpg'];
    end
    saveas(f, [thisplotpath S3T_str plotfile]);
end
end

