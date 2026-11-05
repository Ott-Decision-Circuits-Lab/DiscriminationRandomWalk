function InitiatePsychtoolbox(iTrial)
global BpodSystem
if BpodSystem.Data.Custom.TrialData.AuditoryTrial(iTrial) && ~BpodSystem.Data.Custom.TrialData.ClickTask(iTrial) && ~BpodSystem.Data.Custom.SessionMeta.PsychtoolboxStartup
    PsychToolboxSoundServer('init');
    BpodSystem.Data.Custom.SessionMeta.PsychtoolboxStartup = true;
end