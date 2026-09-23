function batchrun_mahan

delaystd = 4;
experiments = {'Srivas', 'Alon'};

%keydelay = [0 8 16 24];
keydelay = [0 24];
respdelay = 0;

cdOld = cd;

for e = 1:length(experiments)
    if strcmp(experiments{e}, 'Srivas')
        TwoRespFeatures = 0;
    elseif strcmp(experiments{e}, 'Alon')
        TwoRespFeatures = 1;
    else
        msgbox('something is wrong - cancelling')
        return
    end
    for k = 1:length(keydelay)
        name = sprintf('key%d_resp%d', keydelay(k), respdelay);
        path = ['/Users/mn361/Kent/Research/Final_ST2/Model/Variables/save_inputstrength/'...
            experiments{e} '/' name];
        if ~exist(path, 'dir')
            mkdir(path)
        end 
         cd(path)
         runModel(1,0,0,100,1,keydelay(k),respdelay,delaystd,TwoRespFeatures);
         savedata(name);
%         st2data2eeglab(name,0);
    end
end
cd(cdOld);
