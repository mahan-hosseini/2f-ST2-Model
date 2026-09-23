function plotdist(condname,params)

if ~exist('params', 'var')
    params = struct([]);
end

if isfield(params, 'legendstrings')
    legendstrings = params.legendstrings;
else
    legendstrings = condname;
end

targetpos = 20;
posrange = -2:2;
respdist = zeros(length(posrange),length(condname));
prepostdist = zeros(length(condname),2);
%loadpath = 'current/';
loadpath = [cd '/']; %MAHAN: Got rid of 'current', just use cd.

for cond=1:length(condname)

    condfile = condname{cond};
    disp(['Loading ' loadpath condfile '...']);
    load([loadpath condfile]);

    allkey = reshape(permute(T1batterydata, [1 5 4 3 2]), [1, size(T1batterydata, 2) * size(T1batterydata, 3) ...
        * size(T1batterydata, 4) * size(T1batterydata, 5)]);

    allresp = reshape(permute(T1respdata, [1 5 4 3 2]), [1, size(T1respdata, 2) * size(T1respdata, 3) ...
        * size(T1respdata, 4) * size(T1respdata, 5)]);

    bindings = allresp(((allkey(:) > 0) & (allresp(:) > 0)));
    disp(sprintf('Condition %s: %d trials.', condname{cond},length(T1respdata(:))));
    disp(sprintf('Response feature bound in %d trials.', length(bindings)));
    if exist('multbind', 'var')
        disp(sprintf('Multiple response features bound in %d trials', multbind));
    end

    for i=1:length(bindings)
        if bindings(i) == 1
            bindings(i) = 0;
        elseif bindings(i) < targetpos
            bindings(i) = bindings(i) - targetpos;
        elseif bindings(i) >= targetpos
            bindings(i) = bindings(i) + 1 - targetpos;
        end
    end

    frequency = hist(bindings,posrange);

    intrusionrange = find(posrange); %API
    %    intrusionrange = 1:length(posrange); %APR
    totalintrusions = sum(frequency(intrusionrange));

    API = 0;
    for pos=intrusionrange
        API = API + (posrange(pos) * (frequency(pos)/totalintrusions));
    end

    normfreq = (frequency/sum(frequency))*100;
    respdist(:,cond) = normfreq';
    disp(sprintf('API = %.2f; Response Distribution = %s', API, num2str(round(normfreq))));
    normfreq = (frequency/sum(frequency(posrange ~= 0)))*100;
    prepostdist(cond,:) = [sum(normfreq(posrange < 0)) sum(normfreq(posrange > 0))];
end

figure;bar(posrange,respdist);
set(gcf, 'Position', [1 1 1280 1024 * (2/3)]);

fontsize = 24;
set(gca,'XTick', posrange, 'FontSize',fontsize-2,'FontWeight','normal');
xlabel('Response position relative to target', 'FontWeight', 'normal', 'FontSize', fontsize, 'FontName', 'Arial');
ylabel('% Frequency', 'FontWeight', 'normal', 'FontSize', fontsize, 'FontName', 'Arial');
ylim([0 70]);
legend(legendstrings, 'Location','NorthWest');

if isequal(condname, {'key0_resp0', 'key8_resp0'}) || isequal(condname, {'key0_resp0', 'key0_resp2'})
    legendname = {'High Frequency', 'Low Frequency'};
else
    legendname = condname;
end

rgbblue = '#4c57a7';
rgbgreen = '#33bca0';
figure; 
b = bar(prepostdist');
b(1).FaceColor = rgbgreen; b(2).FaceColor = rgbblue;
set(gca,'XTickLabel', {'Pre-target', 'Post-target'}, 'FontSize',fontsize-2,'FontWeight','normal');
ylabel('% Frequency', 'FontWeight', 'normal', 'FontSize', fontsize, 'FontName', 'Arial');
legend(legendname);

round(prepostdist)
end
