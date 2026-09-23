function st2data2eeglab(setname, resplocked, conditions)
%load st2model data and save for eeglab usage
%creates following vERP channels
%1 - vP3
%2 - vN2pc
%3 - vSSVEP
%4 - key feature P3 (only if PadT1ExPostsyn is available)
%5 - Input
%6 - Binding pool gate
%add event markers

eeglab % start func, adds stuff to working dir

% MAHAN:
%       It might be worth it to read a couple of notes I wrote in runModel.m 
%       about using this model in its singletarget version 
% MAHAN: 
%       Changed a bit that implements info about markers (i.e. condition)
%       to EEG.event.type structure so we can split it up into multiple .set
%       files later on.


if nargin < 2
    disp('Not enough arguments');
    return;
end

%loadpath = 'save_before_reducing_strength_range/';
% loadpath = 'current/'; %MAHAN: got rid of this, changed it to cdeeglab
loadpath = [cd '/']; 
disp(['Loading ' loadpath setname '..']);
load([loadpath setname]);

retinadelay = 14;
onset_time = 900;
numtimepoints = size(ExPostsynBat_basic,3);

%samprate = numtimepoints/segmtime;
samprate = 200;

numtrials = size(ExPostsynBat_basic,1);
numlags = size(ExPostsynBat_basic,2);
numlayers = size(ExPostsynBat_basic,4);

%add retina delay to vERP traces
%ExPostSyn is trials, lags, timepoints, layers
disp('Adding retina delay to vERP traces..');
numtimepoints = numtimepoints + retinadelay;
PadExPostSyn = zeros(numtrials,numlags,numtimepoints,numlayers);
%no retina delay for input layer
PadExPostSyn(:,:,1:(end-retinadelay),1) = ExPostsynBat_basic(:,1:numlags,:,1);
%retina delay for other layers
PadExPostSyn(:,:,retinadelay+1:end,2:end) = ExPostsynBat_basic(:,1:numlags,:,2:end);
PadExPostSyn = permute(PadExPostSyn, [2 1 3 4]);

if exist('T1ExPostsynHistory', 'var')
    PadT1ExPostsyn = zeros(numtrials,numlags,numtimepoints,numlayers);
    PadT1ExPostsyn(:,:,retinadelay+1:end,:) = T1ExPostsynHistory(:,:,:,:);
    PadT1ExPostsyn = permute(PadT1ExPostsyn, [2 1 3 4]);
end

vERP = zeros(6,numtimepoints,numtrials*numlags);

%%%%%%%%%%%%%%%%%%%%%%%%virtual P3 extraction%%%%%%%%%%%%%%%%%%%%%%%%%%%%


% vP3SeparateLags = reshape(squeeze(sum(PadExPostSyn(:,:,:,[3 4 6 8 17 18 21]),4)), ...
%     [size(PadExPostSyn,1) * size(PadExPostSyn,2), size(PadExPostSyn,3)]);
% 
% % vP3SeparateLags = reshape(squeeze(sum(PadExPostSyn(:,:,:,[9]),4)), ...
% %     [size(PadExPostSyn,1) * size(PadExPostSyn,2), size(PadExPostSyn,3)]);
% 
% %vP3 is timepoints, trials
% vP3 = zeros(numtimepoints,numtrials*numlags);
% 
% vP3 = permute(vP3SeparateLags,[2 1]);
%assign to vERP

disp('Extracting virtual P3..');
vP3 = local_compute_vP3(PadExPostSyn); %MAHAN: weighs the different layers according to their relevance
vERP(1,:,:) = vP3';

%%%%%%%%%%%%%%%%%%%%%%%%virtual N2pc extraction%%%%%%%%%%%%%%%%%%%%%%%%%%%%
disp('Extracting virtual N2pc..');
vN2pcSeparateLags = reshape(squeeze(PadExPostSyn(:,:,:,13)), ...
    [size(PadExPostSyn,1) * size(PadExPostSyn,2), size(PadExPostSyn,3)]);

