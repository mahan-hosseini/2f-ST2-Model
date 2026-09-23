function testModel(singletarg,skeletal,SOAtorun,T1value,T2value,basic,blank)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%runs the model
%modify parameters in code to determine wich conditions, number of targets
%and SOA to run
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

global SOA onetarg don0t dot1 dot2 singletrial T1val T2val skel slimerp
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%These parameters determine which conditions are run.  

%do this first
%global PresynapHistory ExPostsynHistory InhibPostsynHistory MembPotHistory BasicAccu

SOA = SOAtorun;
%set onetarg to 1 for one target
onetarg = singletarg;

skel = skeletal;

slimerp = 0;

T1val = T1value;
T2val = T2value;

%run a single trial for test purpose
singletrial = 1;

%Set to zero to skip this condition
don0t = basic;  %basic
dot1 = blank;   %T1+1 blank
dot2 = 0;   %T2+1 blank
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%run the model
bigbattery

