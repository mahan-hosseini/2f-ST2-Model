%%  Plot comparison plots of vERPs between model-delay configurations
%   ==> Writing this for key9 vs key24 [i.e. replicating Alon &
%       Martin's Exp 2 & Exp 1 respectively]
%   ==> One could rather easily change this function to dynamically work
%       with different & more than 2 delayconfigs, but I don't expect to need
%       that so I'll just write it for key9/key24 comparisons
%   ==> Update: I of course had to use this for different delay-configs (13 & 36tps) because I changed the way GammaNoise was implemented to also have shape be modulated by the extent of keydelay
%	Again being lazy, I just left all the var-names as is and changed the Plottitles (lines are somewhere in the end)
%	If at some point this needs to be used with another set of delaycfgs, you can just leave everything as is and change the name lines (just make sure that you are naming the correct subplot the correct thing)

function MR_plot_AvAct_Comparisons(vERP, ActArray_9, ActArray_24, BlasterOut_9, BlasterOut_24, marker_9, marker_24, smooth, layer, plotpath, saveplots, TwoRespFeatures)
%% PREPARATION
% check input
if TwoRespFeatures == 0
    msgbox('Currently only supporting Alon model-comparison plots - cancelling!')
    return
end

% flag of vERPs we are plotting
dummylayer = 13; % dummy layer used if we are not interested in a specific layer's act, but vERP instead
if strcmp(vERP, 'P3')
    doP3 = 1; doN2pc = 0; layer = dummylayer;
elseif strcmp(vERP, 'N2pc')
    doP3 = 0; doN2pc = 1; layer = dummylayer;
elseif strcmp(vERP, 'Layer')
    doP3 = 0; doN2pc = 0; layer = layer;
end

% conditions stuff to loop in func below
conditions = {'correct', 'post1'};
iscond = conditions;
% iscond = cell(1); % some remnants of old plotAvActs function
% for c = 1:length(conditions)
%     if sum(strcmp(marker, conditions{c})) >= 1 % if we have this condition in at least one trial
%         if isempty(iscond{end})
%             iscond{end} = conditions{c};
%         else
%             iscond{end+1} = conditions{c};
%         end
%     end
% end
num_conds = length(iscond);

% plot it
plotit(ActArray_9, ActArray_24, BlasterOut_9, BlasterOut_24, marker_9, marker_24, num_conds, smooth, iscond, layer, saveplots, plotpath, doP3, doN2pc, TwoRespFeatures)
end

%%      FUNCTION plotit - does the plotting
function plotit(ActArray_9, ActArray_24, BlasterOut_9, BlasterOut_24, marker_9, marker_24, num_conds, smooth, iscond, layer, saveplots, plotpath, doP3, doN2pc, TwoRespFeatures)
f = figure;
% set(f, 'Position', [636         961        1575         377])
set(f, 'Position', [1367        -215        1280         905]) % laptop
ylimmax = -inf; ylimmin = inf;
% loop over conditions (cor & int)
for c = 1:num_conds
    % loop over experiments (or delayconfigs)
    for e = 1:2
        subplot(2,1,e)
        ax(e) = gca;
        switch e
            case 1
                this_indices = strcmp(marker_9, iscond{c});
                cur_act = ActArray_9(this_indices, :); % note - structure of this is trials x timepoints
            case 2
                this_indices = strcmp(marker_24, iscond{c});
                cur_act = ActArray_24(this_indices, :);
        end
        av_act = mean(cur_act,1);
        hold on
        p = [];
        % smooth vERPs with derivative
        if strcmp(smooth, 'yes') % if u wanna smooth, do it
            [av_act] = smooth_vERPs(av_act, doN2pc, doP3);
        end
        % update ylims (don't include very beginning for this because it
        % will lead to ugly ylims for plotting VMs [we are not interested in that timeframe for AvActs anyways])
        if max(av_act(100:end)) > ylimmax
            ylimmax = max(av_act(100:end));
        end
        if min(av_act(100:end)) < ylimmin
            ylimmin = min(av_act(100:end));
        end
        p = plot(av_act);
        if strcmp(iscond{c}, 'correct')
            p.Color = 'k';
        elseif strcmp(iscond{c}, 'post1')
            p.Color = 'r';
        end
        % previously would use flag-var plotSE here, but got rid of it so we always plotsSE, too
        plotSEtoo(cur_act, smooth, p.Color, doN2pc, doP3)
        p.LineWidth = 2;
        hold off
    end
end

% set x & ylims
for e = 1:2
    if doN2pc
%         ax(e).XLim = [200 340];
        ax(e).XLim = [200 400];
    else
        ax(e).XLim = [200 400];
    end
    if ylimmin < 0 % need this for the +/-0.15*ylimmin bit
        ax(e).YLim = [ylimmin+0.15*ylimmin ylimmax+0.15*ylimmax]; % some room @ top & bottom
    else
        ax(e).YLim = [ylimmin-0.15*ylimmin ylimmax+0.15*ylimmax]; % some room @ top & bottom
    end
    hold off
end

% Blaster
% loop over conditions (cor & int)
all_blasterfires = cell(num_conds,2); % 2 cols bc 2 exps
for c = 1:num_conds
    % loop over experiments (or delaycfgs)
    for e = 1:2
        subplot(2,1,e)
        switch e
            case 1
                this_indices = strcmp(marker_9, iscond{c});
                this_blaster = squeeze(BlasterOut_9(this_indices, :)); % extract blaster of this condition's trials
            case 2
                this_indices = strcmp(marker_24, iscond{c});
                this_blaster = squeeze(BlasterOut_24(this_indices, :));
        end
        hold on
        if strcmp(iscond{c}, 'correct')
            blast_col = 'k';
        elseif strcmp(iscond{c}, 'post1')
            blast_col = 'r';
        end
        % Indicate blaster firing timing, too, always, even in N2pc, why not
        this_vN2pc = mean(this_blaster,1); % average across all trials
        all_blasterfires{c,e} = blasterfiring(this_vN2pc); % define blasterfiring as 50% AUC under 'this' vN2pc
        blast = vline2(all_blasterfires{c,e}, 'color', blast_col);
        blast.LineWidth = 2.5;
        blast.LineStyle = ':';
        hold off
    end
end


hold on
% fix ax stuff 
for e = 1:2
    axes(ax(e))
    % 0) Add a legend informing about average blasterfiring latencies in ms
    %   ==> Note - no need for sanity checks here because num_conds is
    %       always 2 here [it's hardcoded above]
    for c = 1:num_conds
        if ~isempty(all_blasterfires{c,e})
            all_blasterfires{c,e} = transfertime_steps2ms(all_blasterfires{c,e});
            all_blasterfires{c,e} = [num2str(all_blasterfires{c,e}) ' ms'];
        end
    end
    blasterstring = string(all_blasterfires(:,e));
    l = legend(blasterstring);
    title(l, 'Blasterfiring')
    ax(e).FontSize = 18; 
    % 1) show time in ms-equivalents
    for x = 1:length(ax(e).XTick) 
        if str2double(ax(e).XTickLabels{x}) > size(ActArray_9, 2) %if xticks are longer than num of timepoints
            ax(e).XTickLabels{x} = '';
        else
            this_xticklabel = transfertime_steps2ms(ax(e).XTick(x));
            ax(e).XTickLabels{x} = this_xticklabel;
        end
    end
    % 2) add some lines @ yticks to facilitate visual amplitude comparisons
    subplot(2,1,e)
    for h = 1:length(ax(e).YTick) 
        thisline = hline(ax(e).YTick(h));
        thisline.Color = rgb('jungle green');
        thisline.LineStyle = ':';
    end
    % 3) titles 
    %   NOTE! - MultRuns_Final2 is the finalfinal version of the model in
    %       which the shape parameter of GammaNoise distributions is modulated
    %       by tau(k) too. In these we have different values for tau(k) to
    %       replicate the experiments of Alon & Martin. But instead of
    %       re-naming all the variables and stuff we just keep the logic the
    %       same and re-name only the plot-titles!
    switch e
        case 1                      
            if contains(plotpath, 'MultRuns_Final2')
                ax(e).Title.String = '13tp Key Delay (Experiment #2)';
            else
                ax(e).Title.String = '9tp Key Delay (Experiment #2)'; %9tps used in Model without shape modulations
            end
            ax(e).Title.FontSize = 20;
        case 2
            if contains(plotpath, 'MultRuns_Final2')
                ax(e).Title.String = '36tp Key Delay (Experiment #1)'; 
            else
                ax(e).Title.String = '24tp Key Delay (Experiment #1)'; %24tps used in Model without shape modulations
            end
            ax(e).Title.FontSize = 20;
    end
