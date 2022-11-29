% To do the slice timing correction I need the timepoints each slice hase
% been acquired! 

% add paths
addpath(fullfile('..','functions'));

% get any of the fmri dicom files not nifti
path    = get_base_dir;
timings = struct();

% find dicom folder names with system command and regexp
prisma_id_multiband3 = 23666;
prisma_id_multiband2 = 23736;

% get any of the fmri dicom files not nifti
%% MB 3
[~, folders_txt] = system(sprintf('dicq -f PRISMA_%d',prisma_id_multiband3));

% fmri ep2d_bold,..., fMRI (runs 1-6) 
exp ='(?<=fMRI.*] ).*/.*(?=\n)';
d_names_fMRI = regexp(folders_txt,exp,'match','dotexceptnewline');
fnames_fMRI  = spm_select('FPList',d_names_fMRI{1},'^MR');
multiband_3_dicom = fnames_fMRI(1,:);  
hdr_mb3           = spm_dicom_headers(multiband_3_dicom);

timings.mb3.so       = hdr_mb3{1}.Private_0019_1029; %ms
timings.mb3.tr       = hdr_mb3{1}.RepetitionTime/1000;
timings.mb3.nslices  = length(timings.mb3.so);
timings.mb3.refslice = timings.mb3.tr / 2 * 1000;
timings.mb3.ta       = 0; % this is zero because all entries are in ms
timings.mb3.prefix   = 'a';


%% MB 2
[~, folders_txt] = system(sprintf('dicq -f PRISMA_%d',prisma_id_multiband2));

% fmri ep2d_bold,..., fMRI (runs 1-6) 
exp ='(?<=fMRI.*] ).*/.*(?=\n)';
d_names_fMRI         = regexp(folders_txt,exp,'match','dotexceptnewline');
fnames_fMRI          = spm_select('FPList',d_names_fMRI{1},'^MR');
multiband_2_dicom    = fnames_fMRI(1,:);
hdr_mb2              = spm_dicom_headers(multiband_2_dicom);
timings.mb2.so       = hdr_mb2{1}.Private_0019_1029; % ms
timings.mb2.tr       = hdr_mb2{1}.RepetitionTime/1000;
timings.mb2.nslices  = length(timings.mb2.so);
timings.mb2.refslice = timings.mb2.tr /2 * 1000; % in ms
timings.mb2.ta       = 0;
timings.mb2.prefix   = 'a';

%% Get timings and save
%save(fullfile(path.code, 'preprocessing/defaults/timings.mat'),'timings');

