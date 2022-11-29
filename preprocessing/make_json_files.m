data_folder =  '/projects/crunchie/habermann/data/scanner/rawdata/';

% make three diff json files for bold data of the three conditions
% of the main experiment

% C: controllable
% P: predictable
% U: unpredictable

task_names = {'controllable','predictable', 'uncontrollable'};

for t_type = 1:3
    
    % json filename
    fname         = fullfile(data_folder,sprintf(task_names{t_type}));

    % json bold
    bold_json                                = struct();
    bold_json.TaskName                       = ;
    bold_json.RepetitionTime                 = ;
    bold_json.EchoTime                       = ;
    bold_json.FlipAngle                      = ;
    bold_json.SliceTiming                    = ;
    bold_json.MultibandAccelerationFactor    = ;
    bold_json.ParallelReductionFactorInPlane = ;
    bold_json.PhaseEncodingDirection         = ;
    bold_json.InstitutionName                = ;
    bold_json.InstitutionAddress             = ;
    bold_json.DeviceSerialNumber             = ;
    bold_json.B0FieldSource                  = ;

    bold_json = jsoncode(bold_json,PrettyPrint=true);

    % print the file just as usual with fprintf etc. for the three diff 
    % trial types - do I need one for the T1 weighted image???
end
