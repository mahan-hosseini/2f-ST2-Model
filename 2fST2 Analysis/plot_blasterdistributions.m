%%          Use ActArrayLayer to plot blaster distributions
function plot_blasterdistributions(name, varpath, plotpath, saveplots, TwoRespFeatures)
%% Variable Stuff and Prep
% if varpath is not set to lead to keyx_respx, try concatenating first before failing below
if ~contains(varpath, name)
    varpath = [varpath name '/'];
end
% Some sanity checks
if ~contains(varpath, name) % check if in correct path..
    msgbox('MISMATCH BETWEEN NAME & VARPATH! - CANCELLING')
    return
end
switch TwoRespFeatures % check if TwoRespFeatures corresponds to path
    case 0
        if ~contains(varpath, 'Srivas')
            msgbox('MISMATCH BETWEEN TwoRespFeats & VARPATH! - CANCELLING')
            return
        end
    case 1
        if ~contains(varpath, 'Alon')
            msgbox('MISMATCH BETWEEN TwoRespFeats & VARPATH! - CANCELLING')
            return
        end
end

% Then, load ActArray-Variable
if exist([varpath 'ActArrayLayer_Blaster Out.mat'],'file') 
    load([varpath 'ActArrayLayer_Blaster Out.mat'])
    BlasterOutFull = ActArrayLayer;
    clear ActArrayLayer
elseif exist ([varpath 'AvActArrayLayer_Blaster Out.mat'], 'file')
    load([varpath 'AvActArrayLayer_Blaster Out.mat'])
    BlasterOutFull = AvActArrayLayer;
    clear AvActArrayLayer
else
    msgbox('BLASTER OUT ACT ARRAY MISSING IN VARPATH - PUT IT IN');
    return
end

% Now, throw out misses
[marker, ~, keepepochs] = extract_responses(name, varpath, TwoRespFeatures); % uses name_responly.mat (which transfer-function generates, too)
BlasterOut = BlasterOutFull(keepepochs,:,1);

% Find number of conditions in this dataset to know how many colours we need
conditions = unique(marker); 
num_conds = length(conditions);

% Extract single-trial's blasterlatency and store in a variable
blasters{num_conds,3} = []; % we want latencies x trialnumber x condition
for c = 1:num_conds
    this_cond = conditions{c};
    trialnums = sum(strcmp(marker,conditions{c}));
    this_indices = find(strcmp(marker, conditions{c})); % using find because strcmp gives 0s & 1s but we want index-numbers so this_indices has the same length == trialnums!
    if length(this_indices) ~= trialnums  
        msgbox('Something wrong with trialnums - canceling!') % just a quick sanity check, bc wrong indexing would break everything here
        return                                                % i know this is probably quite paranoid but whatever (:
    end
    blasters{c,1} = zeros(1,trialnums); % initialize blasterlat-array
    for t = 1:trialnums
        this_trial = BlasterOut(this_indices(t), :);
        this_lat = blasterfiring(this_trial); % this gives latency in datapoints
        blasters{c,1}(t) = transfertime_steps2ms(this_lat); % store latency as ms-equivalents
    end
    blasters{c,2} = trialnums;
    blasters{c,3} = conditions{c};
end

% quickly combine -2 with -1s and +2s with +1s if we have all 5 conditions in our data
if sum(ismember(conditions,'pre2') + ismember(conditions,'pre1') + ismember(conditions,'post1') + ismember(conditions,'post2')) == 4
    Srivas3Cond = 1;   
else
    Srivas3Cond = 0;
end

%% Plot it
figure;
set(gcf, 'Position', [1622         -12         822         659])

nbins = 50;
axes_fontsize = 13;
VWidth = 3; % VlineWidth

if Srivas3Cond == 0 % if we don't combine anything, just use the condition var to loop
    this_color = cell(num_conds);
    for c = 1:num_conds
        hold on
        this_cond = conditions{c};
        if strcmp(this_cond, 'pre2')
            this_color{c} = rgb('light green');
        elseif strcmp(this_cond, 'pre1')
            this_color{c} = 'g';
        elseif strcmp(this_cond, 'correct')
            this_color{c} = 'k';
        elseif strcmp(this_cond, 'post1')
            this_color{c} = 'r';
        elseif strcmp(this_cond, 'post2')
            this_color{c} = rgb('rose');
        end
        if strcmp(this_cond, 'correct')
            histogram(blasters{c,1}, nbins, 'FaceColor', this_color{c}, 'FaceAlpha', 0.2)
        else
            histogram(blasters{c,1}, nbins, 'FaceColor', this_color{c}, 'FaceAlpha', 0.4) % alpha of coloured bars larger
        end
        hold off
    end
    for c = 1:num_conds
        hold on
        v = vline(mean(blasters{c,1}));
        v.Color = this_color{c};
        v.LineWidth = VWidth;
        hold off
    end
else % if we want to combine conditions, cat the blaster-lat-vectors first
    for c = 1:num_conds
        this_cond = conditions{c};
        if strcmp(this_cond, 'pre2')
            pre2blast = blasters{c,1};
        elseif strcmp(this_cond, 'pre1')
            pre1blast = blasters{c,1};
        elseif strcmp(this_cond, 'correct')
            corblast = blasters{c,1};
        elseif strcmp(this_cond, 'post1')
            post1blast = blasters{c,1};
        elseif strcmp(this_cond, 'post2')
            post2blast = blasters{c,1};
        end
    end
    for cc = 1:3
        hold on
        switch cc
            case 1 % pre-target ints
                pretargblast = horzcat(pre2blast,pre1blast); % cat the blaster-vectors 
                histogram(pretargblast, nbins, 'FaceColor', 'g', 'FaceAlpha', 0.4)
            case 2 
                histogram(corblast, nbins, 'FaceColor', 'k', 'FaceAlpha', 0.2)
            case 3
                posttargblast = horzcat(post1blast,post2blast); % cat the blaster-vectors 
                histogram(posttargblast, nbins, 'FaceColor', 'r', 'FaceAlpha', 0.4)
        end
        hold off
    end
    preV = vline(mean(pretargblast)); corV = vline(mean(corblast)); postV = vline(mean(posttargblast));
    preV.Color = 'g'; corV.Color = 'k'; postV.Color = 'r';
    preV.LineWidth = VWidth; corV.LineWidth = VWidth; postV.LineWidth = VWidth;
end

% axis stuff
ax = gca;
ax.FontSize = axes_fontsize;
if Srivas3Cond 
    combined = ' - Combined +-1/2 Conditions';
else
    combined = '';
end
ax.Title.String = ['Blaster Latency Distributions ' combined];
ax.Title.FontSize = 20;

% save
if TwoRespFeatures
    analysis = 'Alon';
else
    analysis = 'Srivas';
end
if saveplots
    saveas(gcf,[plotpath analysis ' - ' name 'Blaster Latency Distributions.jpg'])
end
end