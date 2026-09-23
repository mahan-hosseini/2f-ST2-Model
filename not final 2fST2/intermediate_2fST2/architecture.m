function architecture
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%This function  sets up parameters used by the model
%and defines the connectivity
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
global BIAS LEAK DT_VM EE EI EL GAMMA THETA NUMLAYERS NUMNEURONS NUMWM TDUK TDUR TDUWEIGHT STARTVAL NUMINPUTS THETA2 THETA3
global Weightcount Weightlist
global WMBIAS NUMNEURONSBYLAYER NUMTARGS NUMDISTRACTORS NUMBINDERS SOA NUMRESPBINDERS
global Weightparams Weightindex WMNEGBIAS  itoken1 itoken2 itoken3 itoken4 skel
global TwoRespFeats %MAHAN

%This will be the weight matrix, which we rebuild every time we run the
%model
%This is inefficient yes, but the vast majority of computation is consumed
%by running the model
%**************************************************************************
%parameters

% MAHAN:
%   It might be worth it to read a couple of notes I wrote in runModel.m 
%   about using this model in its singletarget version 

%SRIVAS
NUMLAYERS = 22;   % number of layers in the network
%number of possible items in the RSVP stream
%10 targets and 10 distractors
NUMDISTRACTORS = 15;
NUMTARGS = 10;

NUMWM = 4;  % number of tokens

%function of each layer, and number of nodes
%N = 20, the number of items (10 targets, 10 distractors), NUMBINDERS = 40, NUMWM = 4
%1 Input                NUMNEURONS
%2 Masking layer        NUMNEURONS
%3 Item                 NUMNEURONS
%4 Task Filtered Layer(TFL) NUMNEURONS
%5 TFL shutoff          NUMNEURONS
%6 Binder gate              NUMBINDERS
%7 Binder trace          NUMBINDERS
%8 Token gate             NUMWM
%9 Token trace           NUMWM
%10 Item shutoff        NUMNEURONS
%11 Blaster In            1
%12 Blaster In Shutoff     1
% 13  Blaster Out                    1
% 14  Blaster Out shutoff            1

%SRIVAS

%15 Input                NUMNEURONS
%16 Masking layer        NUMNEURONS
%17 Item                 NUMNEURONS
%18 Task Filtered Layer(TFL) NUMNEURONS
%19 TFL shutoff          NUMNEURONS
%20 Item Shutoff         NUMNEURONS
%21 Binder gate          NUMNEURONS
%22 Binder trace         NUMNEURONS
PATHWAY2 = 15:22;

NUMNEURONS = NUMDISTRACTORS + NUMTARGS;
%the size of the binding pool is number of targets * number of tokens
NUMBINDERS = NUMWM*NUMTARGS;
%SRIVAS
NUMRESPBINDERS = NUMWM*NUMNEURONS;

%in lower stages, 1 neuron per layer per item
NUMINPUTS = NUMNEURONS;
NUMNEURONSBYLAYER  = [NUMNEURONS,NUMNEURONS,NUMNEURONS,NUMNEURONS,NUMNEURONS,NUMBINDERS,NUMBINDERS,NUMWM,NUMWM,NUMNEURONS,1,1,1,1,NUMNEURONS,NUMNEURONS,NUMNEURONS,NUMNEURONS,NUMNEURONS,NUMNEURONS,NUMRESPBINDERS,NUMRESPBINDERS];

Weightindex = zeros(NUMLAYERS,NUMLAYERS,NUMRESPBINDERS,NUMRESPBINDERS);
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%Parameters
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
BIAS(1:NUMLAYERS) = 0.0;
%BIAS(3) = 0.0001; %was -.0003
% MAHAN: Got rid of excitation (i.e. positive bias) in key item layer.. doesn't change much
% except biasing a high keydelay value because the period without a stream is longer
% which means inflated VMs of neurons before the stream starts = easier to
% reach threshold
BIAS(3) = 0;

%SRIVAS
BIAS(17) = -.0003; %was -.0003
%BIAS(17) = 0;

