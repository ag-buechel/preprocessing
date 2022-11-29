function warp_skullstrip(all_sub_ids)

% warp skull strip, based on the segmentation of mean EPI
% normalize the skull stripped mean EPI to MNI space


% add paths
addpath(fullfile('..','functions'));

path         = get_base_dir;
path         = path.preprocdir;
n_subs       = length(all_sub_ids);
run_parallel = 1;

matlabbatch  = cell(1,n_subs);

for sub = 1:n_subs

    sub_id     = all_sub_ids(sub);
    func_dir   = fullfile(path, sprintf('sub-%02d',sub_id), 'func');

    % skullstrips to warp
    strip_file = spm_select('FPList', func_dir, '^s[1-9]skull-strip.*\.nii');
    c1_file    = spm_select('FPList', func_dir, '^c1.*\.nii');
    c2_file    = spm_select('FPList', func_dir, '^c2.*\.nii');

    images     = {cellstr(char(strip_file, c1_file, c2_file))}; 

    % warp based on flowfield ('warpfield' in FSL)
    % the flowfield is based on segmentation of mean epi
    u_rc1_file = spm_select('FPList', func_dir, '^u_rc1.*');
    flowfields = cellstr(repmat(u_rc1_file, length(images{1}),1));

    matlabbatch{sub}.spm.tools.dartel.crt_warped.flowfields = flowfields;
    matlabbatch{sub}.spm.tools.dartel.crt_warped.images     = images;
    matlabbatch{sub}.spm.tools.dartel.crt_warped.jactransf  = 0;
    matlabbatch{sub}.spm.tools.dartel.crt_warped.K          = 6;
    matlabbatch{sub}.spm.tools.dartel.crt_warped.interp     = 1;

end

% to not block to many cores on the server
n_procs = n_subs;

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