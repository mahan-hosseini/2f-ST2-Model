%%                  Allguesses is trial x lag x guesses
function plot_VulFigures_SingleRun
%
%   0) Load a given latinhib condition

% ***************************** IMPORTANT ********************************* 
% THIS FUNCTION IS NOT USED FOR THE RESULTS PRESENTED IN THE THESIS / PAPER
% THAT FUNCTION IS CALLED "ReplicatingVul_RunAndPlotMultRuns"
% *************************************************************************

% prepare loading
varpath = "/Users/mahan/Library/CloudStorage/GoogleDrive-mambahan@googlemail.com/My Drive/Research/Final_ST2/Model/Variables/ReplicatingVul/";
% plotpath = '/Users/mahan/Library/CloudStorage/GoogleDrive-mambahan@googlemail.com/My Drive/Research/Final_ST2/Model/Plots/ReplicatingVul/';
plotpath = "/Users/mahan/Desktop";
endname = "Srivas/key0_resp0/";
varname = "latinhib ";
latinhibs = {"0/", "-.01/", "-.02/", "-.03/", "-.04/", "-.05/"};

% prepare orig var
guesses.original = [];
guesses(length(latinhibs)).original = [];
for l = 1:length(latinhibs)
    load(strcat(varpath, varname, latinhibs{l}, endname, "Guesses.mat"));
    guesses(l).original = allguesses;
    clear allguesses
end

