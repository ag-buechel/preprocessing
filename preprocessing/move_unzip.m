function move_unzip(subs)
% to maintain BIDS compatibility, preprocessing is done outside the raw
% BIDS directory. the nii.gz files need thus to be unzipped and stored in
% the derivatives folder

% add paths
addpath(fullfile('..','functions'));

base_dir    = get_base_dir;
BIDS_dir    = base_dir.BIDSdir;
preproc_dir = base_dir.preprocdir;
modalities  = {'func','fmap', 'anat'};

for s = 1:length(subs)
    sub           = subs(s);

    fprintf('Unzipping files from subject %d (%d of %d)\n',sub,s,length(subs));

    for m = 1:length(modalities)
        modality = modalities{m};
        fprintf('%s\n', modality);
        source_folder  = fullfile(BIDS_dir,sprintf('sub-%02d',sub),modality);
        target_folder  = fullfile(preproc_dir,sprintf('sub-%02d',sub),modality);

        if ~exist(target_folder)
            mkdir(target_folder);
            files_to_move = cellstr(spm_select('FPList',source_folder,'.*\.nii.gz'));
            gunzip(files_to_move, target_folder);
        else
            fprintf('%s folder already created\n', modality);
        end

    end
   
end



end