%vN2pc is timepoints, trials
vN2pc = zeros(numtimepoints,numtrials*numlags);

vN2pc = permute(vN2pcSeparateLags,[2 1]);

%assign to vERP
vERP(2,:,:) = vN2pc;

%%%%%%%%%%%%%%%%%%%%%%%%virtual ssVEP extraction%%%%%%%%%%%%%%%%%%%%%%%%%%%%
disp('Extracting virtual ssVEP..');
vSSVEPSeparateLags = reshape(squeeze(sum(PadExPostSyn(:,:,:,[1 2]),4)), ...
    [size(PadExPostSyn,1) * size(PadExPostSyn,2), size(PadExPostSyn,3)]);

%vSSVEP is timepoints, trials
vSSVEP = zeros(numtimepoints,numtrials*numlags);

vSSVEP = permute(vSSVEPSeparateLags,[2 1]);

%assign to vERP
vERP(3,:,:) = vSSVEP;

%%%%%%%%%%%%%%%%%%%%%%%%Key feature P3 extraction%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if exist ('PadT1ExPostsyn', 'var')
    disp('Extracting key pathway P3..');
    KeyP3SeparateLags = reshape(squeeze(sum(PadT1ExPostsyn(:,:,:,[3 4 6 8]),4)), ...
        [size(PadT1ExPostsyn,1) * size(PadT1ExPostsyn,2), size(PadT1ExPostsyn,3)]);

    %KeyP3 is timepoints, trials
    KeyP3 = zeros(numtimepoints,numtrials*numlags);

    KeyP3 = permute(KeyP3SeparateLags,[2 1]);
    %assign to vERP
    vERP(4,:,:) = KeyP3;
else
    disp('Extracting key pathway P3..');
    KeyP3SeparateLags = reshape(squeeze(sum(PadExPostSyn(:,:,:,[3 4 6 8]),4)), ...
        [size(PadExPostSyn,1) * size(PadExPostSyn,2), size(PadExPostSyn,3)]);

    %KeyP3 is timepoints, trials
    KeyP3 = zeros(numtimepoints,numtrials*numlags);

    KeyP3 = permute(KeyP3SeparateLags,[2 1]);
    %assign to vERP
    vERP(4,:,:) = KeyP3;
end    

%%%%%%%%%%%%%%%%%%%%%%%%Input Activation extraction%%%%%%%%%%%%%%%%%%%%%%%%%%%%
disp('Extracting Input Activation..');
InputSeparateLags = reshape(squeeze(PadExPostSyn(:,:,:,1)), ...
    [size(PadExPostSyn,1) * size(PadExPostSyn,2), size(PadExPostSyn,3)]);

%Input is timepoints, trials
Input = zeros(numtimepoints,numtrials*numlags);

Input = permute(InputSeparateLags,[2 1]);
%assign to vERP
vERP(5,:,:) = Input;

%%%%%%%%%%%%%%%%%%%%%%%%Token trace extraction%%%%%%%%%%%%%%%%%%%%%%%%%%%%
disp('Extracting token trace..');
bindpoolSeparateLags = reshape(squeeze(sum(PadExPostSyn(:,:,:,[9]),4)), ...
    [size(PadExPostSyn,1) * size(PadExPostSyn,2), size(PadExPostSyn,3)]);

%binding pool gate is timepoints, trials
bindpool = zeros(numtimepoints,numtrials*numlags);

bindpool = permute(bindpoolSeparateLags,[2 1]);
%assign to vERP
vERP(6,:,:) = bindpool;

disp('Creating event markers for selected trials..');

allkey = reshape(permute(T1batterydata, [1 5 4 3 2]), [1, size(T1batterydata, 2) * size(T1batterydata, 3) ...
    * size(T1batterydata, 4) * size(T1batterydata, 5)]);

allresp = reshape(permute(T1respdata, [1 5 4 3 2]), [1, size(T1respdata, 2) * size(T1respdata, 3) ...
    * size(T1respdata, 4) * size(T1respdata, 5)]);

