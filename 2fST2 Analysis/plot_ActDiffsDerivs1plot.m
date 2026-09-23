%% Plot act-diffs superimposed on act-traces or (old) derivative-diffs with blasterifirng & AUC of diff-curve & zero in a textbox
%   Note - works only on all_neurons & all_blasters vars extracted using
%   extract_1NeurDiffDelays.m






%                               IMPORTANT
%   IF YOU LOOK AT THIS AFTER SOME TIME, REMEMBER THAT WE DECIDED TO
%   ***NOT*** ANALYSE DERIVATIVES (i.e., pointwise changes of timeseries
%   over time), BUT TO JUST SUBTRACT THE POSTSYN ACTIVATION TIME SERIES
%   FROM ONE ANOTHER!
%   ==> THEREFORE, EVEN THOUGH WE DO COMPUTE WHAT WE CALL "DERIVATIVES"
%       BEFORE PLOTTING STUFF, THESE ARE NEVER USED FOR PLOTTING ANYTHING!
%   ==> INSTEAD, WE JUST COMPUTE TARGET - +1 & PLOT THAT AS THE GREEN LINE!









function plot_ActDiffsDerivs1plot(VM, layer, keydelays, varpath, plotpath, saveplots)

%% Preparation
% Some Name stuff
if VM == 0
    ActName = 'Act';
elseif VM == 1
    ActName = 'VM';
end

% sanity checks
if ~ismember(layer,[13, 17,18])
    msgbox('FUNC WORKS ONLY FOR RESP ITEM, BLASTOUT & TFL AT THE MOMENT - CANCELLING!')
    return
end
if ~isequal(keydelays, 0:6:24)
    msgbox('ARE YOU SURE YOU CHANGED KEYDELAYS?! - WAS 0:6:24 - CANCELLING!')
    return
end

LayerName = getLayerName(layer);

DelayNames = cell(length(keydelays),1);
for i = 1:length(keydelays)
    DelayNames{i} = num2str(keydelays(i));
end

% Initialize big structures we will use for this
FullNeurons = struct('target', struct('correct', [], 'post1', [], 'total', []), 'plusone', struct('correct', [], 'post1', [], 'total', []));
FullBlasters = struct('target', struct('correct', [], 'post1', [], 'total', []), 'plusone', struct('correct', [], 'post1', [], 'total', []));

% Load everything of this layer & act, one at a time
% target - correct (black solid)
load([varpath ActName ' of Target - Unit at ' LayerName ' for correct Responses.mat'], 'all_neurons', 'all_blasters')
FullNeurons.target.correct = all_neurons;
FullBlasters.target.correct = all_blasters;
clear all_neurons all_blasters

% +1 unit - correct (black dashed)
load([varpath ActName ' of +1 - Unit at ' LayerName ' for correct Responses.mat'], 'all_neurons', 'all_blasters')
FullNeurons.plusone.correct = all_neurons;
FullBlasters.plusone.correct = all_blasters;
clear all_neurons all_blasters

% target - post1 (red solid)
load([varpath ActName ' of Target - Unit at ' LayerName ' for post1 Responses.mat'], 'all_neurons', 'all_blasters')
FullNeurons.target.post1 = all_neurons;
FullBlasters.target.post1 = all_blasters;
clear all_neurons all_blasters

% +1 unit - post1 (red dashed)
load([varpath ActName ' of +1 - Unit at ' LayerName ' for post1 Responses.mat'], 'all_neurons', 'all_blasters')
FullNeurons.plusone.post1 = all_neurons;
FullBlasters.plusone.post1 = all_blasters;
clear all_neurons all_blasters

% target & plusone - all trials (i.e. responses)
for d = 1:length(keydelays)
    FullNeurons.target.total{d} = cat(1,FullNeurons.target.correct{d}, FullNeurons.target.post1{d});
    FullBlasters.target.total{d} = cat(1,FullBlasters.target.correct{d}, FullBlasters.target.post1{d});
    FullNeurons.plusone.total{d} = cat(1,FullNeurons.plusone.correct{d}, FullNeurons.plusone.post1{d});
    FullBlasters.plusone.total{d} = cat(1,FullBlasters.plusone.correct{d}, FullBlasters.plusone.post1{d});
    % sanity check: blasters of plusone & target have to be equal for total
    if ~isequal(FullBlasters.target.total{d}, FullBlasters.plusone.total{d})
        msgbox('Something is very wrong with FullBlasters, cancelling function!')
        return
    end
