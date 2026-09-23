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

if nargin < 2
    disp('Not enough arguments');
    return;
end

%loadpath = 'save_before_reducing_strength_range/';
loadpath = 'current/';
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
disp('Extracting virtual P3..');
vP3SeparateLags = reshape(squeeze(sum(PadExPostSyn(:,:,:,[3 4 6 8 17 18 21]),4)), ...
    [size(PadExPostSyn,1) * size(PadExPostSyn,2), size(PadExPostSyn,3)]);

% vP3SeparateLags = reshape(squeeze(sum(PadExPostSyn(:,:,:,[9]),4)), ...
%     [size(PadExPostSyn,1) * size(PadExPostSyn,2), size(PadExPostSyn,3)]);

%vP3 is timepoints, trials
vP3 = zeros(numtimepoints,numtrials*numlags);

vP3 = permute(vP3SeparateLags,[2 1]);
%assign to vERP
vERP(1,:,:) = vP3;

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

for i = 1:size(vERP,3)
    if allkey(i) > 0
        if allresp(i) == 0
            marker = 'miss';
            shift = 0;
        elseif allresp(i) == 1
            marker = 'correct';
            shift = 0;
        elseif allresp(i) - targetpos == -2
            marker = 'pre2';
            shift = 200;
        elseif allresp(i) - targetpos == -1
            marker = 'pre1';
            shift = 100;
        elseif allresp(i) - targetpos == 0
            marker = 'post1';
            shift = -100;
        elseif allresp(i) - targetpos == 1
            marker = 'post2';
            shift = -200;
        end
        shift = shift / 5;
    else
        marker = 'miss';
        shift = 0;
    end

    if (~exist('conditions', 'var') && ~strcmp(marker,'miss')) || ...
        (exist('conditions', 'var') && ~isempty(strmatch(marker, conditions, 'exact')))
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

for i = 1:EEG.trials
    EEG.event(i) = struct('type',marker,'latency',contlat(i),'points',1,...
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