%HARDCODED: position of target
targetpos = 20;
keepepochs = [];
marker{size(vERP, 3)} = []; % initialize marker cell array

for i = 1:size(vERP,3)
    if allkey(i) > 0
        if allresp(i) == 0
            marker{i} = 'miss'; %MAHAN: changed marker to marker{i} to make things easier
            shift = 0;
        elseif allresp(i) == 1
            marker{i} = 'correct';
            shift = 0;
        elseif allresp(i) - targetpos == -2
            marker{i} = 'pre2';
            shift = 200;
        elseif allresp(i) - targetpos == -1
            marker{i} = 'pre1';
            shift = 100;
        elseif allresp(i) - targetpos == 0
            marker{i} = 'post1';
            shift = -100;
        elseif allresp(i) - targetpos == 1
            marker{i} = 'post2';
            shift = -200;
        end
        shift = shift / 5;
    else
        marker{i} = 'miss';
        shift = 0;
    end
    if (~exist('conditions', 'var') && ~strcmp(marker{i},'miss')) || ...
        (exist('conditions', 'var') && ~isempty(strcmp(marker{i}, conditions)))
        if resplocked
            if shift > 0
                vERP(:,shift+1:end,i) = vERP(:,1:end-shift,i);
                vERP(:,1:shift,i) = 0;
            elseif shift < 0
                shift = abs(shift);
                vERP(:,1:end-shift,i) = vERP(:,shift+1:end,i);
                vERP(:,end-shift+1:end,i) = 0;
            end
        end
        keepepochs = [keepepochs i];
    end
end

vERP = vERP(:,:,keepepochs);

tmpmarker = marker; %MAHAN: select only markers of epochs we are keeping
marker = cell(1, length(keepepochs));
for i = 1:length(keepepochs)
    marker{i} = tmpmarker{keepepochs(i)};
end

%%%%%%%%%%%%%%%%%%%%%import vERP into EEGlab%%%%%%%%%%%%%%%%%%%%%%%%%%
disp('Importing vERP to eeglab..');
xmin = -1 * (onset_time / 1000);
EEG = pop_importdata( 'dataformat', 'matlab', 'data', vERP, 'setname', setname , ...
    'srate',samprate, 'subject', 'ST2', 'pnts',numtimepoints, ...
    'xmin',xmin, 'nbchan',size(vERP,1));
EEG.trials = size(EEG.data,3);
EEG.event = struct('type',[],'latency',[],'points',[],'description',[],'channelnumber',[],'epoch',[]);
% %%%%%%%%%%%%%%%%%%%%%add Event markers%%%%%%%%%%%%%%%%%%%%%%%%%%

lats = zeros(1,EEG.trials);
epochs = 1:EEG.trials;
contlat = eeg_lat2point(lats,epochs,samprate,[EEG.xmin EEG.xmax]);

%MAHAN: Add marker in EEG.event.type structure to inform about condition of
%trials (so we can split into seperate .set files later, e.g.)
for i = 1:EEG.trials
    EEG.event(i) = struct('type',marker{i},'latency',contlat(i),'points',1,...
        'description','','channelnumber',0,'epoch',i);
end
EEG = eeg_checkset( EEG, 'eventconsistency');

if exist('conditions', 'var')
    setname = [setname '_' cell2mat(conditions)];
end

if resplocked == true
    setname = [setname '_resplock'];
end

disp(sprintf('Saving %s.set with %d trials', setname, EEG.trials));
pop_saveset( EEG,  'filename', [setname '.set']);
end

function vP3 = local_compute_vP3(PadExPostSyn)
%% COMPUTE vP3 from PadExPostSyn using 'scaling' to weigh different layers accordingly
%   -----------------------------------------------------------------------
%   OUTPUT --
%   vP3 is size trials x timepoints (and when used in my other
%   functions usually still includes misses!! make sure to throw them out
%   later!)
%   -----------------------------------------------------------------------

