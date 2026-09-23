%% Function ReplicatingVul_RunAndPlotMultRuns runs 20 runs of the model & replicates Vul's Figures
%   Input: runModel - 1 if you want to run the model & 0 if not
function ReplicatingVul_RunAndPlotMultRuns(runModel20x)

%% 0 - IMPORTANT NOTE!!!
% WHEN RUNNING THE MODEL MULTIPLE TIMES WE NEED TO MAKE SURE THAT THE RNG
% SEEDS ARE RESET IN EACH RUN - THE ORIGINAL MODEL HAD THIS LINE IN
% RUNMODEL.M
%               %initialise random number generators
%                rand('twister', 5489);
%                randn('state', 0);
%   ==> THIS ENSURES THAT THE SAME RESULTS COME OUT WHEN YOU RUN THE MODEL
%   IN THE SAME CFG TWICE
%   ==> HOWEVER FOR OUR PURPOSES OF RUNNING THE MODEL (E.G.) 20x, WE HAVE
%   TO RE-SET THE RNG
%   ==> THIS HAS TO BE DONE MANUALLY (ADDED IN RUNMODEL.M)
%                rng('shuffle', 'twister') % for runing the model multiple times (e.g. when replicating Vul)
%   ==> YOU HAVE TO COMMENT ONE OR THE OTHER OUT
%   ==> WHEN DONE WITH RUNNING THE MODEL IN THIS CONTEXT, 
%
%
%               !!!!!!! MAKE SURE TO CHANGE IT BACK !!!!!!!!

