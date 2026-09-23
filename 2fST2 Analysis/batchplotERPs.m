%% BATCHRUN plotERPs for all configs (exp1/2 & LPF yes/no)
function batchplotERPs(filepath,plotpath,plotSE)
% initialize stuff
experiments = {'Exp1', 'Exp2'};
all_LPFs = [0 1];
% loop through configs
for e = 1:length(experiments)
    this_exp = experiments{e};
    for l = 1:length(all_LPFs)
        LPF = all_LPFs(l);
        clear P3s N2pcs LPF_P3s LPF_N2pcs
        % determine what to load
        if strcmp(this_exp, 'Exp1')
            if LPF
%                 loadname = '25HzN2pc_LPF_ERP_structs.mat'; %exploring cutoff of 25Hz for N2pc LPF
                loadname = 'LPF_ERP_structs.mat';
            else
                loadname = 'ERP_structs.mat';
            end
        elseif strcmp(this_exp, 'Exp2')
            if LPF
%                 loadname = '25HzN2pc_LPF_ERP_structs_Exp2.mat';
                loadname = 'LPF_ERP_structs_Exp2.mat';
            else
                loadname = 'ERP_structs_Exp2.mat';
            end
        end
        % load it to struct first
        loadstr = load([filepath loadname]); 
        % extract from struct depending on whether we LPFed or not
        if LPF
            P3s = loadstr.LPF_P3s;
            N2pcs = loadstr.LPF_N2pcs;
        else
            P3s = loadstr.P3s;
            N2pcs = loadstr.N2pcs;
        end
        plotERPs(P3s, N2pcs, plotpath, LPF, plotSE)
    end
end
end