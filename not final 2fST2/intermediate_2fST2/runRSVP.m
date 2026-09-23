function runRSVP(RSVPname,lag)

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%runRSVP(RSVPname,lag)
%
%Runs a series of RSVP streams through the model.
%This is where all of the work is done
%For one condition only.
%
%Inputs:
%
%RSVPname:  the name of the RSVP stream, generated in inputpatterns.m
%
%lag:  which lag(s) to run.
%If lag = 0, the model will run lags 1 through NUMSTREAMS
%If lag > 0, the model will run only that lag

% MAHAN:
%   It might be worth it to read a couple of notes I wrote in runModel.m 
%   about using this model in its singletarget version 

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%5

global BIAS LEAK DT_VM EE EI EL GAMMA THETA NUMLAYERS NUMWM TDUK TDUWEIGHT STARTVAL NUMSTREAMS NUMINPUTS THETA2 THETA3
global Neurons Retina Weightcount RespRetina
global History MPHistory OutHistory InHistory BiasHistory HebbHistory PresynapHistory ExPostsynHistory InhibPostsynHistory MembPotHistory
global WMBIAS NUMNEURONSBYLAYER NUMBINDERS NUMRESPBINDERS BinderHistory WMNEGBIAS NUMTARGS NUMNEURONS
global Weightparams targvals runlength onetarg accuracy resptargvals
global T1Trace T2Trace NUMITEMS keydelay respdelay stepperlag
global TwoRespFeats TDUR SaveNeurAct %MAHAN
if SaveNeurAct == 1
    global ExPostsynFull %MAHAN
elseif SaveNeurAct == 2
    global VMFull %MAHAN
elseif SaveNeurAct == 3
    global InhibFull %MAHAN
elseif SaveNeurAct == 4
    global LeakFull %MAHAN
elseif SaveNeurAct == 5
    global ExciteFull %MAHAN
end


%temporary globals here
global step sigout bias

%temporaray neurons variable
newneurons = zeros(NUMLAYERS,NUMRESPBINDERS);
targvals  = zeros(NUMSTREAMS,NUMWM,NUMTARGS);
resptargvals = zeros(NUMSTREAMS,NUMWM,NUMITEMS);
%the Histories are used for storing activity of the network and displaying
%it in showneurons, or saving it to disk.
%erps
%lags, timesteps, layers
PresynapHistory = zeros(NUMSTREAMS,runlength,NUMLAYERS);   %Presynaptic Output History
ExPostsynHistory = zeros(NUMSTREAMS,runlength,NUMLAYERS);   %Excitatory Postsynaptic Output History
InhibPostsynHistory = zeros(NUMSTREAMS,runlength,NUMLAYERS);   %Inhibitory Postsynaptic Output History
MembPotHistory = zeros(NUMSTREAMS,runlength,NUMLAYERS);     %Membrane potential
if SaveNeurAct == 1
    %MAHAN: Add tracking of ExPostsynFull
    ExPostsynFull = zeros(NUMSTREAMS,runlength,NUMLAYERS,NUMRESPBINDERS); %MAHAN: Full Excitatory Postsyn Output History (with neurons)
elseif SaveNeurAct == 2
    VMFull = zeros(NUMSTREAMS,runlength,NUMLAYERS,NUMRESPBINDERS); %MAHAN: add tracking of neurons' membrane potentials
elseif SaveNeurAct == 3
    InhibFull = zeros(NUMSTREAMS,runlength,NUMLAYERS,NUMRESPBINDERS); %MAHAN: add tracking of neurons' inhibitory input
elseif SaveNeurAct == 4
    LeakFull = zeros(NUMSTREAMS,runlength,NUMLAYERS,NUMRESPBINDERS); %MAHAN: add tracking of neurons' leak input
elseif SaveNeurAct == 5
    ExciteFull = zeros(NUMSTREAMS,runlength,NUMLAYERS,NUMRESPBINDERS); %MAHAN: add tracking of neurons' excitatory input
end


%showneurons
HebbHistory = zeros(NUMSTREAMS,runlength,NUMINPUTS,NUMINPUTS);      %No longer used,  Saved for future use in showneurons.m
History = zeros(NUMSTREAMS,runlength,NUMLAYERS,NUMINPUTS);      %used by Showneurons
OutHistory = zeros(NUMSTREAMS,runlength,NUMLAYERS,NUMINPUTS);   %Output Function
MPHistory = zeros(NUMSTREAMS,runlength,NUMLAYERS,NUMINPUTS);     %Membrane potential
BiasHistory = zeros(NUMSTREAMS,runlength,NUMLAYERS,NUMINPUTS+1);   %Bias
InHistory = zeros(NUMSTREAMS,runlength,NUMLAYERS,NUMINPUTS);   %inhibition history
BinderHistory = zeros(NUMSTREAMS,runlength,4,NUMRESPBINDERS);   %  Binders