%% 1 - Run 20 runs of the model with latinhib = 0
runs = 20;
varpath = "/Users/mahan/Library/CloudStorage/GoogleDrive-mambahan@googlemail.com/My Drive/Research/Final_ST2/Model/Variables/ReplicatingVul/MultRuns_latinhib0/";
if runModel20x
    for r = 1:runs
        % prepare path
        runname = ['Run #' num2str(r) '\'];
        thispath = [varpath runname];
        if ~isfolder(thispath)
            mkdir(thispath);
        end
        cd(thispath)
        % run model (open respTFL, don't save any layer/neur Act)
        %runModel(singletarg,skeletal,blank,soarate,ExPostSynOnly,keyd,respd,randd,TwoRespFeatures,NeurExPostsyn)
        runModel(1,0,0,100,0,0,0,4,0,0)
    end
end

%% 2 - Combine allguesses into big trial x guess matrix

% paths & varnames
%varpath = 'D:\Kent\Research\Final_ST2\Model\Variables\ReplicatingVul\MultRuns_latinhib0\';
plotpath = "/Users/mahan/Desktop/";

% get values needed to create guesses var
load(strcat(varpath, "Run #1/Guesses"));
runnum = 20; % number of runs hardcoded in 1st section
trialnum = size(allguesses,1);
lagnum = size(allguesses,2);
guessnum = size(allguesses,3);

% create guesses var (large trial x guesses matrix)
%   1 - fullguesses 
fullguesses = nan(runnum, trialnum, lagnum, guessnum); % run x trials x lags x guesses
for r = 1:runnum
    runname = strcat("Run #", num2str(r), "/");
    thispath = strcat(varpath, runname);
    load(strcat(thispath, "Guesses"));
    fullguesses(r, :, :, :) = allguesses;
    clear allguesses
end
%   2 - guesses (reshaping the whole thing in 1 line didn't work for some reason, concatenating manually)
collapselagstrials = reshape(fullguesses, runnum, trialnum*lagnum, guessnum); % reshape across trials & lags (same thing in 2fst2) for each run 
for r = 1:runnum                                                              % catting to get matrix
    if r == 1
        guesses = squeeze(collapselagstrials(r,:,:));
    else
        guesses = cat(1, guesses, squeeze(collapselagstrials(r,:,:)));
    end
end

%%  3 - Store info about proportion of misses, singlebinds & multbinds
% Note - if at some point you should wonder why cleanguesses length is
% smaller than guesses - missnum that's because there are trials that were
% not guesses but in which the reported type was not in the -5 to +5 range
fulltrialnum = size(guesses,1);
missnum = 0;
singlebindnum = 0;
multbindnum = 0;
for t = 1:fulltrialnum
    if isnan(guesses(t,1))                      % if 1st index is NaN it's a miss
        missnum = missnum + 1;
    else
        if isnan(guesses(t,2))
            singlebindnum = singlebindnum + 1; % if 2nd index is NaN only 1 type was bound
        else
            multbindnum = multbindnum + 1;     % if 2nd index is not NaN at least 2 types were bound
        end
    end
end

%%  4 - Create remaining vars needed for plots

%   1) Only include -2 to +2s
%   (so that variability in (e.g.) -3s doesn't confound proportions of set
%    going -2 to +2)
idx2include = find(ismember(guesses(:,1), [1 15:19 20:24])); % -5 to +5 (range of Vul's figure)
cleanguesses = guesses(idx2include,:);                       % cleanguesses has G1 range that we want

%   2) Store proportions of Guess 1s (Responses)
%   ==> just 1st col of cleanmat (because those are responses))
trialnum = size(cleanguesses,1);                                     % num of rows is trialnum
G1Set = unique(cleanguesses(:,1));                                   % Guess1 set is unique entries of 1st column (response)
G1Props = zeros(1, length(G1Set));
for G1 = 1:length(G1Set)
    this_freq = sum(cleanguesses(:, 1) == G1Set(G1));                % how often was this response the 1st guess
    G1Props(G1) = this_freq / trialnum;                              % make a proportion out of it and store
end

%   3) Store distributions of probabilities of 2nd guesses conditional on 1st
%   ==> G1 goes from -2 to +2 (separate coloured lines) & G2 from -5 to +5 (figure's xaxis)
G1Set_narrow = [18, 19, 1, 20, 21]; % response set is just -2 to +2 [different than previous G1Set!]
G2Set = [1 15:19 20:24];     % G2 only from -5 to +5
G1Strings = {'minus2', 'minus1', 'target', 'plus1', 'plus2'};         % only need cond. probs for G2 of -2 to +2 responses (Vul has xaxis range of -5 to +5 but only 5 separate lines, from -2 to +2)
G2Struct = struct('minus2', [], 'minus1', [], 'target', [], 'plus1', [], 'plus2', []);
%   ==> Loop over guess1 (response) set
for G1 = 1:length(G1Strings)
    clear idx2include
    % Find out indices where current response was made
    idx2include = find(cleanguesses(:,1) == G1Set_narrow(G1));                                                 % extract only those trials from cleanmat where guess1 was given response
    G2Struct.(G1Strings{G1}).guess2vec_wNaNs = [];
    G2Struct.(G1Strings{G1}).guess2vec_wNaNs = cleanguesses(idx2include, 2);                            % only 2nd column
    
    % Only take those trials where there was a second guess (ie. exclude singlebinds)
    idx2include_G2 = find(ismember(G2Struct.(G1Strings{G1}).guess2vec_wNaNs, G2Set));           % range of -5 to +5 (Vul's xaxis range)
    G2Struct.(G1Strings{G1}).guess2vec = G2Struct.(G1Strings{G1}).guess2vec_wNaNs(idx2include_G2);
    G2Struct.(G1Strings{G1}).trialnum = length(G2Struct.(G1Strings{G1}).guess2vec);              % how many trials with response being r & there being a 2nd guess
    
    % Extract Guess2 Set (this is different to G1Set, because Vul looked at -5 to +5 (w.r.t. target) for Guess2s
    G2Struct.(G1Strings{G1}).G2Set = unique(G2Struct.(G1Strings{G1}).guess2vec);             % extract all unique responses of Guess 2 (Vul went from -5 to +5 for G2)
    G2Struct.(G1Strings{G1}).G2Strings = cell(1,length(G2Struct.(G1Strings{G1}).G2Set));
    
    % Loop over all different Guess2s of this given response and compute their respective proportions (similar to how we computed proportion of responses above)
    for G2 = 1:length(G2Struct.(G1Strings{G1}).G2Set)
        G2Struct.(G1Strings{G1}).G2Strings{G2} = typeidx2respstr(G2Struct.(G1Strings{G1}).G2Set(G2));
        this_freq = sum(G2Struct.(G1Strings{G1}).guess2vec == G2Struct.(G1Strings{G1}).G2Set(G2));
        G2Struct.(G1Strings{G1}).G2Props(G2) = this_freq / G2Struct.(G1Strings{G1}).trialnum;
    end
end

%%  5 - Save the vars if needed
% save(strcat(varpath, "Guesses MultRuns Variables")) % just save the workspace to file

%%  6 - Plot the Figures
plotit(varpath, plotpath)
end


%% function that plots all plots
function plotit(varpath, plotpath)
% load var
load(strcat(varpath, "Guesses MultRuns Variables"))

% 0 - plot a histogram of only Guess 1 reponses
orig_responseset = G1Set; % get the correct & ordered response set & proportions (step will be repeated for different lines when replicating Vuls Fig 9 below)
responseset = zeros(1,length(orig_responseset));
for r = 1:length(orig_responseset)
    responseset(r) = typeidx2respnum(orig_responseset(r)); % change model type numbering to be numbering of responses with target being 0
end
responseprops = G1Props;
[ordered_responseset, ordered_responseprops] = order_responsevectors(responseset, responseprops); % order the vectors
plot_guess1_distribution(ordered_responseset, ordered_responseprops, plotpath);

% % 1 - barplot showing miss, singlebind & multbind proportions
% these_props = zeros(1,3);
% trialnum = size(guesses,1);                          % how many trials
% these_props(1) = missnum / trialnum;
% these_props(2) = singlebindnum / trialnum;
% these_props(3) = multbindnum / trialnum;
% figure;
% set(gcf, 'Position', [384   503   857   476])
% barplot = bar(these_props, 'FaceColor', 'flat');
% barplot.CData(1, :) = rgb('sky blue');
% barplot.CData(2, :) = rgb('lavender');
% barplot.CData(3, :) = rgb('khaki');
% ax = gca;
% ax.XTickLabels = {'Misses', 'Single Binds', 'Multi Binds'};
% ax.YLabel.String = 'Proportion';
% this_name = 'Binding Distributions.'; % for title & saving
% ax.Title.String = this_name;
% ax.FontSize = 17;
% ax.YLim = [0 0.8];
% saveas(gcf, [plotpath this_name '.jpg'])

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
% ordered vars were previously generated (see plot #0 above)
responseline = plot(ordered_responseset, ordered_responseprops);
responseline.Color = [rgb('grey') 0.5];
responseline.LineWidth = thicklinewidth;
hold on



% red line - distribution of guess2s if response was minus 2
orig_minus2set = G2Struct.minus2.G2Set;
minus2set = zeros(1, length(orig_minus2set));
for r = 1:length(orig_minus2set)
    minus2set(r) = typeidx2respnum(orig_minus2set(r)); % change model type numbering to be numbering of responses with target being 0
end
minus2props = G2Struct.minus2.G2Props;
[ordered_minus2set, ordered_minus2props] = order_responsevectors(minus2set, minus2props); % order the vectors
% interpolation to ensure that coloured lines are comparable to grey line
% (otherwise grey line always has 1 datapoint more by definition because
% it's not plotting a conditional probability)
% ==> First, find the position of the value we need to interpolate a given line
% ==> Then insert the interpolated value there
% ==> Finally add remaining values to the vector (this is the concatenation below)
% ==> Standardise so AUC is 1
% ==> Remove interpolated value (will not be plotted!)
missingval_minus2 = interp1(ordered_minus2set, ordered_minus2props, -2, 'nearest');      % find the missing value
minus2idx = find(ordered_minus2set < -2);                                     % find idx where to insert interpolated value before interpolating it
final_minus2set = ordered_minus2set(minus2idx);                               % the "start"
final_minus2set(end+1) = -2;                                                  % add missing value to set 
final_minus2set = [final_minus2set ordered_minus2set(minus2idx(end)+1:end)];  % cat first (new) half of set with previous half
final_minus2props = ordered_minus2props(minus2idx);                           % do the same thing for the proportion vector
final_minus2props(end+1) = missingval_minus2;                                 % insert interpolated value here
final_minus2props = [final_minus2props ordered_minus2props(minus2idx(end)+1:end)];
final_minus2props = final_minus2props / sum(final_minus2props);               % make sure that proportions add up to 1 after addition of interp'd value
final_minus2props = final_minus2props(final_minus2set ~= -2);                 % throw out interpolated value (we only needed it for standardising amplitudes of coloured/grey lines - will not be plotted)
final_minus2set = final_minus2set(final_minus2set ~= -2);                     % IMPORTANT - props first! (otherwise set-vector used for indexing 1 too short!)
minus2line = plotcolouredlines(final_minus2set, final_minus2props, 'r', thinlinewidth);     % plot it

% olive line - distribution of guess2s if response was minus 1
orig_minus1set = G2Struct.minus1.G2Set;
minus1set = zeros(1, length(orig_minus1set));
for r = 1:length(orig_minus1set)
    minus1set(r) = typeidx2respnum(orig_minus1set(r)); % change model type numbering to be numbering of responses with target being 0
end
minus1props = G2Struct.minus1.G2Props;
[ordered_minus1set, ordered_minus1props] = order_responsevectors(minus1set, minus1props); % order the vectors
% interpolation 
missingval_minus1 = interp1(ordered_minus1set, ordered_minus1props, -1, 'nearest');      
minus1idx = find(ordered_minus1set < -1);                                     
final_minus1set = ordered_minus1set(minus1idx);                               
final_minus1set(end+1) = -1;                                                  
final_minus1set = [final_minus1set ordered_minus1set(minus1idx(end)+1:end)]; 
final_minus1props = ordered_minus1props(minus1idx);                           
final_minus1props(end+1) = missingval_minus1;                                 
final_minus1props = [final_minus1props ordered_minus1props(minus1idx(end)+1:end)];
final_minus1props = final_minus1props / sum(final_minus1props);   
final_minus1props = final_minus1props(final_minus1set ~= -1);               % IMPORTANT - props first! (otherwise set-vector used for indexing 1 too short!)
final_minus1set = final_minus1set(final_minus1set ~= -1);                     
minus1line = plotcolouredlines(final_minus1set, final_minus1props, rgb('olive'), thinlinewidth);

% green line - distribution of guess2s if response was target
orig_targetset = G2Struct.target.G2Set;
targetset = zeros(1, length(orig_targetset));
for r = 1:length(orig_targetset)
    targetset(r) = typeidx2respnum(orig_targetset(r)); % change model type numbering to be numbering of responses with target being 0
end
targetprops = G2Struct.target.G2Props;
[ordered_targetset, ordered_targetprops] = order_responsevectors(targetset, targetprops); % order the vectors
% interpolation
missingval_target = interp1(ordered_targetset, ordered_targetprops, 0, 'nearest');      
targetidx = find(ordered_targetset < 0);                                     
final_targetset = ordered_targetset(targetidx);                               
final_targetset(end+1) = 0;                                                  
final_targetset = [final_targetset ordered_targetset(targetidx(end)+1:end)]; 
final_targetprops = ordered_targetprops(targetidx);                           
final_targetprops(end+1) = missingval_target;                                 
final_targetprops = [final_targetprops ordered_targetprops(targetidx(end)+1:end)];
final_targetprops = final_targetprops / sum(final_targetprops);              
final_targetprops = final_targetprops(final_targetset ~= 0);
final_targetset = final_targetset(final_targetset ~= 0);                     
targetline = plotcolouredlines(final_targetset, final_targetprops, 'g', thinlinewidth);

% blue line - distribution of guess2s if response was plus 1
orig_plus1set = G2Struct.plus1.G2Set;
plus1set = zeros(1, length(orig_plus1set));
for r = 1:length(orig_plus1set)
    plus1set(r) = typeidx2respnum(orig_plus1set(r)); % change model type numbering to be numbering of responses with target being 0
end
plus1props = G2Struct.plus1.G2Props;
[ordered_plus1set, ordered_plus1props] = order_responsevectors(plus1set, plus1props); % order the vectors
% interpolation
missingval_plus1 = interp1(ordered_plus1set, ordered_plus1props, 1, 'nearest');      
plus1idx = find(ordered_plus1set < 1);                                     
final_plus1set = ordered_plus1set(plus1idx);                               
final_plus1set(end+1) = 1;                                                  
final_plus1set = [final_plus1set ordered_plus1set(plus1idx(end)+1:end)]; 
final_plus1props = ordered_plus1props(plus1idx);                           
final_plus1props(end+1) = missingval_plus1;                                 
final_plus1props = [final_plus1props ordered_plus1props(plus1idx(end)+1:end)];
final_plus1props = final_plus1props / sum(final_plus1props);              
final_plus1props = final_plus1props(final_plus1set ~= 1);
final_plus1set = final_plus1set(final_plus1set ~= 1);                     
plus1line = plotcolouredlines(final_plus1set, final_plus1props, 'b', thinlinewidth);

% purple line - distribution of guess2s if response was plus 2
orig_plus2set = G2Struct.plus2.G2Set;
plus2set = zeros(1, length(orig_plus2set));
for r = 1:length(orig_plus2set)
    plus2set(r) = typeidx2respnum(orig_plus2set(r)); % change model type numbering to be numbering of responses with target being 0
end
plus2props = G2Struct.plus2.G2Props;
[ordered_plus2set, ordered_plus2props] = order_responsevectors(plus2set, plus2props); % order the vectors
% interpolation
missingval_plus2 = interp1(ordered_plus2set, ordered_plus2props, 2, 'nearest');      
plus2idx = find(ordered_plus2set < 2);                                     
final_plus2set = ordered_plus2set(plus2idx);                               
final_plus2set(end+1) = 2;                                                  
final_plus2set = [final_plus2set ordered_plus2set(plus2idx(end)+1:end)]; 
final_plus2props = ordered_plus2props(plus2idx);                           
final_plus2props(end+1) = missingval_plus2;                                 
final_plus2props = [final_plus2props ordered_plus2props(plus2idx(end)+1:end)];
final_plus2props = final_plus2props / sum(final_plus2props);    
final_plus2props = final_plus2props(final_plus2set ~= 2);
final_plus2set = final_plus2set(final_plus2set ~= 2);                     
plus2line = plotcolouredlines(final_plus2set, final_plus2props, rgb('purple'), thinlinewidth);

hold off

% figure stuff to make it resemble Vul's
ax = gca;
ax.XLim = [-5 5];
ax.XLabel.String = 'Serial position (0 = Target)';
ax.YLabel.String = 'Frequency of Guess 2 report';
ax.FontSize = 20;
lgd = legend([responseline, minus2line, minus1line, targetline, plus1line, plus2line], ... % make sure that markers are not in legend - cat the lines!
    {'Guess 1 Prediction', 'Guess 1 = -2', 'Guess 1 = -1', 'Guess 1 = 0', 'Guess 1 = 1', 'Guess 1 = 2'}, 'FontSize', 14);
set(lgd, 'Box', 'off')

% title & save
this_name = 'Vul''s Figure 9 with the 2fST2.'; % for title & saving
ax.Title.String = this_name;
ax.Title.FontSize = ax.Title.FontSize - 2;
% hardcoded saveas line because plotpath caused issues for some reason
saveas(gcf, strcat("/Users/mahan/Desktop/", this_name, ".jpg"))
%saveas(gcf, strcat(plotpath, this_name, ".jpg"));
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

%% function transforms numbering of types in 2fst2 to response-string w.r.t. target
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

%% function transforms numbering of types in 2fst2 to response-number w.r.t. target
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

%% function plots only Guess 1 distribution (ie. responses)
function plot_guess1_distribution(ordered_responseset, ordered_responseprops, plotpath)
fig = figure;
b = bar(ordered_responseset, ordered_responseprops);
ax = gca;
ax.FontSize = 22;
b.FaceColor = rgb('slate blue');
% hardcoded saveas line because plotpath caused issues for some reason
saveas(fig, "/Users/mahan/Desktop/Response Distribution.png")
%saveas(fig, strcat(plotpath, "Response Distribution.png"))
end