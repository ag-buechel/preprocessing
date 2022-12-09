% Make json files for all recorded data types to adhere to the BIDS format

% add path
addpath(fullfile('..','functions'));
path   = get_base_dir;

bids_dir = path.BIDSdir;

%% BOLD DATA

% make three diff json files for bold data of the three conditions
% of the main experiment actually the settings are all the same, but the
% task description differs, that's the only reason we need three different
% files...

% [ copain C: controllable
%   copain P: predictable
%   copain U: unpredictable ]

% get a dicom of a participant 
% I start at participant nr 6 (Prisma ID: 23797) because the others are pilots, but I will
% add the jsons for those as well later

exmpl_prisma_ID = 23797;

[~, folders_txt] = system(sprintf('dicq -f PRISMA_%d', exmpl_prisma_ID));

% fmri ep2d_bold,..., fMRI (runs 1-6) 
exp ='(?<=fMRI.*] ).*/.*(?=\n)';
d_names_fMRI    = regexp(folders_txt,exp,'match','dotexceptnewline');
fnames_fMRI     = spm_select('FPList',d_names_fMRI{1},'^MR');
exmpl_dicom     = fnames_fMRI(1,:);
hdr             = spm_dicom_headers(exmpl_dicom);
hdr             = hdr{1};

% json bold
% solve the PhaseEncodingDirection problem, because I have fieldmap data
bold_json                              = struct();
bold_json.SeriesDescription            = hdr.SeriesDescription;
bold_json.ImageType                    = hdr.ImageType;
bold_json.Modality                     = hdr.Modality;
bold_json.TaskName                     = "copain C";
bold_json.SliceTiming                  = hdr.Private_0019_1029;
bold_json.RepetitionTime               = hdr.RepetitionTime / 1000;
bold_json.EchoTime                     = hdr.EchoTime / 1000;
bold_json.FlipAngle                    = hdr.FlipAngle;
bold_json.Manufacturer                 = hdr.Manufacturer;
bold_json.InstitutionName              = hdr.InstitutionName;
bold_json.InstitutionAddress           = hdr.InstitutionAddress;
bold_json.MRAcquisitionType            = hdr.MRAcquisitionType;
bold_json.DeviceSerialNumber           = hdr.DeviceSerialNumber;
bold_json.ScanningSequence             = hdr.ScanningSequence;
bold_json.SequenceVariant              = hdr.SequenceVariant;
bold_json.SequenceName                 = hdr.SequenceName;
bold_json.MultibandAccelerationFactor  = 2; % this shouldn't be coded here but found in the dicom
% bold_json.PhaseEncodingDirection

% print it for C
encoded_bold_json = jsonencode(bold_json, PrettyPrint=true);

% save as json file in raw folder
fname     = fullfile(bids_dir,"task-copainC_bold.json");
fid       = fopen(fname, 'w');
fprintf(fid, encoded_bold_json);
fclose(fid);

% change task name and print it for P
bold_json.TaskName  = "copain P";
encoded_bold_json   = jsonencode(bold_json, PrettyPrint=true);
fname               = fullfile(bids_dir,"task-copainP_bold.json");
fid                 = fopen(fname, 'w');
fprintf(fid, encoded_bold_json);
fclose(fid);

% change task name and print it for U
bold_json.TaskName  = "copain U";
encoded_bold_json   = jsonencode(bold_json, PrettyPrint=true);
fname               = fullfile(bids_dir,"task-copainU_bold.json");
fid                 = fopen(fname, 'w');
fprintf(fid, encoded_bold_json);
fclose(fid);


%% ANAT DATA
% get a dicom of a participant 
% I start at participant nr 6 (Prisma ID: 23797) because the others are pilots, but I will
% add the jsons for those as well later
exmpl_prisma_ID = 23797;

[~, folders_txt] = system(sprintf('dicq -f PRISMA_%d', exmpl_prisma_ID));

exp             = '(?<=mprage.*] ).*/.*(?=\n)';
d_names_anat    = regexp(folders_txt,exp,'match','dotexceptnewline');
fnames_anat     = spm_select('FPList',d_names_anat{1},'^MR');
exmpl_dicom     = fnames_anat(1,:);
hdr             = spm_dicom_headers(exmpl_dicom);
hdr             = hdr{1};

% T1w json
T1w_json = struct();
T1w_json.SeriesDescription  = hdr.SeriesDescription;
T1w_json.ImageType          = hdr.ImageType;
T1w_json.Modality           = hdr.Modality;
T1w_json.RepetitionTime     = hdr.RepetitionTime / 1000;
T1w_json.EchoTime           = hdr.EchoTime / 1000;
T1w_json.SliceThickness     = hdr.SliceThickness;
T1w_json.FlipAngle          = hdr.FlipAngle;
T1w_json.Manufacturer       = hdr.Manufacturer;
T1w_json.MRAcquisitionType  = hdr.MRAcquisitionType;
T1w_json.InstitutionName    = hdr.InstitutionName;
T1w_json.InstitutionAddress = hdr.InstitutionAddress;
T1w_json.DeviceSerialNumber = hdr.DeviceSerialNumber;
T1w_json.ScanningSequence   = hdr.ScanningSequence;
T1w_json.SequenceVariant    = hdr.SequenceVariant;
T1w_json.ScanOptions        = hdr.ScanOptions;
%T1w_json.PhaseEncodingDirection !!!!

