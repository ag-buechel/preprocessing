function coregistration(all_sub_ids)
% We want to bring the images in the same space for later group analysis.
% The first step to do this is to warp the T1 to the functional images.
% The target image is the functional images ("reference")and the T1 
% gets moved ("source").

% Reference is thus the mean epi, source image is the T1 anatomical image.

% Input:  1 - the mean EPIs (one mean EPI/sub) "meanusub_..."
%         2 - the anatomical images 

% Output: Let's see what will come out


% add paths & define variables
addpath(fullfile('..','functions'));

path           = get_base_dir;
n_subs         = length(all_sub_ids);
run_parallel   = 1;


% make coregistration template with defaults from SPM
template.spm.spatial.coreg.estimate.other             = {''};
template.spm.spatial.coreg.estimate.eoptions.cost_fun = 'nmi';
template.spm.spatial.coreg.estimate.eoptions.sep      = [4 2];
template.spm.spatial.coreg.estimate.eoptions.tol      = [0.02 0.02 0.02 0.001 0.001 0.001 0.01 0.01 0.01 0.001 0.001 0.001];
template.spm.spatial.coreg.estimate.eoptions.fwhm     = [7 7];


% pre-define matlabbatch structure
matlabbatch = {};

% get ref and source for all subjects
for sub = 1:n_subs

    sub_id    = all_sub_ids(sub);
    func_dir  = fullfile(path.preprocdir, sprintf('sub-%02d',sub_id), 'func');
    anat_dir  = fullfile(path.preprocdir, sprintf('sub-%02d',sub_id), 'anat');

    mean_epi_file  = spm_select('FPList', func_dir, '^meanusub.*\.nii$');
    anat_file      = spm_select('FPList', anat_dir, '^sPRISMA.*\.nii$');
    % change the T1 name and make this coherent with import !! so that
    % people only need to name this once at the beginning
    
    % add template info (shared for all subs)
    matlabbatch{sub} = template;

    % add images as cellstr.
    matlabbatch{sub}.spm.spatial.coreg.estimate.ref    = cellstr(mean_epi_file);
    matlabbatch{sub}.spm.spatial.coreg.estimate.source = cellstr(anat_file);

end

% run matlabbatch
n_procs = n_subs; % to not block to many cores on the server

if n_procs > 8 % this should also be defined in the masterfile
    n_procs = 8;
end

% run matlabbatch
if run_parallel == 1
    run_spm_parallel(matlabbatch, n_procs);
else
    spm_jobman('run',matlabbatch);
end


end