%% Find out firing latency of blaster as point of 50% AUC under vN2pc wave
%   1xtps vector, which is mean(BlasterOut,1) or a single trial;
function blaster_latency = blasterfiring(vN2pc)
    % 1st, standardize AUC to be 1
    area = trapz(vN2pc);
    z_vN2pc = vN2pc / area; 
    % 2nd, find latency at which area is 0.5
    areasum = 0;
    for i = 1:length(z_vN2pc)
        areasum = areasum + z_vN2pc(i);
        if areasum >= 0.5
            blaster_latency = i;
            break
        end
    end
end