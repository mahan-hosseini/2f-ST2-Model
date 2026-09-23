function calcRT_mahan(name, varpath, plotpath, saveplots, TwoRespFeatures)

% if we are not in name-dir, cat the strings
if ~contains(varpath, name)
    varpath = [varpath name '/'];
end

% load the layersummed act-values (only) of our matfile
load([varpath name '.mat'], 'ExPostsynBat_basic')

% some vars
retinadelay = 14;
numtrials = size(ExPostsynBat_basic,1);
numlags = size(ExPostsynBat_basic,2);
numtimepoints = size(ExPostsynBat_basic,3) + retinadelay;
layer = 9;

% initialize (layer is always 9 == token trace)
PadExPostSyn = zeros(numtrials, numlags, numtimepoints, 1);
% assign & implement retina delay
PadExPostSyn(:, :, retinadelay+1:end, 1, :) = ExPostsynBat_basic(:, :, :, layer);
% permute to make sure the size of this is lags x trials x tps
PadExPostSyn = permute(PadExPostSyn, [2, 1, 3, 4]);
check_PadExPostSyn(PadExPostSyn,4); % sanity check - really make sure it's in the correct format
% creat FullBindPool variable & delete the others
FullBindPool = reshape(squeeze(PadExPostSyn(:,:,:,1,:)), ... 
    [size(PadExPostSyn,1) * size(PadExPostSyn,2), size(PadExPostSyn,3)]); % IMPORTANT - FullBindPool includes misses!!! remove using marker!
FullBindPool = squeeze(FullBindPool);
clear PadExPostSyn ExPostsynBat_basic

% extract responses
[marker, fullmarker, keepepochs] = extract_responses(name, varpath, TwoRespFeatures);

% IMPORTANT - FullBindPool includes misses!!! remove using marker!
BindPool = FullBindPool(keepepochs,:);

% extract a struct with 3 fields from BindPool, one for each response condition (pre-targs, cor & post-targs)
BindPoolStruct = struct('pretargs', [], 'correct', [], 'posttargs', []);
for i = 1:length(marker)
    if strcmp(marker{i}, 'pre2') || strcmp(marker{i}, 'pre1') 
        if isempty(BindPoolStruct.pretargs)
            BindPoolStruct.pretargs = BindPool(i,:);
        else
            BindPoolStruct.pretargs = cat(1, BindPoolStruct.pretargs, BindPool(i,:));
        end
    elseif strcmp(marker{i}, 'correct')
        if isempty(BindPoolStruct.correct)
            BindPoolStruct.correct = BindPool(i,:);
        else
            BindPoolStruct.correct = cat(1, BindPoolStruct.correct, BindPool(i,:));
        end
    elseif strcmp(marker{i}, 'post1') || strcmp(marker{i}, 'post2') 
        if isempty(BindPoolStruct.posttargs)
            BindPoolStruct.posttargs = BindPool(i,:);
        else
            BindPoolStruct.posttargs = cat(1, BindPoolStruct.posttargs, BindPool(i,:));
        end
    end
end

% which threshold do we want to define a reaction with
thresh = .75;

RTs = struct('pretargs', [], 'correct', [], 'posttargs', []);
meanRT = struct('pretargs', [], 'correct', [], 'posttargs', []);
sdRT = struct('pretargs', [], 'correct', [], 'posttargs', []);

conditions = {'pretargs', 'correct', 'posttargs'};
for c = 1:length(conditions)
    thisnumtrials = size(BindPoolStruct.(conditions{c}),1);
    RTs.(conditions{c}) = zeros(thisnumtrials,1);
    for i = 1:thisnumtrials
        thistrial = BindPoolStruct.(conditions{c})(i,:);
        maxexpost = max(thistrial);
        thisindex = find((thistrial > thresh*maxexpost),1);
        RTs.(conditions{c})(i) = transfertime_steps2ms(thisindex); % transfer model's time-steps to ms-equivalent
    end
    meanRT.(conditions{c}) = mean(RTs.(conditions{c}));
    sdRT.(conditions{c}) = std(RTs.(conditions{c}),1);
end

botellaRT = [383; 393; 411];

% Plot it
figure;
set(gcf,'Position', [328   115   809   558]); % laptop
color1 = rgb('rust');
color2 = rgb('olive');
colororder([color1; color2]);
yyaxis left
p1 = plot(2:4, [meanRT.correct meanRT.pretargs meanRT.posttargs]);
hold on
yyaxis right
p2 = plot(2:4, botellaRT);
hold off

% line & color stuff
hold on
p1.LineWidth = 2.5; p2.LineWidth = p1.LineWidth;
p1.Color = color1; p2.Color = color2;
p1.MarkerFaceColor = color1; p2.MarkerFaceColor = color2;
p1.Marker = 'square'; p2.Marker = p1.Marker;
p1.MarkerSize = 9; p2.MarkerSize = p1.MarkerSize;
hold off

% figure & axes stuff
hold on
ax = gca;
ax.FontSize = 21;
ax.XLim = [1 5];
ax.XTick = 2:4;
ax.XTickLabel= {'Correct','Pre-target','Post-target'};

yyaxis left 
ylabel('2f-ST^2 reaction time (ms equivalent)', 'Color', color1)
ylim([500 600])
yticks([500 550 600])

yyaxis right
ylabel('Botella (1992) reaction time (ms)', 'Color', color2)
ylim([375 425])
yticks([375 400 425])

legend('2f-ST^2 Model', 'Botella (1992)', 'Location', 'northwest');

hold off

% save it
if saveplots
    if ~exist(plotpath, 'dir')
        mkdir(plotpath)
    end
    saveas(gcf, [plotpath 'RT - Botella & 2fST2.jpg'])
end

% print stuff
disp('*** MODEL MEAN-RTs ***')
fprintf('\n Cor: %d, Pre: %d, Post: %d \n', round(meanRT.correct), round(meanRT.pretargs), round(meanRT.posttargs))
disp('*** MODEL SD-RTs ***')
fprintf('\n Cor: %d, Pre: %d, Post: %d \n', round(sdRT.correct), round(sdRT.pretargs), round(sdRT.posttargs))
end




