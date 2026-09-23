%%  PLOT_MAINRESULTS plots main results for a run of the 2fST2 conveniently at once and saves it to plotpath
function plot_mainresults(name,varpath,plotpath,saveplots,TwoRespFeatures, blastdisttoo)

%   1) Plot response distributions
plot_respdists(name,varpath,plotpath,saveplots,TwoRespFeatures)

%   2) Plot P3 & N2pc using plotAvActs_mahan
vERPs = {'P3', 'N2pc'};
layer = 13; % only used if vERP = 'Layer'!!!
VM = 0;
Srivas3Trace = 0;
smooth = 'yes'; % dont smooth for now 
% smooth = 'no';
for v = 1:length(vERPs)
    this_vERP = vERPs{v};
    plotAvActs_mahan(VM, name, this_vERP, smooth, layer, varpath, plotpath, saveplots, TwoRespFeatures, Srivas3Trace)
end

if blastdisttoo
    %   3) Plot blaster-firing latency-distributions
    if ~contains(varpath, '\Srivas\') && ~contains(varpath, '\Alon\')
        switch TwoRespFeatures
            case 0
                varpath = [varpath 'Srivas/'];
            case 1
                varpath = [varpath 'Alon/'];
        end
    end
    if ~exist([varpath name '/AvActArrayLayer_Blaster Out.mat'], 'file') % if we haven't yet, extract blasterout from name.mat
        transfer_modelmat2ArrayLayer(varpath, name, 13);
    end
    plot_blasterdistributions(name, varpath, plotpath, saveplots, TwoRespFeatures)
end
end

