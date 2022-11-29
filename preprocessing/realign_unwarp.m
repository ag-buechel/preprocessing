function realign_unwarp(all_sub_ids)

% The EPIs needs to be re-aligned to correct for time induced differences
% between volumes e.g. due to movement. The amount that each volume is 
% out of alignment with a specified reference volume is estimated. Even
% after realignment there is still considerable variance due to subject
% movements. realign_unwarp tries to tackle this problem in an iterative
% fashion using the fieldmaps as an additional source to also correct for
% movement induced variances.
 

% add paths
addpath(fullfile('..','functions'));

% use fieldmap to realign and unwarp epi images
path         = get_base_dir;
path         = path.preprocdir;
n_subs       = length(all_sub_ids);
run_parallel = 1;

matlabbatch  = cell(1,n_subs);


for sub = 1:n_subs

    sub_id = all_sub_ids(sub);

    % define path struct for subject
    vdm_dir = fullfile(path, sprintf('sub-%02d',sub_id), 'fmap');
    epi_dir = fullfile(path, sprintf('sub-%02d',sub_id), 'func');

    % get files
    epi_files = cellstr(spm_select('FPList', epi_dir, '^sub-.*\.nii'));
    vdm_files = cellstr(spm_select('FPList', vdm_dir, '^vdm5_.*session[1-6]\.nii'));

    for session = 1:length(epi_files)
        matlabbatch{sub}.spm.spatial.realignunwarp.data(session).scans  = epi_files(session);
        matlabbatch{sub}.spm.spatial.realignunwarp.data(session).pmscan = vdm_files(session);
    end

    % fill with default options
    matlabbatch{sub}.spm.spatial.realignunwarp.eoptions.quality = 0.9;
    matlabbatch{sub}.spm.spatial.realignunwarp.eoptions.sep = 4;
    matlabbatch{sub}.spm.spatial.realignunwarp.eoptions.fwhm = 5;
    matlabbatch{sub}.spm.spatial.realignunwarp.eoptions.rtm = 0;
    matlabbatch{sub}.spm.spatial.realignunwarp.eoptions.einterp = 2;
    matlabbatch{sub}.spm.spatial.realignunwarp.eoptions.ewrap = [0 0 0];
    matlabbatch{sub}.spm.spatial.realignunwarp.eoptions.weight = '';
    matlabbatch{sub}.spm.spatial.realignunwarp.uweoptions.basfcn = [12 12];
    matlabbatch{sub}.spm.spatial.realignunwarp.uweoptions.regorder = 1;
    matlabbatch{sub}.spm.spatial.realignunwarp.uweoptions.lambda = 100000;
    matlabbatch{sub}.spm.spatial.realignunwarp.uweoptions.jm = 0;
    matlabbatch{sub}.spm.spatial.realignunwarp.uweoptions.fot = [4 5];
    matlabbatch{sub}.spm.spatial.realignunwarp.uweoptions.sot = [];
    matlabbatch{sub}.spm.spatial.realignunwarp.uweoptions.uwfwhm = 4;
    matlabbatch{sub}.spm.spatial.realignunwarp.uweoptions.rem = 1;
    matlabbatch{sub}.spm.spatial.realignunwarp.uweoptions.noi = 5;
    matlabbatch{sub}.spm.spatial.realignunwarp.uweoptions.expround = 'First';
    matlabbatch{sub}.spm.spatial.realignunwarp.uwroptions.uwwhich = [2 1];
    matlabbatch{sub}.spm.spatial.realignunwarp.uwroptions.rinterp = 4;
    matlabbatch{sub}.spm.spatial.realignunwarp.uwroptions.wrap = [0 0 0];
    matlabbatch{sub}.spm.spatial.realignunwarp.uwroptions.mask = 1;
    matlabbatch{sub}.spm.spatial.realignunwarp.uwroptions.prefix = 'u';

end


% run matlabbatch
n_procs = n_subs; % to not block to many cores on the server

if n_procs > 10
    n_procs = 10;
end

if run_parallel == 1
    run_spm_parallel(matlabbatch, n_procs);
else
    spm_jobman('run',matlabbatch);
end

end