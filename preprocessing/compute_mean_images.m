function compute_mean_images
% 
% Compute mean over subjects fpr the following
%
% 1. warped, skull-stripped mean epi
% 2. warped c1 image (== grey matter) based on segmentation of mean epi

% add paths
addpath(fullfile('..','functions'));

path = get_base_dir;
path = path.preprocdir; 

run_parallel = 1;

% template for mean image matlab batch
template = [];
template.spm.util.imcalc.outdir         = cellstr(path);
template.spm.util.imcalc.expression     = 'mean(X)'; 
template.spm.util.imcalc.var            = struct('name', {}, 'value', {});
template.spm.util.imcalc.options.dmtx   = 1;
template.spm.util.imcalc.options.mask   = 0;
template.spm.util.imcalc.options.interp = 1;
template.spm.util.imcalc.options.dtype  = 4;

matlabbatch = cell(1,2);
counter     = 0;

% rethink this sub structure...(?)
subs   = dir(fullfile(path, 'sub-*'));
n_subs = length(subs);

% cells for skull stripped mean epis and c1 file
mean_files   = cell(n_subs, 1);
c1mean_files = cell(n_subs, 1);


% loop over subs to get mean images
for sub = 1:n_subs
    sub_dir   = fullfile(subs(sub).folder, subs(sub).name);
    func_dir  = fullfile(sub_dir, 'func');

    mean_file   = spm_select('FPList', func_dir, '^ws[0-9]skull-strip-mean-epi.nii$'); 
    c1mean_file = spm_select('FPList', func_dir, '^wc1mean.*\.nii$');

    mean_files{sub}  = mean_file;
    c1mean_files{sub} = c1mean_file;
end

counter = counter + 1;
matlabbatch{counter} = template;
matlabbatch{counter}.spm.util.imcalc.input  = mean_files;
matlabbatch{counter}.spm.util.imcalc.output = sprintf('mean-skullstrip-mean-epi.nii');

counter = counter + 1;
matlabbatch{counter} = template;
matlabbatch{counter}.spm.util.imcalc.input  = c1mean_files;
matlabbatch{counter}.spm.util.imcalc.output = sprintf('mean-c1.nii');

% run matlabbatch
if run_parallel == 1
    run_spm_parallel(matlabbatch, 2); % only two images
else
    spm_jobman('run',matlabbatch);
end

end