%sigmoidal output
sigout = zeros(NUMLAYERS,NUMNEURONS);  %output of neurons - theta 1
sigout2 = zeros(NUMLAYERS,NUMNEURONS);  %output of neurons - theta 2
sigout3 = zeros(NUMLAYERS,NUMNEURONS);  %output of neurons - theta 3

%we run just this lag if it's been specified by the input
lagdo = lag;
%or if lag = 0, we run all 8 lags
if(lag == 0)
    for i=1:NUMSTREAMS
        if (~isempty(nonzeros(RSVPname(i,:))))
            lagdo = [lagdo i];
        end
    end
    lagdo = lagdo(2:end);
end

%main loop
for (lag = lagdo)  %start a new lag
    
    disp(sprintf('Lag %d...', lag));
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %Preparing the model for a new lag                                    %
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %SRIVAS - disabled this
    %architecture;  %we run architecture again
    
    if(~onetarg) %display current lag for two targets
        sprintf('Current lag %d',lag)
    end
    
    %from the appropriate element of RSVPname (in INPUTPATTERNS)
    %generate the actual input stream
    generateinput(RSVPname,lag);
    
    %14 layers by 40 (numbinders is num targets 10 * num wm tokens 4) neurons.
    %This stores the activation of each neuron - reset for new lag
    Neurons = zeros(NUMLAYERS,NUMRESPBINDERS);
    
    %Initialize the Neurons in a given layer to STARTVAL.
    for(layer = 1:NUMLAYERS);
        Neurons(layer,:) = STARTVAL(layer);
