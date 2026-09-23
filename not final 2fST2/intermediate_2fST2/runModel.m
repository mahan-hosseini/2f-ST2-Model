function runModel(singletarg,skeletal,blank,soarate,ExPostSynOnly,keyd,respd,randd,TwoRespFeatures,NeurExPostsyn)
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
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

global SOA onetarg don0t dot1 dot2 singletrial slimerp skel keydelay respdelay delaystd
global keystartval keyendval keystepres skelmask numtrials respstartval respendval respstepres
global TwoRespFeats  SaveNeurAct %MAHAN

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

%initialise random number generators
rand('twister', 5489);
randn('state', 0);

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
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%run the model
for run = 1:length(SOAtorun)
    SOA = SOAtorun(run);
    bigbattery
end
diary