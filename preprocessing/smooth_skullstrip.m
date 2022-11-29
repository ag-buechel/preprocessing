function smooth_skullstrip(all_sub_ids, modality, skern)
% smooth the skullstripped mean EPI or anatomical image for all subjects
% FWHM of smoothig kernel in mm (skern input)
% For what do we need this?

% add paths
addpath(fullfile('..','functions'));

path         = get_base_dir;
path         = path.preprocdir;
n_subs       = length(all_sub_ids);
run_parallel = 1;


matlabbatch = {};

for sub = 1:n_subs

    sub_id          = all_sub_ids(sub);

    if strcmp(modality, 'anat')
        direc       = fullfile(path, sprintf('sub-%02d',sub_id), 'anat');
        skullstrip_file = spm_select('FPList', direc, '^skull-strip.*\.nii$');

    elseif strcmp(modality, 'func')
        direc     = fullfile(path, sprintf('sub-%02d',sub_id), 'func');
        skullstrip_file = spm_select('FPList', direc, '^skull-strip.*\.nii$');
        
    end




    matlabbatch{sub}.spm.spatial.smooth.data   = {skullstrip_file}; % check if in cellstr
    matlabbatch{sub}.spm.spatial.smooth.fwhm   = repmat(skern, 1,3);
    matlabbatch{sub}.spm.spatial.smooth.prefix = ['s' num2str(skern)];

end



% run matlabbatch
n_procs = n_subs; % to not block to many cores on the server

if n_procs > 8 
    n_procs = 8;
end

if run_parallel == 1
    run_spm_parallel(matlabbatch, n_procs);
else
    spm_jobman('run',matlabbatch);
end

end