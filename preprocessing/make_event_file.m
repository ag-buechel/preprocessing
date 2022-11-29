function make_event_file(all_sub_id)

% Make a BIDS compatible events file for every run in 
% the zipped not to touch "func" folder of each sub. This file should
% contain the onset (in seconds) of the event measured from the beginning
% of the acquisition. Timepoint 0 == first stored data point, so point
% without the dummy scans that we already discarded.


% As in my case the run defines the condition in the event .tsv file the
% different trial types are equal to the three different intensities.
% duration = stim_onset bis onset white fixcross II to include the
% different rise and fall times + expecation phase + all button presses

% trial types 
% pain intensities: 1 = low, 2 = medium, 3 = high (in beh.tsv file)
% expectation  = 4 (in events.tsv file)
% buttonpress  = 9 (in trigger.tsv file)


% get paths
path   = get_base_dir;
n_subs = length(all_sub_id);


for s = 1:n_subs
    sub_id        = all_sub_id(s);
    sub_folder    = fullfile(path.BIDSdir,sprintf('sub-%02d',sub_id)); 
    run_files     = spm_select('FPList', fullfile(sub_folder, 'func'),'$*.nii.gz');

    % get P.mat for baseline, risetime and VAS values
    P                  = load(fullfile(sub_folder, 'beh/P.mat'));
    rise_speed         = P.P.pain.rS;
    baseline           = P.P.pain.bT;
    s_plateau          = P.P.pain.s_stim_plat;
    temperatures       = P.P.pain.VAS(:,2);
    diffs              = temperatures - baseline;
    rise_times         = diffs/rise_speed; % add this to onsets (col vector with risetimes for the three temps)



    % determine nr of runs per sub
    n_runs = height(run_files);

    % make one events.tsv file, named after BIDS conventions, and place in
    % func folder with the zipped nifits
    % sort by the timestamp
    for r = 1:n_runs
        fprintf(sprintf('sub %d, run %d \n', sub_id, r));

        % get the three different files (events, trigger, beh) for every run
        % (just in case - the scanner pulses are in "_pulses.tsv" file)
        % adapt this here to make it flexible for multiple runs
        if exist(spm_select('FPList', fullfile(sub_folder, 'beh/'), sprintf('run-%02d_beh_v[1-9].tsv$',r)))
            f_trialtype = spm_select('FPList', fullfile(sub_folder, 'beh/'), sprintf('run-%02d_beh_v[1-9].tsv$',r));
        else
            f_trialtype = spm_select('FPList', fullfile(sub_folder, 'beh/'), sprintf('run-%02d_beh.tsv$',r));
        end

        f_events    = spm_select('FPList', fullfile(sub_folder, 'beh/'), sprintf('run-%02d_events.tsv$',r));
        f_bpress    = spm_select('FPList', fullfile(sub_folder, 'beh/'), sprintf('run-%02d_trigger.tsv$',r));

        trialtype = readtable(f_trialtype, 'FileType', 'delimitedtext'); 
        events    = readtable(f_events, 'FileType', 'delimitedtext');
        bpress    = readtable(f_bpress, 'FileType', 'delimitedtext');

        if isempty(trialtype)
            fprintf(sprintf('no trialtype information for sub %d \n trying to load alternative tsv file \n', sub_id));
            
            % if the same runnumber is started a second time it can happen
            % that they have a second "empty" tsv file
            try
               f_trialtype = spm_select('FPList', fullfile(sub_folder, 'beh/'), sprintf('run-%02d_beh.tsv$',r));
               trialtype = readtable(f_trialtype, 'FileType', 'delimitedtext'); 
            catch
                fprintf(sprintf('no alternative tsv file for sub %d\n', sub_id));
            end
        end

        % discard test trials in trialtype and events
        trialtype    = trialtype(trialtype.test_trial == 0,:);
        ix_startmain = find(sign(diff(events.time))<0);
        events       = events(ix_startmain(end)+1:end,:);
       
        % write as tsv file
        % onset  duration  trial_type
        
        % pain on
        stim_on_idx  = find(strcmp('stim_on', events.event_info));
        %stim_off_idx = find(strcmp('fixcross_2', events.event_info));

        t_stim_on  = events.time(stim_on_idx);
        %t_stim_off = events.time(stim_off_idx); 
        dur_stim   = repelem(s_plateau,length(t_stim_on));

        intensity = trialtype.intensity;
        intensity(intensity == 30) = 1;
        intensity(intensity == 50) = 2;
        intensity(intensity == 70) = 3;

        pain_table = [t_stim_on,dur_stim',intensity];

        % add the risetime to the pain onset info
        pain_table(pain_table(:,3)==1,1) = pain_table(pain_table(:,3)==1,1) + rise_times(1); 
        pain_table(pain_table(:,3)==2,1) = pain_table(pain_table(:,3)==2,1) + rise_times(2);
        pain_table(pain_table(:,3)==3,1) = pain_table(pain_table(:,3)==3,1) + rise_times(3); 

        % expectation
        t_expect     = events.time(find(strcmp('expect_on', events.event_info)));
        dur_expect   = t_stim_on - t_expect;
        expect_table = [t_expect,dur_expect,repelem(4,length(t_expect))']; 


        % button presses
        try 
            t_bp     = bpress.time;
            bp_table = [t_bp, zeros(length(t_bp), 1), repelem(9, length(t_bp))' ];
        catch
            warning('no button presses in sub %d run %d',sub_id,r);
        end


        % put everything together and sort 
        all_events = [pain_table;expect_table;bp_table];
        all_events = sortrows(all_events);

        % write it to BIDS conform tsv file with correct naming
        condition  = trialtype.condition{1};
        fname_BIDS = sprintf('sub-%02d_task-%s_run-%02d_events.tsv',sub_id,condition,r);
        fname_BIDS = fullfile(sub_folder,'func',fname_BIDS);

        if ~exist("fname_BIDS",'file')
            fid = fopen(fname_BIDS,'w');
            fwrite(fid, sprintf('onset\tduration\ttrial_type\n'));
    
            for i = 1:height(all_events)
                fwrite(fid,sprintf('%f\t%f\t%f\n', all_events(i,1),all_events(i,2),all_events(i,3)));
            end
    
            fclose(fid);
        else
            warning(sprintf('event file already exists for sub %d - run %d',sub_id,r));
        end


    end

end


end