%         %Allow special adjustment for Task Demand Unit in layer 4
        if layer == 4
            for(neuron = 1: NUMNEURONSBYLAYER(layer))
                if(TDUK(neuron) > 0)
                    Neurons(layer,neuron) = TDUK(neuron) * TDUWEIGHT*20;
                end
            end
        end
        if TwoRespFeats
            %         %Allow special adjustment for Task Demand Unit in layer 18 (resp TFL)
            %MAHAN: For me TDUR([1 20]) = 0, so TDUR*TDUWEIGHT*20 is just zero,
            %   too and these couple of lines don't do anything. But just in case
            %   nonzero TDUR values for target-items should be used, they will
            %   work
            if layer == 18
                for(neuron = 1: NUMNEURONSBYLAYER(layer))
                    if(TDUR(neuron) > 0)
                        Neurons(layer,neuron) = TDUR(neuron) * TDUWEIGHT*20;
                    end
                end
            end
        end
    end
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %this is the main loop for a lag - runs through timesteps to runlength%
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    for step = 1:runlength
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %1)Layer 1 (input) is treated separately, it's input is copied in %
        %  from the variable "Retina" (from generateinput using           %
        %  inputpatterns) which has, for each time step, the              %
        %  values of all 20 neurons.                                      %
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        
        %Retina is smaller than number of timesteps
        keyshift = step-keydelay;
        if keyshift > 0 && keyshift <= size(Retina,1)
            Neurons(1,1:NUMINPUTS) = Retina(keyshift,1:NUMINPUTS);
            %compute output activation for input layer
            sigout(1,1:NUMINPUTS)= Retina(keyshift,1:NUMINPUTS);
        else % no input after stream is over
            Neurons(1,1:NUMINPUTS) = 0;
            sigout(1,1:NUMINPUTS)= 0;
        end

        respshift = step-respdelay;
        if respshift > 0 && respshift <= size(RespRetina,1)
            %SRIVAS
            Neurons(15,1:NUMINPUTS) = RespRetina(respshift,1:NUMINPUTS);
            %compute output activation for input layer
            sigout(15,1:NUMINPUTS)= RespRetina(respshift,1:NUMINPUTS);
        else % no input after stream is over
            %SRIVAS
            Neurons(15,1:NUMINPUTS) = 0;
            sigout(15,1:NUMINPUTS)= 0;
        end
        
        %initialize the excitatory and inhibitory connection variables
        %ge * g bar e
        bias = zeros(NUMLAYERS,NUMRESPBINDERS);
        %gi * g bar i
        negbias = zeros(NUMLAYERS,NUMRESPBINDERS);
        %excitatory postsynpatic activation
        ExPostsynAct = zeros(NUMLAYERS,NUMRESPBINDERS);
        %inhibitory postsynaptic activation
        InhibPostsynAct = zeros(NUMLAYERS,NUMRESPBINDERS);
        %presynaptic activation
        PresynAct = zeros(NUMLAYERS,NUMRESPBINDERS);
        if SaveNeurAct == 3
            %MAHAN: add tracking of inhibitory force
            inforce_full = zeros(NUMLAYERS,NUMRESPBINDERS);
        elseif SaveNeurAct == 4
            %MAHAN: add tracking of leak force
            leakforce_full = zeros(NUMLAYERS,NUMRESPBINDERS);
        elseif SaveNeurAct == 5
            %MAHAN: add tracking of inhibitory force
            exforce_full = zeros(NUMLAYERS,NUMRESPBINDERS);
        end
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %2)Compute outputs of neurons based on their membrane potentials. %
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        
        %Compute the output using 3 different thresholds for all neurons
        %start at layer 2(masking) - input layer activation is computed in
        %step 1
        % vertical loop
        for lay=2:NUMLAYERS
            for n = 1:NUMNEURONSBYLAYER(lay) % horizontal loop
                
                % check if membrane potential above threshold (theta 1)
                out = max(0,Neurons(lay,n)-THETA(lay));
                % THETA is threshold, GAMMA controls shape, XX1 type
                % activation function
                sigout(lay,n) = (out*GAMMA(lay))/(out*GAMMA(lay)+1);
                
                % check if membrane potential above threshold (theta 2)
                out2 = max(0,Neurons(lay,n)-THETA2(lay));
                %THETA is threshold, GAMMA controls shape
                sigout2(lay,n) = (out2*GAMMA(lay))/(out2*GAMMA(lay)+1);
                
                % check if membrane potential above threshold (theta 3)
                out3 = max(0,Neurons(lay,n)-THETA3(lay));
                % THETA is threshold, GAMMA controls shape
                sigout3(lay,n) = (out3*GAMMA(lay))/(out3*GAMMA(lay)+1);
                
            end %end horizontal loop
        end %end vertical loop
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %3)Now multiply weights by presynaptic output values and add them.%
        %-> creates the post synaptic output                              %
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %run through the list of weights - Weightcount = number of weights
        for w = 1:Weightcount
            layer1 = Weightparams(w,1); %presynaptic layer
            layer2 = Weightparams(w,2); %postsynaptic layer
            n1 = Weightparams(w,3); %presynaptic neuron
            n2 = Weightparams(w,4); %postsynaptic neuron
            ww = Weightparams(w,5);  %weight value
            type = Weightparams(w,6); %weight type
            sat = Weightparams(w,7); %weight saturation
            whichthresh = Weightparams(w,8); %weight threshold 1,2 or 3
            
            %depending on threshold for weight use different output
            if(whichthresh == 1) %theta 1
                so = sigout(layer1,n1);
            elseif (whichthresh == 2) %theta 2
                so = sigout2(layer1,n1);
            else %theta 3
                so = sigout3(layer1,n1);
            end
            
            %presynaptic activation
            PresynAct(layer1,n1) = PresynAct(layer1,n1) + so;
            
            %compute excitatory and inhibitory input to postsynaptic neuron
            if ww > 0 %positive weight value - excitatory connection
                % note the saturation of the output function
                % excitatory input to postsynaptic neuron - add to previous
                % value as there can be multiple connections going into a
                % neuron
                bias(layer2,n2) = bias(layer2,n2) + min(sat,so)*ww;
                %excitatory postsynpatic activation
                if(layer1 == 7 || layer1 == 9 || layer1 == 5 || layer1 == 10 || layer1 == 12 || layer1 == 14 || ...
                        layer1 == 22 || layer1 == 19 || layer1 == 20) %include trace and off neurons
                    ExPostsynAct(layer1,n1) = ExPostsynAct(layer1,n1) + so*ww;
                else
                    if(layer1 ~= layer2) %exclude lateral connections
                        if(~(layer1 == 6 && layer2 == 7) && ~(layer1 == 21 && layer2 == 22) && ~(layer1 == 8 && layer2 == 9)) %exclude gate to trace
                            ExPostsynAct(layer1,n1) = ExPostsynAct(layer1,n1) + so*ww;
                        end
                    end
                end
            elseif ww < 0
                % negative weight value - inhibitory connection
                % inhibitory input to postsynaptic neuron - add to previous
                % value as there can be multiple connections going into a
                % neuron
                negbias(layer2,n2) = negbias(layer2,n2) + min(sat,so)*ww;
                %inhibitory postsynaptic activation
                if(layer1 == 7 || layer1 == 9 || layer1 == 5 || layer1 == 10 || layer1 == 12 || layer1 == 14 || ...
                        layer1 == 22 || layer1 == 19 || layer1 == 20) %include trace and off neurons
                    InhibPostsynAct(layer1,n1) = InhibPostsynAct(layer1,n1) + so*ww;
                else
                    if(layer1 ~= layer2) %exclude lateral connections
                        if(~(layer1 == 6 && layer2 == 7) && ~(layer1 == 21 && layer2 == 22) && ~(layer1 == 8 && layer2 == 9)) %exclude gate to trace
                            InhibPostsynAct(layer1,n1) = InhibPostsynAct(layer1,n1) + so*ww;
                        end
                    end
                end
            end
            
        end %list of weights
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %4)Compute new membrane potentials based on:                     %
        %  excitation, inhibition, bias and leak                         %
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        
        for layer = 2:NUMLAYERS %vertical loop
            
            %add the BIAS weight to excitatory synaptic connections (bias)
            if(layer ~= 8) %all layers except token gate
                bias(layer,:) = bias(layer,:) + BIAS(layer);
                
                %Special bias for token gate layer
            else %excitatory
                %adds the ordered bias for the working memory neurons to
                %ensure sequential use of tokens
                bias(layer,1:NUMWM) = bias(layer,1:NUMWM) + reshape(WMBIAS(1:NUMWM),1,NUMWM);
            end
            %and inbitory bias
            if layer == 8
                negbias(layer,1:NUMWM) = negbias(layer,1:NUMWM) + reshape(WMNEGBIAS(1:NUMWM),1,NUMWM);
            end
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            
            
            for neuron = 1:NUMNEURONSBYLAYER(layer) %horizontal loop
                
                %add the task demand unit input to Task filtered layer%%%%%
                    % **************** IMPORTANT ******************
                    % MAHAN: Avoid longer duration influence of TDU
                    % projections due to the fact that we have a longer
                    % 'prestimulus' period in keydelay
                    %   -- TDUs only project to TFL after period of
                    %   keydelay being over (i.e. stream started), not
                    %   before
                if layer == 4 && TDUK(neuron) > 0
                    if keydelay > 0 && step <= keydelay
                        bias(layer,neuron) = 0;
                    else
                        bias(layer,neuron) = bias(layer,neuron) + TDUK(neuron)*TDUWEIGHT;
                    end
                elseif layer == 4 && TDUK(neuron) < 0
                    if keydelay > 0 && step <= keydelay
                        negbias(layer,neuron) = 0;
                    else
                        negbias(layer,neuron) = negbias(layer,neuron) + TDUK(neuron)*TDUWEIGHT;
                    end
                end
                %MAHAN: If we want only two items' response feature to meet task, implement task demands in resp-path, too
                if TwoRespFeats
                    if layer == 18 && TDUR(neuron) > 0
                        bias(layer,neuron) = bias(layer,neuron) + TDUR(neuron)*TDUWEIGHT;
                    elseif layer == 18 && TDUR(neuron) < 0
                        negbias(layer,neuron) = negbias(layer,neuron) + TDUR(neuron)*TDUWEIGHT;
                    end
                end
                
                %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                %Strong inhibition of the blaster
                %the 5 msec time resolution isn't quite sufficient to
                %mediate rapid inhibition of the blaster, so we force it
                %here by forcing the blaster to 0 activation if the shutoff
                %node is active.
                %At Blaster In Off Layer and output larger than zero
                if layer == 12 && sigout(12,1)
                    newneurons(11,1) = 0; % set Blaster In to zero
                end
                %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                
                %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                %now compute the excitation, inhibition and leak going into
                %this neuron
                %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                %inhibitory force
                inforce = negbias(layer,neuron)*(-1)*(EI(layer)-Neurons(layer,neuron));   %switch the sign!
                if SaveNeurAct == 3
                    inforce_full(layer,neuron) = inforce; %MAHAN: add layer x neuron wide tracking
                end
                %leak force
                leakforce = LEAK(layer) * (EL(layer)-Neurons(layer,neuron));
                if SaveNeurAct == 4
                    leakforce_full(layer,neuron) = leakforce; %MAHAN: add layer x neuron wide tracking
                end
                %excitation force
                exforce = bias(layer,neuron) * (EE(layer)-Neurons(layer,neuron));
                if SaveNeurAct == 5
                    exforce_full(layer,neuron) = exforce; %MAHAN: add layer x neuron wide tracking
                end
                
                %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                %Compute the change in membrane
                %potential for this neuron based on excitatory, inhibitory
                %and leak
                %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                change = (DT_VM(layer)*(exforce +inforce+leakforce));
                
                %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                %set of new neuron values - old plus change
                %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                newneurons(layer,neuron) = Neurons(layer,neuron) + change;
                
            end  %for neuron - "horizontal loop"
            
        end % for layer - "vertical loop"
        
        %membrane potentials
        MembPotAct = Neurons(:,:);
        
        %showneurons - lag, step, layer, neuron
        OutHistory(lag,step,:,:) = PresynAct(:,1:NUMNEURONS);
        InHistory(lag,step,:,:) = ExPostsynAct(:,1:NUMNEURONS);
        MPHistory(lag,step,:,:) = MembPotAct(:,1:NUMNEURONS);
        BiasHistory(lag,step,:,:) = reshape(bias(:,1:NUMINPUTS+1),[1,1,NUMLAYERS,NUMINPUTS+1]);
        BinderHistory(lag,step,1:4,:) = reshape(Neurons([6:7 21:22],1:NUMRESPBINDERS),[1,1,4,NUMRESPBINDERS]);
        
        T1Trace = squeeze(InHistory(:,:,:,1));
        T2Trace = squeeze(InHistory(:,:,:,2));
        
        %save the excitatory and inhibitory postsynaptic output, presynaptic
        %output and membrane potentials
        %(Format: lag,timestep,layer)
        TempMemb = zeros(NUMLAYERS,1);
        TempPre = zeros(NUMLAYERS,1);
        TempEx = zeros(NUMLAYERS,1);
        TempInhib = zeros(NUMLAYERS,1);
        %sum over all neurons in a layer but exclude non-existent target
        %nodes 3-10
        for laycount = 1:NUMLAYERS
            TempMemb(laycount) = sum(MembPotAct(laycount,[1:2 11:end]));
            TempPre(laycount) = sum(PresynAct(laycount,[1:2 11:end]));
            TempEx(laycount) = sum(ExPostsynAct(laycount,[1:2 11:end]));
            TempInhib(laycount) = sum(InhibPostsynAct(laycount,[1:2 11:end]));
        end
        MembPotHistory(lag,step,:) = TempMemb';
        PresynapHistory(lag,step,:) = TempPre';
        ExPostsynHistory(lag,step,:) = TempEx';
        InhibPostsynHistory(lag,step,:) = TempInhib';
        if SaveNeurAct == 1
            %MAHAN: Add tracking of ExPostsynFull
            ExPostsynFull(lag,step,:,:) = ExPostsynAct;
        elseif SaveNeurAct == 2
            %MAHAN: Add tracking of membrane potentials
            VMFull(lag,step,:,:) = MembPotAct;
        elseif SaveNeurAct == 3
            %MAHAN: Add tracking of inhibitory channel
            InhibFull(lag,step,:,:) = inforce_full;
        elseif SaveNeurAct == 4
            %MAHAN: Add tracking of leak channel
            LeakFull(lag,step,:,:) = leakforce_full;
        elseif SaveNeurAct == 5
            %MAHAN: Add tracking of excitatory channel
            ExciteFull(lag,step,:,:) = exforce_full;
        end
       
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %5)Set the current membrane potentials to equal the new ones      %
        % ready for next timestep                                         %
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        Neurons(1:NUMLAYERS,1:NUMRESPBINDERS) = newneurons;
        
    end % for timestep - start new timestep
    
    %check the performance for this trial, target was seen if the token and
    %binder are both active together - this is done for each run of a
    %stream
    perfcheck(lag);
    
    %if target false dont save ERP for this trial
    %accuracy conditions
    % 1) T1 T2
    % 2) T1 notT2
    % 3) notT1 T2
    % 4) notT1 notT2
    T1perf = max(targvals(lag,:,1));
    if onetarg
        if T1perf > 0 %T
            accuracy(lag) = 1;
        else %¬T
            accuracy(lag) = 3;
        end
    else
        T2perf = max(targvals(lag,:,2));
        if T1perf > 0 && T2perf > 0 %T1 T2
            accuracy(lag) = 1;
        elseif T1perf > 0 && T2perf == 0 %T1 ¬T2
            accuracy(lag) = 2;
        elseif T1perf == 0 && T2perf > 0 %¬T1 T2
            accuracy(lag) = 3;
        elseif T1perf == 0 && T2perf == 0 %¬T1 ¬T2
            accuracy(lag) = 4;
        end
    end
    
end %for lag

%used in showneurons
History = MPHistory;
History(:,1,:,1) = 1;

%evaluate the performance of the model - this is done once after all
%streams have been executed. to get final performance
evaltargs;