function segmentation(all_sub_ids, modality)

% SPM segmentation on:
%                     1 - the mean EPIs (one mean EPI/sub)(if modality "func")
%                     2 - the anatomical images (if modality "anat")

% With the segmented images the flow/warpfields are created in the next
% step. they are needed for normalization to MNI space using the DARTEL
% toolbox.

% add paths
addpath(fullfile('..','functions'));

% get paths % add paths
path         = get_base_dir;
path_code    = fullfile(path.code, 'preprocessing'); 
path         = path.preprocdir;

n_subs       = length(all_sub_ids);
run_parallel = 1;


% As I don't provide tissue probability maps right now, I will use the
% default TPM file that Lukas provided in his defaults and Christian uses
% the same map
tpm_file     = fullfile(path_code, 'defaults/enhanced_TPM.nii');

% template for the segmentation matlabbatch
template = [];
template.spm.spatial.preproc.channel.biasreg = 0.001;
template.spm.spatial.preproc.channel.biasfwhm = 60;
template.spm.spatial.preproc.channel.write = [0 0];

template.spm.spatial.preproc.tissue(1).tpm = {[tpm_file ,',1']};
template.spm.spatial.preproc.tissue(1).ngaus = 2;
template.spm.spatial.preproc.tissue(1).native = [1 1];
template.spm.spatial.preproc.tissue(1).warped = [0 0];

template.spm.spatial.preproc.tissue(2).tpm = {[tpm_file ',2']};
template.spm.spatial.preproc.tissue(2).ngaus = 1;
template.spm.spatial.preproc.tissue(2).native = [1 1];
template.spm.spatial.preproc.tissue(2).warped = [0 0];

template.spm.spatial.preproc.tissue(3).tpm = {[tpm_file ',3']};
template.spm.spatial.preproc.tissue(3).ngaus = 2;
template.spm.spatial.preproc.tissue(3).native = [1 1];
template.spm.spatial.preproc.tissue(3).warped = [0 0];

template.spm.spatial.preproc.tissue(4).tpm = {[tpm_file ',4']};
template.spm.spatial.preproc.tissue(4).ngaus = 3;
template.spm.spatial.preproc.tissue(4).native = [0 0];
template.spm.spatial.preproc.tissue(4).warped = [0 0];

template.spm.spatial.preproc.tissue(5).tpm = {[tpm_file ',5']};
template.spm.spatial.preproc.tissue(5).ngaus = 4;
template.spm.spatial.preproc.tissue(5).native = [0 0];
template.spm.spatial.preproc.tissue(5).warped = [0 0];

template.spm.spatial.preproc.tissue(6).tpm = {[tpm_file ',6']};
template.spm.spatial.preproc.tissue(6).ngaus = 2;
template.spm.spatial.preproc.tissue(6).native = [0 0];
template.spm.spatial.preproc.tissue(6).warped = [0 0];

template.spm.spatial.preproc.warp.mrf = 1;
template.spm.spatial.preproc.warp.cleanup = 1;
template.spm.spatial.preproc.warp.reg = [0 0.001 0.5 0.05 0.2];
template.spm.spatial.preproc.warp.affreg = 'mni';
template.spm.spatial.preproc.warp.fwhm = 0;
template.spm.spatial.preproc.warp.samp = 3;
template.spm.spatial.preproc.warp.write = [0 0];


matlabbatch = {};

for sub = 1:n_subs
    sub_id               = all_sub_ids(sub);

    if strcmp(modality, 'func')
        direc                = fullfile(path, sprintf('sub-%02d',sub_id), 'func');
        file                 = spm_select('FPList', direc, '^meanusub.*\.nii$');

    elseif strcmp(modality, 'anat')
        direc                = fullfile(path, sprintf('sub-%02d',sub_id), 'anat');
        file                 = spm_select('FPList', direc, '^sPRISMA.*\.nii$');

    else
        error('No correct modality provided for segmentation. Options: "func", "anat"\n');
        
    end

    matlabbatch{sub}     = template;
    matlabbatch{sub}.spm.spatial.preproc.channel.vols = cellstr(file);

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