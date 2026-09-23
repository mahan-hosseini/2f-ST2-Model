% global vars
chapters = {'Chapter 3', 'Chapter 4'};
analyses = {'Alon', 'Srivas'};
basevarpath = 'D:\Kent\Research\Final_ST2\Model\Variables\MultRuns_Final\';
baseplotpath = 'D:\Kent\Research\Final_ST2\Model\Plots\MultRuns_Final\';
saveplots = 1;
% big loop
for c = 1:length(chapters)
    for a = 1:length(analyses)
        % set paths
        varpath = [basevarpath chapters{c} '\' analyses{a} '\'];
        plotpath = [baseplotpath chapters{c} '\' analyses{a} '\'];
        % set TwoRespFeatures
        if strcmp(analyses{a}, 'Alon')
            TwoRespFeatures = 1;
            Srivas3Trace = 1;
        elseif strcmp(analyses{a}, 'Srivas')
            TwoRespFeatures = 0;
            Srivas3Trace = 0;
        end
        % set allnames
        if strcmp(chapters{c}, 'Chapter 4') && strcmp(analyses{a}, 'Alon')
            allnames = {'key0_resp0', 'key9_resp0', 'key24_resp0'};
        else
            allnames = {'key0_resp0', 'key24_resp0'};    
        end
        % run
        runMultipleRuns(allnames, TwoRespFeatures, Srivas3Trace, varpath, plotpath, saveplots)
    end
end