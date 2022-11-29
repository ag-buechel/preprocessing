% PREPROCESSING PIPELINE (to be used as a template)
%
% This script is the overview of the full preprocessing pipeline
% for the COPAIN project from Marie (November 2022), 
% but some parts are adapted from Lukas scripts for preprocessing of the
% bafeg data. 
%
% First part deals with importing the DICOM images from the server,
% converting them according to BIDS format and make event files.
%
% Second part is the pre-processing of the images so that they can be used 
% in first and second level analyses.

% ADJUSTMENTS:
% -------------------------------------------------------------------------
% 1. PATH STRUCTURE 
% Specify paths here: functions/get_base_dir.m. This is the main part that
% should be adapted for your study. 
% 
% 2. PRISMA IDs
% Also you need to provide a file
% containing the Prisma IDs and the participant number of your subject.

% 3. TIMINGS
% For slice timing correction run "get_slice_timepoints.m" to create your
% personal timings.mat and store it in the defaults folder
% -------------------------------------------------------------------------

% still missing: JSON files for BIDS, backward deformation (CBs script)

%% 0. Specific settings
% pilot subs = [1,2,4,5]; [1,2] have different scan parameters  
all_sub_ids   = 6:59;  % pilots + main subs, all new scan params
smooth_kernel = 3;
modality = "anat"; % define what should be segmented

% visual inspection of anatomical images, decide later how many images can
% be displayed at once without getting to small images/or get to confused
disp_multiple_T1(subject_subset);

%% 1. Import DICOM
dicom_import(all_sub_ids);

%% 2. Convert to 4D nifti and zip the files according to BIDS
nii_conv_3D_to_4D(all_sub_ids);

%% 3. Make an event file for the first level specification
make_event_file(all_sub_ids);

%% 4. Move and unzip the folder in the BIDS conform "derivatives" folder
% Input:  zipped 4D niftis & images for the fieldmap from the raw folder
% Output: unzipped 4D niftis (one per run) in the derivatives "func" folder
% and fmap files in the derivatives fmap folder and anatomical images in
% "anat" folder
move_unzip(all_sub_ids);

%% 5. Compute fieldmap
% to be able to correct for B0 inhomogeneities
compute_fieldmap(all_sub_ids);

% after this step there are:
% - nr of runs x files with wfmag_ prefix in func folder
% - 1 file with u prefix in func folder
% - vdm5 (voxel displacement map) for each session/run in fmap folder
% - sc file (?) in fmap folder
% - m file in fmap folder
% - fpm file in fmap folder
% - bmask in fmap folder

%% 6. Realing and unwarp
% Input: 
%        - vdm5 files
%        - 4D niftis, unchanged

realign_unwarp(all_sub_ids);

% after this step I get:
% - uw.mat files (func)
% - mean epi: meanusub-... (func)

%% 7. Slice time correction
% get_slice_timepoints; function to get the timings.mat for the first time
% it is now stored in the default folder

% Input: 
%        - Timings (this needs to be setted once in the beginning in the 
%          settings file as it is different for each study)
%        - ^usub epis for each run (4D nii)

slice_timing_correction(all_sub_ids);

% Output:
%        - ^ausub x nr of runs (4D nii)

%% 8. Coregistration
% There is a step in the CB preprocessing script which is called "reorient"
% and happens before coregistration - what is done here?

% Input:
%         1 - the mean EPIs (one mean EPI/sub) "meanusub_..."(results from realign unwarp)
%         2 - the anatomical images 

coregistration(all_sub_ids);

%% 9. Segmentation
% This segementation is based on the mean EPI and step 9. "Compute
% Flowfields" as well. After the discusion in group meeting I decided to
% use the anatomical images. So change those two steps or make it an option
% to choose among mean EPI or T1 

% If coregistered, the T1 image is segmented (do they need to be
% "reoriented"?)

% Input: - anatomical image or mean epi
%        - tissue probability map (defaults folder)

segmentation(all_sub_ids, modality);

%% 10. Skullstrip
% This is also done with the segmented file (struct or mean EPI)
% Input: 
%        - output from segmentation (c1, c2 files)
% Output: 
%        - 'skull-strip-T1.nii' or 'skull-strip-mean-epi.nii'; depending
% on user input

skullstrip(all_sub_ids, modality);

%% 11. Smooth skullstrip anatomical image skull stripped
% FWHM of smoothig kernel in mm (skern input) - why? maybe only for
% cosmetic / display purposes
% Input:
%       - skullstripped mean epi / anatomical image
% Output:
%       - s'smoothing_kernel'skull-stripped... image
smooth_skullstrip(all_sub_ids, modality, smooth_kernel);

%% 12. Compute Flowfields
% In christians skript this is called "do_norm" here the flowfields or
% warpfields are computed for the later normalization. 
% Input:
%     - outputs from segmentation (rc1/rc2_file) 
% Output: 
%     - u_rc1 file (in folder of segmented image)

compute_flowfields(all_sub_ids, modality);

%% Backwards deformations (CB script - I don't know If I need it.)

%% 13. Warp images (to MNI space) -> Lievens Mail for most recent one from cat toolbox
% skullstrip, meanEPI, grey_matter files (c1), white matter (c2)
% with the u_rc1_file that result from compute_flowfield

% Output:
%         - w prefix files in anat/func folder

warp_images(all_sub_ids, modality);


%% 14. Compute mean images of skullstripped, smoothed anat image & mean epi(?)
compute_mean_images(all_sub_ids, modality);