end



%% Compute the derivatives & BlasterLatencies
% initialize structs we use for plotting
Derivatives = struct('targ_correct', [], 'plusone_correct',  [], 'targ_post1',  [], 'plusone_post1', [], 'targ_total',  [], 'plusone_total', []);
BlastLats = struct('correct', [], 'post1',  [], 'total',  []);

for d = 1:length(keydelays)
    % target - correct (black solid)
    Derivatives(d).targ_correct = diff(mean(FullNeurons.target.correct{d},1));
    % +1 unit - correct (black dashed)
    Derivatives(d).plusone_correct = diff(mean(FullNeurons.plusone.correct{d},1));
    % target - post1 (red solid)
    Derivatives(d).targ_post1 = diff(mean(FullNeurons.target.post1{d},1));
    % +1 unit - post1(red dashed)
    Derivatives(d).plusone_post1 = diff(mean(FullNeurons.plusone.post1{d},1));
    % target & plusone - alltrials & 1 blasterlatency
    Derivatives(d).targ_total = diff(mean(FullNeurons.target.total{d},1));
    Derivatives(d).plusone_total = diff(mean(FullNeurons.plusone.total{d},1));
    % blaster latencies (irrespective of unit, just response!)
    BlastLats(d).correct = blasterfiring(mean(FullBlasters.target.correct{d},1));
    BlastLats(d).post1 = blasterfiring(mean(FullBlasters.target.post1{d},1));
    BlastLats(d).total = blasterfiring(mean(FullBlasters.plusone.total{d},1));
    % quick sanity check
    if ~isequal(FullBlasters.target.correct, FullBlasters.plusone.correct)
        msgbox('Something is very wrong with FullBlasters, cancelling function!')
        return
    end
end

%% Plot it
plotit(FullNeurons, BlastLats, layer, ActName, LayerName, DelayNames, plotpath, saveplots)

% plotit_derivdiffs(FullNeurons, Derivatives, BlastLats, layer, ActName, LayerName, DelayNames, plotpath, saveplots)

% plotit_old(Derivatives, BlastLats, layer, ActName, LayerName, DelayNames, plotpath, saveplots)

end

%% FUNCTION - plotit - plots only total diffs of total, but adds 4-traces of acts as plotActs1plot does
function plotit(FullNeurons, BlastLats, layer, ActName, LayerName, DelayNames, plotpath, saveplots)

% extract differences across all delays before plotting them, especially to
% find ylims first, because we have multiple figures, have to know them
% before plotting       
%   ==> No need for this anymore because we will use linkaxes
% ylimmin_l = inf; ylimmax_l = -inf;
% ylimmin_r = inf; ylimmax_r = -inf;

% some settings we need so we can plot Acts & VMs with this func
scalefac = 1; % if we don't want to scale
if strcmp(ActName, 'Act')
    VM = 0;
    if layer ~= 13
        scalefac = 10; % auc scale factor (act-diff-vals are tiny)
    end
elseif strcmp(ActName, 'VM')
    VM = 1;
    scalefac = 5;
end

% xlims
if VM == 0
    if layer == 18
        this_xlims = [200 350];
    else
        this_xlims = [150 400];
    end
else
    if layer == 13
        this_xlims = [200 350];
    else
        this_xlims = [150 450];
    end
end

% initialize diff & blaster
diff_total = zeros(length(DelayNames), size(FullNeurons.target.correct{1},2));
blast_cor = zeros(length(DelayNames),1);
blast_int = zeros(length(DelayNames),1);

% Get Differences & Blaster
for dd = 1:length(DelayNames)
    diff_total(dd,:) = mean(FullNeurons.target.total{dd},1) - mean(FullNeurons.plusone.total{dd},1);
    blast_cor(dd) = BlastLats(dd).correct;
    blast_int(dd) = BlastLats(dd).post1;
end

