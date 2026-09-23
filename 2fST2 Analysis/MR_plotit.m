%%      FUNCTION Multiple Runs (MR) plotit - does the plotting
function MR_plotit(VM, num_conds, smooth, Srivas3Trace, marker, iscond, ActArray, layer, saveplots, BlasterOut, thisplotpath, name, doP3, doN2pc, plotSE, zoomXAx, TwoRespFeatures)
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
            % smooth
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
            % smooth
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
    all_blasterfires = cell(num_conds,1);
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
            all_blasterfires{c} = blasterfiring(this_vERP); % define blasterfiring as 50% AUC under 'this' vN2pc
            blast = vline2(all_blasterfires{c}, 'color', blast_col);
            blast.LineWidth = 2.5;
            blast.LineStyle = ':';
            hold off
        end
    end
elseif Srivas3Trace == 1
    num_conds = 3;
    all_blasterfires = cell(num_conds,1);
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
            all_blasterfires{c} = blasterfiring(this_vERP); % define blasterfiring as 50% AUC under 'this' vN2pc
            blast = vline2(all_blasterfires{c}, 'color', blast_col);
            blast.LineWidth = 2.5;
            blast.LineStyle = ':';
            hold off
        end
    end
end

hold on

% Add a legend informing about average blasterfiring latencies in ms
for c = 1:num_conds
    if ~isempty(all_blasterfires{c})
        all_blasterfires{c} = transfertime_steps2ms(all_blasterfires{c});
        all_blasterfires{c} = [num2str(all_blasterfires{c}) ' ms'];
    end
end
% important: this is to make sure that we don't have empty cells (stuff we
% looped over in the plotting loop that was not plotted (e.g., -2 if
% Srivas3Trace = 0 or pretargets if plotting Alon)
all_blasterfires = all_blasterfires(~cellfun('isempty',all_blasterfires)); 
blasterstring = string(all_blasterfires);
l = legend(blasterstring);
title(l, 'Blasterfiring')

% Axis-fontsize & plot ms-equivalents
ax = gca;
ax.FontSize = 18;
for x = 1:length(ax.XTick)
    this_xticklabel = transfertime_steps2ms(ax.XTick(x));
    ax.XTickLabels{x} = this_xticklabel;
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
