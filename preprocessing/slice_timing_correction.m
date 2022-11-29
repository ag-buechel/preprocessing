function slice_timing_correction(all_sub_ids)
% performing slice timing correction on realigned and unwarped niftis
% That means that all of the slices acquired for one volume needs to be
% shifted in time by the duration it took to acquire the slice. As we have
% super short TRs this shouldn't change a lot... but is reasonable.

% add paths
addpath(fullfile('..','functions'));

path         = get_base_dir;
path_code    = path.code;
path         = path.preprocdir;
n_subs       = length(all_sub_ids);
run_parallel = 1;


% timing constants extracted from exemplary DICOM file in 
% 'get_slice_timepoints.m'
timings  = load(fullfile(path_code, 'preprocessing','defaults', 'timings.mat'));

for sub = 1:n_subs

    sub_id    = all_sub_ids(sub);
    epi_dir   = fullfile(path, sprintf('sub-%02d',sub_id), 'func');
    epi_files = cellstr(spm_select('FPList', epi_dir, '^usub-.*\.nii'));

    % the first three pilot subjects were measured with different scan
    % parameters: 1.5 * 1.5 * 1.5 mm3, multiband factor 3
    if sub_id < 3
        st = timings.timings.mb3; % slice timings
    else
        % all other subs: 2 * 2 * 2 mm3, multiband factor 2
        st = timings.timings.mb2; % slice timings
    end

    matlabbatch{sub}.spm.temporal.st       = st;
    matlabbatch{sub}.spm.temporal.st.scans = {cellstr(epi_files)};

end


% run matlabbatch
n_procs = n_subs; % to not block to many cores on the server

if n_procs > 8 
    n_procs = 8;
end

if run_parallel == 1
    run_spm_parallel(matlabbatch,n_procs);
else
    spm_jobman('run', matlabbatch);
end

end