% go
for dd = 1:length(DelayNames)
    f(dd) = figure;
    set(gcf, 'Position', [1366          19        1289         492]) %laptop
    colororder([rgb('rust'); rgb('olive')]);
    
    % Extract current delay
    ThisDelay = DelayNames{dd};
    
    % plot it - left axis, activations
    yyaxis left
    for s = 1:4
        this_act = [];
        hold on
        switch s
            case 1
                this_act = FullNeurons.target.correct{dd};
                color = 'k';
                line = '-';
            case 2
                this_act = FullNeurons.target.post1{dd};
                color = 'r';
                line = '-';
            case 3
                this_act = FullNeurons.plusone.correct{dd};
                color = 'k';
                line = '--';
            case 4
                this_act = FullNeurons.plusone.post1{dd};
                color = 'r';
                line = '--';
        end
        p(s) = plot(mean(this_act,1)); % plot only mean-act across trials
        hold off
        hold on
        p(s).Color = color;
%         p(s).Color(4) = 0.5; % make acts/VMs transparent behind Diffs
        p(s).LineStyle = line;
        p(s).LineWidth = 2.5; 
        if layer == 13 && ismember(s, [3 4]) % only have 1 neuron if vN2pc plotted
            p(s).Visible = 0;
        end
        hold off
    end
    
    % plot it - right axis, difference
    hold on
    this_diff = diff_total(dd,:);     % assign which diff we are doing
    this_diff = this_diff * scalefac;
    yyaxis right
    hold on
    p(5) = plot(this_diff);
    zero = hline(0);
    hold off

    % fix style
    hold on
    p(5).LineWidth = 3.5;
    p(5).Color = rgb('olive');
    zero.Color = rgb('olive');
    zero.LineWidth = 1.5;
    zero.LineStyle = '--';
    hold off
    
    % auc as sum of absolute values, i.e. area between curve & zero
    this_auc = sum(abs(this_diff)); 
    
    % axes
    ax = gca;
    ax.FontSize = 15;
    ax.XLim = this_xlims;           % XLim
    for x = 1:length(ax.XTick)
        this_xticklabel = transfertime_steps2ms(ax.XTick(x));
        ax.XTickLabels{x} = this_xticklabel;
    end                             % Title
%     delayinms = str2num(ThisDelay) * 5;
    ax.Title.String = [ActName ' - Traces & Difference-Wave of ' char([0xD835 0xDF0F]) 'k = ' num2str(ThisDelay) ' at ' LayerName]; % delay in time-steps
    ax.Title.FontSize = 20;         % AUC Box
    annotation('textbox', [.75 .7 .2 .1], 'String', ['AUC = ' num2str(floor(this_auc))], 'FontSize', 20, 'FitBoxToText', 'on') 
    yyaxis left                     % Labels
    switch VM
        case 0
            ylabel('Postsyn. Activations', 'FontSize', 20, 'Color', rgb('rust'))
            if layer == 18
                ax.YLim = [0 0.14]; %resp tfl acts are the most important, make sure their ylims are correct.
            end
        case 1
            ylabel('Membrane Potentials', 'FontSize', 20, 'Color', rgb('rust'))
    end
    yyaxis right
    if VM == 0 && layer == 18
        ax.YLim = [-.2 .8];
    end
    ylabel({'Target-unit - +1-unit Difference', ['Scaled by ' num2str(scalefac)]}, 'FontSize', 20, 'Color', rgb('olive'))
    xlabel('Time (ms-equivalent)', 'FontSize', 20)
    
    % after fixing axes-stuff: if respTFL & VMs, indicate the threshold to the binders using hline
    if VM && layer == 18
        hold on
        yyaxis left
        thresh2bind = hline(0.35, 'b');
        thresh2bind.LineStyle = '-.';
        thresh2bind.LineWidth = 1.5;
        thresh2bind.Color(4) = 0.5;
    end
end
    % save ylims        ( no need for this anymore, because of linkaxes below)
%     this_ylimmin_l = min([mean(FullNeurons.target.correct{dd},1), ...
%         mean(FullNeurons.target.post1{dd},1), ...
%         mean(FullNeurons.plusone.correct{dd},1), ...
%         mean(FullNeurons.plusone.post1{dd},1)]);
%     if this_ylimmin_l < ylimmin_l
%         ylimmin_l = this_ylimmin_l;
%     end
%     this_ylimmax_l = max([mean(FullNeurons.target.correct{dd},1), ...
%         mean(FullNeurons.target.post1{dd},1), ...
%         mean(FullNeurons.plusone.correct{dd},1), ...
%         mean(FullNeurons.plusone.post1{dd},1)]);
%     if this_ylimmax_l > ylimmax_l
%         ylimmax_l = this_ylimmax_l;
%     end
%     this_ylimmin_r = min(this_diff);
%     if this_ylimmin_r < ylimmin_r
%         ylimmin_r = this_ylimmin_r;
%     end
%     this_ylimmax_r = max(this_diff);
%     if this_ylimmax_r > ylimmax_r
%         ylimmax_r = this_ylimmax_r;
%     end
% end                   -- old forloop end!

