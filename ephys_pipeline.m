% Ephys data-analysis example script

close all
clear
clc

%% Load data
DATAPATH = '/example_data/';

[data1, timestamps, info] = load_open_ephys_data([DATAPATH '100_CH13.continuous']);
[data2, timestamps, info] = load_open_ephys_data([DATAPATH '100_CH14.continuous']);
[data3, timestamps, info] = load_open_ephys_data([DATAPATH '100_CH15.continuous']);
[data4, timestamps, info] = load_open_ephys_data([DATAPATH '100_CH16.continuous']);


[BehavioralEvents, OpenEphysTimestamps] = OpenEphysEvents2Bpod([DATAPATH '/all_channels.events']);

%[events, timestamps, info] = load_open_ephys_data([DATAPATH 'all_channels.events']);

data = [data1 data2 data3 data4];

figure
plot(data(1000:5000,1))
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

%%
plot(filtered_unit(1,1000:5000),'r')

%% Detect peaks

for chnum = 1:4
    pk{chnum} = peakdetect(-filtered_unit(chnum,:),60);
end

hold on
plot(pk{chnum},1,'o')

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
