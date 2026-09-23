function plotVERP(setname, condition)

EEG = pop_loadset('filename', [setname '.set']);

keepepochs = zeros(1,EEG.trials);
for epochnum=1:EEG.trials
    if strmatch(EEG.epoch(epochnum).eventtype, conditions, 'exact')
        keepepochs(epochnum) = 1;
    else
        keepepochs(epochnum) = 0;
    end
end