%   Transform orig shape & create vars we need for figure
for l = 1:length(latinhibs)
    %   1) Collapse across trials & lags (mean the same thing for 2fst2)
    %   ==> fullmat has trials x guessnumber dimensions
    guesses(l).fullmat = reshape(guesses(l).original, size(guesses(l).original,1)*size(guesses(l).original,2), size(guesses(l).original,3));
    
    %   2) Store info about proportion of misses, singlebinds & multbinds
    %   ==> Use the same structure you want to generate for step 5 (rows =
    %       latinhibs)
    fulltrialnum = size(guesses(l).fullmat,1);
    missnum = 0;
    singlebindnum = 0;
    multbindnum = 0;
    for t = 1:fulltrialnum
        if isnan(guesses(l).fullmat(t,1))                      % if 1st index is NaN it's a miss
            missnum = missnum + 1;
        else
            if isnan(guesses(l).fullmat(t,2))
                singlebindnum = singlebindnum + 1; % if 2nd index is NaN only 1 type was bound
            else
                multbindnum = multbindnum + 1;     % if 2nd index is not NaN at least 2 types were bound
            end
        end
    end
    % Assign to struct & delete vars for next loop iteration
    guesses(l).missnum = missnum;
    guesses(l).singlebindnum = singlebindnum;
    guesses(l).multbindnum = multbindnum;
    clear missnum singlebindnum multbindnum
    
    %   3) Only include -2 to +2s (so that variability in (e.g.) -3s
    %      doesn't confound proportions of set going -2 to +2)
    idx2include = find(ismember(guesses(l).fullmat(:,1), [1 15:19 20:24])); % -5 to +5 (range of Vul's figure)
%     idx2include = find(~isnan(guesses(l).fullmat(:,1)));
    guesses(l).cleanmat = guesses(l).fullmat(idx2include,:);
    
    %   4) Store proportions of Guess 1s (Responses)
    %   ==> just 1st col of cleanmat (because those are responses))
    guesses(l).trialnum = size(guesses(l).cleanmat,1);                          % num of rows is trialnum
    guesses(l).responseset = unique(guesses(l).cleanmat(:,1));                  % response set is unique entries of 1st column (response) [possibility to include -3 responses, but our model doesn't do that for Srivas, key0_resp0 & the "orig" rng seed)
    guesses(l).respprops = zeros(1, length(guesses(l).responseset));
    for r = 1:length(guesses(l).responseset)
        this_freq = sum(guesses(l).cleanmat(:, 1) == guesses(l).responseset(r));% how often was this response the 1st guess
        guesses(l).respprops(r) = this_freq / guesses(l).trialnum;              % make a proportion out of it and store
    end
    
    %   5) Store distributions of probabilities of 2nd guesses conditional on 1st
    %   ==> Response set is just -2 to +2
    responseset = [18, 19, 1, 20, 21];
    fullguess2set = [1 15:19 20:24]; % only from -5 to +5
    responsestrings = {'minus2', 'minus1', 'target', 'plus1', 'plus2'};         % only need cond. probs for G2 of -2 to +2 responses (Vul has xaxis range of -5 to +5 but only 5 separate lines, from -2 to +2)
    %   ==> Loop over response set
    for r = 1:length(responsestrings)
        clear idx2include
        % Find out indices where current response was made
        idx2include = find(guesses(l).cleanmat(:,1) == responseset(r));                                            % extract only those trials from cleanmat where guess1 was given response
        guesses(l).(responsestrings{r}).guess2vec_wNaNs = [];
        guesses(l).(responsestrings{r}).guess2vec_wNaNs = guesses(l).cleanmat(idx2include, 2);                     % only 2nd column
        % Only take those trials where there was a second guess (ie. exclude singlebinds)
        idx2include_g2 = find(ismember(guesses(l).(responsestrings{r}).guess2vec_wNaNs, fullguess2set));           % range of -5 to +5 (Vul's xaxis range)
        guesses(l).(responsestrings{r}).guess2vec = guesses(l).(responsestrings{r}).guess2vec_wNaNs(idx2include_g2);
        guesses(l).(responsestrings{r}).trialnum = length(guesses(l).(responsestrings{r}).guess2vec);              % how many trials with response being r & there being a 2nd guess
        % Extract Guess2 Set (this is different to responseset, because Vul looked at -5 to +5 (w.r.t. target) for Guess2s
        guesses(l).(responsestrings{r}).guess2set = unique(guesses(l).(responsestrings{r}).guess2vec);             % extract all unique responses of Guess 2 (Vul went from -5 to +5 for G2)
        guesses(l).(responsestrings{r}).guess2strings = cell(1,length(guesses(l).(responsestrings{r}).guess2set));
        % Loop over all different Guess2s of this given response and compute their respective proportions (similar to how we computed proportion of responses above)
        for g2 = 1:length(guesses(l).(responsestrings{r}).guess2set)
            guesses(l).(responsestrings{r}).guess2strings{g2} = typeidx2respstr(guesses(l).(responsestrings{r}).guess2set(g2));
            this_freq = sum(guesses(l).(responsestrings{r}).guess2vec == guesses(l).(responsestrings{r}).guess2set(g2));
            guesses(l).(responsestrings{r}).guess2props(g2) = this_freq / guesses(l).(responsestrings{r}).trialnum;
        end
    end
end

%   6) Save the structure
save('Guess Structure', 'guesses')

%   7) Then do the plotting on the proportions
%   ==> Grey line just uses the Response proportions
plotit(guesses, plotpath)
end

