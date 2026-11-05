function SaveCustomDataAndParamsCSV()
%{
Function to write trial custom data from DiscriminationConfidence
into a tab separated value file (.tsv)

Author: Greg Knoll
Date: October 13, 2022
%}

global BpodSystem

nTrials = BpodSystem.Data.nTrials;

TrialData = BpodSystem.Data.Custom.TrialData;

%{
---------------------------------------------------------------------------
preprocess the data
- remove last entry in arrays that are nTrials+1 long (from the incomplete
  last trial)
- split any nTrials x 2 array into two nTrials x 1 arrays

then save in the table as a column (requires using .', which inverts the
dimensions)
---------------------------------------------------------------------------
%}
DataTable = table();

% ---------------------Sample and Choice variables-------------------- %
DataTable.EarlyWithdrawal = TrialData.EarlyWithdrawal(1:nTrials).';
DataTable.SampleLength = TrialData.SampleLength(1:nTrials).';

DataTable.ChoiceLeft = TrialData.ChoiceLeft(1:nTrials).';
DataTable.MoveTime = TrialData.MoveTime(1:nTrials).';
DataTable.ResolutionTime = TrialData.ResolutionTime(1:nTrials).';
DataTable.FixBroke = TrialData.FixBroke(1:nTrials).';
DataTable.FixDur = TrialData.FixDur(1:nTrials).';

DataTable.Feedback = TrialData.Feedback(1:nTrials).';
DataTable.FeedbackTime = TrialData.FeedbackTime(1:nTrials).';

DataTable.CatchTrial = TrialData.CatchTrial(1:nTrials).';


% -----------------------Reward variables------------------------------ %
DataTable.LeftRewarded = TrialData.LeftRewarded(1:nTrials).';
DataTable.ChoiceCorrect = TrialData.ChoiceCorrect(1:nTrials).';
DataTable.Rewarded = TrialData.Rewarded(1:nTrials).';

DataTable.RewardMagnitudeL = TrialData.RewardMagnitudeL(1:nTrials).';
DataTable.RewardMagnitudeR = TrialData.RewardMagnitudeR(1:nTrials).';


% -------------------------Stim variables------------------------------ %
DataTable.DecisionVariable = TrialData.DecisionVariable(1:nTrials).';
DataTable.LaserTrial = TrialData.LaserTrial(1:nTrials).';
DataTable.AuditoryTrial = TrialData.AuditoryTrial(1:nTrials).';
DataTable.ClickTask = TrialData.ClickTask(1:nTrials).';


% ----------------------------Params----------------------------------- %
ParamNames = BpodSystem.GUIData.ParameterGUI.ParamNames;
ParamVals = BpodSystem.Data.TrialSettings.';
ParamsTable = cell2table(ParamVals, "VariableNames", ParamNames);


% --------------------------------------------------------------------- %
% Combine the data and params tables and save to .csv
% --------------------------------------------------------------------- %
FullTable = [DataTable ParamsTable];

[filepath, SessionName, ext] = fileparts(BpodSystem.Path.CurrentDataFile);

SessionFolder = strcat('\\ottlabfs.bccn-berlin.pri\ottlab\data\', BpodSystem.Data.Info.Subject,...
                  '\bpod_session\', SessionName(end-14:end));
if ~isfolder(SessionFolder)
    disp('bpod_session is not a directory. A folder is created.')
    mkdir(SessionFolder);
end

CSVName = "_trial_custom_data_and_params.csv";
FileName = strcat(SessionFolder, '\', SessionName, CSVName);

writetable(FullTable, FileName, "Delimiter", "\t")

end  % SaveCustomDataAndParamsCSV()
