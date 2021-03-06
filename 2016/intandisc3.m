function [AllTimeStamps AllWaveForms] = intandisc3(data,sr,thr,varargin)
%INTANDISC   Unit discrimination.
%   [T W] = INTANDISC(DATA,SR,THR) performs threshold discrimination of
%   continuous unit data (DATA) sampled at the rate SR using the specified
%   threshold (THR). Peak times (T, 'TimeStamps') and spike waveforms (W,
%   'WaveForms') are saved for each tetrode. A 750 us censored period is
%   applied after each spike. Time window for waveform data is set to -300
%   to 1000 us.
%
%   INTANDISC(DATA,SR,THR,DR) saves the results in the specified directory 
%   (DR). If DR is empty, the data is not saved.
%
%   See also READ_INTAN_DATA.

%   Balazs Hangya, Cold Spring Harbor Laboratory
%   1 Bungtown Road, Cold Spring Harbor
%   balazs.cshl@gmail.com
%   9-May-2013

% Default arguments
prs = inputParser;
addRequired(prs,'data',@isnumeric)   % raw or filtered data
addRequired(prs,'thr',@isnumeric)   % discrimination threshold
addOptional(prs,'resdir',['C:' filesep 'Balazs' filesep '_data' filesep 'Intan' filesep 'Tina' filesep],...
    @(s)ischar(s)|isempty(s))   % results directory
addParamValue(prs,'Filtering','enable',@(s)ischar(s)|...
    ismember(s,{'disable','enable'}))   % switch for filtering
parse(prs,data,thr,varargin{:})
g = prs.Results;

% File name
savestr0 = ['save(''' g.resdir filesep 'TT'];

% Sampling rate
nqf = sr / 2;   % Nyquist freq.
deadtime = 0.00075;   % 750 us dead time
dtp = deadtime * sr;   % dead time in data points

% Waveform window
win = [-0.0003 0.0006];   % -300 to 600 us
winp = round(win*sr);   % waveform window in data points

% Threshold discrimintaion
NumChannels = size(data,2);   % number of channels - 16
NumTetrodes = NumChannels / 4;   % number of tetrodes - 4
[tvdisc AllTimeStamps AllWaveForms] = deal(cell(1,NumTetrodes));
for iT = 1:NumTetrodes
    [cvdisc tdata] = deal(cell(1,4));
    for iC = 1:4
        chnum = (iT - 1) * 4 + iC;  % current channel
        disp(['tetrode: ' num2str(iT) '   Channel: ' num2str(chnum)])
        cdata = data(:,chnum)';   % data from one channel
        if isequal(g.Filtering,'enable')
            [b,a] = butter(3,[700 7000]/nqf,'bandpass');   % Butterworth filter
            unit = filter(b,a,cdata);  % filter
        elseif isequal(g.Filtering,'disable')
            unit = cdata;
        else
            error('intandisc2:InputArg','Unsupported input argument for filtering.')
        end
        cvdisc{iC} = disc(-unit,thr);   % discriminate (spike times)
        tdata{iC} = -unit;   % data from the current tetrode
    end
    tvdisc{iT} = cell2mat(cvdisc);
    tvdisc{iT} = sort(tvdisc{iT},'ascend');  % all spike times from one tetrode
        
    % Dead time
    dtv = diff(tvdisc{iT});   % ISI
    censor_inx = dtv < dtp;   % ISI < dead time
    tvdisc{iT}(find(censor_inx)+1) = [];   % remove spikes within the censor period
    tvdisc{iT}(tvdisc{iT}<=-winp(1)|tvdisc{iT}>=size(data,1)-winp(2)) = [];   % we may lose some spikes near the ends of the file
    
    % Waveform
    winx = repmat(tvdisc{iT}(:)+winp(1),1,sum(abs(winp))) + repmat(0:sum(abs(winp))-1,length(tvdisc{iT}),1);
    wv = nan(size(winx,1),4,size(winx,2));   % waveforms: spikes x channels x time
    for iC = 1:4
        wv(:,iC,:) = tdata{iC}(winx);   % waveform data
    end
    WaveForms = wv;
    AllWaveForms{iT} = WaveForms;
    
    % Spike times
    spike_times = tvdisc{iT} / sr;
    TimeStamps = spike_times;
    AllTimeStamps{iT} = TimeStamps;
    savestr = [savestr0 num2str(iT) ''',''WaveForms'',''TimeStamps'');'];
    
    % Save
    if ~isempty(g.resdir)
        eval(savestr)
    end
end