encoded_T1w_json   = jsonencode(T1w_json, PrettyPrint=true);
fname               = fullfile(bids_dir,"T1w.json");
fid                 = fopen(fname, 'w');
fprintf(fid, encoded_T1w_json);
fclose(fid);


%% FIELDMAP
exmpl_prisma_ID = 23797;
[~, folders_txt] = system(sprintf('dicq -f PRISMA_%d', exmpl_prisma_ID));

exp = '(?<=gre_field_map.*] ).*/.*(?=\n)';
d_names_fmap= regexp(folders_txt,exp,'match','dotexceptnewline');

fnames_magnitude  = spm_select('FPList',d_names_fmap{1},'^MR');
dicom_magnitude1  = fnames_magnitude(1,:);
dicom_magnitude2  = fnames_magnitude(100,:);
fnames_phasediff  = spm_select('FPList',d_names_fmap{2},'^MR');
dicom_phasediff   = fnames_phasediff(1,:);


% magnitude 1
hdr               = spm_dicom_headers(dicom_magnitude1);
hdr               = hdr{1};

magnitude1_json   = struct();
magnitude1_json.SeriesDescription  = hdr.SeriesDescription;
magnitude1_json.ImageType          = hdr.ImageType;
magnitude1_json.Modality           = hdr.Modality;
magnitude1_json.RepetitionTime     = hdr.RepetitionTime/1000;
magnitude1_json.EchoTime           = hdr.EchoTime/1000;
magnitude1_json.SliceThickness     = hdr.SliceThickness;
magnitude1_json.FlipAngle          = hdr.FlipAngle;
magnitude1_json.InstitutionName    = hdr.InstitutionName;
magnitude1_json.InstitutionAddress = hdr.InstitutionAddress;
magnitude1_json.DeviceSerialNumber = hdr.DeviceSerialNumber;
magnitude1_json.ScanningSequence   = hdr.ScanningSequence;
magnitude1_json.SequenceVariant    = hdr.SequenceVariant;
%magnitude1_json.PhaseEncodingDirection

encoded_magnitude1_json  = jsonencode(magnitude1_json, PrettyPrint=true);
fname                    = fullfile(bids_dir,"magnitude1.json");
fid                      = fopen(fname, 'w');
fprintf(fid, encoded_magnitude1_json);
fclose(fid);

% magnitude 2
hdr               = spm_dicom_headers(dicom_magnitude2);
hdr               = hdr{1};

magnitude2_json   = struct();
magnitude2_json.SeriesDescription  = hdr.SeriesDescription;
magnitude2_json.ImageType          = hdr.ImageType;
magnitude2_json.Modality           = hdr.Modality;
magnitude2_json.RepetitionTime     = hdr.RepetitionTime/1000;
magnitude2_json.EchoTime           = hdr.EchoTime/1000;
magnitude2_json.SliceThickness     = hdr.SliceThickness;
magnitude2_json.FlipAngle          = hdr.FlipAngle;
magnitude2_json.InstitutionName    = hdr.InstitutionName;
magnitude2_json.InstitutionAddress = hdr.InstitutionAddress;
magnitude2_json.DeviceSerialNumber = hdr.DeviceSerialNumber;
magnitude2_json.ScanningSequence   = hdr.ScanningSequence;
magnitude2_json.SequenceVariant    = hdr.SequenceVariant;
%magnitude2_json.PhaseEncodingDirection

encoded_magnitude2_json  = jsonencode(magnitude2_json, PrettyPrint=true);
fname                    = fullfile(bids_dir,"magnitude2.json");
fid                      = fopen(fname, 'w');

fprintf(fid, encoded_magnitude2_json);
fclose(fid);


% phasediff
hdr               = spm_dicom_headers(dicom_phasediff);
hdr               = hdr{1};

phasediff_json   = struct();
phasediff_json.SeriesDescription  = hdr.SeriesDescription;
phasediff_json.ImageType          = hdr.ImageType;
phasediff_json.Modality           = hdr.Modality;
phasediff_json.RepetitionTime     = hdr.RepetitionTime/1000;
phasediff_json.EchoTime1          = magnitude1_json.EchoTime;
phasediff_json.EchoTime2          = magnitude2_json.EchoTime;
phasediff_json.SliceThickness     = hdr.SliceThickness;
phasediff_json.FlipAngle          = hdr.FlipAngle;
phasediff_json.InstitutionName    = hdr.InstitutionName;
phasediff_json.InstitutionAddress = hdr.InstitutionAddress;
phasediff_json.DeviceSerialNumber = hdr.DeviceSerialNumber;
phasediff_json.ScanningSequence   = hdr.ScanningSequence;
phasediff_json.SequenceVariant    = hdr.SequenceVariant;
%phasediff_json.PhaseEncodingDirection

encoded_phasediff_json  = jsonencode(phasediff_json, PrettyPrint=true);
fname                    = fullfile(bids_dir,"phasediff.json");
fid                      = fopen(fname, 'w');

fprintf(fid, encoded_phasediff_json);
fclose(fid);

%% DATASET DESCRIPTION
dataset_description_json             = struct();
dataset_description_json.Name        = "COPAIN"; 
dataset_description_json.BIDSVersion = 1.0;
dataset_description_json.Authors     = ["Marie Habermann", "Christian Buechel"];

encoded_dataset_description_json  = jsonencode(dataset_description_json, PrettyPrint=true);
fname                             = fullfile(bids_dir,"dataset_description.json");
fid                               = fopen(fname, 'w');

fprintf(fid, encoded_dataset_description_json);
fclose(fid);