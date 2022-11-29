% FULL PREPROCESSING PIPELINE (to be used as a template)
%
% This script is the overview of the full preprocessing pipeline
% for the COPAIN project from Marie, but most of the parts are adapted from
% Lukas script for the SPM course in 2021.
%
% First part deals with importing the DICOM images from the server,
% converting them according to BIDS format and make event files.
%
% Second part is the pre-processing of the images so that they can be used 
% in first and second level analyses.

% Specify paths here:
%
% Give vector of sub ids to be preprocessed here:
% subs = 
%
% Specify sub IDs and prisma IDs here! 
% (really here or as input for the DICOM import function?)
%% 0. Specific settings
% pilot subs = [1,2,4,5]; [1,2] have different scan parameters  
all_sub_ids   = 6:59;  % pilots + main subs, all new scan params
smooth_kernel = 3;

%% 1. Import DICOM
dicom_import(all_sub_ids);

%% 2. Convert to 4D nifti and zip the files according to BIDS
nii_conv_3D_to_4D(all_sub_ids);

%% 3. Make an event file for the first level specification
make_event_file(all_sub_ids);

%% 4. Move and unzip the folder in the BIDS conform "derivatives" folder
% add the T1 images in the folder as they might be needed for the
% segmentation later on
move_unzip(all_sub_ids);

%% 5. Compute fieldmap
% to be able to correct for B0 inhomogeneities
compute_fieldmap(all_sub_ids);

%% 6. Realing and unwarp
realign_unwarp(all_sub_ids);

%% 7. Slice time correction
% get_slice_timepoints; function to get the timings.mat for the first time
% it is now stored in the default folder
slice_timing_correction(all_sub_ids);

%% (non-linear) co-registration?

%% 8. Segmentation
% This segementation is based on the mean EPI and step 9. "Compute
% Flowfields" as well. After the discusion in group meeting I decided to
% use the anatomical images. So change those two steps or make it an option
% to choose among mean EPI or T1 
segmentation(all_sub_ids);



%% 9. Compute Flowfields
compute_flowfields(all_sub_ids);

%% 10. Skullstrip
skullstrip(all_sub_ids);

%% 11. Smooth skullstrip
% FWHM of smoothig kernel in mm (skern input)
smooth_skullstrip(all_sub_ids,smooth_kernel);

%% 12. Warp skullstrip
warp_skullstrip(all_sub_ids);

%% 13. Compute mean images
compute_mean_images;
