function skullstrip(all_sub_ids)

% Skullstrip all mean EPIs

% add paths
addpath(fullfile('..','functions'));

path         = get_base_dir;
path         = path.preprocdir;
n_subs       = length(all_sub_ids);
run_parallel = 1;

matlabbatch  = cell(1,n_subs);

for sub = 1:n_subs

    sub_id    = all_sub_ids(sub);
    func_dir  = fullfile(path, sprintf('sub-%02d',sub_id), 'func');
    mean_file = spm_select('FPList', func_dir, '^meanusub.*\.nii$');
    c1_file   = spm_select('FPList', func_dir, '^c1.*\.nii$');
    c2_file   = spm_select('FPList', func_dir, '^c2.*\.nii$');
    c3_file   = spm_select('FPList', func_dir, '^c3.*\.nii$');

    Vfnames = cellstr(char(mean_file, c1_file, c2_file, c3_file));

    matlabbatch{sub}.spm.util.imcalc.input          = Vfnames;
    matlabbatch{sub}.spm.util.imcalc.output         = 'skull-strip-mean-epi.nii';
    matlabbatch{sub}.spm.util.imcalc.outdir         = {func_dir};
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