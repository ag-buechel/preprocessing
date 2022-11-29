function compute_fieldmap(all_sub_ids)

% This function computes the fieldmap for the subjects. We do this because
% EPI images can be distorted due to B0 (magnetic field) inhomogeneities.
% Signal that has been displaced can be returned to its proper location if
% we use the B0 fieldmap, that's why we compute it.

% add paths
addpath(fullfile('..','functions'));
search_string = '^sub.*\.nii$';

% get all folders for subjects
path            = get_base_dir;
fm_default_file = cellstr(path.fm_default_file);
path            = path.preprocdir;
run_parallel    = 1;
n_subs          = length(all_sub_ids);

for sub = 1:n_subs
    
    sub_id = all_sub_ids(sub);

    % get sub specific folders
    epi_dir =  fullfile(path, sprintf('sub-%02d',sub_id), 'func');
    fm_dir  =  fullfile(path, sprintf('sub-%02d',sub_id), 'fmap');
    
    % get file names
    fm_files  = cellstr(spm_select('ExtFPList', fm_dir, search_string));
    epi_files = cellstr(spm_select('FPList', epi_dir, search_string));  

    if length(fm_files) ~= 3 || length(epi_files) ~=6
        % maybe make this warning more informative
        warning('wrong amount of files in %s\n', sub_dir);
    end

    magn1_file = fm_files(~cellfun(@isempty,regexp(fm_files, 'magnitude1')));
    phase_file = fm_files(~cellfun(@isempty,regexp(fm_files, 'phasediff')));

    matlabbatch{sub}.spm.tools.fieldmap.calculatevdm.subj.data.presubphasemag.phase = phase_file;
    matlabbatch{sub}.spm.tools.fieldmap.calculatevdm.subj.data.presubphasemag.magnitude = magn1_file;
    matlabbatch{sub}.spm.tools.fieldmap.calculatevdm.subj.defaults.defaultsfile = fm_default_file;

    for epi = 1:length(epi_files)
        matlabbatch{sub}.spm.tools.fieldmap.calculatevdm.subj.session(epi).epi = epi_files(epi);
    end

    matlabbatch{sub}.spm.tools.fieldmap.calculatevdm.subj.matchvdm = 1;
    matlabbatch{sub}.spm.tools.fieldmap.calculatevdm.subj.sessname = 'session';
    matlabbatch{sub}.spm.tools.fieldmap.calculatevdm.subj.writeunwarped = 1;
    matlabbatch{sub}.spm.tools.fieldmap.calculatevdm.subj.anat = '';
    matlabbatch{sub}.spm.tools.fieldmap.calculatevdm.subj.matchanat = 0;

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