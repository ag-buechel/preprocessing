function run_spm_parallel(matlabbatch,n_cores)
% basically lukas function to parallelize SPM preprocessing
% relies on parallel computing toolbox

% start parallel pool if there is none, splot matlabbatch and run parallel

start_pool_conditionally(n_cores);
loop_procs = split_vect(matlabbatch,n_cores);

spm_path = fileparts(which('spm'));

parfor worker = 1:n_cores
    warning('off', 'all');
    addpath(genpath(spm_path));
    warning('on', 'all');

    spm_jobman('run', loop_procs{worker});
end

end