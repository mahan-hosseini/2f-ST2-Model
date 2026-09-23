function transfer_modelmat2ArrayLayer(varpath, name, whichlayers)

% if varpath is not set to lead to keyx_respx, try concatenating first before failing below
if ~contains(varpath, name)
    varpath = [varpath name '/'];
end

% cd to varpath (this func needs to be in cd where the name_matfile is)
cdOld = cd; % to cd back to it later
cd(varpath);

% start with a little sanity check whether everything is fine
thisdir = cd;
if ~contains(thisdir, name)
    disp('CHECK CD AND NAME! CANCELLING FUNCTION!')
    return
else
    disp('SANITY CHECK PASSED - TRANSFERRING FILES')
end

% load the matfile
load([name '.mat'])

% some vars
retinadelay = 14;
% check if VM or Act
if exist('ExPostsynFull_basic', 'var')
    VM = 0;
    TheArray = ExPostsynFull_basic;
elseif exist('VMFull_basic', 'var')
    VM = 1;
    TheArray = VMFull_basic;
else
%   ==> This is a bit weird because we don't have individual neurons, 
%       but we need this for cases in which we are not interested in individual 
%       neurons, but still would like to plot the blasterdistributions
    VM = 2; % 2 == averaged 
    TheArray = ExPostsynBat_basic;
end
numtrials = size(TheArray,1);
numlags = size(TheArray,2);
if ndims(TheArray) > 4
    numneurons = size(TheArray,5);
    AverageAct = 0; % need this to see if we are using an averaged array
else
    AverageAct = 1;
end
for l = 1:length(whichlayers)
    % which layer to do
    layer = whichlayers(l);
    disp(['CURRENTLY TRANSFERRING ' getLayerName(layer)])
    % initialize
    if layer == 1
        numtimepoints = size(TheArray,3);
    else
        numtimepoints = size(TheArray,3) + retinadelay;
    end
    if AverageAct
        PadExPostSyn = zeros(numtrials,numlags,numtimepoints,1);
        if layer == 1
            PadExPostSyn(:, :, :, 1) = TheArray(:, :, :, layer);
        else
            PadExPostSyn(:, :, retinadelay+1:end, 1) = TheArray(:, :, :, layer);
        end
        % permute to make sure the size of this is lags x trials x tps
        PadExPostSyn = permute(PadExPostSyn, [2, 1, 3, 4]);
        check_PadExPostSyn(PadExPostSyn,4); % sanity check - really make sure it's in the correct format
        ActArrayLayer = reshape(squeeze(PadExPostSyn(:,:,:,1,:)), ...
            [size(PadExPostSyn,1) * size(PadExPostSyn,2), size(PadExPostSyn,3)]);
        ActArrayLayer = squeeze(ActArrayLayer);
    else
        PadExPostSyn = zeros(numtrials, numlags, numtimepoints, 1, numneurons);
        if layer == 1
            PadExPostSyn(:, :, :, 1, :) = TheArray(:, :, :, layer, :);
        else
            PadExPostSyn(:, :, retinadelay+1:end, 1, :) = TheArray(:, :, :, layer, :);
        end
        % permute to make sure the size of this is lags x trials x tps
        PadExPostSyn = permute(PadExPostSyn, [2, 1, 3, 4, 5]);
        check_PadExPostSyn(PadExPostSyn,4); % sanity check - really make sure it's in the correct format
        ActArrayLayer = reshape(squeeze(PadExPostSyn(:,:,:,1,:)), ...
            [size(PadExPostSyn,1) * size(PadExPostSyn,2), size(PadExPostSyn,3), ...
            size(PadExPostSyn,5)]);
        ActArrayLayer = squeeze(ActArrayLayer);
    end
    layname = getLayerName(layer);
    switch VM
        case 0
            save(['ActArrayLayer_' layname '.mat'], 'ActArrayLayer')
            clear ActArrayLayer
        case 1
            VMArrayLayer = ActArrayLayer;
            save(['VMArrayLayer_' layname '.mat'], 'VMArrayLayer')
            clear VMArrayLayer
        case 2
            AvActArrayLayer = ActArrayLayer;
            save(['AvActArrayLayer_' layname '.mat'], 'AvActArrayLayer')
            clear AvActArrayLayer
    end
end

% Now, save only the responses as _responly .matfile for comparedelays_singleunit
save([name '_responly.mat'], 'T1batterydata', 'T1respdata')

% cd back to cdOld
cd(cdOld);

% we are done
disp('DONE')

end