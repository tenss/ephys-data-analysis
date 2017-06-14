% Ephys data-analysis example script

close all
clear
clc

%% Load data
DATAPATH = '/example_data/';

% load raw signals
[data1, timestamps, info] = load_open_ephys_data([DATAPATH '100_CH13.continuous']);
[data2, timestamps, info] = load_open_ephys_data([DATAPATH '100_CH14.continuous']);
[data3, timestamps, info] = load_open_ephys_data([DATAPATH '100_CH15.continuous']);
[data4, timestamps, info] = load_open_ephys_data([DATAPATH '100_CH16.continuous']);

data = [data1 data2 data3 data4];

% load event file
[BehavioralEvents, OpenEphysTimestamps] = OpenEphysEvents2Bpod([DATAPATH '/all_channels.events']);

% get stimulus onset (if connecting pulse pal directly to open ephys)
StimOnset = OpenEphysTimestamps(diff(OpenEphysTimestamps)>2);

%%
figure
plot(data(1:10000,1))
hold on

%% Filter your data
sr = info.header.sampleRate;
nqf = sr / 2;   % Nyquist freq.

filtered_unit = zeros(4,size(data,1));
for chnum = 1:4
    cdata = data(:,chnum)';   % data from one channel
    [b,a] = butter(3,[700 7000]/nqf,'bandpass');   % Butterworth filter
    filtered_unit(chnum,:) = filter(b,a,cdata);  % filter
end

plot(filtered_unit(1,1:10000),'r')

%% Detect peaks
threshold = 60;
for chnum = 1:4
    pk{chnum} = peakdetect(-filtered_unit(chnum,:),threshold);
end

hold on
plot(1:10000,-threshold*ones(10000),'k')
c=colormap(jet(10));
for chnum = 1:1
    plot(repmat(pk{1,chnum}(1,1:15)',1,2),[-400 400],'Color',c(chnum,:))
end


%% Censoring

deadtime = 0.00075;   % 750 us dead time
pks = sort(cell2mat(pk));
allspikes = censor(pks,sr,deadtime);

%% Cut spikes
win = [-0.0003 0.0006];   % -300 to 600 us
waveforms = cutspike(data,allspikes,sr,win);

avw = squeeze(mean(waveforms,1));
figure;plot(-avw')


%% plot raster
spike_times = allspikes/sr;


aux = OpenEphysTimestamps(diff(OpenEphysTimestamps)>5);
H = spikeraster(spike_times,aux,[-0.5 0.5]);