%% function that plots all plots
function plotit(guesses, plotpath)
latinhibs = {'0\', '-.01\', '-.02\', '-.03\', '-.04\', '-.05\'};
latinhibstrings = {'0', '-.01', '-.02', '-.03', '-.04', '-.05'};
for l = 1:length(latinhibs)
    % % 1 - barplot showing miss, singlebind & multbind proportions
    % these_props = zeros(1,3);
    % trialnum = size(guesses(l).fullmat,1);                          % how many trials
    % these_props(1) = guesses(l).missnum / trialnum;
    % these_props(2) = guesses(l).singlebindnum / trialnum;
    % these_props(3) = guesses(l).multbindnum / trialnum;
    % figure;
    % set(gcf, 'Position', [384   503   857   476])
    % barplot = bar(these_props, 'FaceColor', 'flat');
    % barplot.CData(1, :) = rgb('sky blue');
    % barplot.CData(2, :) = rgb('lavender');
    % barplot.CData(3, :) = rgb('khaki');
    % ax = gca;
    % ax.XTickLabels = {'Misses', 'Single Binds', 'Multi Binds'};
    % ax.YLabel.String = 'Proportion';
    % this_name = ['Binding Distributions. Resp. TFL Latinhib = ' latinhibstrings{l}]; % for title & saving
    % ax.Title.String = this_name;
    % ax.FontSize = 17;
    % ax.XLabel.FontSize = 20;
    % ax.YLim = [0 0.8];
    % saveas(gcf, strcat(plotpath, this_name, ".jpg"))
    
    % 2 - Vul's Figure 9
    % For each line: 
    %   1) Transform type numbering to be -x to +x instead of 1 & 15-25 (e.g.)
    %   2) Order responsevectors (set & proportions) so that 0 is in index 
    %      inbetween -1 and +1 (e.g. - could be -2 and +1 too)
    %   3) Plot the line

    figure;
    set(gcf, 'Position', [13   508   953   445])
    thinlinewidth = 1.5;
    thicklinewidth = 10;

    % grey line - responses
    orig_responseset = guesses(l).responseset;
    responseset = zeros(1,length(orig_responseset));
    for r = 1:length(orig_responseset)
        responseset(r) = typeidx2respnum(orig_responseset(r)); % change model type numbering to be numbering of responses with target being 0
    end
    responseprops = guesses(l).respprops;
    [ordered_responseset, ordered_responseprops] = order_responsevectors(responseset, responseprops); % order the vectors
    responseline = plot(ordered_responseset, ordered_responseprops); 
    responseline.Color = [rgb('grey') 0.5];
    responseline.LineWidth = thicklinewidth;
    hold on

    % red line - distribution of guess2s if response was minus 2
    orig_minus2set = guesses(l).minus2.guess2set;
    minus2set = zeros(1, length(orig_minus2set));
    for r = 1:length(orig_minus2set)
        minus2set(r) = typeidx2respnum(orig_minus2set(r)); % change model type numbering to be numbering of responses with target being 0
    end
    minus2props = guesses(l).minus2.guess2props;
    [ordered_minus2set, ordered_minus2props] = order_responsevectors(minus2set, minus2props); % order the vectors
    minus2line = plotcolouredlines(ordered_minus2set, ordered_minus2props, 'r', thinlinewidth);  

    % olive line - distribution of guess2s if response was minus 1
    orig_minus1set = guesses(l).minus1.guess2set;
    minus1set = zeros(1, length(orig_minus1set));
    for r = 1:length(orig_minus1set)
        minus1set(r) = typeidx2respnum(orig_minus1set(r)); % change model type numbering to be numbering of responses with target being 0
    end
    minus1props = guesses(l).minus1.guess2props;
    [ordered_minus1set, ordered_minus1props] = order_responsevectors(minus1set, minus1props); % order the vectors
    minus1line = plotcolouredlines(ordered_minus1set, ordered_minus1props, rgb('olive'), thinlinewidth);      

    % green line - distribution of guess2s if response was target
    orig_targetset = guesses(l).target.guess2set;
    targetset = zeros(1, length(orig_targetset));
    for r = 1:length(orig_targetset)
        targetset(r) = typeidx2respnum(orig_targetset(r)); % change model type numbering to be numbering of responses with target being 0
    end
    targetprops = guesses(l).target.guess2props;
    [ordered_targetset, ordered_targetprops] = order_responsevectors(targetset, targetprops); % order the vectors
    targetline = plotcolouredlines(ordered_targetset, ordered_targetprops, 'g', thinlinewidth);      

    % blue line - distribution of guess2s if response was plus 1
    orig_plus1set = guesses(l).plus1.guess2set;
    plus1set = zeros(1, length(orig_plus1set));
    for r = 1:length(orig_plus1set)
        plus1set(r) = typeidx2respnum(orig_plus1set(r)); % change model type numbering to be numbering of responses with target being 0
    end
    plus1props = guesses(l).plus1.guess2props;
    [ordered_plus1set, ordered_plus1props] = order_responsevectors(plus1set, plus1props); % order the vectors
    plus1line = plotcolouredlines(ordered_plus1set, ordered_plus1props, 'b', thinlinewidth);      

    % purple line - distribution of guess2s if response was plus 2
    if ~isempty(guesses(l).plus2.guess2set) % there was a case in which no multbindings occured for plus2 responses
        orig_plus2set = guesses(l).plus2.guess2set;
        plus2set = zeros(1, length(orig_plus2set));
        for r = 1:length(orig_plus2set)
            plus2set(r) = typeidx2respnum(orig_plus2set(r)); % change model type numbering to be numbering of responses with target being 0
        end
        plus2props = guesses(l).plus2.guess2props;
        [ordered_plus2set, ordered_plus2props] = order_responsevectors(plus2set, plus2props); % order the vectors
        plus2line = plotcolouredlines(ordered_plus2set, ordered_plus2props, rgb('purple'), thinlinewidth);
    end

    hold off

    % figure stuff to make it resemble Vul's
    ax = gca; 
    X_absmax = max([abs(ax.XLim(1)) abs(ax.XLim(2))]); % make the plot symmetrical around 0
    ax.XLim = [-5 5]; 
    ax.XLabel.String = 'Serial position (0 = Target)';
    ax.YLabel.String = 'Frequency of Guess 2 report';
    ax.FontSize = 20;
    lgd = legend([responseline, minus2line, minus1line, targetline, plus1line, plus2line], ... % make sure that markers are not in legend - cat the lines!
        {'Guess 1 Prediction', 'Guess 1 = -2', 'Guess 1 = -1', 'Guess 1 = 0', 'Guess 1 = 1', 'Guess 1 = 2'}, 'FontSize', 14);
    set(lgd, 'Box', 'off')

    % title & save
    this_name = ['Vul''s Figure 9 with the 2fST2. Resp. TFL Latinhib = ' latinhibstrings{l}]; % for title & saving
    ax.Title.String = this_name;
    ax.Title.FontSize = ax.Title.FontSize - 2;
    saveas(gcf, [plotpath this_name '.jpg']);
