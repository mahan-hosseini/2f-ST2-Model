function bigbattery
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%This script runs the model several times, simulating several conditions.
%Use flags in code following global var declaration to choose the
%conditions to be run.
%
%Conditions are:  Basic, T1+1 blank,  T2+1 blank
%8 lags between T1 and T2 are run (repeatedly) for each condition
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

global T1BLANK T2BLANK T1BLANK2 genval genval2 BASICRSVP T2perf T1perf Swapencoding NUMLAYERS NUMSTREAMS keyvals respvals T1resp
global BatT1Perf BatT2Perf BatT1CPerf BatT2CPerf Batswap T1batterydata T2batterydata Swapbatterydata
global Equalgens doubleencoding Batdoub doubledata  don0t dot1 dot2
global PresynapHistory ExPostsynHistory InhibPostsynHistory MembPotHistory
global summate summateacc summatecount summate2 summateacc2 summatecount2 summateflag summateflag2
global SOA runlength onetarg accuracy singletrial T1val T2val
global T1Trace T2Trace slimerp skel BasicAccu multbind delaystd
global keystartval keyendval keystepres keydistval resptargval respitemval respstartval
global respendval respstepres respdistval keydelay respdelay
% MAHAN: Do we want to save individual neuron's excitatory postsyn. activations or membrane potentials (1 = former, 2 = latter)?
global SaveNeurAct

if SaveNeurAct == 1
    %MAHAN: add tracking of excitatory postsyn-potential for each neuron
	global ExPostsynFull 
elseif SaveNeurAct == 2
    %MAHAN: save neuron-level VMs
    global VMFull 
elseif SaveNeurAct == 3
    %MAHAN: save inhib force
    global InhibFull
elseif SaveNeurAct == 4
    %MAHAN: save leak force
    global LeakFull
elseif SaveNeurAct == 5
    %MAHAN: save excite force
    global ExciteFull
end
%MAHAN: add tracking of input strengths for each target combination
%global inputstrengths

% allow T2+1 blank only for 2 target
if(onetarg)
    dot2 = 0;   %T2+1 blank
end

%model run stopwatch start
tic;

%set to 1 for equal T1 and T2
Equalgens = 0;

inputpatterns   %setup the RSVP streams
architecture    %setup the network

lag = 0;
numlags = NUMSTREAMS;
multbind = 0;

%check how many conditions were run - basic, blanks, etc
numconditions = 1;
if (dot1)
    numconditions = 2;
end
if(dot2)
    numconditions = 3;
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%SET THE INPUT STRENGTH FOR TARGETS AND DISTRACTORS
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%run a single trial for test purpose
if(singletrial)
    keyvals = 1;
else
    %SRIVAS
    %%% KEY FEATURE STRENGTHS %%%
    allkeyvals = keystartval:keystepres:keyendval;
    keymidval = allkeyvals(ceil(length(allkeyvals)/2));
    keylowseg = allkeyvals(ceil(length(allkeyvals)/3));
    keyupseg = allkeyvals(2*ceil(length(allkeyvals)/3));
    
    %low key strength values
    %     keydistval = keymidval;
    %     keyvals = keystartval:keystepres:keyupseg;
    
    %high key strength values
    %     keydistval = keymidval;
    %     keyvals = keylowseg+keystepres:keystepres:keyendval;
    
    %all key strength values
    keydistval = keymidval;
    keyvals = keystartval:keystepres:keyendval;
    
    %%% REPSONSE FEATURE STRENGTHS %%%
    allrespvals = respstartval:respstepres:respendval;
    respmidval = allrespvals(ceil(length(allrespvals)/2));
    resplowseg = allrespvals(ceil(length(allrespvals)/3));
    respupseg = allrespvals(2*ceil(length(allrespvals)/3));
    
    %low resp strength values
    %     respdistval = resplowseg;
    %     respvals = respstartval:respstepres:respupseg;
    
    %high resp strength values
    %     respdistval = respupseg;
    %     respvals = resplowseg+respstepres:respstepres:respendval;
    
    %all resp strength values
    respdistval = respmidval;
    respvals = respstartval:respstepres:respendval;
    
    disp(sprintf('key pathway delay = %d.', keydelay));
    disp(sprintf('response pathway delay = %d.', respdelay));
    disp(sprintf('random delay SD = %d.', delaystd));
    
    %MAHAN: inform about what we are saving, if anything
    if SaveNeurAct == 0
        disp('*** SAVING ONLY LAYERWIDE ACTS ***')
    elseif SaveNeurAct == 1
        disp('*** SAVING EACH NEURON''S ACTS ***')
    elseif SaveNeurAct == 2
        disp('*** SAVING EACH NEURON''S MEMBRANE POTENTIAL ***')
    elseif SaveNeurAct == 3
        disp('*** SAVING EACH NEURON''S INHIBITORY INPUT ***')
    elseif SaveNeurAct == 4
        disp('*** SAVING EACH NEURON''S LEAK INPUT ***')
    elseif SaveNeurAct == 5
        disp('*** SAVING EACH NEURON''S EXCITATORY INPUT ***')
    end
        
    
    disp(sprintf('Key inputs range from %.4f to %.4f.', keyvals(1), keyvals(length(keyvals))));
    disp(sprintf('Response inputs range from %.4f to %.4f.', respvals(1), respvals(length(respvals))));
    numvals = length(keyvals);
    numrespvals = length(respvals);
