function runModel(singletarg,skeletal,blank,soarate,ExPostSynOnly,keyd,respd,randd)
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
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

global SOA onetarg don0t dot1 dot2 singletrial slimerp skel keydelay respdelay delaystd
global keystartval keyendval keystepres skelmask numtrials respstartval respendval respstepres
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