%rate of change parameter, how fast does the neuron's memb_pot approach its
%steady state value
DT_VM(1:NUMLAYERS) = 1.2;

%SRIVAS
DT_VM(PATHWAY2) = 1.2;
%DT_VM(17) = 0.9; % low response strength
%DT_VM(17) = 1.5; % high response strength

%excitatory, inhibitory and Leak reversal potentials.
EE(1:NUMLAYERS) = 3;
EI(1:NUMLAYERS) = -.2;
EL(1:NUMLAYERS) = 0;
EI(11) = 0;

% Gamma controls the shape of the neurons' output functions
% Theta is the threshold
% Neurons have three thresholds: Theta, Theta2 and Theta3
GAMMA(1:NUMLAYERS) = 5;
THETA(1:NUMLAYERS) = 0.15;
THETA2(1:NUMLAYERS) = 0.4;
THETA3(1:NUMLAYERS) = .5;
THETA2(13) = 0.48;
THETA3(13) = 0.7;
THETA3(3) = .25;
THETA3(6) = .5;
THETA3(4) = .52;
THETA3(10) = .45;
%THETA3(3) = .3;

%SRIVAS
THETA(3) = 0.13; %SRIVAS was 0.15
THETA(4) = 0.25; %SRIVAS was 0.15
THETA(18) = .35; %SRIVAS was 0.15
THETA3(18) = .52;
THETA3(17) = .25; %SRIVAS was 0.25
THETA3(20) = .45; %SRIVAS was 0.45
THETA3(21) = .3; %SRIVAS was .5
THETA3(19) = .2; %SRIVAS was .5

%membrane potentials at timestep 1.
STARTVAL(1:NUMLAYERS) = 0;

%leak current strength
LEAK(1:NUMLAYERS) = .07;
LEAK(2) = .01;
LEAK(3) = .04;
LEAK(5) = .02;
LEAK(6) = .07;
LEAK(7) = .01;
LEAK(9) = .01;
LEAK(10) = .02;

%SRIVAS
LEAK(4) = .0715; %SRIVAS .07
LEAK(16) = .01;
LEAK(17) = .04; %SRIVAS was .04
LEAK(19) = .02;
LEAK(20) = .02;
LEAK(21) = .07;
LEAK(22) = .01;
LEAK(18) = .07; %SRIVAS was .07

%ordered bias applied to the WM Gates to allow a winner of the competition.
%both positive and negative bias are used to rapidly pin the membrane
%potential after either suppression or excitement
WMBIAS = [.01,.01,.01,.01];
WMNEGBIAS = [-.014,-.015,-.016,-.017];

%**************************************************************************

%weightset(source,dest,type)
%weight types
%type 1 = one to one
%type 2 = all to all
%type 3 = notched layerwide
NUMWEIGHTTYPES = 3;
weightset = zeros(NUMLAYERS,NUMLAYERS,NUMWEIGHTTYPES);


%input to masking layer
if(SOA == 100)
    weightset(1,2,1) = .023; %psychreview.022; changed to get T1 reduction with new resolution
elseif(SOA == 50)
    weightset(1,2,1) = .058; %psychreview.05; this change gives us crossover for easy hard and good behavioural - % before blaster change .0605
end
%forward masking inhibition
weightset(1,2,3) = -.105;
%lateral inhibition masking layer
weightset(2,2,3) = -.06;
%masking to item layers
weightset(2,3,1) = .014;
%masking to TFL
weightset(2,4,1) = .000;
%item to TFL
weightset(3,4,1) = .013;%SRIVAS - was 0.015
%item recurrent excitation
weightset(3,3,1) = .0095;
%TFL recurrent excitation
weightset(4,4,1) = .022;
%TFL off
weightset(5,5,1) = .01;  %.003 is the limit for self sustain
%Item off
weightset(10,10,1) = .0095;  %.003 is the limit for self sustain
%Item to off
weightset(3,10,1) = 0.02;   %excite the shutoff %SRIVAS was 0.02
%Off to Item
weightset(10,3,1) = -.15;    %shutoff
%TFL to off
weightset(4,5,1) = 0.0075;   %excite the shutoff %SRIVAS was 0.0075
%Off to TFL
weightset(5,4,1) = -.15;    %shutoff %SRIVAS was -.12
%Token gate to trace
weightset(8,9,1) = .0055;
%Token trace to gate
weightset(9,8,1) = -.6;
%Token trace recurrent excitation
weightset(9,9,1) = .06;
if skel %blaster triggered by masking layer
    weightset(2,11,2) = .02003;