end

if onetarg
    numTcombi = numvals * numrespvals * numrespvals;
else
    numTcombi = numvals^2;
end
disp(sprintf('Number of trials to run: %d\n', numTcombi));
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%if onetarget do only one set of target values
T1start = 1;
T1stop = numvals;

%stop running two nested loops for onetarget
if(onetarg)
    T2start = 0;
    T2stop = 0;
else
    T2start = 1;
    T2stop = numvals;
end

%number of easy and hard trials
if(singletrial)
    numeasy = 1;
    numhard = 1;
else
    numeasy = floor(numvals/2);
    numhard = ceil(numvals/2);
end

%variables for storing the raw activation values of individual neurons
%summate(trialnum,timestep,layer,neuron)
%these variables are encoded in the function evaltargs.m
summate = zeros(numTcombi,NUMSTREAMS,runlength,3,2);
summateacc = zeros(400, 3);
summatecount = zeros(NUMSTREAMS,numTcombi);

summate2 = zeros(numTcombi,NUMSTREAMS,runlength,3,2);
summateacc2 = zeros(400, 3);
summatecount2 = zeros(NUMSTREAMS,numTcombi);

%behavioural storage variable
T2batterydata = zeros(3,T1stop,T2stop,NUMSTREAMS); %values for T2 for each trial - neuron 2
Swapbatterydata = zeros(3,T1stop,T2stop,NUMSTREAMS);
doubledata = zeros(3,T1stop,T2stop,NUMSTREAMS);

%SRIVAS
T1batterydata= zeros(1,T1stop,numrespvals,numrespvals,NUMSTREAMS); %values for T1 for each trial - encodes whatever is in neuron 1 so ok for single target
T1respdata= zeros(1,T1stop,numrespvals,numrespvals,NUMSTREAMS);

%Flags for storing output traces
summateflag = 1;
summateflag2 = 1;

