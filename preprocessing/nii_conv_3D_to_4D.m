function nii_conv_3D_to_4D(all_sub_id)
% convert all 3D niftis of one run to one
% 4D nifti per run 

% add paths
addpath(fullfile('..','functions'));

% define variables
n_subs       = length(all_sub_id);
path         = get_base_dir;
path_code    = path.code;
data_folder  = fullfile(path.basedir, 'rawdata');
run_parallel = 1;
n_procs      = 8; % for revelation to handle 8 parallel processes
batch_nr     = 1;

% get condition information for BIDS format spec
condition_fname = '/projects/crunchie/habermann/copain/code/exp_scanner/scripts/c_file_scanner.txt';
conditions      = readtable(condition_fname,'ReadVariableNames',0);

% import timings
% they are only different for subs < 3
load(fullfile(path_code, 'preprocessing','defaults', 'timings.mat'));


for sub = 1:n_subs 
        sub_id        = all_sub_id(sub);
        sub_folder    = fullfile(data_folder,sprintf('sub-%02d',sub_id));

        if sub_id < 3
            TR = timings.mb3.tr;
        else
            TR = timings.mb2.tr;
        end

    if isempty(dir(fullfile(sub_folder, 'func', '*.nii.gz'))) 
        fprintf('convert 3D data from subject %d (%d of %d)\n',sub_id, sub, n_subs);

        % get conditions for sub
        [~, dirs] = spm_select('List',fullfile(sub_folder,'func'));
        n_runs = size(dirs,1);

        % loop over runs
        for run = 1:n_runs

            % get img names
            img_names = spm_select('FPList', fullfile(sub_folder, 'func', dirs(run,:)));

            % outfile name 
            % filename BIDS conform
            % e.g.:
            % sub-01_task-c_run-01_bold.nii.gz
            % sub-01_task-p_run-02_bold.nii.gz
            % sub-01_task-u_run-03_bold.nii.gz

            cond       = conditions{sub_id,run}{1};
            out_fname  = fullfile(sub_folder,'func',sprintf('/sub-%02d_task-%s_run-%02d_bold.nii',sub_id,cond,run));
            info       = niftiinfo(img_names(1,:));

            % make matlabbatch 
            % make matlabbatch and convert file, save 
            % directly in the func folder of the sub
            matlabbatch{batch_nr}.spm.util.cat.vols  = cellstr(img_names);
            matlabbatch{batch_nr}.spm.util.cat.name  = out_fname;
            matlabbatch{batch_nr}.spm.util.cat.dtype = 4;
            matlabbatch{batch_nr}.spm.util.cat.RT    = TR;

            batch_nr = batch_nr + 1;

        end 

    else
         fprintf('data from sub %d already converted to 4D\n', sub_id);
    end

end


% run matlabbatch
try
    if run_parallel == 1
        run_spm_parallel(matlabbatch, n_procs);
    else
        spm_jobman('run',matlabbatch);
    end
catch
    warning('no matlabbatch to run');
end

% loop over subjects again to zip files and delete unzipped files
% from the rawdata folder
for sub = 1:n_subs
    sub_id        = all_sub_id(sub);
    sub_folder    = fullfile(data_folder,sprintf('sub-%02d',sub_id));  

    if isempty(dir(fullfile(sub_folder, 'func', '*.nii.gz')))  
        fprintf('delete old folders and zip files of subject %d (%d of %d)\n',sub_id, sub, n_subs);
        
        [files, dirs] = spm_select('List',fullfile(sub_folder,'func'));
        n_runs = size(dirs,1);

        % func data
        for run = 1:n_runs
            % folder name run
            folder_name = fullfile(sub_folder,'func',sprintf('run_%d', run));
        
            % delete the run_1:run_6 subfolders
            if exist(folder_name, 'dir') == 7
                rmdir(folder_name,'s')
            else
                warning(sprintf('no folder sub %d for run %d to be removed', sub_id, run));
            end
        
            % zip the files in the gz format
            fname = dir(fullfile(sub_folder,'func',sprintf('*run-%02d*.nii',run)));

            if exist(fullfile(sub_folder,'func',fname.name), 'file') == 2
                full_fpath = fullfile(fname.folder,fname.name);
                gzip(full_fpath)
            else
                warning(sprintf('no nii sub %d for run %d to be zipped', sub_id, run));
            end
            
            % delete the non-zipped file
            try
                delete(full_fpath);
            catch
                warning(sprintf('file already deleted run %d',run));
            end
        end

        try
            % anat data change the order for future subs to avoid repetition
            % change name before zipping
            fname     = dir(fullfile(sub_folder,'anat/*.nii'));
            fname     = fullfile(fname.folder, fname.name);
            new_fname = fullfile(sub_folder, 'anat', sprintf('sub-%02d_T1w.nii',sub_id));
            movefile(fullfile(sub_folder, 'anat', fname), new_fname);
            gzip(new_fname);
            delete(fname);
    
            % gradient field map data
            % in map_1 are the magnitude files 
            % in map_2 is the substracted phase image
            
            % magnitude 
            fname     = dir(fullfile(sub_folder,'fmap/map_1/*.nii'));
            
            % 1
            fname1     = fname(1).name;
            new_fname = fullfile(sub_folder,'fmap',sprintf('sub-%02d_magnitude1.nii',sub_id));
            movefile(fullfile(sub_folder,'fmap/map_1/',fname1),new_fname);
            gzip(new_fname)
        
            % 2
            fname2     = fname(2).name;
            new_fname = fullfile(sub_folder,'fmap',sprintf('sub-%02d_magnitude2.nii',sub_id));
            movefile(fullfile(sub_folder,'fmap/map_1/',fname2),new_fname);
            gzip(new_fname)
        
            % phase difference 
            fname      = dir(fullfile(sub_folder,'fmap/map_2/*.nii'));
            fname3     = fname(1).name;
            new_fname = fullfile(sub_folder,'fmap',sprintf('sub-%02d_phasediff.nii', sub_id));
            movefile(fullfile(sub_folder,'fmap/map_2/',fname3),new_fname);
            gzip(new_fname)
        
            % delete old folders and files
            rmdir(fullfile(sub_folder,'fmap/map_1'));
            rmdir(fullfile(sub_folder,'fmap/map_2'));
            delete(fullfile(sub_folder,'fmap/*.nii'));
        catch
            fprintf('already zipped anat & fmap sub %d\n', sub_id);
        end

    else
        fprintf('data from sub %d already converted to 4D\n', sub_id); 
%         try
%             fprintf('deleting unzipped nifis from sub %d \n', sub_id);
%             unzipped_niftis = dir(fullfile(sub_folder,'func','*.nii'));
%             for nifti = 1:height(unzipped_niftis)
%                 delete(fullfile(unzipped_niftis(nifti).folder,unzipped_niftis(nifti).name));
%             end
%         catch
%             warning('no unzipped niftis to be deleted');
%         end
    end

end % of sub loop

