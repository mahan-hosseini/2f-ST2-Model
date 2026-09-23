function avdata = st2trace(condname, condition, lag, layers, onset, newfig)

load(strrep(condname, ' ', '_'), 'ExPostsynBat_*', 'BasicAccu');
%erp = cat(1, MembPotBat_easy, MembPotBat_hard);
erp = ExPostsynBat_basic;

% condition = [1 2];
% lag = [3 3];
% start = [180 180];
duration = 400;
scalefactor = 5000;
% retinaldelay = 70 / 5;
retinaldelay = 0;
onset = onset./5;
prestimulus = 500 / 5;
plotstart = prestimulus * -1;

input = zeros(length(lag), duration, 'double');
avdata = zeros(length(lag), duration, 'double');

for i = 1:length(lag)
    choice = (BasicAccu(:, lag(i)) == condition(i));
    data = squeeze(mean(erp(choice, lag(i), onset(i) - retinaldelay - prestimulus: onset(i) + duration - 1 - retinaldelay - prestimulus, :),1));
    input(i, :) = data(:, 1)';
    for j = 1:length(layers)
        avdata(i, :) = avdata(i, :) + data(:, layers(j))';
    end
    % avdata(i, :) = avdata(i, :) ./ length(layers);
end

if newfig
f = figure('Color', 'w');
figpos = get(f, 'Position');
set(f, 'Position', [1 1 1280 1024 * (2/3)]);
a = axes('FontName', 'Arial', 'FontSize', 16, 'FontWeight', 'Bold', 'Color', 'none');
hold all;
xlabel(gca, 'Time from target onset (ms equivalent)', 'FontName', 'Arial', 'FontSize', 18, 'FontWeight', 'Bold');
ylabel(gca, 'Postsynaptic activation', 'FontName', 'Arial', 'FontSize', 18, 'FontWeight', 'Bold');
set(a, 'ColorOrder', [1 0 0; 0 1 0], 'LineStyleOrder','-');    
% set(a, 'ColorOrder', [0 0 0], 'LineStyleOrder','-|--|:|-.');
% ylim([0 5]);
else
    hold all
end

for i = 1:length(lag)
    % plot((start(i) - 120:start(i) - 120 + duration - 1) .* 5, input(1, :) .* scalefactor,  'LineWidth', 3);
    % plot((start(i) - 120:start(i) - 120 + duration - 1) .* 5, avdata(i, :),  'LineWidth', 10);
    plot((plotstart:duration - 1 + plotstart) .* 5, avdata(i, :),  'LineWidth', 3, 'DisplayName', condname);
end

ylimits = get(gca, 'YLim');
lref = line([0 0], [0 ylimits(2)], 'Color', 'k');
hAnnotation = get(lref,'Annotation');
hLegendEntry = get(hAnnotation','LegendInformation');
set(hLegendEntry,'IconDisplayStyle','off');
legend off;
legend show;
% plot((0:duration - 1) .* 5, input(2, :) .* scalefactor,  'LineWidth', 3, 'Color', 'k');
% plot((0:duration - 1) .* 5, avdata(2, :),  'LineWidth', 3, 'Color', 'k');