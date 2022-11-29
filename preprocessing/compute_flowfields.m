function compute_flowfields(all_sub_ids, modality)

% Input: Segmented images!
% Output: (Warp-)/Flowfields for later normalization to mni space
%          this is done for the second level analysis

% Compute flowfields for normalization from native space of the images to
% MNI space. 
% Normalize all epis to MNI space using dartel-based flowfields based on
% segmentation of mean epis / or T1s.

% add paths
addpath(fullfile('..','functions'));

% indicate template to normalize to
path           = get_base_dir;
template_path  = path.templates; % TAKE THE NEW TEMPLATE FROM CAT TOOLBOX! SEE LIEVENS MAIL
path           = path.preprocdir;
n_subs         = length(all_sub_ids);
run_parallel   = 1;

% template for the batch
template.spm.tools.dartel.warp1.settings.rform = 0;
template.spm.tools.dartel.warp1.settings.param(1).its = 3;
template.spm.tools.dartel.warp1.settings.param(1).rparam = [4 2 1e-06];
template.spm.tools.dartel.warp1.settings.param(1).K = 0;
template.spm.tools.dartel.warp1.settings.param(1).template = cellstr(fullfile(template_path, 'Template_1_IXI555_MNI152.nii'));
template.spm.tools.dartel.warp1.settings.param(2).its = 3;
template.spm.tools.dartel.warp1.settings.param(2).rparam = [2 1 1e-06];
template.spm.tools.dartel.warp1.settings.param(2).K = 0;
template.spm.tools.dartel.warp1.settings.param(2).template = cellstr(fullfile(template_path, 'Template_2_IXI555_MNI152.nii'));
template.spm.tools.dartel.warp1.settings.param(3).its = 3;
template.spm.tools.dartel.warp1.settings.param(3).rparam = [1 0.5 1e-06];
template.spm.tools.dartel.warp1.settings.param(3).K = 1;
template.spm.tools.dartel.warp1.settings.param(3).template = cellstr(fullfile(template_path, 'Template_3_IXI555_MNI152.nii'));
template.spm.tools.dartel.warp1.settings.param(4).its = 3;
template.spm.tools.dartel.warp1.settings.param(4).rparam = [0.5 0.25 1e-06];
template.spm.tools.dartel.warp1.settings.param(4).K = 2;
template.spm.tools.dartel.warp1.settings.param(4).template = cellstr(fullfile(template_path, 'Template_4_IXI555_MNI152.nii'));
template.spm.tools.dartel.warp1.settings.param(5).its = 3;
template.spm.tools.dartel.warp1.settings.param(5).rparam = [0.25 0.125 1e-06];
template.spm.tools.dartel.warp1.settings.param(5).K = 4;
template.spm.tools.dartel.warp1.settings.param(5).template = cellstr(fullfile(template_path, 'Template_5_IXI555_MNI152.nii'));
template.spm.tools.dartel.warp1.settings.param(6).its = 3;
template.spm.tools.dartel.warp1.settings.param(6).rparam = [0.25 0.125 1e-06];
template.spm.tools.dartel.warp1.settings.param(6).K = 6;
template.spm.tools.dartel.warp1.settings.param(6).template = cellstr(fullfile(template_path, 'Template_6_IXI555_MNI152.nii'));
template.spm.tools.dartel.warp1.settings.optim.lmreg = 0.01;
template.spm.tools.dartel.warp1.settings.optim.cyc = 3;
template.spm.tools.dartel.warp1.settings.optim.its = 3;


% get paths and loop over subjects
matlabbatch = {};

for sub = 1:n_subs

    sub_id    = all_sub_ids(sub);

    if strcmp(modality, 'anat')
        direc     = fullfile(path, sprintf('sub-%02d',sub_id), 'anat');

    elseif strcmp(modality, 'func')
        direc     = fullfile(path, sprintf('sub-%02d',sub_id), 'func');
    end

    rc1_file  = spm_select('FPList', direc, '^rc1.*\.nii$');
    rc2_file  = spm_select('FPList', direc, '^rc2.*\.nii$');

    matlabbatch{sub} = template;
    matlabbatch{sub}.spm.tools.dartel.warp1.images = {cellstr(rc1_file), cellstr(rc2_file)};

end


% run matlabbatch
n_procs = n_subs; % to not block to many cores on the server

if n_procs > 8 
    n_procs = 8;
end

% run matlabbatch
if run_parallel == 1
    run_spm_parallel(matlabbatch, n_procs);
else
    spm_jobman('run',matlabbatch);
end

end