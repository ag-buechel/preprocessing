function [path] = get_base_dir

% get paths for preprocessing. 
% maybe add some other hostnames here? 

path.basedir   = '/projects/crunchie/habermann/copain/data/scanner';
path.code      = '/projects/crunchie/habermann/copain/code/analysis_mri';
path.templates = '/common/apps/spm12-7771/toolbox/cat12/templates_volumes';

path.BIDSdir         = fullfile(path.basedir , 'rawdata'); % that should be the folder with the zipped not-to-touch data sets
path.preprocdir      = fullfile(path.BIDSdir , 'derivatives', 'spm_preproc');
path.firstleveldir   = fullfile(path.BIDSdir, 'derivatives', 'spm_firstlevel');
path.secondleveldir  = fullfile(path.BIDSdir, 'derivatives', 'spm_secondlevel');

% add spm - this shouldn't be necessary...
addpath('/common/apps/spm12-7771');

% file for computation of fieldmap
% what exactly is this default file for?

path.fm_default_file = fullfile(path.code, '/preprocessing/defaults/pm_defaults_Prisma_ISN_15.m');

end