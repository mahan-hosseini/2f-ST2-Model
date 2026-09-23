function data = plottrace(condname, errtype, layer, onset, newfig)

%P3 layers = [3 4 6 8 17 18 21]
%target onset = 800

load(condname, 'T1respdata', 'ExPostsynBat_basic');
%erp = cat(1, MembPotBat_easy, MembPotBat_hard);
erp = ExPostsynBat_basic;

duration = 240;
%retinaldelay = 70 / 5;
retinaldelay = 0;
onset = onset/5;
prestimulus = 0 / 5;
plotstart = prestimulus * -1;

targetpos = 20;

misses = 0;
correctresp = 0;
preintrusions = 0;
postintrusions = 0;

%T1respdata = T1respdata(:,round(size(T1respdata,2)/3),:,:,:);
allresp = reshape(T1respdata, [1, size(T1respdata, 2) * size(T1respdata, 3) * size(T1respdata, 4) * size(T1respdata, 5)]);
for i=1:length(allresp)
    if allresp(i) == 0
        misses = [misses i];
    elseif allresp(i) == 1
        correctresp = [correctresp i];
    elseif allresp(i) < targetpos
        preintrusions = [preintrusions i];
    elseif allresp(i) >= targetpos
        postintrusions = [postintrusions i];
    end
end

misses = misses(2:end);
correctresp = correctresp(2:end);
preintrusions = preintrusions(2:end);
postintrusions = postintrusions(2:end);

erp = reshape(erp, [size(erp,1) * size(erp,2), size(erp,3),size(erp,4)]);

if strcmp(errtype, 'pre')
    trials = preintrusions;
    errtype = 'Pre-target intrusions';
elseif strcmp(errtype, 'correct')
    trials = correctresp;
    errtype = 'Pre-target intrusions';
elseif strcmp(errtype, 'post')
    trials = postintrusions;
    errtype = 'Post-target intrusions';
elseif strcmp(errtype, 'all')
    trials = [preintrusions correctresp postintrusions];
    errtype = 'Low key word frequency';
end

avdata = sum(mean(erp(trials, onset - retinaldelay - prestimulus: onset + duration - 1 - retinaldelay - prestimulus, layer),1),3);

if newfig
    f = figure('Color', 'w');
    set(f, 'Position', [1 1 1280 1024 * (2/3)]);
    a = axes('FontName', 'Arial', 'FontSize', 16, 'FontWeight', 'Bold', 'Color', 'none');
    hold all;
    xlabel(gca, 'Time from target onset (ms equivalent)', 'FontName', 'Arial', 'FontSize', 18, 'FontWeight', 'Bold');
    ylabel(gca, 'Postsynaptic activation', 'FontName', 'Arial', 'FontSize', 18, 'FontWeight', 'Bold');
    set(a, 'ColorOrder', [1 0 0; 0 1 0], 'LineStyleOrder','-');
    set(a, 'ColorOrder', [0 0 0], 'LineStyleOrder','-|--|:|-.');
    %set(a, 'YDir', 'reverse');
    % ylim([0 5]);
else
    hold all
end

plot((plotstart:duration - 1 + plotstart) .* 5, avdata(1, :),  'LineWidth', 3, 'DisplayName', errtype);

ylimits = get(gca, 'YLim');
lref = line([0 0], [0 ylimits(2)], 'Color', 'k');
hAnnotation = get(lref,'Annotation');
hLegendEntry = get(hAnnotation','LegendInformation');
set(hLegendEntry,'IconDisplayStyle','off');

legend off;
%legend show;
data = avdata;