% link axes & set global limits
allaxes = [];
for dd = 1:length(f)
    allaxes = [allaxes f(dd).Children];
end
linkaxes(allaxes, 'xy') % links axes-limits of everything

% plot blasters after finalizing axes
for dd = 1:length(f)
    figure(f(dd))
    if layer ~= 13
        hold on
        blast1 = vline2(blast_cor(dd), 'color', 'k');
        blast1.LineWidth = 1.5;
        blast1.LineStyle = ':';
%         blast1.Color = [blast1.Color 0.5]; % make it transparent
        blast2 = vline2(blast_int(dd), 'color', 'r');
        blast2.LineWidth = blast1.LineWidth;
        blast2.LineStyle = blast1.LineStyle;
%         blast2.Color = [blast2.Color 0.5];
        hold off
    end
end

% save figures
for dd = 1:length(DelayNames)
%     ax = f(dd).Children;
    if saveplots
        if ~exist(plotpath, 'dir')
            mkdir(plotpath)
        end
        ThisDelay = DelayNames{dd};
        saveas(f(dd), [plotpath ActName ' Traces & Diff of ' ThisDelay ' tp Key Delay at ' LayerName '.jpg'])
    end
end

end

% %% FUNCTION - plotit - plots only total deriv-diffs of total, but adds 4-traces of acts as plotActs1plot does
% function plotit_derivdiffs(FullNeurons, Derivatives, BlastLats, layer, ActName, LayerName, DelayNames, plotpath, saveplots)
% 
% % extract differences across all delays before plotting them, especially to
% % find ylims first, because we have multiple figures, have to know them
% % before plotting       
% %   ==> No need for this anymore because we will use linkaxes
% % ylimmin_l = inf; ylimmax_l = -inf;
% % ylimmin_r = inf; ylimmax_r = -inf;
% 
% % some settings we need so we can plot Acts & VMs with this func
% scalefac = 1; % if we don't want to scale
% if strcmp(ActName, 'Act')
%     VM = 0;
%     if layer ~= 13
%         scalefac = 10^3; % auc scale factor (deriv-diff-vals are tiny)
%     end
% elseif strcmp(ActName, 'VM')
%     VM = 1;
%     scalefac = 10^2;
% end
% 
% % xlims
% if VM == 0
%     if layer == 18
%         this_xlims = [200 350];
%     else
%         this_xlims = [150 400];
%     end
% else
%     if layer == 13
%         this_xlims = [200 350];
%     else
%         this_xlims = [150 450];
%     end
% end
% 
% % initialize diffs, too
% diff_cor = zeros(length(DelayNames), size(Derivatives(1).targ_correct,2));
% diff_int = zeros(length(DelayNames), size(Derivatives(1).targ_correct,2));
% diff_total = zeros(length(DelayNames), size(Derivatives(1).targ_correct,2));
% blast_cor = zeros(length(DelayNames),1);
% blast_int = zeros(length(DelayNames),1);
% blast_total= zeros(length(DelayNames),1);
% 
% % Get Differences
% for dd = 1:length(DelayNames)
%     diff_cor(dd,:) = Derivatives(dd).targ_correct - Derivatives(dd).plusone_correct;
%     diff_int(dd,:) = Derivatives(dd).targ_post1 - Derivatives(dd).plusone_post1;
%     diff_total(dd,:) = Derivatives(dd).targ_total - Derivatives(dd).plusone_total;
%     blast_cor(dd) = BlastLats(dd).correct;
%     blast_int(dd) = BlastLats(dd).post1;
%     blast_total(dd) = BlastLats(dd).total;
% end
% 
% for dd = 1:length(DelayNames)
%     f(dd) = figure;
%     set(gcf, 'Position', [1366          19        1289         492]) %laptop
%     colororder([rgb('rust'); rgb('olive')]);
%     
%     % Extract current delay
%     ThisDelay = DelayNames{dd};
%     
%     % plot it - left axis, activations
%     yyaxis left
%     for s = 1:4
%         this_act = [];
%         hold on
%         switch s
%             case 1
%                 this_act = FullNeurons.target.correct{dd};
%                 color = 'k';
%                 line = '-';
%             case 2
%                 this_act = FullNeurons.target.post1{dd};
%                 color = 'r';
%                 line = '-';
%             case 3
%                 this_act = FullNeurons.plusone.correct{dd};
%                 color = 'k';
%                 line = '--';
%             case 4
%                 this_act = FullNeurons.plusone.post1{dd};
%                 color = 'r';
%                 line = '--';
%         end
%         p(s) = plot(mean(this_act,1)); % plot only mean-act across trials
%         hold off
%         hold on
%         p(s).Color = color;
%         p(s).Color(4) = 0.5; % make acts/VMs transparent behind DerivDiffs
%         p(s).LineStyle = line;
%         p(s).LineWidth = 1.8; 
%         if layer == 13 && ismember(s, [3 4]) % only have 1 neuron if vN2pc plotted
%             p(s).Visible = 0;
%         end
%         hold off
%     end
%     
%     % plot it - right axis, derivativ-difference
%     hold on
%     this_diff = diff_total(dd,:);     % assign which diff we are doing
%     this_diff = this_diff * scalefac;
%     yyaxis right
%     hold on
%     p(5) = plot(this_diff);
%     zero = hline(0);
%     hold off
% 
%     % fix style
%     hold on
%     p(5).LineWidth = 2;
%     p(5).Color = rgb('olive');
%     zero.Color = rgb('olive');
%     zero.LineWidth = 0.6;
%     zero.LineStyle = '--';
%     hold off
%     
%     % auc as sum of absolute values, i.e. area between curve & zero
%     this_auc = sum(abs(this_diff)); 
%     
%     % axes
%     ax = gca;
%     ax.FontSize = 15;
%     ax.XLim = this_xlims;           % XLim
%     for x = 1:length(ax.XTick)
%         this_xticklabel = transfertime_steps2ms(ax.XTick(x));
%         ax.XTickLabels{x} = this_xticklabel;
%     end                             % Title
%     ax.Title.String = [ActName ' - Traces & Deriv-Diffs of ' ThisDelay ' tp delay at ' LayerName]; 
%     ax.Title.FontSize = 20;         % AUC Box
%     annotation('textbox', [.75 .7 .2 .1], 'String', ['AUC = ' num2str(floor(this_auc))], 'FontSize', 20, 'FitBoxToText', 'on') 
%     yyaxis left                     % Labels
%     switch VM
%         case 0
%             ylabel('Postsyn. Activations', 'FontSize', 20, 'Color', rgb('rust'))
%         case 1
%             ylabel('Membrane Potentials', 'FontSize', 20, 'Color', rgb('rust'))
%     end
%     yyaxis right
%     ylabel({'Target-unit - +1-unit Deriv. Difference', ['Scaled by ' num2str(scalefac)]}, 'FontSize', 20, 'Color', rgb('olive'))
%     xlabel('Time (ms-equivalent)', 'FontSize', 20)
%     
%     % after fixing axes-stuff: if respTFL & VMs, indicate the threshold to the binders using hline
%     if VM && layer == 18
%         hold on
%         yyaxis left
%         thresh2bind = hline(0.35, 'b', 'threshold to binder');
%         thresh2bind.LineStyle = '-.';
%         thresh2bind.LineWidth = 1.5;
%         thresh2bind.Color(4) = 0.3;
%     end
% end
%     % save ylims        ( no need for this anymore, because of linkaxes below)
% %     this_ylimmin_l = min([mean(FullNeurons.target.correct{dd},1), ...
% %         mean(FullNeurons.target.post1{dd},1), ...
% %         mean(FullNeurons.plusone.correct{dd},1), ...
% %         mean(FullNeurons.plusone.post1{dd},1)]);
% %     if this_ylimmin_l < ylimmin_l
% %         ylimmin_l = this_ylimmin_l;
% %     end
% %     this_ylimmax_l = max([mean(FullNeurons.target.correct{dd},1), ...
% %         mean(FullNeurons.target.post1{dd},1), ...
% %         mean(FullNeurons.plusone.correct{dd},1), ...
% %         mean(FullNeurons.plusone.post1{dd},1)]);
% %     if this_ylimmax_l > ylimmax_l
% %         ylimmax_l = this_ylimmax_l;
% %     end
% %     this_ylimmin_r = min(this_diff);
% %     if this_ylimmin_r < ylimmin_r
% %         ylimmin_r = this_ylimmin_r;
% %     end
% %     this_ylimmax_r = max(this_diff);
% %     if this_ylimmax_r > ylimmax_r
% %         ylimmax_r = this_ylimmax_r;
% %     end
% % end                   -- old forloop end!
% 
% % link axes & set global limits
% allaxes = [];
% for dd = 1:length(f)
%     allaxes = [allaxes f(dd).Children];
% end
% linkaxes(allaxes, 'xy') % links axes-limits of everything
% 
% % plot blasters after finalizing axes
% for dd = 1:length(f)
%     figure(f(dd))
%     if layer ~= 13
%         hold on
%         blast1 = vline2(blast_cor(dd), 'color', 'k');
%         blast1.LineWidth = 1.5;
%         blast1.LineStyle = ':';
%         blast1.Color = [blast1.Color 0.5]; % make it transparent
%         blast2 = vline2(blast_int(dd), 'color', 'r');
%         blast2.LineWidth = blast1.LineWidth;
%         blast2.LineStyle = blast1.LineStyle;
%         blast2.Color = [blast2.Color 0.5];
%         hold off
%     end
% end
% 
% %               ALL OF THIS DID NOT WORK (last fig always was the only one
% %                                          that was changed -- no idea why, still..)
% %
% % for i = 1:length(f)
% %     yyaxis left
% %     f(i).Children.YLim = [ylimmin_l ylimmax_l];
% %     yyaxis right
% %     f(i).Children.YLim = [ylimmin_r ylimmax_r];
% % end
% % linkaxes([f(1).Children, f(2).Children, f(3).Children, f().Children, f(1).Children
% %     f(dd)
% %     yyaxis left
% %     f(dd).Children.YLim = [ylimmin_l ylimmax_l];
% %     yyaxis right
% %     f(dd).Children.YLim = [ylimmin_r ylimmax_r];
% 
% % save figures
% for dd = 1:length(DelayNames)
% %     ax = f(dd).Children;
%     if saveplots
%         if ~exist(plotpath, 'dir')
%             mkdir(plotpath)
%         end
%         ThisDelay = DelayNames{dd};
%         saveas(f(dd), [plotpath ActName ' Traces & DerivDiff of ' ThisDelay ' tp Key Delay at ' LayerName '.jpg'])
%     end
% end
% 
% end
% 
% %%      FUNCTION plotit - does the plotting - old Version, 1 subplot for cor/int/total
% function plotit_old(Derivatives, BlastLats, layer, ActName, LayerName, DelayNames, plotpath, saveplots)
% 
% % extract differences across all delays before plotting them, especially to
% % find ylims first, because we have multiple figures, have to know them before plotting
% ylimin = inf; ylimmax = -inf;
% 
% % initialize diffs, too
% diff_cor = zeros(length(DelayNames), size(Derivatives(1).targ_correct,2));
% diff_int = zeros(length(DelayNames), size(Derivatives(1).targ_correct,2));
% diff_total = zeros(length(DelayNames), size(Derivatives(1).targ_correct,2));
% blast_cor = zeros(length(DelayNames),1);
% blast_int = zeros(length(DelayNames),1);
% blast_total= zeros(length(DelayNames),1);
% 
% % Get Differences
% for dd = 1:length(DelayNames)
%     diff_cor(dd,:) = Derivatives(dd).targ_correct - Derivatives(dd).plusone_correct;
%     diff_int(dd,:) = Derivatives(dd).targ_post1 - Derivatives(dd).plusone_post1;
%     diff_total(dd,:) = Derivatives(dd).targ_total - Derivatives(dd).plusone_total;
%     blast_cor(dd) = BlastLats(dd).correct;
%     blast_int(dd) = BlastLats(dd).post1;
%     blast_total(dd) = BlastLats(dd).total;
% end
% 
% % get ylimbounds
% ylimmin = min(min([diff_cor diff_int diff_total])); % probably could just use total but whatever
% ylimmax = max(max([diff_cor diff_int diff_total]));
% 
% for dd = 1:length(DelayNames)
%     figure;
%     set(gcf, 'Position', [1366          19        1289         492]) %laptop
%     
%     % Extract current delay
%     ThisDelay = DelayNames{dd};
%     
%     % stuff for looping subplots
%     plotnames = {'Correct Responses', 'Intrusion Responses', 'All Responses'};
%     
%     % auc scale factor
%     scalefac = 10^4;
%     
%     % loop over subplots
%     for s = 1:length(plotnames)
%         subplot(3,1,s)
%         
%         % assign which diff we are doing
%         this_diff = []; this_blast = []; this_auc = [];
%         switch s
%             case 1
%                 this_diff = diff_cor(dd,:);
%                 this_blast = blast_cor(dd);
%                 color = 'k';
%             case 2
%                 this_diff = diff_int(dd,:);
%                 this_blast = blast_int(dd);
%                 color = 'r';
%             case 3
%                 this_diff = diff_total(dd,:);
%                 this_blast = blast_total(dd);
%                 color = rgb('olive');
%         end
%         
%         % auc
%         if strcmp(ActName, 'Act') && layer == 18
%             this_diff = this_diff(200:400);
%         else
%             this_diff = this_diff(150:400);
%         end
%         this_auc = trapz(this_diff);
%         this_auc = this_auc * scalefac;
%         
%         % plot it
%         hold on
%         p(s) = plot(this_diff);
%         hold off
%         
%         % fix style
%         hold on
%         p(s).LineWidth = 1.5;
%         p(s).Color = color;
%         hold off
%         
%         % axes
%         ax = gca;
%         ax.XLim = [1 length(this_diff)];
%         if strcmp(ActName, 'Act') && layer == 18
%             ax.XTick = 0:50:200;
%             ax.XTickLabels = 200:50:400;
%         else
%             ax.XTick = 0:50:250;
%             ax.XTickLabels = 150:50:400;
%         end
%         ax.YLim = [ylimmin ylimmax];
%         title([plotnames{s} ' - AUC = ' num2str(this_auc)], 'fontsize', 12) % put auc in the title
%         
%         % blasters
%         hold on
%         shift = 200; % because we shift this_diff by 200 indices
%         blast = vline2(this_blast-shift, 'color', color);
%         blast.LineWidth = 2;
%         blast.LineStyle = ':';
%         hold off
%     end
%     
%     % Suptitle
%     hold on
%     [~, h1] = suplabel([ActName ': Target - +1-Unit Deriv-Diffs of ' ThisDelay 'tp delay at ' LayerName], 't', [.08, .13, .84, .84]);
%     h1.FontSize = 17;
%     hold off
%     
%     % Save
%     if saveplots
%         if ~exist(plotpath, 'dir')
%             mkdir(plotpath)
%         end
%         saveas(gcf, [plotpath ActName ' Derivatives of ' ThisDelay ' tp Key Delay at ' LayerName '.jpg'])
%     end
% end
% end
% 
% 
% %%      FUNCTION OLD - plotit - does the plotting
% %
% %
% %
% %
% %
% %
% %       (like ERPs, not 3 diff waves)
% %
% %
% %
% %
% %
% %
% % function plotit(Derivatives, BlastLats, ActName, LayerName, DelayNames, plotpath, saveplots)
% % for dd = 1:length(DelayNames)
% %     figure;
% %     set(gcf, 'Position', [1366          19        1289         492]) %laptop
% %     ylimmax = 0; ylimmin = 0;
% %
% %     % Extract current delay
% %     ThisDelay = DelayNames{dd};
% %
% %     ylimmax = max([Derivatives(dd).targ_correct, Derivatives(dd).plusone_correct, Derivatives(dd).targ_post1, Derivatives(dd).plusone_post1]);
% %     ylimmin = min([Derivatives(dd).targ_correct, Derivatives(dd).plusone_correct, Derivatives(dd).targ_post1, Derivatives(dd).plusone_post1]);
% %
% %     % Plot
% %     p(1) = plot(Derivatives(dd).targ_correct);
% %     hold on
% %     p(2) = plot(Derivatives(dd).plusone_correct);
% %     p(3) = plot(Derivatives(dd).targ_post1);
% %     p(4) = plot(Derivatives(dd).plusone_post1);
% %     hold off
% %
% %     % Fix style
% %     hold on
% %     p(1).LineWidth = 1.5; p(2).LineWidth = 1.5; p(3).LineWidth = 1.5; p(4).LineWidth = 1.5;
% %     p(1).Color = 'k'; p(2).Color = 'k';
% %     p(3).Color = 'r'; p(4).Color = 'r';
% %     p(1).LineStyle = '-'; p(3).LineStyle = '-';
% %     p(2).LineStyle = '--'; p(4).LineStyle = '--';
% %     hold off
% %
% %     % Blaster
% %     hold on
% %     blast1 = vline2(BlastLats(dd).targ_correct, 'color', 'k'); % only need one vline for correct, one for intrusion responses (same latency for target & +1 neuron)
% %     blast2 = vline2(BlastLats(dd).targ_post1, 'color', 'r');
% %     blast1.LineWidth = 2; blast2.LineWidth = 2;
% %     blast1.LineStyle = ':'; blast2.LineStyle = ':';
% %     hold off
% %
% %     % Info about Derivatives-Differences between Correct & Intrusion in Text boxes
% %     stepsize = 50;
% %     x_limits = [150 400];
% %     if strcmp(LayerName, getLayerName(17)) % scale derivative means up by this to have bigger numbers
% %         scalingfac = 10000;
% %     elseif strcmp(LayerName, getLayerName(18))
% %         scalingfac = 5000;
% %     end
% %     x_steps = x_limits(1):stepsize:x_limits(2);
% %
% %     % 1 - Compute [taking the absolute difference, because we are
% %     %   interested in extent of overall diff. in change as delay increases, not direction]!
% %     DerivDiff_target = abs(Derivatives(dd).targ_correct - Derivatives(dd).targ_post1);
% %     DerivDiff_plusone = abs(Derivatives(dd).plusone_correct - Derivatives(dd).plusone_post1);
% %     DerivDiff_total = DerivDiff_target + DerivDiff_plusone;
% %     % 2 - TimeWindows
% %     for step = 1:length(x_steps)-1
% %         Steps_target(step) = mean(DerivDiff_target(x_steps(step)+1:x_steps(step+1))); Steps_target(step) = Steps_target(step) * scalingfac;
% %         Steps_plusone(step) = mean(DerivDiff_plusone(x_steps(step)+1:x_steps(step+1))); Steps_plusone(step) = Steps_plusone(step) * scalingfac;
% %         Steps_total(step) = mean(DerivDiff_total(x_steps(step)+1:x_steps(step+1))); Steps_total(step) = Steps_total(step) * scalingfac;
% %     end
% %     % 2 - Add Box
% %     annotation('textbox', [.55 .7 .2 .1], 'String', ['Target-unit: ' num2str(Steps_target)], 'FitBoxToText', 'on')
% %     annotation('textbox', [.55 .65 .2 .1], 'String', ['+1-unit: ' num2str(Steps_plusone)],'FitBoxToText',  'on')
% %     annotation('textbox', [.55 .6 .2 .1], 'String', ['Absolute Diff Overall: ' num2str(Steps_total)], 'FitBoxToText', 'on')
% %     annotation('textbox', [.55 .55 .2 .1], 'String', ['Abs Sum of ''Overall'' Across Timeseries: ' num2str(sum(abs(Steps_total)))], 'FitBoxToText', 'on')
% %
% %     % Axes stuff
% %     hold on
% %     ax = gca;
% %     ax.FontSize = 15;
% %     xlim([x_limits(1) x_limits(2)]);
% %     if ~isequal(ylimmin,ylimmax)
% %         ylim([ylimmin ylimmax])
% %     end
% %     hold off
% %
% %     % Title stuff
% %     hold on
% %     [~, h1] = suplabel([ActName ' - Derivatives of ' ThisDelay 'tp delay at ' LayerName], 't', [.08, .14, .84, .84]);
% %     [~, h2] = suplabel(['Box shows av. & ABSOLUTE cor. - int. deriv.-diff. in steps of ' num2str(stepsize) ...
% %         'tps scaled by factor of ' num2str(scalingfac) '.'], 't', [.08, .1, .84, .84]);
% %     h1.FontSize = 15; h2.FontSize = h1.FontSize;
% %     hold off
% %
% %     % Save
% %     if saveplots
% %         if ~exist(plotpath, 'dir')
% %             mkdir(plotpath)
% %         end
% %         saveas(gcf, [plotpath ActName ' - Derivatives of ' ThisDelay 'tp Key Delay at ' LayerName '.jpg'])
% %     end
% % end
% % end