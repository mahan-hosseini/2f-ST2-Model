function latencies  = plotVERPimage(setname,channelname)
%latency_type = -1; %no sorting
%latency_type = 0; %peak sorting
latency_type = 1; %50% area latency sorting
%latency_type = 2; %phase sorting

loadpath = 'N:/Work/ST2/TwoPathway';
savepath = 'N:/Work/ST2/';

dosave = false;
smooth = 1;

if strcmp(channelname, 'P3')
    channel = 1;
    savename = [savepath setname '_vP3image'];
    plotrange = [-100 1000];
    range = [200 800];
    caxislimits = [-0.7 0.7];
    erplim = [0 caxislimits(2)];

    %    caxislimits = [-0.3 0.3];
    channel = 6;
range = [514.2652 544.1597 569.1071];
caxislimits = [-0.07 0.07];

elseif strcmp(channelname, 'N2pc')
    channel = 2;
    savename = [savepath setname '_vN2pcimage'];
    plotrange = [-100 800];
    range = [100 650];
    caxislimits = [-30 30];
    erplim = [0 caxislimits(2)];
end

EEG = pop_loadset('filename', [setname '.set'], 'filepath', loadpath);

%sorting
critpercent = 50;
timepoints = size(EEG.data, 2);
epochs = size(EEG.data, 3);
latencies = zeros(1,epochs);

disp('Sorting trials...');
for epochnum=1:epochs

    if latency_type == 0
        maxval = 0;
        maxidx = 1;
        for tp=1:timepoints
            if EEG.times(tp) >= range(1) && EEG.times(tp) <= range(2) && maxval < EEG.data(channel, tp, epochnum)
                maxval = EEG.data(channel, tp, epochnum);
                maxidx = tp;
            end
        end
        latencies(epochnum) = EEG.times(maxidx);
        EEG.event(1,EEG.epoch(1,epochnum).event(1,1)).description = EEG.times(maxidx);
        EEG.event(1,EEG.epoch(1,epochnum).event(1,2)).description = EEG.times(maxidx);

    elseif latency_type == 1
        area = 0;
        for tp=1:timepoints
            if EEG.times(tp) >= range(1) && EEG.times(tp) <= range(2)
                area = area + EEG.data(channel, tp, epochnum);
            end
        end
        if area <= 0
            continue;
        end

        critval = (critpercent/100) * area;
        area = 0;
        for tp=1:timepoints
            if EEG.times(tp) >= range(1) && EEG.times(tp) <= range(2)
                area = area + EEG.data(channel, tp, epochnum);
                if area >= critval
                    latencies(epochnum) = EEG.times(tp);
                    EEG.event(1,EEG.epoch(1,epochnum).event(1,1)).description = EEG.times(tp);
                    break;
                end
            end
        end
    end
end

EEG = eeg_checkset(EEG,'eventconsistency');

figure('Color', 'white');

if latency_type == 2 %phasesorting
    [peak latency] = max(mean(EEG.data(channel,80:end,:),3));
    latency = ((latency + 80) * 5) + EEG.times(1);
    center = latency;

    [data,outsort,outtrials,limits,axhndls,erp,amps,cohers,cohsig,ampsig,allamps,...
        phaseangles,phsamp,sortidx,erpsig] = ...
        pop_erpimage(EEG,1, channel,[],[],smooth,1,{},[],'',...
        'erp','yerplabel','Activation','limits',[plotrange erplim NaN NaN NaN NaN],...
        'cbar','caxis',caxislimits,...
        'phasesort',[center 0 1.53],'vert',center,'cycles',0.5);

elseif latency_type == 0 || latency_type == 1
    [data,outsort,outtrials,limits,axhndls,erp,amps,cohers,cohsig,ampsig,allamps,...
        phaseangles,phsamp,sortidx,erpsig] = ...
        pop_erpimage(EEG,1, channel,[],[],smooth,1,{},[],'description',...
        'erp','yerplabel','Activation','limits',[plotrange erplim NaN NaN NaN NaN],...
        'cbar','caxis',caxislimits, 'vert',range);

elseif latency_type == -1
    [data,outsort,outtrials,limits,axhndls,erp,amps,cohers,cohsig,ampsig,allamps,...
        phaseangles,phsamp,sortidx,erpsig] = ...
        pop_erpimage(EEG,1, channel,[],[],smooth,1,{},[],'',...
        'yerplabel','Activation','limits',[plotrange erplim NaN NaN NaN NaN],...
        'cbar','caxis',caxislimits, 'vert',range);
end

if dosave
    EEG.data = EEG.data(:,:,sortidx);
    pop_saveset(EEG, 'filename', [setname '.set'], 'filepath', savepath);
end

%export figure
%specify options for exportfig here
opts = struct('Bounds','tight','Color','cmyk','FontSizeMax',15,'Width',30);
exportfig(gcf,[savename '.eps'],opts);

disp(['Mean onset latency = ' num2str(mean(latencies)) '; SD = ' num2str(std(latencies, 1)) '.']);