else %normal RSVP TFL triggers blaster
    %TFL to Blaster in %SRIVAS this was 0.02003
    weightset(4,11,2) = .02803; %0.018;% <- old value made this change to have equal blaster for seen and missed
end
%Blaster In to Blaster out
weightset(11,13,2) = 4;
%Blaster Out to TFL
weightset(13,4,2) = .8;
%Blaster out to item
weightset(13,3,2) = .3;
%Blaster out to off
weightset(13,14,2) =.5;
%Blaster out lateral excitation
weightset(13,13,2) =.04;
%Off to Blaster out
weightset(14,13,2) =-1;
%Blaster In to Off
weightset(11,12,1) = 5;
%Blaster off recurrent excitation
weightset(12,12,1) = .0112;%old value .01 - this change needed to prevent blaster from firing twice in blank condition

%Off to Blaster In
weightset(12,11,1) = -1;
%Binding gate to blaster in off
% Inhibiting the blaster during activation of the binding pool
weightset(6,12,2) = .01;
%Binding gate to trace
weightset(6,7,1) = .0039;
%Binding trace to gate
weightset(7,6,1) = -.05; %SRIVAS was -.05
%Binding trace recurrent excitation
weightset(7,7,1) = .01;

%SRIVAS
%input to masking layer
if(SOA == 100)
    weightset(15,16,1) = .023; %SRIVAS was .023 %psychreview.022; changed to get T1 reduction with new resolution
elseif(SOA == 50)
    weightset(15,16,1) = .058; %psychreview.05; this change gives us crossover for easy hard and good behavioural - % before blaster change .0605
end
%forward masking inhibition
weightset(15,16,3) = -.105;
%lateral inhibition masking layer
weightset(16,16,3) = -.06;
%masking to item layers
weightset(16,17,1) = .014; %SRIVAS was .014
%masking to TFL
weightset(16,18,1) = .000;
%item to TFL
weightset(17,18,1) = .015; %SRIVAS was .015
%item recurrent excitation
weightset(17,17,1) = .0095;
%TFL recurrent excitation
weightset(18,18,1) = .022;
%TFL off
weightset(19,19,1) = .01;  %.003 is the limit for self sustain
%Item off
weightset(20,20,1) = .0095;  %.003 is the limit for self sustain
%Item to off
weightset(17,20,1) = 0.02;   %excite the shutoff SRIVAS was .02





%Off to Item
% weightset(20,17,1) = -.15;    %shutoff %SRIVAS was -0.15
%MAHAN: Shutting off the off-node here
weightset(20,17,1) = 0;   




%TFL to off
weightset(18,19,1) = 0.01;   %excite the shutoff %SRIVAS was .0075
%Off to TFL
weightset(19,18,1) = -.5;    %shutoff %SRIVAS was -.12
%Blaster Out to TFL
weightset(13,18,2) = 0.8; %SRIVAS was 0.8
%Blaster out to item
weightset(13,17,2) = .3;

%Binding gate to blaster in off
% Inhibiting the blaster during activation of the binding pool
weightset(21,12,2) = .01;
%Binding gate to trace
weightset(21,22,1) = .01; %SRIVAS was 0.0039
%Binding trace to gate
weightset(22,21,1) = -.05; %SRIVAS was -.05
%Binding trace recurrent excitation
weightset(22,22,1) = .01;




%response lateral inhibition
weightset(18,18,3) = -.05; 