%%%%%%%%%%%%%%%%%%  FIRST RUN: Basic Condition
if(don0t)
    %Flags used later to insert blanks into the stream  These variables are used in generateinput.m
    T1BLANK = 0;  %T1+1 blank
    T2BLANK = 0;   %T2+1 blank
    T1BLANK2 = 0;   %T1 +2 blank
    trialcounter = 1;
    accuracy = zeros(1,numlags);
    BasicAccu = zeros(numTcombi,numlags);
    %initialise ERP storage
    if slimerp == 0
        MembPotBat_basic = zeros(numTcombi,NUMSTREAMS,runlength,NUMLAYERS);
        PresynapBat_basic = zeros(numTcombi,NUMSTREAMS,runlength,NUMLAYERS);
        InhibPostsynBat_basic = zeros(numTcombi,NUMSTREAMS,runlength,NUMLAYERS);
    end
    ExPostsynBat_basic = zeros(numTcombi,NUMSTREAMS,runlength,NUMLAYERS);
    if SaveNeurAct == 1
        %MAHAN: add per neuron variable %MAHAN - doesn't work as I want... 
        ExPostsynFull_basic = zeros(numTcombi,NUMSTREAMS,runlength,NUMLAYERS, 100);
    elseif SaveNeurAct == 2
        %MAHAN: add tracking of VMs for all neurons
        VMFull_basic = zeros(numTcombi,NUMSTREAMS,runlength,NUMLAYERS, 100); 
    elseif SaveNeurAct == 3
        %MAHAN: add tracking of InhibForce for all neurons
        InhibFull_basic = zeros(numTcombi,NUMSTREAMS,runlength,NUMLAYERS,100);
    elseif SaveNeurAct == 4
        %MAHAN: add tracking of LeakForce for all neurons
        LeakFull_basic = zeros(numTcombi,NUMSTREAMS,runlength,NUMLAYERS,100);
    elseif SaveNeurAct == 5
        %MAHAN: add tracking of ExciteForce for all neurons
        ExciteFull_basic = zeros(numTcombi,NUMSTREAMS,runlength,NUMLAYERS,100);
    end

    
    %save the trace for T1 and T2 in a layers
    T1ExPostsynHistory = zeros(numTcombi,NUMSTREAMS,runlength,NUMLAYERS);
    T2ExPostsynHistory = zeros(numTcombi,NUMSTREAMS,runlength,NUMLAYERS);
    T1strength = zeros(1,numTcombi);
    T2strength = zeros(1,numTcombi);
    
    if false %if(onetarg) SRIVAS
        EasyAccu = zeros(numeasy,numlags);
        easycount = 1;
        MembPotBat_easy = zeros(numeasy,NUMSTREAMS,runlength,NUMLAYERS);
        PresynapBat_easy = zeros(numeasy,NUMSTREAMS,runlength,NUMLAYERS);
        ExPostsynBat_easy = zeros(numeasy,NUMSTREAMS,runlength,NUMLAYERS);
        InhibPostsynBat_easy = zeros(numeasy,NUMSTREAMS,runlength,NUMLAYERS);
        HardAccu = zeros(numhard,numlags);
        hardcount = 1;
        MembPotBat_hard = zeros(numhard,NUMSTREAMS,runlength,NUMLAYERS);
        PresynapBat_hard = zeros(numhard,NUMSTREAMS,runlength,NUMLAYERS);
        ExPostsynBat_hard = zeros(numhard,NUMSTREAMS,runlength,NUMLAYERS);
        InhibPostsynBat_hard = zeros(numhard,NUMSTREAMS,runlength,NUMLAYERS);
    end
    
    for i=T1start:T1stop
        for m=1:numrespvals
            for k=1:numrespvals
                %     for i=T1start:T1stop
                %         for m=1:1
                %             for k=1:1
                
                for j=T2start:T2stop
                    if singletrial
                        genval = keyvals(T1val);
                        genval2 = keyvals(T2val);
                    elseif onetarg
                        genval = keyvals(i);
                        resptargval = respvals(m);
                        respitemval = respvals(k);
                    else
                        genval = keyvals(i);
                        genval2 = keyvals(j);
                    end
                    
                    first = i; %i loop index
                    if onetarg
                        second = 1;
                    else
                        second = j; %j loop index
                    end
                    
                    if (onetarg)
                        disp(sprintf('Key - Target: %0.4f; Distractors: %0.4f',genval,keydistval));
                        disp(sprintf('Response - Target %0.4f; Intruder: %0.4f; Others: %0.4f\n',resptargval,respitemval,respdistval));
                    else
                        sprintf('This set of lags: T1 has value %0.4f - T2 has value %0.4f - Distractors have value %0.4f',genval,genval2,keydistval)
                    end
                    
                    %MAHAN: store input strengths of this trial
                    %   because input strengths are equal for different
                    %   lags, we copy them as often as we have lags within
                    %   each trial
                    %       -- need to do some data-structure change stuff
                    %       for these to correspond to 'trials' in the
                    %       sense of targetcombinations*lags
                    %       (see st2data2eeglab-func where this happens)
                    %   also no need for these to be global because we are
                    %   saving them further down in a separate variable
                    if ~exist('inputstrengths', 'var')
                        inputstrengths = struct('keytarg', [], 'keydist', [], ...
                            'resptarg', [], 'respint', [], 'respdist', []);
                        inputstrengths(numTcombi).keytarg = 0;
                    end
                    inputstrengths(trialcounter).keytarg(1:numlags) = genval;
                    inputstrengths(trialcounter).keydist(1:numlags) = keydistval;
                    inputstrengths(trialcounter).resptarg(1:numlags) = resptargval;
                    inputstrengths(trialcounter).respint(1:numlags) = respitemval;
                    inputstrengths(trialcounter).respdist(1:numlags) = respdistval;
                    
                    %%%%%%this line actually runs the model%%%%%%
                    runRSVP(BASICRSVP,lag)
                    %print trial info
                    disp(sprintf('\n%d target combinations left in basic condition.',numTcombi-trialcounter));
                    
                    %these store the output
                    BasicAccu(trialcounter,:) = accuracy;
                    %fill T1 and T2 performance into battery variable
                    T1batterydata(1,first,m,k,1:NUMSTREAMS) = reshape(T1perf,[1,1,1,1,NUMSTREAMS]);
                    T2batterydata(1,first,second,1:NUMSTREAMS) = reshape(T2perf,[1,1,1,NUMSTREAMS]);
                    Swapbatterydata(1,first,second,1:NUMSTREAMS) = reshape(Swapencoding,[1,1,1,NUMSTREAMS]);
                    doubledata(1,first,second,1:NUMSTREAMS) =  reshape(doubleencoding,[1,1,1,NUMSTREAMS]);
                    
                    %SRIVAS
                    T1respdata(1,first,m,k,1:NUMSTREAMS) = reshape(T1resp,[1,1,1,1,NUMSTREAMS]);
                    
                    %copy erp data to battery wide variable here
                    if ~slimerp
                        %membrane potentials
                        %number of runs,lag,timestep,layers
                        MembPotBat_basic(trialcounter,:,:,:) = MembPotHistory;
                        %presynaptic output
                        PresynapBat_basic(trialcounter,:,:,:) = PresynapHistory;
                        %inhibitory postsynaptic output
                        InhibPostsynBat_basic(trialcounter,:,:,:) = InhibPostsynHistory;
                        
                        %target nodes erp only and strength
                        T1ExPostsynHistory(trialcounter,:,:,:) = T1Trace;
                        T1strength(trialcounter) = genval;
                        if ~onetarg
                            T2ExPostsynHistory(trialcounter,:,:,:) = T2Trace;
                            T2strength(trialcounter) = genval2;
                        end
                    end
                    %excitatory postsynaptic output
                    ExPostsynBat_basic(trialcounter,:,:,:) = ExPostsynHistory;
                    if SaveNeurAct == 1
                        %MAHAN: excitatory postsynaptic output by neuron
                        ExPostsynFull_basic(trialcounter,:,:,:,:) = ExPostsynFull;
                        %   ==> MAHAN: I wrote a note about how to use these variables in runModel.m
                    elseif SaveNeurAct == 2
                        VMFull_basic(trialcounter,:,:,:,:) = VMFull;
                    elseif SaveNeurAct == 3
                        InhibFull_basic(trialcounter,:,:,:,:) = InhibFull;
                    elseif SaveNeurAct == 4
                        LeakFull_basic(trialcounter,:,:,:,:) = LeakFull;
                    elseif SaveNeurAct == 5
                        ExciteFull_basic(trialcounter,:,:,:,:) = ExciteFull;
                    end
                    
                    
                    if false %if(onetarg) SRIVAS
                        %easy/hard currently only for single target
                        if genval > keydistval %easy target
                            EasyAccu(easycount,:) = accuracy;
                            %membrane potentials
                            %number of runs,lag,timestep,layers
                            MembPotBat_easy(easycount,:,:,:) = MembPotHistory;
                            %presynaptic output
                            PresynapBat_easy(easycount,:,:,:) = PresynapHistory;
                            %excitatory postsynaptic output
                            ExPostsynBat_easy(easycount,:,:,:) = ExPostsynHistory;
                            %inhibitory postsynaptic output
                            InhibPostsynBat_easy(easycount,:,:,:) = InhibPostsynHistory;
                            easycount = easycount + 1;
                        elseif genval <= keydistval %hard target
                            HardAccu(hardcount,:) = accuracy;
                            %membrane potentials
                            %number of runs,lag,timestep,layers
                            MembPotBat_hard(hardcount,:,:,:) = MembPotHistory;
                            %presynaptic output
                            PresynapBat_hard(hardcount,:,:,:) = PresynapHistory;
                            %excitatory postsynaptic output
                            ExPostsynBat_hard(hardcount,:,:,:) = ExPostsynHistory;
                            %inhibitory postsynaptic output
                            InhibPostsynBat_hard(hardcount,:,:,:) = InhibPostsynHistory;
                            hardcount = hardcount + 1;
                        end
                    end
                    
                    trialcounter = trialcounter + 1;
                end
            end
        end
    end
    if singletrial == 0
        if(onetarg)
            if skel
                erpfile = [ 'STSTerp_1targskel_' num2str(SOA) 'ms' ];
                T1T2file = [ 'STST_T1T2trace_1targskel_' num2str(SOA) 'ms' ];
            else
                erpfile = [ 'STSTerp_1targ_' num2str(SOA) 'ms' ];
                T1T2file = [ 'STST_T1T2trace_1targ_' num2str(SOA) 'ms' ];
            end
            if slimerp
                save(erpfile,'ExPostsynBat_*','BasicAccu');
            else
                if SaveNeurAct == 1
                    %MAHAN: save 'ExPostsynFull_*', too now and use v7.3 to handle big files
                    save(erpfile,'MembPotBat_*', 'PresynapBat_*', 'ExPostsynBat_*','InhibPostsynBat_*','BasicAccu', 'ExPostsynFull_*' , '-v7.3');%,'EasyAccu','HardAccu');
                elseif SaveNeurAct == 2
                    %MAHAN: similar if we computed membrane potentials of neurons
                    save(erpfile,'MembPotBat_*', 'PresynapBat_*', 'ExPostsynBat_*','InhibPostsynBat_*','BasicAccu','VMFull_basic', '-v7.3');%,'EasyAccu','HardAccu');
                elseif SaveNeurAct == 3
                    %MAHAN: similar if we computed inhib input of neurons
                    save(erpfile,'MembPotBat_*', 'PresynapBat_*', 'ExPostsynBat_*','InhibPostsynBat_*','BasicAccu','InhibFull_basic', '-v7.3');%,'EasyAccu','HardAccu');
                elseif SaveNeurAct == 4
                    %MAHAN: similar if we computed leak input of neurons
                    save(erpfile,'MembPotBat_*', 'PresynapBat_*', 'ExPostsynBat_*','InhibPostsynBat_*','BasicAccu','LeakFull_basic', '-v7.3');%,'EasyAccu','HardAccu');
                elseif SaveNeurAct == 5
                    %MAHAN: similar if we computed excite input of neurons
                    save(erpfile,'MembPotBat_*', 'PresynapBat_*', 'ExPostsynBat_*','InhibPostsynBat_*','BasicAccu','ExciteFull_basic', '-v7.3');%,'EasyAccu','HardAccu');
                else
                    save(erpfile,'MembPotBat_*', 'PresynapBat_*', 'ExPostsynBat_*','InhibPostsynBat_*','BasicAccu');%,'EasyAccu','HardAccu');
                end
            end
        else
            if skel
                erpfile = [ 'STSTerpskel_' num2str(SOA) 'ms' ];
                T1T2file = [ 'STST_T1T2traceskel_' num2str(SOA) 'ms' ];
            else
                erpfile = [ 'STSTerp_' num2str(SOA) 'ms' ];
                T1T2file = [ 'STST_T1T2trace_' num2str(SOA) 'ms' ];
            end
            if slimerp
                save(erpfile,'ExPostsynBat_*','BasicAccu');
            else
                save(erpfile,'MembPotBat_*', 'PresynapBat_*', 'ExPostsynBat_*','InhibPostsynBat_*','BasicAccu');
            end
        end
        
        %save T1 and T2 excitatory postsynaptic traces
        save(T1T2file,'T1ExPostsynHistory', 'T2ExPostsynHistory','T1strength','T2strength');
        
        clear MembPotBat_* PresynapBat_* ExPostsynBat_* InhibPostsynBat_* T1ExPostsynHistory T2ExPostsynHistory T1strength T2strength;
    end
