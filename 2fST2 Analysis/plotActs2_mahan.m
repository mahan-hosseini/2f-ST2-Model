function plotActs2_mahan(name, VM, vERP, layer, zoomXAx, varpath, plotpath, saveplots, TwoRespFeatures)
%%                          PREPARATION
% Determine what to do & sanity checks
if (strcmp(vERP, 'P3') || strcmp(vERP, 'N2pc') || strcmp(vERP, 'Layer')) == 0
    msgbox('CHECK vERP INPUT! HAS TO BE EITHER P3, N2pc or Layer! STOPPING FUNC.!')
    return
end
% dummylayer = 13; % dummy layer used if we are not interested in a specific layer's act, but vERP instead
if strcmp(vERP, 'P3')
    %     doP3 = 1; doN2pc = 0; layer = dummylayer;
    msgbox('CURRENTLY NO SUPPORT FOR P3s (have 2 write a new version of compute_vP3 for it) - CANCELLING!')
    return
elseif strcmp(vERP, 'N2pc')
    %     doP3 = 0; doN2pc = 1; layer = dummylayer;
    layer = 13; doP3 = 0;
elseif strcmp(vERP, 'Layer')
    doP3 = 0; doN2pc = 0; layer = layer; % this line doesn't do anything (bc we stoped using doP3 & doN2pc, really)
end

% check if in correct path..
if ~contains(varpath, name)
    msgbox('MISMATCH BETWEEN NAME & VARPATH! - CANCELLING')
    return
end
% check if TwoRespFeatures corresponds to path
switch TwoRespFeatures
    case 0
        if ~contains(varpath, 'Srivas')
            msgbox('MISMATCH BETWEEN TwoRespFeats & VARPATH! - CANCELLING')
            return
        end
    case 1
        if ~contains(varpath, 'Alon')
            msgbox('MISMATCH BETWEEN TwoRespFeats & VARPATH! - CANCELLING')
            return
        end
end

% load the variables we need
layname = getLayerName(layer);

% load stuff & assign to "ActArrayFull"
switch VM
    case 0
        load([varpath 'ActArrayLayer_' layname '.mat'])
        ActArrayFull = ActArrayLayer;
        clear ActArrayLayer
    case 1
        load([varpath 'VMArrayLayer_' layname '.mat'])
        ActArrayFull = VMArrayLayer;
        clear VMArrayLayer
    otherwise
        msgbox('NO SUPPORT FOR INPUT CHANNELS YET! CANCELLING')
        return
end

% load the vN2pc to indicate mean blasterfiring
if exist([varpath 'ActArrayLayer_Blaster Out.mat'],'file')
    load([varpath 'ActArrayLayer_Blaster Out.mat'])
    BlasterOutFull = ActArrayLayer;
    clear ActArrayLayer
elseif exist([varpath 'AvActArrayLayer_Blaster Out.mat'],'file')
    load([varpath 'AvActArrayLayer_Blaster Out.mat'])
    BlasterOutFull = AvActArrayLayer;
    clear AvActArrayLayer
else
    msgbox('BLASTER OUT MISSING IN VARPATH - RUN TRANSFERFUNC ON AV-NAME.MATFILE & PUT IT IN');
    return
end


%%      FIND OUT TRIALS WE ARE KEEPING & THEIR CONDITION
%MAHAN: Extract epochs we want to keep & assign their conditions.
%   (this uses name_responly.mat that transfer_modelmat2ArrayLayer also generates)
[marker, ~, keepepochs] = extract_responses(name, varpath, TwoRespFeatures);

% throw out misses
ActArray = ActArrayFull(keepepochs,:,:);
if ndims(BlasterOutFull) > 2 % this is because we sometimes load BlasterOutFull from AvActArray and sometimes from ActArray
    BlasterOut = BlasterOutFull(keepepochs,:,1);
else
    BlasterOut = BlasterOutFull(keepepochs,:);
end

%%  ACTIVATION TRACES - SRIVAS & ALON VERSION DIFFER IN NUMBER OF CONDITIONS!
% Find number of conditions in this dataset to know how many plots we need
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
iscond = unique(marker);
num_conds = length(iscond);

