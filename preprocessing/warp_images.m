function warp_images(all_sub_ids, modality)

% warp images (mean epi, anatomical image and grey & white matter files) to
% MNI space with the computed flowfields from step "compute_flowfields. 

% warping based on flowfield ('warpfield' in FSL)
% the flowfield is based on segmentation of mean epi or the anatomical
% image depending on earlier steps in preprocessing

% add paths
addpath(fullfile('..','functions'));

path         = get_base_dir;
path         = path.preprocdir;
n_subs       = length(all_sub_ids);
run_parallel = 1;

matlabbatch  = cell(1,n_subs);

for sub = 1:n_subs

    sub_id     = all_sub_ids(sub);


    if strcmp(modality, 'anat')
        mod_dir     = fullfile(path, sprintf('sub-%02d',sub_id), 'anat');
        func_dir    =  fullfile(path, sprintf('sub-%02d',sub_id), 'func');

        strip_file  = spm_select('FPList', mod_dir, '^s[1-9]skull-strip.*\.nii');
        c1_file     = spm_select('FPList', mod_dir, '^c1.*\.nii');
        c2_file     = spm_select('FPList', mod_dir, '^c2.*\.nii');
        u_rc1_file  = spm_select('FPList', mod_dir, '^u_rc1.*');

        mean_epi    =  spm_select('FPList', func_dir, '^meanusub.*\.nii$');
        images      =  {cellstr(char(mean_epi, strip_file, c1_file, c2_file))}; 

    elseif strcmp(modality, 'func')
        mod_dir     = fullfile(path, sprintf('sub-%02d',sub_id), 'func');

        strip_file  = spm_select('FPList', mod_dir, '^s[1-9]skull-strip.*\.nii');
        c1_file     = spm_select('FPList', mod_dir, '^c1.*\.nii');
        c2_file     = spm_select('FPList', mod_dir, '^c2.*\.nii');
        u_rc1_file  = spm_select('FPList', mod_dir, '^u_rc1.*');

        images      = {cellstr(char(strip_file, c1_file, c2_file))}; 

    end
    

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

% move warped mean epi in func folder if segmentation based on T1
if strcmp(modality, 'anat')

    for sub = 1:n_subs
        sub_id     = all_sub_ids(sub);

        anat_dir   = fullfile(path, sprintf('sub-%02d',sub_id), 'anat');
        func_dir   =  fullfile(path, sprintf('sub-%02d',sub_id), 'func');

        warped_epi =  spm_select('FPList', anat_dir, '^wmeanusub.*\.nii$');

        movefile(warped_epi, func_dir);

    end
end

end