% nirl_group_qsirecon_gfa_results.m
% DG, May 2025

% This script allows the user to select the project for which the DWI-DTI
% data was preprocessed and postprocessed (with QSIRecon), and collect the
% group gfa results (mean generalized fractional anisotropy along streamlines)
% (https://qsirecon.readthedocs.io/en/latest/builtin_workflows.html#dsi-studio-connectivity-measures)
% Lastly, it allows the user to define the regions of the atlas to extract
% values from, that is, to filter the gfa+count values for further analysis

% NOTE: FOR NOW, THIS SCRIPT WORKS ONLY FOR WAVE 1 DATA COLLECTION (ses-visit00m)
% AND ONLY FOR THE 4S456Parcels ATLAS (Schaefer + CIT168 subcortical parcellation)

clear all; close all; clc;
lab_dir = '/proj/belgerlab/projects/data';
code_dir = '/proj/belgerlab/projects/code/dwi/qsirecon';
cd(lab_dir);

% --- KEEP QSIPREP AND QSIRECON VERSIONS (USED) UPDATED HERE !! ---
qsiprepv = 'qsiprep-1.0.0rc1';
qsireconv = 'qsirecon-1.0.0rc1';

fprintf('Please, select the Project and its directory \n');
proj_dir = uigetdir(lab_dir);

if contains(proj_dir, 'PASS')
    fprintf('PASS project selected \n'); proj = 'PASS';
elseif contains(proj_dir, 'STAARS')
    fprintf('STAARS project selected \n'); proj = 'STAARS';
elseif contains(proj_dir, 'CogNIT')
    fprintf('CogNIT project selected \n'); proj = 'CogNIT';
else
    error('No valid directory was selected. Please, retry');
end
proj_dir = fullfile(proj_dir, '/derivatives/', qsiprepv);

if ~exist(proj_dir)
    warning('Expected directory: %s', proj_dir);
    error('No qsiprep work has been done for %s', proj);
elseif exist(proj_dir)
    fprintf('qsiprep work found for %s \n', proj);
end
proj_dir_ext =  fullfile(proj_dir, '/derivatives/', qsireconv, '/derivatives/qsirecon-DSIStudio/');

% example: proj_dir_ext = '/proj/belgerlab/projects/data/PASS/derivatives/qsiprep-1.0.0rc1/derivatives/qsirecon-1.0.0rc1/derivatives/qsirecon-DSIStudio/'

% check if qsirecon dir/data exists
if ~exist(proj_dir_ext)
    warning('Expected directory: %s', proj_dir_ext);
    error('No qsirecon work has been done for %s', proj);
elseif exist(proj_dir_ext)
    fprintf('qsirecon work found for %s \n', proj);
    fprintf('at: %s \n', proj_dir_ext);
end

%% loop over participants directories and get gfa values
list = dir(proj_dir_ext);
sub_dirs = list([list.isdir] & contains({list.name}, 'sub')); % get a list of subjects postprocessed

fprintf('...Extracting gfa and count values -pass method- ... \n');

gfa_matrices = cell(size(sub_dirs,1), 1);
count_streamlines = cell(size(sub_dirs,1), 1);
for i = 1:size(sub_dirs,1)
    clearvars -regexp atlas_ % clear variables from the workspace that have 'atlas_' in their name

    dwi_dir = fullfile(proj_dir_ext, sub_dirs(i).name, 'ses-visit00m', 'dwi');
    list_subj = dir(dwi_dir);
    connvals_file = list_subj(contains({list_subj.name}, 'connectivity') & endsWith(string({list_subj.name}),'.mat'));
    connvals_file = fullfile(connvals_file.folder,connvals_file.name);

    if ~exist(connvals_file)
        warning('No connectivity values file found for %s',sub_dirs(i).name);
        warning('Assigning NaNs as results');
        gfa_matrices{i} = NaN;
        count_streamlines{i} = NaN;
    elseif exist(connvals_file)
        load(connvals_file)
        gfa_matrices{i} = atlas_4S456Parcels_gfa_pass_connectivity;
        count_streamlines{i} = atlas_4S456Parcels_count_pass_connectivity;
        % "Due to the arbitrary nature of streamline tractography, the pass method is probably more realistic"
        % https://qsirecon.readthedocs.io/en/latest/builtin_workflows.html#dsi-studio-connectivity-measures
    end
end
clearvars -regexp atlas_ % clean some variables again

%% select regions after user's selection and filter gfa data
% check if atlas dir exists
atlasDir = fullfile(proj_dir, 'derivatives', qsireconv, 'atlases');
if ~exist(atlasDir)
    error('No qsirecon has been saved/defined for postprocessing for %s', proj);
elseif exist(atlasDir)
    cd(atlasDir);
end

fprintf('Select directory AND tsv/csv/txt file with atlas labels file! \n');
filterSpec = {'*.tsv;*.csv;*.txt', 'Text Files (*.tsv, *.csv, *.txt)'};
[labels_file, labels_path] = uigetfile(filterSpec, 'Select a Label File', atlasDir);
atlas_labels = fullfile(labels_path,labels_file);
[~,~,ext] = fileparts(atlas_labels);
switch lower(ext)
    case '.csv'
        atlas_data = readtable(atlas_labels, 'FileType', 'text', 'Delimiter', ',');
    case '.tsv'
        atlas_data = readtable(atlas_labels, 'FileType', 'text', 'Delimiter', '\t');
    case '.txt'
        atlas_data = readtable(atlas_labels, 'FileType', 'text'); % auto-detects delimiter
end

% spell out the labels!!!!
fprintf('Schaefer labels spelled out at: https://onlinelibrary.wiley.com/doi/10.1002/hbm.26173 \n');
fprintf('CIT168 (subcortical) labels spelled out at: https://www.nature.com/articles/sdata201863 \n');

labels = string(atlas_data.label);
cd(code_dir);
[spelled_out_labels] = nirl_spell_out_4S456_labels(labels);

% make the user to choose among ~95 labels instead of 468
promptString = sprintf('Select regions within/out of networks');
[selectedIndices, wasSelected] = listdlg('PromptString', 'Select regions within/out of networks to take data from:', ...
    'SelectionMode', 'multiple', ...
    'ListString', spelled_out_labels,...
    'ListSize', [580, 460]); % [width, height]

% % double indexation: take indices of selection, and get original labels + indices
% original_indices = [];
% for i = 1:length(selectedIndices)
%     currentl = labels(selectedIndices(i));
%     original_indices{i} = atlas_data.index(contains(atlas_data.label, currentl));
% end
% original_indices_all = vertcat(original_indices{:}); % concatenate all arrays into a single column
% original_indices_sorted = sort(original_indices_all(:)); % Convert to vector and sort

% % now, filter data (gfa+count)!
% gfa_matrices_filtered = cell(size(sub_dirs,1),1);
% count_streamlines_filtered = cell(size(sub_dirs,1),1);
% for i = 1:size(sub_dirs,1)
%     gfa_matrices_filtered{i} = gfa_matrices{i,1}...
%         (original_indices_sorted,original_indices_sorted);
%     count_streamlines_filtered{i} = count_streamlines{i,1}...
%         (original_indices_sorted,original_indices_sorted);
% end

% now, filter data (gfa+count)!
gfa_matrices_filtered = cell(size(sub_dirs,1),1);
count_streamlines_filtered = cell(size(sub_dirs,1),1);
for i = 1:size(sub_dirs,1)
    gfa_matrices_filtered{i} = gfa_matrices{i,1}...
        (selectedIndices,selectedIndices);
    count_streamlines_filtered{i} = count_streamlines{i,1}...
        (selectedIndices,selectedIndices);
end

%% save filtered data
derivatives_proj_dir_ext = fullfile(proj_dir_ext,'derivatives/');
if ~exist(derivatives_proj_dir_ext, 'dir')
    mkdir(derivatives_proj_dir_ext);
end

filtered_qsirecon_results = struct;
filtered_qsirecon_results.gfa_pass = gfa_matrices_filtered';
filtered_qsirecon_results.count_pass = gfa_matrices_filtered';
filtered_qsirecon_results.selectedIndices = selectedIndices';
filtered_qsirecon_results.selectedLabels = labels(selectedIndices);
filtered_qsirecon_results.selectedLabels_spelledOut = spelled_out_labels(selectedIndices);

timestamp = datestr(now, 'yyyymmdd_HHMMSS');
filename = [derivatives_proj_dir_ext, 'filtered_qsirecon_results_', timestamp, '.mat'];
save(filename, 'filtered_qsirecon_results');

[~,name,ext] = fileparts(filename);
filename = [name, ext];
fprintf('Filtered results saved at: \n');
fprintf('%s \n',derivatives_proj_dir_ext);
fprintf('As: %s \n',filename);

fileattrib(fullfile(derivatives_proj_dir_ext, filename), '+w', 'g'); % gives rights to others to save+read the file