end
end

%% function plots conditional probabilities (coloured lines with gaps)
function p = plotcolouredlines(guessset, guessprobs, condcolour, linewidth)

% Using 2 vectors of same length with NaNs and using plot(x,y) plots with
% gaps!
% ==> See: https://de.mathworks.com/matlabcentral/answers/558911-plotting-with-gaps-in-x-axis-data
%
% prepare vars
xaxisrange = -5:1:5;                    % define range of xaxis (-5 to +5)
plotY = nan(1,11);                      % initialise vector of probabilities
plotX = xaxisrange;

% assign vars using set & prob vars
for i = 1:length(xaxisrange)
    if ismember(plotX(i), guessset)
        idx2include = find(guessset == plotX(i));
        plotY(i) = guessprobs(idx2include);
    end
end

% plot the line with gaps
p = plot(plotX, plotY);                     % plot line
p.Color = condcolour;                       % change colour
p.LineWidth = linewidth;                    % change width

% plot markers in a loop to make sure points that don't have a "neighbor"
% xvalue (hence cannot be a line) are plotted!
for i = 1:length(guessset)
    plot(guessset(i), guessprobs(i), 'x', 'MarkerSize', 15, 'Color', condcolour, 'LineWidth', 2);
end

end

%% function transforms numbering of types in 2fst2 to response ***STRING*** w.r.t. target
function respstr = typeidx2respstr(typeidx)
if typeidx == 1
    respstr = '0';
elseif typeidx < 20 % 19 & below are pretarget intrusions
    respidx = typeidx - 20; % because 19 is -1, 18 is -2 etc.
    respstr = num2str(respidx);