% Saturating weights have an output function that can't go past this value.
% Low Saturation values makes them behave in a nearly binary fashion (on or off)  The default
% value is 1.0
% This binary behavior should be eventually reimplemented as increased
% GAMMA, thus eliminating this parameter
weightsat = ones(NUMLAYERS,NUMLAYERS,NUMWEIGHTTYPES);

% weights that saturate below 1
%item to off
weightsat(3,10,1) = .2;
%Blaster in to off
weightsat(11,12,1) = .01;
%Blaster in to out
weightsat(11,13,2) = .01;
%Blaster out to item
weightsat(13,3,2) = .01;
%Blaster out to TFL
weightsat(13,4,2) = .01;

%SRIVAS

%item to off
weightsat(17,20,1) = .2; %SRIVAS was 0.2
%Blaster out to item
weightsat(13,17,2) = .01;
%Blaster out to TFL
weightsat(13,18,2) = .01;


%For each connection, which threshold does it use
%type 1 = one to one
%type 2 = all to all
%type 3 = notched layerwide - everyone but itself
weightthresh= ones(NUMLAYERS,NUMLAYERS,NUMWEIGHTTYPES); %default 1
%Token gate to Blaster in off
weightthresh(8,12,2) = 2;
%Token gate to trace
weightthresh(8,9,1) = 2;
%Token gate to TFL
weightthresh(8,4,2) = 2;
%TFL recurrent
weightthresh(4,4,1) = 2;
%TFL to off
weightthresh(4,5,1) = 3;
%Item to off
weightthresh(3,10,1) = 3;
%Off to TFL
weightthresh(5,4,1) = 2;
%TFL off recurrent
weightthresh(5,5,1) = 2;
%Off to item
weightthresh(10,3,1) = 3;
%Item off recurrent
weightthresh(10,10,1) = 2;
%Binding gate to trace
weightthresh(6,7,1) = 3;
%Binding gate to Blaster in off
weightthresh(6,12,2) = 2;
%Token gate to blaster in off
weightthresh(8,12,2) = 2;
%Token trace to gate
weightthresh(9,8,1) = 2;
%Blaster out to Item
weightthresh(13,3,2) = 2;
%Blaster out to TFL
weightthresh(13,4,2) = 2;
%Blaster out to off
weightthresh(13,14,2) = 3;

%SRIVAS

%Token gate to TFL
weightthresh(8,18,2) = 2;
%TFL recurrent
weightthresh(18,18,1) = 2;
%TFL to off
weightthresh(18,19,1) = 2; %SRIVAS was 3
%Item to off
weightthresh(17,20,1) = 3;
%Off to TFL
weightthresh(19,18,1) = 3; %SRIVAS was 2
%TFL off recurrent
weightthresh(19,19,1) = 2;
%Off to item
weightthresh(20,17,1) = 3;
%Item off recurrent
weightthresh(20,20,1) = 2;
%Blaster out to Item
weightthresh(13,17,2) = 2;
%Blaster out to TFL
weightthresh(13,18,2) = 2;

%Binding gate to trace
weightthresh(21,22,1) = 3;
%Binding gate to Blaster in off
weightthresh(21,12,2) = 2;


sprintf('Generating Weight list');
%now generate the list of weights
Weightlist = 0;
Weightcount = 0;
Weightparams = 0;
for(layer= 1:NUMLAYERS)
    for(layer2 = 1:NUMLAYERS)
        for(type = 1:NUMWEIGHTTYPES)
            if(weightset(layer,layer2,type) ~= 0)
                for(i = 1:NUMNEURONSBYLAYER(layer))
                    for(j = 1:NUMNEURONSBYLAYER(layer2))
                        switch(type)
                            case 1   %one to one
                                if(i == j)
                                    %AddWeight is defined at the end of this file
                                    AddWeight(layer,layer2,i,j,weightset(layer,layer2,type),1,weightsat(layer,layer2,type),weightthresh(layer,layer2,type));
                                end
                            case 2    %all to all
                                AddWeight(layer,layer2,i,j,weightset(layer,layer2,type),2,weightsat(layer,layer2,type),weightthresh(layer,layer2,type));
                            case 3      %notched lateral
                                if(j ~= i)
                                    AddWeight(layer,layer2,i,j,weightset(layer,layer2,type),3,weightsat(layer,layer2,type),weightthresh(layer,layer2,type));
                                end
                        end  %switch
                    end  %for j
                end  %for i
            end  %if
        end  %for type
    end  %for layer2
