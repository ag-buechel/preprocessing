## Preprocessing for fMRI data 

This script is the overview of the full preprocessing pipeline for the COPAIN project from Marie (November 2022), 
but some parts are adapted from Lukas scripts for preprocessing of the BAFEG data. 
Please note that this is still a work in progress and that it is quite heavily commented.
If you spot any errors please feel free and help to correct them by doing so yourself or inform me.
Have fun :-) 

The file "full_preproc" provides the structure for the different preprocessing steps:

01. dicom import (surely needs to be adjusted for your purposes)
02. nifti conversion from 3D to 4D
03. make event files as close to BIDS format as posible (also will require adjustment from your part)
04. move and unzip the 4D niftis from raw folder into derivatives folder in which we want to work
05. compute fieldmaps
06. realign and unwarp
07. slice time correction (For slice timing correction run "get_slice_timepoints.m" to create your
    personal timings.mat and store it in the defaults folder)
08. coregistration
09. segmentation
10. skullstrip
11. smoothing
12. compute flowfields ("do_norm")
13. warp images
14. compute mean images


ADJUSTMENTS: You will need to adjust the following things in addition
-------------------------------------------------------------------------
1. PATH STRUCTURE 
Specify paths here: functions/get_base_dir.m. This is the main part that
should be adapted for your study. 

2. PRISMA IDs
Also you need to provide a file
containing the Prisma IDs and the participant number of your subject.

3. TIMINGS for slice timing correction
-------------------------------------------------------------------------

still missing: JSON files for BIDS, backward deformation (CBs script)
