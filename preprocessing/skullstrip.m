function skullstrip(all_sub_ids, modality)
% skullstrip:
%             1 - the mean EPIs (one mean EPI/sub)(if modality "func")
%             2 - the anatomical images (if modality "anat")
% Input: 
% 1 - resulting from segmentation (c1,c2,c3 images)- make sure to do the
% segmentation and skullstrip on the same modality (mean epi/T1)
% 2 - the mean EPI from func folder oder anatomical image from anat folder


% add paths
addpath(fullfile('..','functions'));

path         = get_base_dir;
path         = path.preprocdir;
n_subs       = length(all_sub_ids);
run_parallel = 1;

matlabbatch  = cell(1,n_subs);

for sub = 1:n_subs

    sub_id    = all_sub_ids(sub);

    if strcmp(modality, 'anat')
        mod_dir     = fullfile(path, sprintf('sub-%02d',sub_id), 'anat');
        mean_file   = spm_select('FPList', mod_dir, '^sPRISMA.*\.nii$'); 
        output_name = 'skull-strip-T1.nii';

    elseif strcmp(modality, 'func')
        mod_dir     = fullfile(path, sprintf('sub-%02d',sub_id), 'func');
        mean_file   = spm_select('FPList', mod_dir, '^meanusub.*\.nii$');
        output_name = 'skull-strip-mean-epi.nii';
    end
    
    % these should have the same prefixes for both modalities 
    c1_file   = spm_select('FPList', mod_dir, '^c1.*\.nii$'); % grey
    c2_file   = spm_select('FPList', mod_dir, '^c2.*\.nii$'); % white
    c3_file   = spm_select('FPList', mod_dir, '^c3.*\.nii$'); % csf

    Vfnames   = cellstr(char(mean_file, c1_file, c2_file, c3_file));

    matlabbatch{sub}.spm.util.imcalc.input          = Vfnames;
    matlabbatch{sub}.spm.util.imcalc.output         = output_name;
    matlabbatch{sub}.spm.util.imcalc.outdir         = {mod_dir};
    matlabbatch{sub}.spm.util.imcalc.expression     = 'i1 .* ((i2 + i3 + i4) > 0.2)';
    matlabbatch{sub}.spm.util.imcalc.options.dmtx   = 0;
    matlabbatch{sub}.spm.util.imcalc.options.mask   = 0;
    matlabbatch{sub}.spm.util.imcalc.options.interp = 1;
    matlabbatch{sub}.spm.util.imcalc.options.dtype  = 4;
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