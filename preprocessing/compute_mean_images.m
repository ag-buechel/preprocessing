function compute_mean_images(all_sub_ids, modality)
% 
% Compute mean over subjects for the following images
%
% 1. warped skull stripped anatomical image (if modality = 'anat')
% 2. warped mean epi
% 3. warped c1 image (== grey matter) based on segmentation of mean epi

% add paths
addpath(fullfile('..','functions'));

% define path/variables
path    = get_base_dir;
path    = path.preprocdir; 
n_subs  = length(all_sub_ids);
counter = 0;

% template for mean image matlab batch
template = [];
template.spm.util.imcalc.outdir         = cellstr(path);
template.spm.util.imcalc.expression     = 'mean(X)'; 
template.spm.util.imcalc.var            = struct('name', {}, 'value', {});
template.spm.util.imcalc.options.dmtx   = 1;
template.spm.util.imcalc.options.mask   = 0;
template.spm.util.imcalc.options.interp = 1;
template.spm.util.imcalc.options.dtype  = 4;


% cells for skull stripped mean epis and c1 file
mean_epi_files   = cell(n_subs, 1);
c1mean_files     = cell(n_subs, 1);

if strcmp(modality, 'anat')
    mean_anat_files = cell(n_subs, 1);
    matlabbatch     = cell(1,3);
else
    matlabbatch = cell(1,2);
end

% loop over subs to get mean images
for sub = 1:n_subs

    sub_id    = all_sub_ids(sub);
    sub_dir   = fullfile(path, sprintf('sub-%02d',sub_id));
    func_dir  = fullfile(sub_dir, 'func');
    anat_dir  = fullfile(sub_dir, 'anat');

    if strcmp(modality, 'anat')
        mean_epi_file   = spm_select('FPList', func_dir, '^wmeanusub.*\.nii$'); 
        mean_anat_file  = spm_select('FPList', anat_dir, '^ws[0-9]skull-strip-T1.nii$');
        c1mean_file     = spm_select('FPList', anat_dir, '^wc1sPRISMA.*\.nii$');

        mean_anat_files{sub} = mean_anat_file;

    elseif strcmp(modality, 'func')
        mean_epi_file   = spm_select('FPList', func_dir, '^ws[0-9]skull-strip-mean-epi.nii$');
        c1mean_file     = spm_select('FPList', func_dir, '^wc1mean.*\.nii$');
    end

    mean_epi_files{sub} = mean_epi_file;
    c1mean_files{sub}   = c1mean_file;

end

% mean EPIs
counter = counter + 1;
matlabbatch{counter} = template;
matlabbatch{counter}.spm.util.imcalc.input  = mean_epi_files;
matlabbatch{counter}.spm.util.imcalc.output = sprintf('mean-epi.nii');

% mean C1
counter = counter + 1;
matlabbatch{counter} = template;
matlabbatch{counter}.spm.util.imcalc.input  = c1mean_files;
matlabbatch{counter}.spm.util.imcalc.output = sprintf('mean-c1.nii');

% mean anatomical image (T1)
if strcmp(modality, 'anat')
    counter = counter + 1;
    matlabbatch{counter} = template;
    matlabbatch{counter}.spm.util.imcalc.input  = mean_anat_files;
    matlabbatch{counter}.spm.util.imcalc.output = sprintf('mean-T1.nii');
end

% parallelization unnecessary for max 3 images(?)
spm_jobman('run',matlabbatch);

end