%                       P3 exploration
%   --- THESE VALUES MEAN ALL LAYERS CONTRIBUTE ROUGHLY THE SAME ---
%   ==> i.e. all around .144 before weighing differently below (line 67+)
%   ==> max amp normal values are based on my model w key-delay (key24_resp0 & TwoRespFeats = 1)
KeyItemW = 2.4;  % max amp normal = .06
KeyTFLW = 0.9; % max amp normal = .16
KeyBindGTW = 9; % ... = 0.016
TokenGTW = 0; % I think token gate was 0 anyways, whatever, multiply by 0 to make it 0
RespItemW =  2.8; % max amp normal = 0.05
RespTFLW = 1.2; % max amp normal = 0.12
RespBindGT = 16; % max amp normal = 0.009
P3weights = [KeyItemW, KeyTFLW, KeyBindGTW, TokenGTW, ...
    RespItemW, RespTFLW, RespBindGT];
% if we want to explore P3 weightings, first extract each layer's
% activation and put it in a variable
layer = 3;
KeyItem = reshape(squeeze(PadExPostSyn(:,:,:,layer)), ...
    [size(PadExPostSyn,1) * size(PadExPostSyn,2), size(PadExPostSyn,3)]);
layer = 4;
KeyTFL = reshape(squeeze(PadExPostSyn(:,:,:,layer)), ...
    [size(PadExPostSyn,1) * size(PadExPostSyn,2), size(PadExPostSyn,3)]);
layer = 6;
KeyBindGT = reshape(squeeze(PadExPostSyn(:,:,:,layer)), ...
    [size(PadExPostSyn,1) * size(PadExPostSyn,2), size(PadExPostSyn,3)]);
layer = 8;
TokenGT = reshape(squeeze(PadExPostSyn(:,:,:,layer)), ...
    [size(PadExPostSyn,1) * size(PadExPostSyn,2), size(PadExPostSyn,3)]);
layer = 17;
RespItem = reshape(squeeze(PadExPostSyn(:,:,:,layer)), ...
    [size(PadExPostSyn,1) * size(PadExPostSyn,2), size(PadExPostSyn,3)]);
layer = 18;
RespTFL = reshape(squeeze(PadExPostSyn(:,:,:,layer)), ...
    [size(PadExPostSyn,1) * size(PadExPostSyn,2), size(PadExPostSyn,3)]);
layer = 21;
RespBindGT = reshape(squeeze(PadExPostSyn(:,:,:,layer)), ...
    [size(PadExPostSyn,1) * size(PadExPostSyn,2), size(PadExPostSyn,3)]);
%   --- ENTRIES IN P3WEIGHTS RESEMBLE ROUGHLY SAME CONTRIBUTION ----
%   ---               TO vP3 FROM EACH LAYER!                   ----


% NOW WEIGHT layers of the P3 (notes in masterscript_2fST2.m)
KeyItemS = 0.3;
KeyTFLS = 2;
KeyBindGTS = 3;
TokenGTS = 0;
RespItemS = 0.3;
RespTFLS = 2;
RespBindGTS = 3;
scaling = [KeyItemS, KeyTFLS, KeyBindGTS, TokenGTS, ...
    RespItemS, RespTFLS, RespBindGTS];

% then multiply by weights set & scaling factor
KeyItem = KeyItem * P3weights(1) * scaling(1);
KeyTFL = KeyTFL * P3weights(2)  * scaling(2);
KeyBindGT = KeyBindGT * P3weights(3)  * scaling(3);
TokenGT = TokenGT * P3weights(4)  * scaling(4);
RespItem = RespItem * P3weights(5)  * scaling(5);
RespTFL = RespTFL * P3weights(6)  * scaling(6);
RespBindGT = RespBindGT * P3weights(7)  * scaling(7);
% finally sum them up
%ActTraces = sum(KeyItem, KeyTFL, KeyBindGT, TokenGT, RespItem, RespTFL, RespBindGT);
vP3 = KeyItem + KeyTFL + KeyBindGT + TokenGT + RespItem + RespTFL + RespBindGT;

end
