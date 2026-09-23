function getlatency(layer,target)
%this function calculates latencies for individual activation traces stored
%in summate
%parameters:
%layer: 1 - TFL ; 2 - Binding trace ; 3 - Token trace
%neuron: 1 - T1 ; 2 - T2

global seenlatencies missedlatencies

seenlatencies = zeros(8,1);
missedlatencies = zeros(8,1);
amp = 0;
lat = 0;
lagtimesteps = 0;

load STSToutput_100ms;
figure
hold all
for(lag = 1:8)
    [amp lat] = max(squeeze(mean(summate(:,lag,:,layer,target))));
    lat = lat - 130; %T1 onset
    lagtimesteps = 20 * lag;
    lat = lat - lagtimesteps; %T2 lag    
    lat = lat * 5; %get millisecs
    seenlatencies(lag) = lat;
    plot(squeeze(mean(summate(:,lag,:,layer,target))));
end

amp = 0;
lat = 0;
lagtimesteps = 0;

for(lag = 1:8)
    [amp lat] = max(squeeze(mean(summate2(:,lag,:,layer,target))));
    lat = lat - 130; %T1 onset
    lagtimesteps = 20 * lag;
    lat = lat - lagtimesteps; %T2 lag    
    lat = lat * 5; %get millisecs
    missedlatencies(lag) = lat;
end
hold off
seenlatencies
missedlatencies