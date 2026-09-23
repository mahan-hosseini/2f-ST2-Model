function batchplot_acttraces(lays2plot, vERP, varpath, plotpath, TwoRespFeatures, allnames, oneplot, zoomXAx, VMs)

plotmisses = 0;
plotSE = 1;
saveplots = 1;

% loop over length of all names & VMs
for v = 1:length(VMs)
    VM = VMs(v);
    for n = 1:length(allnames)
        name = allnames{n};
        for l = 1:length(lays2plot) % loop over all P3 layers
            layer = lays2plot(l);
            if oneplot
                plotActs1plot_mahan(name, vERP, layer, plotSE, plotmisses, zoomXAx, varpath, plotpath, saveplots, TwoRespFeatures, VM)
            elseif oneplot == 0
                plotActs_mahan(name, vERP, layer, plotSE, plotmisses, zoomXAx, varpath, plotpath, saveplots, TwoRespFeatures, VM)
            end
        end
    end
end
end