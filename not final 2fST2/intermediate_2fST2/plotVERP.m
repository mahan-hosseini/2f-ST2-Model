function VERP_fig = plotVERP(setname, channel, params) %MAHAN: added handle to fig

if ~exist('params', 'var')
    params = struct([]);
end

if isfield(params, 'legendstrings')
    legendstrings = params.legendstrings;
else
    legendstrings = setname;
end

if isfield(params, 'linestyles')
    linestyles = params.linestyles;
end

if isfield(params, 'plotSE')
    plotSE = 1;
end

if strcmp(channel, 'N2pc')
    channum = 2;
    plotwin = [-200 800];
    ylim = [0 25];
    ytick = ylim(1):5:ylim(2);
    range = [100 600];
elseif strcmp(channel, 'P3')
    channum = 1;
    plotwin = [-200 1000];
    ylim = [0 0.6];
    ytick = ylim(1):0.1:ylim(2);
    range = [200 800];
end

fontsize = 22;
f = figure('Color', 'w');
set(f, 'Position', [1 1 1280 1024 * (2/3)]);
set(gca,'FontName', 'Arial', 'FontSize', fontsize-2, 'FontWeight', 'Normal', ...
    'Color', 'none','XLim', plotwin,'YLim',ylim,'YTick',ytick);
%set(gca, 'ColorOrder', [0 0 0.5], 'LineStyleOrder','-|--|:|-.');%
% set(gca, 'ColorOrder', [0 0 0.5; 0.5 0 0; 0.5 0 0; 0 0.5 0; 0 0.5 0;], 'LineStyleOrder','-');
%set(gca, 'ColorOrder', [0 0 0.5; 0 0 0.5; 0.5 0 0; 0.5 0 0;], 'LineStyleOrder','-')
set(gca, 'ColorOrder', [0 0 0.5; 0 0.5 0; 0.5 0 0;], 'LineStyleOrder','-|--')

xlabel(gca, 'Time from target onset (ms equivalent)', 'FontName', 'Arial',...
    'FontSize', fontsize, 'FontWeight', 'Normal');
ylabel(gca, 'Postsynaptic activation', 'FontName', 'Arial', 'FontSize', fontsize, 'FontWeight', 'Normal');
%set(a, 'YDir', 'reverse');
hold all

for setidx=1:1:length(setname)
    EEG = pop_loadset('filename', [setname{setidx} '.set']);
    onset_time = abs(EEG.times(1));
    dsfactor = 1000/EEG.srate;
    plotrange = (plotwin + onset_time) ./ dsfactor;

    if exist('linestyles', 'var')
        plot(EEG.times(plotrange(1):plotrange(2)), ...
            mean(EEG.data(channum, plotrange(1):plotrange(2), :), 3),  ...
            linestyles{setidx}{1}, linestyles{setidx}{2}, 'LineWidth', 3, ...
            'LineStyle', '-'); %MAHAN: Changed linestyles to be 1x2 cell array for each index of setidx (COlor, X - only!)
    else
        plot(EEG.times(plotrange(1):plotrange(2)), ...
            mean(EEG.data(channum, plotrange(1):plotrange(2), :), 3),  ...
            'LineWidth', 3, 'LineStyle', '-');
    end
    if exist('plotSE', 'var')
        sd = std(EEG.data(channum, plotrange(1):plotrange(2), :), [], 3);
        SE = sd / sqrt(EEG.trials);
        s1 = mean(EEG.data(channum, plotrange(1):plotrange(2), :), 3)-SE;
        s2 = mean(EEG.data(channum, plotrange(1):plotrange(2), :), 3)+SE;
        fillX = [EEG.times(plotrange(1):plotrange(2)), ...
            fliplr(EEG.times(plotrange(1):plotrange(2)))];
        fillY = [s1, fliplr(s2)];
        f1 = fill(fillX, fillY, linestyles{setidx}{2}, 'HandleVisibility', 'off'); %MAHAN: handle_vis = off so it won't be included in legend
        f1.FaceAlpha = 0.15; f1.EdgeColor = linestyles{setidx}{2};
        f1.EdgeAlpha = 0.15; f1.LineStyle = ':'; 
    end

    critpercent = 50;
    timepoints = size(EEG.data, 2);
    epochs = size(EEG.data, 3);
    latencies = zeros(1,epochs);

    for epochnum=1:epochs

        area = 0;
        for tp=1:timepoints
            if EEG.times(tp) >= range(1) && EEG.times(tp) <= range(2)
                area = area + EEG.data(channum, tp, epochnum);
            end
        end
        if area <= 0
            continue;
        end

        critval = (critpercent/100) * area;
        area = 0;
        for tp=1:timepoints
            if EEG.times(tp) >= range(1) && EEG.times(tp) <= range(2)
                area = area + EEG.data(channum, tp, epochnum);
                if area >= critval
                    latencies(epochnum) = EEG.times(tp);
                    break;
                end
            end
        end
    end
    datarange = round((onset_time + range)./dsfactor);
    meanamp = mean(mean(EEG.data(channum,datarange(1):datarange(2),:),3),2);
    peakamp = max(mean(EEG.data(channum,datarange(1):datarange(2),:),3),[],2);
    disp(sprintf('%s: Mean amplitude = %.2f.', setname{setidx}, meanamp));
    disp(sprintf('%s: Peak amplitude = %.2f.', setname{setidx}, peakamp));
    disp(sprintf('%s: Mean latency = %.2f, SD = %.2f.', setname{setidx}, mean(latencies), std(latencies, 1)));
end

ylimits = get(gca, 'YLim');
lref = line([0 0], [0 ylimits(2)], 'Color', 'k');
hAnnotation = get(lref,'Annotation');
hLegendEntry = get(hAnnotation','LegendInformation');
set(hLegendEntry,'IconDisplayStyle','off');
hLegend = legend;
set(hLegend, 'Interpreter','none');
legend(legendstrings, 'Location','NorthWest');

if ~isempty(range)
    line1 = line([range(1) range(1)], [ylimits(1) ylimits(2)], 'Color', 'k', 'LineStyle', '--', 'LineWidth', 3);
    line1anno = get(line1,'Annotation');
    line1legentry = get(line1anno','LegendInformation');
    set(line1legentry,'IconDisplayStyle','off')
    line2 = line([range(2) range(2)], [ylimits(1) ylimits(2)], 'Color', 'k', 'LineStyle', '--', 'LineWidth', 3);
    line2anno = get(line2,'Annotation');
    line2legentry = get(line2anno','LegendInformation');
    set(line2legentry,'IconDisplayStyle','off')
end

VERP_fig = gcf; %MAHAN: added handle to fig
end