function runModel(singletarg,skeletal,blank,soarate,ExPostSynOnly,keyd,respd,randd,TwoRespFeatures,NeurExPostsyn,SrivasRNG)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%runs the model
%modify parameters in code to determine wich conditions, number of targets
%and SOA to run
%singletarget - 0 or 1
%skeletal - 0 or 1
%T1+blank - 0 or 1
%SOA - 50 or 100 or [50 100]
%ExPostSynOnly - 0 (saves all potential information (membrane potential, etc)) or
%1 (saves only excitatory postsynaptic potential
% keyd, respd and randd implemented by SRIVAS

% MAHAN: I included a readme_mahan.mat-file with some observations,
%   insights and notes that might be useful to read before using the 2f
%   (singletarget) version of the model.
%       (@yourself, mahan: you have to find it!)

% MAHAN: To replicate Vul, I added code in evaltargs & runRSVP to make the
%        model guess more often if more than 1 response type was bound to the
%        token (i.e., we have a multi-binding)
%        ==> For replicating Vul, we set the lat-inhib in response TFL to 
%            0 so that multbinds occur more often. This can be viewed as 
%            the analogue to human top-down flexibility due to task demands
%            (e.g., if humans know in advance that they have to guess more 
%            than once, they will "set their latinhib lower" than if they 
%            know they just have to report 1 letter)
%        ==> Note, setting response TFL's lateral inhibition has to occur
%            manually in architecture.m

% MAHAN: TwoRespFeatures - 0 or 1 
%   --> 0 
%       runs SRIVAS' original model in which
%       all response features met task demands (i.e. the response pathway has no
%       task-filter)
%   --> 1
%       runs MAHAN'S version which model's Alon Zivonys Experiment in
%       which only the target and the stimulus following it met task demands
%       (i.e. the +1 conjunction)
% MAHAN: NeurExPostsyn - 0 to 5
%   --> 0 
%       only saves the excitatory postsynaptic activation SUMMED across
%       layers (i.e. ExPostsynBat_basic)
%   --> 1
%       saves EACH NEURON'S excitatory postsynaptic activation for all
%       trials, lags and layers (i.e. ExPostsynFull_basic)
%       ==> This variable makes the resulting file about twice as big (~450
%           MB instead of 210) and makes running the model 4 times as slow (for
%           my machine it was 30min without and 2hrs with saving this var)
%   --> 2
%       saves Membrane potentials of all neurons, it's exactly how we do
%       things for saving excitatory postsynaptic potentials if this
%       variable is set to 2
%   --> 3
%       saves the channel potential of the inhibitory input for all neurons
%       (did this to explore a specific behaviour but left it in case
%       someone is interested in checking it for some other reason in the
%       future)
%   --> 4
%       like 3 but for leak input
%   --> 5
%       like 3 but for excitatory input
%   NOTE - I didn't implement a way in which MORE THAN ONE of these
%       would be stored as I thought that this would take too long to compute
%       and the variable would be huge - but it should be easy to change the
%       code to save both if you want (maybe including 'if this variable ==
%       5+' statements
%
% MAHAN: SrivasRNG - 0 or 1
%   --> 0 
%       Re-shuffles RNG in each run of the model. Important for running the
%       model multiple times (as is the case in runMultipleRuns) to get
%       more trials!
%   --> 1
%       Uses the RNG seed Srivas originally used 
%       Important if you want to see the impact of changing parameters
%       (stimulus input strengths etc. will be random on a trial-by-trial 
%       basis but identical over multiple runs!)
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

global SOA onetarg don0t dot1 dot2 singletrial slimerp skel keydelay respdelay delaystd
global keystartval keyendval keystepres skelmask numtrials respstartval respendval respstepres
global TwoRespFeats  SaveNeurAct GammaDist%MAHAN
% global BlasterBoost %MAHAN

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%These parameters determine which conditions are run.

slimerp = ExPostSynOnly;
%slimerp = 0;

skel = skeletal;

onetarg = singletarg;

singletrial = 0;

SOAtorun = soarate;

keydelay = keyd;
respdelay = respd;
delaystd = randd;

TwoRespFeats = TwoRespFeatures; %MAHAN: which version to run? 0 == Srivas' original
SaveNeurAct = NeurExPostsyn; %MAHAN: do we want to save individual neuron's excitatory postsyn. activaitons? 1 == yes

%Set to zero to skip this condition
don0t = 1;  %basic
dot1 = blank;   %T1+1 blank
dot2 = 0;   %T2+1 blank

%log i/o
if exist('runlog.txt', 'file')
    delete('runlog.txt');
end
diary('runlog.txt');

% %initialise random number generators
% MAHAN: Added SrivasRNG input which is 1 if you want to use the same RNG
%        seed that Srivas used in his fortunate conjunction paper (to have
%        comparability between different runs of the model) or 0 if you do not
%        want this - particularly useful for running the model multiple times (see
%        runMultipleRuns.m)
if SrivasRNG
    rand('twister', 5489);
    randn('state', 0);
else
    rng('shuffle', 'twister') % for runing the model multiple times (e.g. when replicating Vul)
end

if TwoRespFeatures
    disp('*** ACTIVE RESPONSE PATHWAY TASK FILTERING ***')
else
    disp('*** NO RESPONSE PATHWAY TASK FILTERING ***')
end

%input strength values
%psychreview values
% startval = .448;
% endval = .604;
% stepres = .012;
%distval = .5;

% this combo seems to work for behavioural and erp..
keystartval = 0.442;
keyendval = 0.61;
keystepres = .028;

% keystepres = .028;
% keystartval = 0.442+keystepres;
% keyendval = 0.61-keystepres;


respstartval = keystartval;
respendval = keyendval;
respstepres = keystepres;

% respstartval = 0.4;
% respendval = 0.9;
% respstepres = .05;

numtrials=1;

if skel
    keydistval = 0;
end

%MAHAN: Create a gamma distribution which we use to vary keydelay 
%       (simulating variability of the N2pc found by Zivony & Eimer)
%       (make the scale of the distribution depend on keyd-value)
%       (dist broader as keydelay increases)
if keydelay < 4 % since floor(3/2) will be 1 and we don't want scale to be negative (which would happen if keydelay is negative!)
    gamscale = 1;
else
    gamscale = floor(keydelay/2);
end

% MAHAN: Have shape also be modulated by keyd (because of RT's floor effect // ~RT-accuracy-tradeoff)
%        ==> Nonlinear space because we argue that impact of decreasing
%            keyfeature's salience is largest if salience was initially high
%            (eg. increasing keydelay by 2 reflects a larger effective difference
%            in salience if keyd was 0 (going from 0 to 2) than if it was 20
%            (going from 20 to 22). 
%        ==> We simulate that RT-acc tradeoff occurs in our model keydelay
%            space inbetween values of 11 to 30 (shapes go from 1 to 2 in this
%            space)
if keydelay <= 10 
    gamshape = 1;
elseif keydelay > 10 && keydelay <= 30
    shapespace = linspace(1,2,length(11:30));
    gamshape = shapespace(keydelay-10);
else 
    gamshape = 2;
end

disp(['Gamma Noise - Scale = ' num2str(gamscale) ' & Shape = ' num2str(gamshape)])

%   1) Create distribution using gamrnd
dist = gamrnd(gamshape,gamscale,500,1);
%   2) Find the median
med_dist = median(dist);
%   3) Find the distance between median and tauK
distance = keydelay - med_dist;
%   5) Check which one is larger and shift the distribution accordingly
%   ==> A note here:
%       If distance > 0, means tauK > med_dist, if distance < 0 means tauK < med_dist
%       Adding distance to the distribution always ends up doing the
%       correct thing, because if distance is negative, adding it will
%       subtract the distance, shifting the distribution (correctly) to the
%       left
dist_shifted = dist + distance;
%   6) Sanity check is median(dist_shifted) = tauK
if ~(round(median(dist_shifted)) == keydelay)
    disp('GAMMA DIST SANITY CHECK NOT PASSED, CHECK END OF RUNMODEL - CANCELLING')
    return
end
%   7) Assign dist_shifted as GammaDist 2 be used for sampling keyD-var
%       ==> De-median the distribution so it's centred around zero (and we
%           can just get a random sample of it and add that sample to tauK
%           in runRSVP)
GammaDist = dist_shifted - keydelay;
clear gamscale dist med_dist distance dist_shifted gamshape shapespace

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%run the model
for run = 1:length(SOAtorun)
    SOA = SOAtorun(run);
    bigbattery
end
diary