end

%%%%%%%%%%%%%%%%%%SECOND RUN: T1+1 Blank Condition
if(dot1)
    T1BLANK2 = 0;
    T1BLANK = 1;
    T2BLANK = 0;
    trialcounter = 1;
    accuracy = zeros(1,numlags);
    BlankAccu = zeros(numTcombi,numlags);
    summateflag = 0;
    summateflag2 = 1;
    %initialise ERP storage
    MembPotBat_T1blank = zeros(numTcombi,NUMSTREAMS,runlength,NUMLAYERS);
    PresynapBat_T1blank = zeros(numTcombi,NUMSTREAMS,runlength,NUMLAYERS);
    ExPostsynBat_T1blank = zeros(numTcombi,NUMSTREAMS,runlength,NUMLAYERS);
    InhibPostsynBat_T1blank = zeros(numTcombi,NUMSTREAMS,runlength,NUMLAYERS);
    if(onetarg)
        BlankEasyAccu = zeros(numeasy,numlags);
        easycount = 1;
        MembPotBat_blankeasy = zeros(numeasy,NUMSTREAMS,runlength,NUMLAYERS);
        PresynapBat_blankeasy = zeros(numeasy,NUMSTREAMS,runlength,NUMLAYERS);
        ExPostsynBat_blankeasy = zeros(numeasy,NUMSTREAMS,runlength,NUMLAYERS);
        InhibPostsynBat_blankeasy = zeros(numeasy,NUMSTREAMS,runlength,NUMLAYERS);
        BlankHardAccu = zeros(numhard,numlags);
        hardcount = 1;
        MembPotBat_blankhard = zeros(numhard,NUMSTREAMS,runlength,NUMLAYERS);
        PresynapBat_blankhard = zeros(numhard,NUMSTREAMS,runlength,NUMLAYERS);
        ExPostsynBat_blankhard = zeros(numhard,NUMSTREAMS,runlength,NUMLAYERS);
        InhibPostsynBat_blankhard = zeros(numhard,NUMSTREAMS,runlength,NUMLAYERS);
    end
    
    for i=T1start:T1stop
        for j=T2start:T2stop
            if onetarg
                genval = keyvals(i);
            else
                genval = keyvals(i);
                genval2 = keyvals(j);
            end
            
            first = i;
            if singletrial || onetarg
                second = 1;
            else
                second = j; %j loop index
            end
            
            if (onetarg)
                sprintf('This set of lags: Target has value %0.4f - Distractors have value %0.4f',genval,keydistval)
            else
                sprintf('This set of lags: T1 has value %0.4f - T2 has value %0.2f - Distractors have value %0.4f',genval,genval2,keydistval)
            end
            
            %%%%%%this line actually runs the model%%%%%%
            runRSVP(BASICRSVP,lag)
            %print trial info
            disp(sprintf('%d target combinations left in T1+1 blank condition',numTcombi-trialcounter));
            
            %these store the output
            BlankAccu(trialcounter,:) = accuracy;
            T1batterydata(2,first,second,1:NUMSTREAMS) = reshape(T1perf,[1,1,1,NUMSTREAMS]);
            T2batterydata(2,first,second,1:NUMSTREAMS) = reshape(T2perf,[1,1,1,NUMSTREAMS]);
            Swapbatterydata(2,first,second,1:NUMSTREAMS) = reshape(Swapencoding,[1,1,1,NUMSTREAMS]);
            doubledata(2,first,second,1:NUMSTREAMS) =  reshape(doubleencoding,[1,1,1,NUMSTREAMS]);
            
            %copy erp data to battery wide variable here
            %membrane potentials
            %number of runs,lag,timestep,layers
            %use only accuracy trials
            MembPotBat_T1blank(trialcounter,:,:,:) = MembPotHistory;
            %presynaptic output
            PresynapBat_T1blank(trialcounter,:,:,:) = PresynapHistory;
            %excitatory postsynaptic output
            ExPostsynBat_T1blank(trialcounter,:,:,:) = ExPostsynHistory;
            %inhibitory postsynaptic output
            InhibPostsynBat_T1blank(trialcounter,:,:,:) = InhibPostsynHistory;
            if(onetarg)
                %blanked easy/hard currently only for single target
                if(genval > keydistval) %blanked easy target
                    BlankEasyAccu(easycount,:) = accuracy;
                    %membrane potentials
                    %number of runs,lag,timestep,layers
                    MembPotBat_blankeasy(easycount,:,:,:) = MembPotHistory;
                    %presynaptic output
                    PresynapBat_blankeasy(easycount,:,:,:) = PresynapHistory;
                    %excitatory postsynaptic output
                    ExPostsynBat_blankeasy(easycount,:,:,:) = ExPostsynHistory;
                    %inhibitory postsynaptic output
                    InhibPostsynBat_blankeasy(easycount,:,:,:) = InhibPostsynHistory;
                    easycount = easycount + 1;
                else %blanked hard target
                    BlankHardAccu(hardcount,:) = accuracy;
                    %membrane potentials
                    %number of runs,lag,timestep,layers
                    MembPotBat_blankhard(hardcount,:,:,:) = MembPotHistory;
                    %presynaptic output
                    PresynapBat_blankhard(hardcount,:,:,:) = PresynapHistory;
                    %excitatory postsynaptic output
                    ExPostsynBat_blankhard(hardcount,:,:,:) = ExPostsynHistory;
                    %inhibitory postsynaptic output
                    InhibPostsynBat_blankhard(hardcount,:,:,:) = InhibPostsynHistory;
                    hardcount = hardcount + 1;
                end
            end
            trialcounter = trialcounter + 1;
        end
    end
    if singletrial == 0
        if(onetarg)
            if skel
                erpfile = [ 'STSTerp_1targskel_' num2str(SOA) 'ms' ];
            else
                erpfile = [ 'STSTerp_1targ_' num2str(SOA) 'ms' ];
            end
            save(erpfile,'MembPotBat_*', 'PresynapBat_*', 'ExPostsynBat_*','InhibPostsynBat_*','BlankAccu','BlankEasyAccu','BlankHardAccu','-append');
        else
            if skel
                erpfile = [ 'STSTerpskel_' num2str(SOA) 'ms' ];
            else
                erpfile = [ 'STSTerp_' num2str(SOA) 'ms' ];
            end
            save(erpfile,'MembPotBat_*', 'PresynapBat_*', 'ExPostsynBat_*','InhibPostsynBat_*','BlankAccu','-append');
        end
        clear MembPotBat_* PresynapBat_* ExPostsynBat_* InhibPostsynBat_*;
    end