elseif typeidx >= 20
    respidx = typeidx - 19; % because 20 is +1, 21 is +2 etc.
    respstr = ['+ ' num2str(respidx)];
end
end

%% function transforms numbering of types in 2fst2 to response ***NUMBER*** w.r.t. target
function respnum = typeidx2respnum(typeidx)
if typeidx == 1
    respnum = 0;
elseif typeidx < 20 % 19 & below are pretarget intrusions
    respnum = typeidx - 20; % because 19 is -1, 18 is -2 etc.
elseif typeidx >= 20
    respnum = typeidx - 19; % because 20 is +1, 21 is +2 etc.
end
end

%% function transforms order of response set & proportions vectors (to have it in the order that will be plotted by the lines)
%   ==> Used for guess2s as well!
%   ==> This is done on -x to +x (w.r.t. target) positioning of responses
%       (important because we are using responseset's signchanges to identify
%       where the target has to go!)
function [ordered_responseset, ordered_responseprops] = order_responsevectors(responseset, responseprops)
% initialise
ordered_responseset = zeros(1,length(responseset));
ordered_responseprops = zeros(1, length(responseset));

% make a vector of signs
signvec = sign(responseset);                 

% sanity check because code does not handle case of target & only pretarget intrusions being made
sanityvec = ones(1,length(signvec)-1);                  
sanityvec = sanityvec * -1;
if isequal(signvec(2:end), sanityvec)
    msgbox('the unlikely case of only pretarget responses and the target being provided happened. the order-function is not set up to handle this. modify code. cancelling function!')
    return
end

% for ifstatement below
signchanges = zeros(1,length(signvec)-1);                 % initialise signchanges
for s = 1:length(signvec)-1
    % if the sum between signs of this idx and the next is 0 sign either changed from -1 to +1 or vice versa.
    % because we always start with pretargs, we know it changed from -1 to +1
    % ==> I.e. that's the index where we want to throw in our target
    signchanges(s) = signvec(s) + signvec(s+1);
end

% order
if signvec(1) == 0 && sum(ismember(signchanges, 0)) > 0               % if responses include target, it's in 1st idx. also: make sure that there is a switch from pretargs to posttargs in responses (otherwise we don't need to do anything with the target)
    for s = 1:length(signvec)-1
        % we could also use find(signchanges == 0) but I'll just do it manually
        signchange = signvec(s) + signvec(s+1);
        if signchange == 0
            switchidx = s;
        end
    end
    % order responsevectors using switchidx
    ordered_responseset(1:switchidx-1) = responseset(2:switchidx);       % pretargs have to be 1 earlier
    ordered_responseset(switchidx) = responseset(1);                     % target now is @ switchidx
    ordered_responseset(switchidx+1:end) = responseset(switchidx+1:end); % end of vector doesn't change (posttargs)
    ordered_responseprops(1:switchidx-1) = responseprops(2:switchidx);
    ordered_responseprops(switchidx) = responseprops(1);
    ordered_responseprops(switchidx+1:end) = responseprops(switchidx+1:end);
else
    % if target was not included, just keep as is (because then ordering is correct)
    ordered_responseset = responseset;
    ordered_responseprops = responseprops;
end
end

%%   PREVIOUS NOTE - Extract uniques of Guessvar's 1st index
%   ==> Could loop, use a structure with row = latinhib condition &
%       fieldnames based on:
%       1st level: Response, Guess 1, Guess 2, etc.
%                  (for repping Fig 9 we just need response & guess #2)
%       2nd level: 'target' if firstindex = 1 & string(firstindex-20)
%                  if firstindex < 20 (preintrusion) & string(firstindex-19) if
%                  postintrusion
%                       -- Because typenums are 19 if -1 int & 20 if +1 int
%   ==> Dimensions of these struct entries would be:
%       trial x 1 (because GIVEN guess num)
%       -- just the entries in a vector FOR EACH GUESS1
%   ==> Then use the entries vector to compute responses x 1 vector
%       FOR EACH GUESS1 with proportions used for plotting