%%                          PLOT IT
plotit(VM, name, TwoRespFeatures, num_conds, marker, iscond, ActArray, BlasterOut, layer, doP3, saveplots, zoomXAx, plotpath)
end

%%      FUNCTION plotit - does the plotting
function plotit(VM, name, TwoRespFeatures, num_conds, marker, iscond, ActArray, BlasterOut, layer, doP3, saveplots, zoomXAx, plotpath)
for s = 1:num_conds
    % initialize figure
    figure;                 % plot a separate figure for each condition
    %     set(gcf, 'Position', [636         961        1575         377])
    set(gcf,'Position', [1          41        1366         651]) % laptop
    % extract only those act-traces that correspond to the response-condition of this loop & get their average as av_acts
    this_indices = []; this_acttrace = []; av_acts = [];
    this_indices = strcmp(marker, iscond{s});
    this_acttrace = ActArray(this_indices, :, :); % note - structure of this is trials x timepoints x neurons
    av_acts = squeeze(mean(this_acttrace,1)); % structure: timepoints x neurons
    % find ylimit min & max (bc this can plot VMs, ylimmin might be < 0)
    ylimmax = max(max(av_acts));
    ylimmin = min(min(av_acts));
    % loop over neurons
    for i = 1:size(this_acttrace, 3)
        % only plot it if its not all zeros (which is the case often because
        % we have many layers with 100 'neurons' activity, even though that
        % layer had less neurons (e.g. only 1 for blaster-output)
        p = [];
        if sum(av_acts(:, i)) ~= 0
            hold on
            p = plot(av_acts(:, i)); % plot the av_act of this neuron
            hold off
            p.LineWidth = 2.5; % make the line thick at first (if it's a distractor, we make it narrower in switch below)
            cur_act = squeeze(this_acttrace(:, :, i));
            % set colour of lines according to neuron & plot the line & SE around it if not a distractor
            if TwoRespFeatures == 0
                hold on
                % SRIVAS
                switch i
                    case 18
                        linecolour = rgb('light green');
                        plotSEtoo(cur_act, 0, linecolour, 0, 0) 
                    case 19
                        linecolour = 'g';
                        plotSEtoo(cur_act, 0, linecolour, 0, 0) 
                    case 1
                        linecolour = 'k';
                        plotSEtoo(cur_act, 0, linecolour, 0, 0) 
                    case 20
                        linecolour = 'r';
                        plotSEtoo(cur_act, 0, linecolour, 0, 0) 
                    case 21
                        linecolour = rgb('rose');
                        plotSEtoo(cur_act, 0, linecolour, 0, 0) 
                    otherwise
                        linecolour = rgb('gold');
                        p.LineWidth = 0.5;
                end
                p.Color = linecolour;
                p.LineStyle = '-';
                hold off
            elseif TwoRespFeatures == 1
                hold on
                % ALON
                switch i
                    case 1  % targetpositions: 1 = cor, 20 = +1
                        linecolour = 'k';
                        plotSEtoo(cur_act, 0, linecolour, 0, 0) 
                    case 20
                        linecolour = 'r';
                        plotSEtoo(cur_act, 0, linecolour, 0, 0) 
                    case 19
                        if ismember(layer, [3 10 17 20]) % if we are looking at item layer or its offnode, colour the -1, too
                            linecolour = 'g';
                            plotSEtoo(cur_act, 0, linecolour, 0, 0) 
                        else
                            p.Color = rgb('gold');
                            p.LineWidth = 0.5;
                        end
                    otherwise
                        p.Color = rgb('gold');
                        p.LineWidth = 0.5;
                end
                p.Color = linecolour;
                p.LineStyle = '-';
                hold off
            end
        end
    end
    
    
    
    % axes-stuff & blasterfiring latencies afterwards
    ax = gca;
    ax.FontSize = 21;
    % x- & y-lims
    if zoomXAx
        if ismember(layer, [1 2 15 16])
            xlim([100 400]) % for input & masking layers
        else
            xlim([200 400])
        end
    end
    if ~isequal(ylimmin,ylimmax)
        ylim([ylimmin ylimmax])
    end
    % x- & y-labels
    switch VM
        case 0
            ax.YLabel.String = 'Postsynaptic Activation';
        case 1
            ax.YLabel.String = 'Membrane Potential';
        case 2
            ax.YLabel.String = 'Inhibitory Input';
        case 3
            ax.YLabel.String = 'Leak Input';
        case 4
            ax.YLabel.String = 'Excitatory Input';
    end
    ax.XLabel.String = 'Time (ms-equivalent)';
    ax.YLabel.FontSize = 20; ax.XLabel.FontSize = 20;
    % fix x-axis to show time in ms-equivalents, not timesteps
    for x = 1:length(ax.XTick)
        if str2double(ax.XTickLabels{x}) > length(av_acts)
            ax.XTickLabels{x} = '';
        else
            this_xticklabel = transfertime_steps2ms(ax.XTick(x));
            ax.XTickLabels{x} = this_xticklabel;
        end
    end
    % blaster
    blast = [];
    % set colour of all lines of this condition (use this if-bit for title stuff later on, too)
    if strcmp(iscond{s}, 'pre2')
        linecolour = rgb('light green');
        condtitle = '-2 INTs';
    elseif strcmp(iscond{s}, 'pre1')
        linecolour = 'g';
        condtitle = '-1 INTs';
    elseif strcmp(iscond{s}, 'correct')
        linecolour = 'k';
        condtitle = 'CORs';
    elseif strcmp(iscond{s}, 'post1')
        linecolour = 'r';
        condtitle = '+1 INTs';
    elseif strcmp(iscond{s}, 'post2')
        linecolour = rgb('rose');
        condtitle = '+2 INTs';
    end
    this_indices = strcmp(marker, iscond{s});
    this_blaster = BlasterOut(this_indices, :); % extract blaster of this condition's trials
    this_vN2pc = mean(this_blaster,1); % average across all trials
    this_blasterfire = blasterfiring(this_vN2pc); % define blasterfiring as 50% AUC under 'this' vN2pc
    if ~ismember(layer,[13 19]) % this breaks for response tfl shutoff, but it's zero for expostsynact anyways...
        blast = vline2(this_blasterfire, 'color', linecolour);
        blast.LineWidth = 4;
        blast.LineStyle = ':';
    end
    blastlegend = transfertime_steps2ms(this_blasterfire);
%     l = legend([num2str(blastlegend) ' ms']) % include numerical blast-val in legend;
    dim = [0.7041 0.8530 0.0930 0.0553];    
    l = annotation('textbox', dim, 'String', ['Blast at: ' num2str(blastlegend) ' ms'], 'FitBoxToText', 'on');
    l.FontSize = 18.9;
    hold off
    
    % super-title
    hold on
    LayerName = getLayerName(layer);
    if doP3
        [~, h1] = suplabel(['vP3s | ' condtitle ' | Trialnum: ' num2str(sum(this_indices))], 't');
    else
        [~, h1] = suplabel([LayerName ' | ' condtitle ' | Trialnum: ' num2str(sum(this_indices))], 't');
    end
    h1.FontSize = 22;
    hold off
    
    % save it
    if saveplots
        % save it (might need to create the dir first)
        if ~exist(plotpath, 'dir')
            mkdir(plotpath)
        end
        % Srivas or Alon
        if TwoRespFeatures == 0
            AnalysisName = 'Srivas ';
        else
            AnalysisName = 'Alon ';
        end
        switch VM
            case 0
                TraceName = 'Act. ';
            case 1
                TraceName = 'VM ';
            case 2
                TraceName = 'Inhib. ';
            case 3
                TraceName = 'Leak ';
            case 4
                TraceName = 'Excite ';
        end
        if doP3
            P3Name = 'vP3s ';
        else
            P3Name = ' ';
        end
        plotfile = [AnalysisName condtitle ' Neuron-' TraceName 'for ' name '.jpg'];
        saveas(gcf, [plotpath plotfile]);
    end
end
end