end
hold off

% indicate if smoothed or not
if strcmp(smooth, 'yes')
    smoothstr = '';
else
    smoothstr = ' (unsmoothed) ';
end

% super-title
LayerName = getLayerName(layer);
if doP3
    [~, h1] = suplabel(['vP3s' smoothstr], 't', [.08 .14 .84 .84]);
elseif doN2pc
    [~, h1] = suplabel(['vN2pcs' smoothstr], 't', [.08 .14 .84 .84]);
else
    [~, h1] = suplabel(['Av. Act. Levels at ' LayerName ' Layer' smoothstr], 't', [.08 .14 .84 .84]);
end
h1.FontSize = 23;

% super-x/ylabels
[~, h2] = suplabel('Time (ms-equivalent)', 'x', [.08 .095 .84 .84]);
[~, h3] = suplabel('Postsynaptic Activation', 'y', [.11 .08 .84 .84]);
h2.FontSize = 20; h3.FontSize = h2.FontSize;
hold off

% save it
if saveplots
    % save it (might need to create the dir first)
    if ~exist(plotpath, 'dir')
        mkdir(plotpath)
    end
    if doP3
        plotfile = ['Key Delay Comparison vP3s' smoothstr '.jpg'];
    elseif doN2pc
        plotfile = ['Key Delay Comparison vN2pcs' smoothstr '.jpg'];
    else
        plotfile = ['Key Delay Comparison Act. levels' smoothstr '.jpg'];
    end
    saveas(f, [plotpath plotfile]);
end
end
