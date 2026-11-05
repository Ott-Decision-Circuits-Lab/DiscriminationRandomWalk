function InitiateOlfactometer(iTrial)
global BpodSystem
global TaskParameters
if ~BpodSystem.Data.Custom.TrialData.AuditoryTrial(iTrial) && ~BpodSystem.Data.Custom.SessionMeta.OlfactometerStartup
    if ~BpodSystem.EmulatorMode
        BpodSystem.Data.Custom.SessionMeta.OlfIp = FindOlfactometer;
        if isempty(BpodSystem.Data.Custom.SessionMeta.OlfIp)
            error('Bpod:Olf2AFC:OlfComFail','Failed to connect to olfactometer')
        end
        OdorA_flow = BpodSystem.Data.Custom.TrialDataOdorFracA(iTrial);
        OdorB_flow = 100 - OdorA_flow;
        SetBankFlowRate(BpodSystem.Data.Custom.SessionMeta.OlfIp, TaskParameters.GUI.OdorA_bank, OdorA_flow)
        SetBankFlowRate(BpodSystem.Data.Custom.SessionMeta.OlfIp, TaskParameters.GUI.OdorB_bank, OdorB_flow)
        clear Odor* flow*
    else
        BpodSystem.Data.Custom.SessionMeta.OlfIp = '198.162.0.0';
    end
    BpodSystem.Data.Custom.SessionMeta.OlfactometerStartup = true;
end