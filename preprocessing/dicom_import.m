function dicom_import(all_sub_id)
    
    % add paths
    addpath(fullfile('..','functions'));

    % define variables and get paths/files
    n_subs       = length(all_sub_id);
    path         = get_base_dir;
    data_folder  = fullfile(path.basedir, 'rawdata');
    prisma_ids   = dlmread(fullfile(path.basedir, 'prisma_ids.tsv'), '\t', 1, 0);
    n_procs      = 8; % for revelation to handle 8 parallel processes
    run_parallel = 1;
    batch_nr     = 1; 

    for s = 1:n_subs
        sub_id      = all_sub_id(s); 
        prisma_id   = prisma_ids(prisma_ids(:,1) == sub_id, 2); 
        sub_folder  = fullfile(data_folder,sprintf('sub-%02d',sub_id));

        if isempty(dir(fullfile(sub_folder, 'func', '*.nii.gz')))
            
            fprintf('import dicom data from sub %d (%d of %d)\n', sub_id, s, n_subs);
        
            % find dicom folder names with system command and regexp
            [~, folders_txt] = system(sprintf('dicq -f PRISMA_%d',prisma_id));
            
            % create a regexp to find folder names
            % 1: mprage (anatomical T1-weighted image)
            exp ='(?<=mprage.*] ).*/.*(?=\n)';
            d_names_anat = regexp(folders_txt,exp,'match','dotexceptnewline');
            
            % 2: fmri ep2d_bold,..., fMRI (runs 1-6) 
            exp ='(?<=fMRI.*] ).*/.*(?=\n)';
            d_names_fMRI = regexp(folders_txt,exp,'match','dotexceptnewline');
            
            % 3: field_map x2 folder 
            exp ='(?<=gre_field_map.*] ).*/.*(?=\n)';
            d_names_fieldmap = regexp(folders_txt,exp,'match','dotexceptnewline');
    
            % spm_select select images without the dummy scans (5 pulses, 4 images)
            % anatomical images fnames
            for d = 1:length(d_names_anat)
                d_name              = d_names_anat{d};
                fnames_anat{d}      = spm_select('List',d_name,'^MR');
                full_fnames_anat{d} = strcat(d_names_anat{d},'/',fnames_anat{d});
            end
    
            % fMRI images fnames
            for d = 1:length(d_names_fMRI)
                d_name              = d_names_fMRI{d};
                fnames_fMRI{d}      = spm_select('List',d_name,'^MR');
                full_fnames_fMRI{d} = strcat(d_names_fMRI{d},'/',fnames_fMRI{d});
                full_fnames_fMRI{d}(1:4,:) = []; % discard dummies
            end
    
            % fieldmap images fnames
            for d = 1:length(d_names_fieldmap)
                d_name                 = d_names_fieldmap{d};
                fnames_fieldmap{d}     = spm_select('List',d_name,'^MR');
                full_fnames_fieldmap{d}= strcat(d_names_fieldmap{d},'/',fnames_fieldmap{d});
            end
    
            % matlab batch for each run, T1 and fieldmap seperately save it in outd 
            % in my projects folder (see batch example below
           
            % batch anat
            for b = 1:length(full_fnames_anat)
                matlabbatch{batch_nr}.spm.util.import.dicom.data = cellstr(full_fnames_anat{b});
                matlabbatch{batch_nr}.spm.util.import.dicom.root = 'flat';
    
                if length(full_fnames_anat) > 1
                    if ~exist(fullfile(sub_folder,sprintf('anat_%d',b)), 'd')
                        mkdir(fullfile(sub_folder,sprintf('anat_%d',b)));
                    end
                    matlabbatch{batch_nr}.spm.util.import.dicom.outdir = {fullfile(sub_folder,sprintf('anat_%d',b))};
                else
                    if ~exist(fullfile(sub_folder,'anat'), 'dir')
                        mkdir(fullfile(sub_folder,'anat'));
                    end
                    matlabbatch{batch_nr}.spm.util.import.dicom.outdir = {fullfile(sub_folder,'anat')};
                end
    
                matlabbatch{batch_nr}.spm.util.import.dicom.protfilter = '.*';
                matlabbatch{batch_nr}.spm.util.import.dicom.convopts.format = 'nii';
                matlabbatch{batch_nr}.spm.util.import.dicom.convopts.meta = 0;
                matlabbatch{batch_nr}.spm.util.import.dicom.convopts.icedims = 0;
    
                batch_nr = batch_nr + 1;
            end
    
            % batch fmri
            for b = 1:length(full_fnames_fMRI)
                
                if ~exist(fullfile(sub_folder,'func',sprintf('run_%d',b)),'dir')
                    mkdir(fullfile(sub_folder,'func',sprintf('run_%d',b)));
                end
    
                matlabbatch{batch_nr}.spm.util.import.dicom.data = cellstr(full_fnames_fMRI{b});
                matlabbatch{batch_nr}.spm.util.import.dicom.root = 'flat';
                matlabbatch{batch_nr}.spm.util.import.dicom.outdir = {fullfile(sub_folder,'func',sprintf('run_%d',b))};
                matlabbatch{batch_nr}.spm.util.import.dicom.protfilter = '.*';
                matlabbatch{batch_nr}.spm.util.import.dicom.convopts.format = 'nii';
                matlabbatch{batch_nr}.spm.util.import.dicom.convopts.meta = 0;
                matlabbatch{batch_nr}.spm.util.import.dicom.convopts.icedims = 0;
    
                batch_nr = batch_nr + 1;
          
            end
    
            % batch fieldmap
            for b = 1:length(full_fnames_fieldmap) 
                
                if ~exist(fullfile(sub_folder,'fmap',sprintf('map_%d',b)),'dir')
                    mkdir(fullfile(sub_folder,'fmap',sprintf('map_%d',b)));
                end
    
                matlabbatch{batch_nr}.spm.util.import.dicom.data = cellstr(full_fnames_fieldmap{b});
                matlabbatch{batch_nr}.spm.util.import.dicom.root = 'flat';
                matlabbatch{batch_nr}.spm.util.import.dicom.outdir = {fullfile(sub_folder,'fmap',sprintf('map_%d',b))};
                matlabbatch{batch_nr}.spm.util.import.dicom.protfilter = '.*';
                matlabbatch{batch_nr}.spm.util.import.dicom.convopts.format = 'nii';
                matlabbatch{batch_nr}.spm.util.import.dicom.convopts.meta = 0;
                matlabbatch{batch_nr}.spm.util.import.dicom.convopts.icedims = 0;
    
                batch_nr = batch_nr + 1;
            end
        else
            fprintf('data from sub %d already imported\n', sub_id);
        end

    end

    % run matlabbatch
    if run_parallel == 1
        run_spm_parallel(matlabbatch, n_procs);
    else
        spm_jobman('run',matlabbatch);
    end


end