end

%%%%%%%%%%%%%%%%%%%%THIRD RUN: T2+1 blank condition
if(dot2)
    summateflag2 = 0;
    T1BLANK = 0;
    T2BLANK = 1;
    trialcounter = 1;
    accuracy = zeros(1,numlags);
    T2BlankAccu = zeros(numTcombi,numlags);
    %initialise ERP storage
    MembPotBat_T2blank = zeros(numTcombi,NUMSTREAMS,runlength,NUMLAYERS);
    PresynapBat_T2blank = zeros(numTcombi,NUMSTREAMS,runlength,NUMLAYERS);
    ExPostsynBat_T2blank = zeros(numTcombi,NUMSTREAMS,runlength,NUMLAYERS);
    InhibPostsynBat_T2blank = zeros(numTcombi,NUMSTREAMS,runlength,NUMLAYERS);
    
    for i=T1start:T1stop
        for j=T2start:T2stop
            if onetarg
                genval = keyvals(i);
            else
                genval = keyvals(i);
                genval2 = keyvals(j);
            end
            first = i;
            if singletrial || onetarg
                second = 1;
            else
                second = j; %j loop index
            end
            
            if (onetarg)
                sprintf('This set of lags: Target has value %0.4f - Distractors have value %0.4f',genval,keydistval)
            else
                sprintf('This set of lags: T1 has value %0.4f - T2 has value %0.2f - Distractors have value %0.4f',genval,genval2,keydistval)
            end
            
            
            %%%%%this line actually runs the model%%%%%%
            runRSVP(BASICRSVP,lag)
            %print trial info
            disp(sprintf('%d target combinations left in T2+1 blank condition',numTcombi-trialcounter));
            
            T2BlankAccu(trialcounter,:) = accuracy;
            T1batterydata(3,first,second,1:NUMSTREAMS) = reshape(T1perf,[1,1,1,NUMSTREAMS]);
            T2batterydata(3,first,second,1:NUMSTREAMS) = reshape(T2perf,[1,1,1,NUMSTREAMS]);
            Swapbatterydata(3,first,second,1:NUMSTREAMS) = reshape(Swapencoding,[1,1,1,NUMSTREAMS]);
            doubledata(3,first,second,1:NUMSTREAMS) =  reshape(doubleencoding,[1,1,1,NUMSTREAMS]);
            
            %copy erp data to battery wide variable here
            %membrane potentials
            %number of runs,lag,timestep,layers
            MembPotBat_T2blank(trialcounter,:,:,:) = MembPotHistory;
            %presynaptic output
            PresynapBat_T2blank(trialcounter,:,:,:) = PresynapHistory;
            %excitatory postsynaptic output
            ExPostsynBat_T2blank(trialcounter,:,:,:) = ExPostsynHistory;
            %inhibitory postsynaptic output
            InhibPostsynBat_T2blank(trialcounter,:,:,:) = InhibPostsynHistory;
            trialcounter = trialcounter + 1;
        end
    end
    if(onetarg)
        erpfile = [ 'STSTerp_1targ_' num2str(SOA) 'ms' ];
        save(erpfile,'MembPotBat_*', 'PresynapBat_*', 'ExPostsynBat_*','InhibPostsynBat_*','T2BlankAccu','-append');
    else
        erpfile = [ 'STSTerp_' num2str(SOA) 'ms' ];
        save(erpfile,'MembPotBat_*', 'PresynapBat_*', 'ExPostsynBat_*','InhibPostsynBat_*','T2BlankAccu','-append');
    end
    clear MembPotBat_* PresynapBat_* ExPostsynBat_* InhibPostsynBat_*;
