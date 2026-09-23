function perfcheck(lag)
%for a given trial, check to see if the binders and tokens are active

global NUMWM Neurons NUMTARGS NUMBINDERS NUMRESPBINDERS NUMITEMS
global Weightparams Weightindex binders targvals resptargvals

%t is tokens, b is binders, targ is target number

for(t = 1:NUMWM)
    if Neurons(9,t) > .5
        binders = 0;
        for(b = 1:NUMBINDERS)
            if(~Weightindex(8,6,t,b))
                if(binders == 0)
                    binders = b;
                else
                    binders = [binders b];
                end
            end
        end

        %targvals(Lag, Token, Target)

        %IF there is a weight between this binder and the target we are
        %checking then check to see if both this binder AND its token have
        %active trace nodes

        %If those nodes are active (above .5), then the corresponding target has been
        %encoded
        %The trace neurons are self-sustaining, so by the end of the trial they
        %are either on or off.

        for b=binders
            for targ= 1:NUMTARGS
                w = Weightindex(4,6,targ,b);
                if(w)
                    if(Neurons(7,b) > .5)
                        targvals(lag,t,targ) = targvals(lag,t,targ) + Weightparams(w,5);
                        disp(sprintf('token %d: key item %d bound to binder %d.', t, targ, b));
                    end
                end
            end
        end
        %SRIVAS
        respbinders = 0;
        for(b = 1:NUMRESPBINDERS)
            if ~Weightindex(8,21,t,b)
                if(respbinders == 0)
                    respbinders = b;
                else
                    respbinders = [respbinders b];
                end
            end

        end

        for b=respbinders
            for item= 1:NUMITEMS
                w = Weightindex(18,21,item,b);
                if(w)
                    if(Neurons(22,b) > .5)
                        resptargvals(lag,t,item) = resptargvals(lag,t,item) + Weightparams(w,5);
                        disp(sprintf('token %d: response item %d bound to binder %d.', t, item, b));
                    end
                end
            end
        end
    end
end


