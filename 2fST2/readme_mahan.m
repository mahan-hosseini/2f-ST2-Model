%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% MAHAN: 
%   Some notes about using the single-target version (i.e. 2fST2):
%       (note that I don't guarantee that any of this is correct, it's just
%       my understanding of things)

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%   1) NUMTARGS (set in architecture.m)
%       This is set to 10, even though it really is just 1
%       This is something that is left from the original ST2 model, which
%       needed this amount of 'targets', so that the second target (T2)
%       could be presented at different serial positions (i.e. lags 1-8)

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%   2) TARGET POSITIONS (compare TDUs at the end of architecture.m)
%       Differ for key & response paths/features
%       Our target is always represented by neuron 1 in a layer 
%           (as in original model)
%       However, for the response pathway, neurons 18 to 21 reflect -2 to
%           +2 intrusions, respectively
%       This can be seen in st2data2eeglab.m around line 160, where:
%           targetpos = 20 (but this pos REALLY IS the +1!)
%       which then goes on to:
%           if allresp(i) == 1 (i.e. the 1st type/item/neuron was the model's
%                               response)
%               response = correct
%           elseif allresp(i) - targetpos == 0 (which means allresp(i) == 20)
%               response = post1
%           and so on
%       Also, the shift variable in this function is only used to
%           response-lock vERP (that I personally didn't do)
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
%   3) Task-Filtered Layers & TDUs
%       Task Demand Units (TDUs) set at the end of architecture.m
%       Used in runRSVP.m
%           (around line 100 when initializing the layer & 
%           around 285 when implementing the weights)
%       The general idea (both, for Srivas or my version) is that if the
%           TDU (for any pathway) is above 0, we add it to the (positive)
%           bias-variable, and if it is below 0, we add it to the (negative)
%           negbias variable
%           ==> bias & negbias are used in runRSVP.m around line 320 when
%               computing the excitation and inhibitory force going in a given
%               neuron
%           ==> Note that the bits of code I added in runRSVP for TDUR of
%               targets don't really run because the TDUR I use is zero. So we
%               inhibit distractors and do not inhibit distractors. But there
%               still is a possibility of going above 0 for TDUR of targets if
%               somebody wants to do so in the future.
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
%   4) Using Excitatory Postsynaptic Activation Arrays
%       Is computed in runRSVP while running the model in variable 
%           ExPostsynAct around lines 240 & 350-380 
%       This variable is then used to either save the summed activation of
%           all neurons in a layer in variable ExPostsynBat_basic
%           (bigbattery.m) or for each neuron individually in
%           ExPostsynFull_basic (sorry about these names)
%       I added an input to runModel that determines whether to save the
%           neuron-activations, too, as it increases the time it takes to run
%           the model by a factor of 4 and also makes the files really big
%       
%                                   IMPORTANT
%       ==> If you work with these variables after running the model to
%           plot the activation levels of individual layers or neurons within
%           these layers, for example, you combine lags x 'trials' into trials.
%       ==> The way I understand this is that this model was set up to have
%           2 targets & different lags. For the single-target version we still
%           practivally have lags, because of the model's architecture, but
%           they don't really have any meaning, so we just combine
%           these 'lags' to all be trials
%       ==> What took me quite some time to figure out is that BEFORE we
%           run the reshape function to get them into trial x timepoint
%           (instead of lags x 'trials' x timepoints), we HAVE TO MAKE SURE
%           that the size of the array is:
%           LAGS x TRIALS x TPs 
%               and NOT
%           TRIALS x LAGS x TPS
%               ==> Otherwise, the responses that we extract (using
%                   st2data2eeglab or my extract_responses function) DO NOT
%                   MATCH THE TRIAL-ORDER OF THE ARRAYS!
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
%   5) How the delay (taus) are implemented
%       ==> KEY & RESPONSE TAUS
%           Happens in runRSVP.m, for example for key-delay, the central
%           line is (line 146 for me):
%        keyshift = step-keydelay;
%           Here, step is timestep and keyshift is then used to index
%           Neurons & sigout variables for first (input) layer.
%        if keyshift > 0 && keyshift <= size(Retina,1)
%            Neurons(1,1:NUMINPUTS) = Retina(keyshift,1:NUMINPUTS);
%            %compute output activation for input layer
%            sigout(1,1:NUMINPUTS)= Retina(keyshift,1:NUMINPUTS);
%        else % no input after stream is over
%            Neurons(1,1:NUMINPUTS) = 0;
%            sigout(1,1:NUMINPUTS)= 0;
%        end
%       -- Hence, if we have a delay, keyshift is negative in the beginning
%           and the if keyshift > 0 ensures that the retina is not copied into
%           the input layer.
%       -- At the point where it becomes positive, the delay is implemented
%       -- E.g., if delay = 20, the FIRST timepoint COPIED to the input
%           layer IN REALITY is timepoint 20
%   
%       ==> RANDOM TAU (in generateinput.m)
%                       SRIVAS' original way
%     randkeydelay = round(delaystd * randn)
%     for(j= 1: stepperlag+randkeydelay)   %now fill in the actual bits of items for each 5 ms timestep
%         keytindex = keytindex + 1;
%         if keytindex <= NUMITEMS * stepperlag
%             Retina(keytindex,1:NUMINPUTS) = tempret;
%         end
%     end
%       -- This is part of the bigger loop (with index i) that loops over
%           items (hence this j-loop happens for every item)
%       -- The random delay is therefore just implemented via varying the
%           length of the j-loop, which copies 'tempret' (the temporary retina
%           of this timepoint) to the 'big' Retina (of size timesteps x items)
%       -- Note that this way leads to non-stationary behaviour of
%           input-layer activations, with the average activation trace of later
%           items being wider and lower-amplitude than of early items. This is
%           because the 'randomness' of previous items keeps adding up and
%           hence the starting point of later items is much more variable than
%           for earlier items (in addition to their random length)
%                       INSERT MY WAY OF RANDN HERE
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
%   6) How the input channels are programmed / work
%   A) Step 3 of runRSVP is to multiply the weights by presynaptic output
%       values and adding them to it which gives the postsynaptic output
%   B) For this, we loop through all weights and if the weight is positive
%       we update 
%           A) the bias
                bias(layer2,n2) = bias(layer2,n2) + min(sat,so)*ww;
