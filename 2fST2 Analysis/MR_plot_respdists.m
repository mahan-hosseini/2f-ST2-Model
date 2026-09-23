%% Get numerical response distributions
function MR_plot_respdists(name, marker, plotpath, saveplots, TwoRespFeatures)

% Get respnums from marker (numerical vector instead of string-cellarray)
respnums = marker2respnums(marker);
trialnums = length(respnums);

% Plot it
figure;
% set(gcf, 'Position', [1000         347        1351         991])
set(gcf,'Position', [1367        -215        1280         907]); % laptop
% for title & saving
if strcmp(name, 'key0_resp0')
    name = 'No Delay';
elseif strcmp(name, 'key24_resp0')
    name = 'Key Delay';
end
switch TwoRespFeatures
    case 0
        xvals = -2:1:2;
        suptitle = ['No Response Task Filtering - ' name];
        savename = ['Srivas'' - ' name ' - Response Distributions.jpg'];
    case 1
        xvals = 0:1;
        suptitle = ['Response Task Filtering - ' name];
        savename = ['Alon''s ' name '- Response Distributions.jpg'];
end

% get correct proportions for each subplot (proportions are across total number of trials)
for ii = 1:length(xvals)
    this_prop(ii) = sum(respnums == xvals(ii)) / trialnums;
end
% plot the bars
b = bar(xvals, this_prop);

% set correct bar-colors
switch TwoRespFeatures
    case 0
        b.CData = [rgb('light green'); 0 1 0; 0 0 0; 1 0 0; rgb('rose')];
    case 1
        b.CData = [0 0 0; 1 0 0];
end
b.FaceColor = 'flat';

% set fontsize
ax = gca;
ax.FontSize = 35;
if TwoRespFeatures
    ax.XTickLabel = {['Cor: ' num2str(round(this_prop(1)*100, 1)) '%'], ...
        ['Int: ' num2str(round(this_prop(2)*100, 1)) '%']};
else
    tmp_xticklab = cell(1,length(this_prop));
    for i = 1:length(this_prop)
        tmp_xticklab{i} = [num2str(round(this_prop(i)*100, 1)) '%'];
    end
    ax.XTickLabel = tmp_xticklab;
end

% Do the labels
hold on
[~, h1] = suplabel('Proportion', 'y');
% [~, h3] = suplabel(suptitle, 't'); %dont want titles
h1.FontSize = 45; %h3.FontSize = h1.FontSize;

% Print exact proportions for writing
fprintf('\n *** RESPONSE DISTRIBUTION NUMERICALLY *** \n')
for i = 1:length(xvals)
    fprintf('\n *** Condition: %d - Proportion: %d *** \n', xvals(i), round(this_prop(i), 3))
end

% Save
if saveplots
    switch TwoRespFeatures
        case 0
            this_plotpath = [plotpath 'Srivas/'];
        case 1
            this_plotpath = [plotpath 'Alon/'];
    end
    if ~exist(this_plotpath, 'dir')
        mkdir(this_plotpath)
    end
    saveas(gcf, [this_plotpath savename])
end
hold off
end