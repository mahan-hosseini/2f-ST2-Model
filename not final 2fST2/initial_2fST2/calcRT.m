function calcRT(setname)

loadpath = 'N:/Work/ST2/TwoPathway';
channum = 6;
thresh = .75;
dosave = true;

meanRT = zeros(length(setname),1);
sdRT = zeros(length(setname),1);

for setidx = 1:length(setname)
    EEG = pop_loadset('filename', [setname{setidx} '.set'], 'filepath', loadpath);

    RT = zeros(1,EEG.trials);
    for epoch = 1:EEG.trials
        trial = squeeze(EEG.data(channum,:,epoch));
        maxexpost = max(trial);
        RT(epoch) = find((trial > thresh*maxexpost),1);
    end
    RT = EEG.times(RT);
    meanRT(setidx) = mean(RT);
    sdRT(setidx) = std(RT,1);
    if dosave
        [sortedRT sortidx] = sort(RT);
        EEG.data = EEG.data(:,:,sortidx);
        pop_saveset(EEG, [setname{setidx} '.set']);
    end
end

botellaRT = [383; 393; 411];

fig = figure;
figpos = get(fig,'Position');
scalefactor=2;
set(fig,'Position',[0,0,figpos(3)*scalefactor,figpos(4)*scalefactor]);

AX = plotyy(1:length(setname),meanRT,1:length(setname),botellaRT,@plotdata);
fontsize = 24;
ax1tick = 500:50:600;
ax2tick = 375:25:425;

set(AX(1),'XLim',[0 length(setname)+1],'XTick', 0:length(setname)+1,...
    'XTickLabel',{'','Correct','Pre-target','Post-target',''},'FontSize',fontsize-2,...
    'FontWeight','normal','YLim',[ax1tick(1) ax1tick(end)],'YTick',ax1tick);
set(get(AX(1),'Xlabel'),'String', 'Response Position', 'FontWeight', 'normal',...
    'FontSize', fontsize, 'FontName', 'Arial');
set(get(AX(1),'Ylabel'),'String', '2f-ST^2 reaction time (ms equivalent)', ...
    'FontWeight', 'normal', 'FontSize', fontsize, 'FontName', 'Arial');
set(AX(2),'XLim',[0 length(setname)+1],'XTick', [],'FontSize',fontsize-2,...
    'FontWeight','normal','YLim',[ax2tick(1) ax2tick(end)],'YTick',ax2tick);
set(get(AX(2),'Ylabel'),'String', 'Botella (1992) reaction time (ms)', ...
    'FontWeight', 'normal', 'FontSize', fontsize, 'FontName', 'Arial');

legend('Botella (1992)','2f-ST^2 Model');
meanRT
sdRT
end

function h = plotdata(x,y)
    h = plot(x,y);
    set(h,'Marker','square','LineWidth',3,'MarkerFaceColor',get(h,'Color'),'MarkerSize',9);
end