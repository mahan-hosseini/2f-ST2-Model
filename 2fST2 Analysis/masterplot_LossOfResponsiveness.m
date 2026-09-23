%% PLOT LOSS OF RESPONSIVENESS PLOTS
function masterplot_LossOfResponsiveness(plotpath, varpath, saveplots)

% fixed vars
layer = 18;
keydelays = 0:6:24;
zoomXAx = 1;
blackred = 0;

% loop vars
VMs = [0 1];
neurons = [1 20];
responses = {'correct', 'post1'};

% % loop 1 - 1NeurDiffDelays
% for v = 1:length(VMs)
%     for n = 1:length(neurons)
%         for r = 1:length(responses)
%             VM = VMs(v);
%             neuron = neurons(n);
%             response = responses{r};
%             plot_1NeurDiffDelays(VM, layer, keydelays, neuron, response, zoomXAx, blackred, varpath, plotpath, saveplots)
%         end
%     end
% end

% loop 2 - plotActs1plot
for v = 1:length(VMs)
    VM = VMs(v);
    plot_ActDiffsDerivs1plot(VM, layer, keydelays, varpath, plotpath, saveplots)
end