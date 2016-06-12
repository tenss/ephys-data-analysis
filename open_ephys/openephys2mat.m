%Select the folder to convert from Open Ephys to mat
% This is intended to use with LoadTT_oe_mat

clear
clc
close all

%addpath(genpath('/home/fede/Data-xps/postdoc/zador/research/spike-sorting/analysis-tools'));

%folder_name = uigetdir;
folder_set = uigetfile_n_dir;%(start_path, dialog_title) 

for j=1:size(folder_set,2)
    
    folder_name = folder_set{1,j};
    
    disp(folder_name)
    
    files = dir(fullfile(folder_name, '/*.spikes'));
    files = {files.name}';

    for i=1:size(files,1)
        
        disp(['Tetrode ' num2str(i)]);

        s = dir( fullfile(folder_name, files{i,1}));

        if s.bytes/10^6<2000

          %[data, timestamps, info] = load_open_ephys_data(fullfile(folder_name, files{i,1}));
          [data, timestamps, info] = load_open_ephys_data_faster(fullfile(folder_name, files{i,1}));

          save([folder_name '/tt' num2str(i) '.mat'],'data','timestamps','-v7.3');

        else
            
            disp(['Data size of tetrode ' num2str(i) ' is ' num2str(s.bytes/10^6) ' MB. Skipping...']);
            continue
        end
    end
end