guesses = nan(NUMSTREAMS,NUMITEMS);
for(i = 1:NUMSTREAMS)
    if length(respbindings) == 1
        T1resp(i) = respbindings(1);
        disp(sprintf('Bound response %d for lag %d', T1resp(i), i));
    elseif length(respbindings) > 1
        multbind = multbind + 1;
        multbindings = find(squeeze(resptargvals(i,1,:)));
        T1resp(i) = multbindings(ceil(rand * length(multbindings)));
        disp([sprintf('Multiple response binding %d for lag %d: ', multbind, i) num2str(respbindings') sprintf(' resolved to %d.', T1resp(i))]);
    else
    end
    %MAHAN: Store reported type (1st guess) & make model "guess more often"
    % gues = 4 (lags, for us in 2fst2 this is just 4 trials)
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
        thistrial_guesses(1,1:length(multbinds)) = [];              % initialise empty array 
        thistrial_guesses(1) = T1resp(i);                           % first index is just what's bound
        num2guess = length(respbindings) - 2;                       % how many guesses do we need to make 
                                                                    % (total length of multbinds - 2 (subtract 2 because: 1 bc we know response & 
                                                                    % 1 because 1 is left after last guess)
        if num2guess == 0                                           % means length(multbinds = 2 - note "respbindings" & "multbindings" are exactly the same 
                                                                    % whenever trial had multbinds (otherwise multbinds var is not made)
            thistrial_guesses(end) = respbindings(respbindings~=T1resp(i));   % second guess is only option, thus it's the type that is not the response (ie. T1resp(i))
        elseif num2guess > 0                                                  % this means we have to guess again
                guessarray = multbindings(multbindings~=T1resp(1));           % throw out response for array to guess on
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
    end
end