end


%go through all of the stored output of the model and compute the accuracies.

%onetarget only has T1 data
BatT1Perf = zeros(numconditions,numlags);

if(~onetarg)
    BatT2Perf = zeros(numconditions,numlags);
    BatT2CPerf = zeros(numconditions,numlags);
    BatT1CPerf = zeros(numconditions,numlags);
    Batswap = zeros(numconditions,numlags);
    Batdoub = zeros(numconditions,numlags);
end

% copy target performance data to battery wide variable
for t = 1:numconditions
    for i = 1:size(T1batterydata,2)%first (i) loop index
        for j = 1:size(T1batterydata,3)%second (j) loop index
            for k = 1:numlags
                if ~onetarg
                    doub = doubledata(t,i,j,k);
                    t2 = T2batterydata(t,i,j,k);
                end
                t1 = T1batterydata(t,i,j,k);
                if t1 %not zero
                    BatT1Perf(t,k)= BatT1Perf(t,k)+ 1;
                end
                
                if ~onetarg
                    if t2
                        BatT2Perf(t,k)= BatT2Perf(t,k)+ 1;
                    end
                    Batdoub(t,k) = Batdoub(t,k) + doub;
                    if t1 && t2
                        BatT2CPerf(t,k)= BatT2CPerf(t,k)+ 1;
                    end
                    if t2
                        BatT1CPerf(t,k)= BatT1CPerf(t,k)+ 1;
                    end
                    if t1 && t2
                        Batswap(t,k) = Batswap(t,k) + Swapbatterydata(t,i,j,k);
                    end
                end
            end
        end
    end
    for k = 1:numlags
        if ~onetarg
            Batdoub(t,k) = Batdoub(t,k)/BatT2CPerf(t,k);
            Batswap(t,k) = Batswap(t,k)/BatT2CPerf(t,k);
            BatT1CPerf(t,k) = BatT2CPerf(t,k) / BatT2Perf(t,k);
            BatT2CPerf(t,k) = BatT2CPerf(t,k) / BatT1Perf(t,k);
            BatT2Perf(t,k) = BatT2Perf(t,k) / numTcombi;
        end
        BatT1Perf(t,k) = BatT1Perf(t,k) / numTcombi;
    end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%Save the behavioural output