end  %for layer1

%Specialweights

%priming weights used to simulate the data from Chua in the paper.
% prime = .003;
% primesat = .2;
% primefact = 2;
%Neuron 17 is the  T1+1 distractor
%16 for T1-1 distractor
% Priming from the T1+1 item to the T2
%AddWeight(3,3,17,2,prime,0,primesat,3);  %
% Priming from the T1-1 item to the T2
%AddWeight(3,3,16,2,prime,0,primesat,3);  %

%inhibition between the tokens
li = -2;
AddWeight(8,8,1,2,li,0,.1,1);
AddWeight(8,8,1,3,li,0,.1,1);
AddWeight(8,8,1,4,li,0,.1,1);
AddWeight(8,8,2,3,li,0,.1,1);
AddWeight(8,8,2,4,li,0,.1,1);
AddWeight(8,8,3,4,li,0,.1,1);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Binding Pool Connections
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%NUMBINDERS = NUMWM*NUMTARGS;
%aka 4 * 10 = 40 binders
token1 = 1:10;
token2 = 11:20;
token3 = 21:30;
token4 = 31:40;

itoken1 = 1;
itoken2 = 1;
itoken3 = 1;
itoken4 = 1;

%For each token, incrementally create a list of all binders NOT associated with that token
for(i= 1:NUMBINDERS)
    if(~max(i ==token1))
        itoken1 = [itoken1 i];
    end
    if(~max(i ==token2))
        itoken2 = [itoken2 i];
    end
    if(~max(i ==token3))
        itoken3 = [itoken3 i];
    end
    if(~max(i ==token4))
        itoken4 = [itoken4 i];
    end
end

itoken1 = itoken1(2:length(itoken1));
itoken2 = itoken2(2:length(itoken2));
itoken3 = itoken3(2:length(itoken3));
itoken4 = itoken4(2:length(itoken4));

%now add inhibitory weights from tokens to any binders that don't belong to it
tokbinder = -2;
for(j = itoken1)
    AddWeight(8,6,1,j,tokbinder,0,.1,1);
end
for(j = itoken2)
    AddWeight(8,6,2,j,tokbinder,0,.1,1);
end
for(j = itoken3)
    AddWeight(8,6,3,j,tokbinder,0,.1,1);
end
for(j = itoken4)
    AddWeight(8,6,4,j,tokbinder,0,.1,1);
end

%Add excitatory weights from each binder to its token
tokbinder = 0.01;
for(j = token1)
    AddWeight(6,8,j,1,tokbinder,0,1,3);
end
for(j = token2)
    AddWeight(6,8,j,2,tokbinder,0,1,3);
end
for(j = token3)
    AddWeight(6,8,j,3,tokbinder,0,1,3);
end
for(j = token4)
    AddWeight(6,8,j,4,tokbinder,0,1,3);
end

%and finally we add excitatory weights from the TFL nodes to their corresponding binders
typebinder = .06;
for(i = 1:NUMTARGS)
    AddWeight(4,6,i,i,typebinder,0,1,2);
    AddWeight(4,6,i,i+10,typebinder,0,1,2);
    AddWeight(4,6,i,i+20,typebinder,0,1,2);
    AddWeight(4,6,i,i+30,typebinder,0,1,2);
end

%SRIVAS
token1 = 1:25;
token2 = 26:50;
token3 = 51:75;
token4 = 76:100;

itoken1 = 1;
itoken2 = 1;
itoken3 = 1;
itoken4 = 1;