%           B) ExPostsynAct
                ExPostsynAct(layer1,n1) = ExPostsynAct(layer1,n1) + so*ww;
%       It's the same for negative weights and inhibitory bias & postsynact
                negbias(layer2,n2) = negbias(layer2,n2) + min(sat,so)*ww;
                InhibPostsynAct(layer1,n1) = InhibPostsynAct(layer1,n1) + so*ww;
%       --> NOTE HERE THAT ExPostsynAct & InhibPostsynAct are used ONLY FOR
%           SAVING THE ACROSS-LAYER (i.e. all neurons summed) values for
%           analyses (this was before I implemented saving neuron-specific 
%           act/vm/chan-values)
%   C) We then compute excitatory, inhibitory and leak force going in to
%       the neuron (i.e. input channels)
                %excitation force
                exforce = bias(layer,neuron) * (EE(layer)-Neurons(layer,neuron));
                %inhibitory force
                inforce = negbias(layer,neuron)*(-1)*(EI(layer)-Neurons(layer,neuron));   %switch the sign!
                %leak force
                leakforce = LEAK(layer) * (EL(layer)-Neurons(layer,neuron));
%   D) We then update the change in membrane potential (VM)
                change = (DT_VM(layer)*(exforce +inforce+leakforce));
%   E) And finally update the neuron's new VM
                newneurons(layer,neuron) = Neurons(layer,neuron) + change;
                
%          --> ADDED THE FOLLOWING NOTE IN runRSVP about bias and inforce,
%               too
%MAHAN: Howard says this bias is the excitatory conductance
%
bias(layer2,n2) = bias(layer2,n2) + min(sat,so)*ww;
% The forces are like currents & the biases are conductances

%MAHAN: we have to switch the sign here because if ww is
%   negative (which it is for the inhibitory channel), then we
%   have to make sure that inforce itself is positive
inforce = negbias(layer,neuron)*(-1)*(EI(layer)-Neurons(layer,neuron));   %switch the sign!

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%   

%