%Duration
duration = floor(toc/60);
disp(sprintf('\nModel ran for %d minutes',duration));

%accuracy and model performance on target detection
% if onetarg
%     outfile = [ 'STSToutput_1targ_' num2str(SOA) 'ms' ];
%     save(outfile, 'duration','BatT1Perf','T1batterydata');
% else
%     outfile = [ 'STSToutput_' num2str(SOA) 'ms' ];
%     save(outfile, 'duration','BatT2Perf','BatT1Perf','BatT2CPerf','BatT1CPerf','Batswap','Batdoub', 'doubledata','T1batterydata','T2batterydata','Swapbatterydata' );
% end

% MAHAN: save the input strengths of all target combinations for further
%   analyses
save(['inputstrength_struct' num2str(SOA) 'ms'], 'inputstrengths')

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% including summate stuff
if singletrial == 0
    if onetarg
        if skel
            outfile = [ 'STSToutput_1targskel_' num2str(SOA) 'ms' ];
            save(outfile, 'duration', 'summate','summatecount','summateacc', 'summate2','summatecount2','summateacc2','BatT1Perf','T1batterydata','T1respdata','multbind','keydelay','respdelay','delaystd');
        else
            outfile = [ 'STSToutput_1targ_' num2str(SOA) 'ms' ];
            save(outfile, 'duration', 'summate','summatecount','summateacc', 'summate2','summatecount2','summateacc2','BatT1Perf','T1batterydata','T1respdata','multbind','keydelay','respdelay','delaystd');
        end
    else
        if skel
            outfile = [ 'STSToutputskel_' num2str(SOA) 'ms' ];
            save(outfile, 'duration', 'summate','summatecount','summateacc', 'summate2','summatecount2','summateacc2','BatT2Perf','BatT1Perf','BatT2CPerf','BatT1CPerf','Batswap','Batdoub', 'doubledata','T1batterydata','T2batterydata','Swapbatterydata' );
        else
            outfile = [ 'STSToutput_' num2str(SOA) 'ms' ];
            save(outfile, 'duration', 'summate','summatecount','summateacc', 'summate2','summatecount2','summateacc2','BatT2Perf','BatT1Perf','BatT2CPerf','BatT1CPerf','Batswap','Batdoub', 'doubledata','T1batterydata','T2batterydata','Swapbatterydata' );
        end
    end
end