%For each token, incrementally create a list of all binders NOT associated with that token
for(i= 1:NUMRESPBINDERS)
    if(~max(i ==token1))
        itoken1 = [itoken1 i];
    end
    if(~max(i ==token2))
        itoken2 = [itoken2 i];
    end
    if(~max(i ==token3))
        itoken3 = [itoken3 i];
    end
    if(~max(i ==token4))
        itoken4 = [itoken4 i];
    end
end

itoken1 = itoken1(2:length(itoken1));
itoken2 = itoken2(2:length(itoken2));
itoken3 = itoken3(2:length(itoken3));
itoken4 = itoken4(2:length(itoken4));

%now add inhibitory weights from tokens to any binders that don't belong to
%it
tokbinder = -4.5; %SRIVAS was -2
for(j = itoken1)
    AddWeight(8,21,1,j,tokbinder,0,.1,1);
end
for(j = itoken2)
    AddWeight(8,21,2,j,tokbinder,0,.1,1);
end
for(j = itoken3)
    AddWeight(8,21,3,j,tokbinder,0,.1,1);
end
for(j = itoken4)
    AddWeight(8,21,4,j,tokbinder,0,.1,1);
end

%Add excitatory weights from each binder to its token
tokbinder = 0.01;
for(j = token1)
    AddWeight(21,8,j,1,tokbinder,0,1,3);
end
for(j = token2)
    AddWeight(21,8,j,2,tokbinder,0,1,3);
end
for(j = token3)
    AddWeight(21,8,j,3,tokbinder,0,1,3);
end
for(j = token4)
    AddWeight(21,8,j,4,tokbinder,0,1,3);
end

%and finally we add excitatory weights from the TFL nodes to their
%corresponding binders
typebinder = .1; %SRIVAS - was 0.04. weights below used threshold of 2
for(i = 1:NUMINPUTS)
    if i ~= 11 && i ~= 25 %exclude first and last distractor because it will definitely end up binding
        AddWeight(18,21,i,i,typebinder,0,1,1);
        AddWeight(18,21,i,i+25,typebinder,0,1,1);
        AddWeight(18,21,i,i+50,typebinder,0,1,1);
        AddWeight(18,21,i,i+75,typebinder,0,1,1);
    end
end

disp(sprintf('Total of %d weights created.',Weightcount));

% Task Demand Unit
%this adds a bias to target category elements  and an inhibitory bias to
% distractors
% TDU(1:NUMNEURONS)  = 0; 
% TDU(1:NUMTARGS) = .003;
% TDU(NUMTARGS+1:NUMNEURONS) = -.3;
%   ----------------------------------------------------------------------
% MAHAN: Need two types of TDUs, one for each pathway. 
%   ----------------------------------------------------------------------
TDUK(1:NUMNEURONS)  = 0;  % TDUK = Key
TDUK(1:NUMTARGS) = .003;
TDUK(NUMTARGS+1:NUMNEURONS) = -.3;
if TwoRespFeats
TDUR(1:NUMNEURONS)  = 0; 
TDUR([1 20]) = 0; % TDUR = Response (only T1 (1) and +1 intrusion (20) are task-relevant
TDUR([2:19 21:NUMNEURONS]) = -.3;
end
TDUWEIGHT = 1;

function AddWeight(lay1,lay2,i,j,val,weighttype,weightsat,thresh)
global Weightcount Weightparams Weightindex
%add a weight to the index
Weightcount = Weightcount + 1;
Weightindex(lay1,lay2,i,j) = Weightcount;
Weightparams(Weightcount,1) =  lay1; %presynaptic layer
Weightparams(Weightcount,2) =  lay2; %postsynaptic layer
Weightparams(Weightcount,3) =  i; %presynaptic neuron
Weightparams(Weightcount,4) =  j; %postsynaptic neuron
Weightparams(Weightcount,5) =  val; %weight value
Weightparams(Weightcount,6) =  weighttype; %deprecated not needed anymore
Weightparams(Weightcount,7) =  weightsat; %weight saturation level
Weightparams(Weightcount,8) =  thresh; %threshold type 1, 2 or 3