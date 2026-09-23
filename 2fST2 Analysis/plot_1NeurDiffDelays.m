%% plot_1NeurDiffDelays
%   plots the same neuron @ a given layer for different delay conditions
%   (atm only supporting keydelay & layeracts (no vERPs) & cor/+1 responses

function plot_1NeurDiffDelays(VM, layer, keydelays, neuron, response, zoomXAx, blackred, varpath, plotpath, saveplots)
%% Quick sanity check of response-input (would be easy to make this work for the other responses, but I couldn't see when I would use it when I wrote this)
if ~(strcmp(response, 'correct') || strcmp(response, 'post1'))
    disp('FUNC. ONLY SUPPORTS 0 & +1 RESPONSES AT THE MOMENT, CANCELLING!')
    return
end
if length(keydelays) ~= 5 % and also this....
    disp('FUNC. ONLY SUPPORTS EXACTLY 5 DIFF DELAYS ATM (bc of legend & defining colours using RGB) - FIX IT! CANCELLING!')
    return
end

%% Load the vars - created via extract_1NeurDiffDelays
% Save all_neurons & all_blasters
% some strings we need
LayerName = getLayerName(layer);
switch neuron
    case 1
        NeuronName = 'Target - Unit';
    case 20
        NeuronName = '+1 - Unit';
end
switch VM
    case 0
        ActName = 'Act';
    case 1
        ActName = 'VM';
end
% Create FullName & load
FullName = [ActName ' of ' NeuronName ' at ' LayerName ' for ' response ' Responses'];
load([varpath FullName '.mat'], 'all_neurons', 'all_blasters')

%% Plot it 
plotit(VM, all_neurons, all_blasters, layer, keydelays, neuron, response, zoomXAx, blackred, plotpath, saveplots)
end

%% Local function: plot the plot
function plotit(VM, all_neurons, all_blasters, layer, keydelays, neuron, response, zoomXAx, blackred, plotpath, saveplots)
% quick prep
figure;
set(gcf, 'Position', [636         961        1575         377])
ylimbounds(1) = 0; ylimbounds(2) = inf;  
if blackred == 0 % if we don't want the blackred
    colors = {rgb('indigo'), rgb('olive'), rgb('magenta'), rgb('crimson'), rgb('jade')};
end
% go
for d = 1:length(keydelays)
    % extract stuff
    this_neuron = all_neurons{d};
    % set the color (blackred (old plotting conventions) or colorful?)
    if blackred == 0
        this_color = colors{d};
    else
        if strcmp(response, 'correct')
            this_color = 'k';
        elseif strcmp(response, 'post1')
            this_color = 'r';
        end
    end
    % extract average
    av_act = mean(this_neuron); % structure: timepoints x 1
    % set ylimbounds
    if min(av_act) < ylimbounds(1)
        ylimbounds(1) = min(av_act);
    end
    if max(av_act) > ylimbounds(2)
        ylimbounds(2) = max(av_act);
    end
    % plot the act
    hold on
    p(d) = plot(av_act);
    plotSEtoo(this_neuron, 0, this_color, 0, 0);
%     plotSEtoo(this_neuron, this_color);
    % set properties of act-line
    p(d).Color = this_color;
    p(d).LineWidth = 2.5;
    % linestyle only changed if blackred = 1 
    if blackred
        if neuron == 1
            p(d).LineStyle = '-';
        elseif neuron == 20
            p(d).LineStyle = '--';
        end
    end
end
% set some axis-stuff
if zoomXAx
    if ismember(layer, [1 2 15 16])
        xlim([100 400]) % for input & masking layers
    else
        xlim([200 400])
    end
end
ylim([ylimbounds(1) ylimbounds(2)])

% add the blaster latency
for d = 1:length(keydelays)
    hold on
    if blackred == 0
        this_color = colors{d};
    else
        if strcmp(response, 'correct')
            this_color = 'k';
        elseif strcmp(response, 'post1')
            this_color = 'r';
        end
    end
    this_blaster = all_blasters{d};
    this_vN2pc = mean(this_blaster,1); % average across all trials
    this_blasterfire = blasterfiring(this_vN2pc); % define blasterfiring as 50% AUC under 'this' vN2pc
    blast = vline2(this_blasterfire, 'color', this_color);
    blast.LineWidth = 4;
    blast.LineStyle = ':';
    blast.Color = [blast.Color 0.5]; % make it transparent
    hold off
end

ax = gca;
ax.FontSize = 21;
% fix x-axis to show time in ms-equivalents, not timesteps
for x = 1:length(ax.XTick)
    this_xticklabel = transfertime_steps2ms(ax.XTick(x));
    ax.XTickLabels{x} = this_xticklabel;
end
hold on
% some strings we need
LayerName = getLayerName(layer);
switch neuron
    case 1
        NeuronName = 'Target - Unit';
    case 20
        NeuronName = '+1 - Unit';
end
switch VM
    case 0
        ActName = 'Act';
    case 1
        ActName = 'VM';
end
if blackred == 0
    colorname = ' - coloured';
elseif blackred == 1
    colorname = ' - blackred';
end
FullName = [ActName ' of ' NeuronName ' at ' LayerName ' for ' response ' Responses' colorname];
% super-title
[~, h1] = suplabel(FullName, 't');
h1.FontSize = 22;
hold off
% legend [tau(k)s in time-steps]
% keydelays_ms = keydelays * 5; % going from timesteps to ms (5ms per timestep, 200Hz)
lgd = legend(num2str(keydelays(1)), num2str(keydelays(2)), num2str(keydelays(3)), num2str(keydelays(4)), num2str(keydelays(5))); 
% lgd = legend(num2str(keydelays_ms(1)), num2str(keydelays_ms(2)), num2str(keydelays_ms(3)), num2str(keydelays_ms(4)), num2str(keydelays_ms(5)));
lgd.Title.String = [char([0xD835 0xDF0F]) 'k'];
lgd.Title.FontSize = 15;
% save it
if saveplots
    % save it (might need to create the dir first)
    if ~exist(plotpath, 'dir')
        mkdir(plotpath)
    end
    saveas(gcf, [plotpath FullName '.jpg']);
end
end