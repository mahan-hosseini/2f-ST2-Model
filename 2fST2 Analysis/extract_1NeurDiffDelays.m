%% extract_1NeurDiffDelays
%   extracts the same neuron @ a given layer for different delay conditions
%   (atm only supporting keydelay & layeracts (no vERPs) & cor/+1 responses
%   ==> Used in e.g. plot_1NeurDiffDelays

function extract_1NeurDiffDelays(VM, layer, keydelays, neuron, response, varpath, TwoRespFeatures)
%% Quick sanity check of response-input (would be easy to make this work for the other responses, but I couldn't see when I would use it when I wrote this)
if ~(strcmp(response, 'correct') || strcmp(response, 'post1'))
    disp('FUNC. ONLY SUPPORTS 0 & +1 RESPONSES AT THE MOMENT, CANCELLING!')
    return
end
if length(keydelays) ~= 5 % and also this....
    disp('FUNC. ONLY SUPPORTS EXACTLY 5 DIFF DELAYS ATM (bc of legend & defining colours using RGB) - FIX IT! CANCELLING!')
    return
end

%% Load stuff (one delay at a time and extract the neuron we need)
all_neurons = cell(length(keydelays),1); all_blasters = cell(length(keydelays),1); % initialize stuff
for d = 1:length(keydelays)
    name = ['key' num2str(keydelays(d)) '_resp0']; % what is this delay's name? [always keydelay]
    disp(['preparing ' num2str(keydelays(d)) 'ms keydelay...']);
    load([varpath name '/' name '.mat'])
    % quick sanity check if VM setting & varpath (i.e. stuff loaded) are correct
    if (VM == 0 && ~exist('ExPostsynFull_basic', 'var')) || (VM == 1 && ~exist('VMFull_basic', 'var')) ...
            || (VM == 2 && ~exist('InhibFull_basic', 'var')) || (VM == 3 && ~exist('LeakFull_basic', 'var')) ...
            || (VM == 4 && ~exist('ExciteFull_basic', 'var'))
        disp('MISMATCH BETWEEN VM & VARS LOADED BC. OF VARPATH! CANCELLING FUNCTION!');
        return
    end
    % What is the Array?
    if VM == 0
        TheArray = ExPostsynFull_basic;
        clear ExPostsynFull_basic % we just work with TheArray from here on
    elseif VM == 1
        TheArray = VMFull_basic;
        clear VMFullFull_basic
    elseif VM == 2
        TheArray = InhibFull_basic;
        clear InhibFull_basic
    elseif VM == 3
        TheArray = LeakFull_basic;
        clear LeakFull_basic
    elseif VM == 4
        TheArray = ExciteFull_basic;
        clear ExciteFull_basic
    end
    % Extract layer of interest of current neuron and blaster of this delay & response 
    [this_neuron, this_blaster] = extract_from_TheArray(name, TheArray, ExPostsynBat_basic, layer, neuron, response, varpath, TwoRespFeatures);
    % Assign this neuron & blaster to vars that have all delay's arrays
    %   ==> Note, % use cell-arrays here because different delays have different number 
    %       of trials of a given response, hence these arrays are not of the same size!
    all_neurons{d} = this_neuron; all_blasters{d} = this_blaster; 
end
% some strings we need
LayerName = getLayerName(layer);
switch neuron
    case 1
        NeuronName = 'Target - Unit';
    case 20
        NeuronName = '+1 - Unit';
end
switch VM
    case 0
        ActName = 'Act';
    case 1
        ActName = 'VM';
end
% Create FullName & save all_neurons & all_blasters
FullName = [ActName ' of ' NeuronName ' at ' LayerName ' for ' response ' Responses'];
save([varpath FullName '.mat'], 'all_neurons', 'all_blasters')
end

%% Local function: extract what we want from 'TheArray'
function [this_neuron, this_blaster] = extract_from_TheArray(name, TheArray, ExPostsynBat_basic, layer, neuron, response, varpath, TwoRespFeatures)
% some prep
retinadelay = 14;
onset_time = 900;
numtimepoints = size(TheArray,3);
samprate = 200;
numtrials = size(TheArray,1);
numlags = size(TheArray,2);
numlayers = size(TheArray,4);
numneurons = size(TheArray,5);
numtimepoints = numtimepoints + retinadelay; % add retina delay to tps

% extract this neuron's array
FullArray = zeros(numtrials, numlags, numtimepoints, 1, numneurons);
FullArray(:, :, retinadelay+1:end, 1, :) = TheArray(:, :, :, layer, :);
FullArray = permute(FullArray, [2, 1, 3, 4, 5]); % permute to make sure the size of this is lags x trials x tps
check_PadExPostSyn(FullArray,numlags); % sanity check - really make sure it's in the correct format
FullArray2 = reshape(squeeze(FullArray(:,:,:,1,:)), ... % FullArray2 has correct format (trials, tps, neurons)
    [size(FullArray,1) * size(FullArray,2), size(FullArray,3), ...
    size(FullArray,5)]);
FullNeuron = squeeze(FullArray2(:, :, neuron)); % extract neuron of interest
clear FullArray FullArray2

% extract Blaster, because we want to plot average blaster-firing latency
%
%   ==> IMPORTANT: EXTRACT BLASTER FROM ExPostsynBat_basic, not TheArray!!!
%
BlasterOut = zeros(numtrials, numlags,numtimepoints, 1); %only the first neuron is blaster-firing act.
BlasterOut(:, :, retinadelay+1:end) = squeeze(ExPostsynBat_basic(:, :, :, 13));
BlasterOut = permute(BlasterOut, [2 1 3]); % permute to make sure the size of this is lags x trials x tps
check_PadExPostSyn(BlasterOut,numlags); % sanity check - really make sure it's in the correct format
BlasterOut2 = reshape(squeeze(BlasterOut), [numtrials * numlags, ...
    numtimepoints]);
clear BlasterOut

% finally, throw out misses from FullNeuron & BlasterOut2
[marker, ~, keepepochs] = extract_responses(name, varpath, TwoRespFeatures);
% first, throw out misses
this_neuron = FullNeuron(keepepochs,:);
this_blaster = BlasterOut2(keepepochs,:);
% then, throw out trials that are not the response we want
if size(this_neuron,1) ~= length(marker)
    disp('THERE''S SOMETHING WRONG WITH YOUR MAKER - CANCELLING FUNC.')
    return
end
this_response = strcmp(marker, response); % gives logical indexes
this_neuron = this_neuron(this_response, :); % extract & done
this_blaster = this_blaster(this_response, :);
end