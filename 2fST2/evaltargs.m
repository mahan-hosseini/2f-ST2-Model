function evaltargs
%Using targvals, which is computed in perfcheck.m  (called by runRSVP) we
%check to see if the target is seen and compute the swaps

global T1perf T2perf Swapencoding
global NUMSTREAMS OutHistory
global doubleencoding targvals resptargvals T1resp resptargval respitemval multbind
global summate summateacc summatecount summateflag summateflag2 summate2 summateacc2 summatecount2
global guesses NUMITEMS %MAHAN: for making the model guess more often

%NUMSTREAMS is lags!!

T1perf = zeros(NUMSTREAMS,1);
T2perf = zeros(NUMSTREAMS,1);
Swapencoding = zeros(NUMSTREAMS,1);
doubleencoding = zeros(NUMSTREAMS,1);
%SRIVAS
T1resp = zeros(NUMSTREAMS,1);
%MAHAN
guesses = nan(NUMSTREAMS, NUMITEMS); % 4 ("lags") x 25 (items)

for(i = 1:NUMSTREAMS)
    T1perf(i) = max(targvals(i,:,1));
    T2perf(i) = max(targvals(i,:,2));
    if(T1perf(i) & T2perf(i))
        %compute Swaps
        %an unknown case, order is 50/50
        if(max(abs(targvals(i,:,1) - targvals(i,:,2))) == 0)
            Swapencoding(i,1) = .5;
        end
        % a definite swap
        if(targvals(i,2,2) ==0 & targvals(i,2,1) > 0&targvals(i,3,2) ==0)
            Swapencoding(i,1) = 1;
        end
        %doubles are duplicate encodings of a single target
        if(targvals(i,1,1) & targvals(i,2,1) & ~targvals(i,2,2))
            doubleencoding(i) = 1;
        end
        if(~targvals(i,2,1) & targvals(i,2,2) & targvals(i,3,2))
            doubleencoding(i) = 1;
        end
    end
    
    %SRIVAS
    respbindings = find(squeeze(resptargvals(i,1,:)));
    if length(respbindings) == 1
        T1resp(i) = respbindings(1);
        disp(sprintf('Bound response %d for lag %d', T1resp(i), i));
    elseif length(respbindings) > 1
        multbind = multbind + 1;
        multbindings = find(squeeze(resptargvals(i,1,:)));
%         if TwoRespFeatures == 0 %Srivas original way
            T1resp(i) = multbindings(ceil(rand * length(multbindings)));
%         elseif TwoRespFeatures == 1
%             coin = randi(2,1,1); % flip a coin whether response was 0 or +1 (valid because we always have 2 responses possible at most)
%             T1resp(i) = multbindings(coin);
%         end
        disp([sprintf('Multiple response binding %d for lag %d: ', multbind, i) num2str(respbindings') sprintf(' resolved to %d.', T1resp(i))]);
    else
        disp(sprintf('No response bound for lag %d.', i));
    end

    
    %MAHAN: Code to make model guess more often (to replicate Vul's experiments)
    % Store reported type (1st guess) & make model "guess more often"
    % gues dimensions = 
    %       4 (lags, for us in 2fst2 this is just 4 trials)
    %       x 
    %       NUMITEMS (25 = numrespneurons (max length, i.e., if all
    %       types would have been bound))
    %           [in contrast: NUMTARGETS (10 = numkeyneurons) [if I understand
    %           it correctly, distractor key features are just repeated)]
    %   & then assign to big global guess matrix (dimension: 4 x 343 x NUMITEMS)
    %   & then extract into 1 x trialnum matrix that keeps dimensions of eg
    %       vars saving neurons acts & VMs etc.
    %   => using nan to see when we can stop guessing
    if length(respbindings) == 1
        thistrial_guesses = respbindings; % if just 1 type bound, that's our guess (don't use multbinds, it doesn't exist in this case!)
    elseif length(respbindings) > 1
        thistrial_guesses = zeros(1,length(multbindings));        % initialise empty array 
        thistrial_guesses(1) = T1resp(i);                           % first index is just what's bound
        num2guess = length(respbindings) - 2;                       % how many guesses do we need to make 
                                                                    % (total length of multbinds - 2 (subtract 2 because: 1 bc we know response & 
                                                                    % 1 because 1 is left after last guess)
        if num2guess == 0                                           % means length(multbinds = 2 - note "respbindings" & "multbindings" are exactly the same 
                                                                    % whenever trial had multbinds (otherwise multbinds var is not made)
            thistrial_guesses(end) = respbindings(respbindings~=T1resp(i));   % second guess is only option, thus it's the type that is not the response (ie. T1resp(i))
        elseif num2guess > 0                                                  % this means we have to guess again
                guessarray = multbindings(multbindings~=T1resp(i));           % throw out response for array to guess on
                for g = 1:num2guess                                           % for all guesses
                    thisguess =  guessarray(ceil(rand * length(guessarray))); % make the guess (exactly how response was chosen)
                    thistrial_guesses(1+g) = thisguess;                       % assign to this trial's guesses
                    guessarray = guessarray(guessarray~=thisguess);           % throw out the guess just made
                end
                if length(guessarray) ~= 1
                    disp('guessing is wrong - stopping model')                % sanity check, after we have made all guesses, only 1 type should be left (always!)
                end
                thistrial_guesses(end) = guessarray;                    
        end
    else
        thistrial_guesses = nan;                                              % if the model missed, just keep nan
    end
    guesses(i,1:length(thistrial_guesses)) = thistrial_guesses;               % assign this trials (ie. lags) guesses to 4 x numitems array 
end


%store activation traces for correct T2s
if(summateflag)
    for(lag = 1:NUMSTREAMS)
        T2perf(lag);
        if(T2perf(lag) > 0)
            'seen';
            summatecount(lag) = summatecount(lag) +1;
            summate(summatecount(lag),lag,:,:,:) = squeeze(OutHistory(lag,:,[4 7 9],1:2));
%             summateacc(summatecount(lag),1) = T1perf(3);
%             summateacc(summatecount(lag),2) = T2perf(3);
        else
            'missed';
            summatecount2(lag) = summatecount2(lag) +1;
            summate2(summatecount2(lag),lag,:,:,:) = squeeze(OutHistory(lag,:,[4 7 9],1:2));
%             summateacc2(summatecount2(lag),1) = T1perf(3);
%             summateacc2(summatecount2(lag),2) = T2perf(3);
        end
    end
end
