function UpdateCustomDataFields(iTrial)
%{ 
Writes the trial values for the custom data initialized in
InitializeCustomDataFields()
%}

global BpodSystem
global TaskParameters

% ---------------------------------------------------------------------- %
% data structure references
% ---------------------------------------------------------------------- %
TDTemp = BpodSystem.Data.Custom.TrialData; % temporary container
GUI = TaskParameters.GUI;

RawData = BpodSystem.Data.RawData;
RawEvents = BpodSystem.Data.RawEvents;
TrialStates = RawEvents.Trial{end}.States;
% ---------------------------------------------------------------------- %


% ---------------------------------------------------------------------- %
% Check each state which would overwrite a custom field 
% ---------------------------------------------------------------------- %
statesThisTrial = RawData.OriginalStateNamesByNumber{iTrial}(RawData.OriginalStateData{iTrial});

if any(strcmp('stay_Cin',statesThisTrial))
    TDTemp.FixDur(iTrial) = diff(TrialStates.stay_Cin);
end

if any(strcmp('stimulus_delivery_min',statesThisTrial))
    if any(strcmp('stimulus_delivery',statesThisTrial))
        TDTemp.SampleLength(iTrial) = TrialStates.stimulus_delivery(1,2) - TrialStates.stimulus_delivery_min(1,1);
    else
        TDTemp.SampleLength(iTrial) = diff(TrialStates.stimulus_delivery_min);
    end
end

if any(strcmp('wait_Sin',statesThisTrial))
    TDTemp.MoveTime(end) = diff(TrialStates.wait_Sin);
end

if any(strcmp('rewarded_Lin',statesThisTrial))
    TDTemp.ChoiceLeft(iTrial) = 1;
    TDTemp.ChoiceCorrect(iTrial) = 1;
    FeedbackPortTimes = TrialStates.rewarded_Lin;
    TDTemp.FeedbackTime(iTrial) = FeedbackPortTimes(end,end)-FeedbackPortTimes(1,1);
    TDTemp.ResolutionTime(iTrial)  = FeedbackPortTimes(end,end);
elseif any(strcmp('rewarded_Rin',statesThisTrial))
    TDTemp.ChoiceLeft(iTrial) = 0;
    TDTemp.ChoiceCorrect(iTrial) = 1;
    FeedbackPortTimes = TrialStates.rewarded_Rin;
    TDTemp.FeedbackTime(iTrial) = FeedbackPortTimes(end,end)-FeedbackPortTimes(1,1);
    TDTemp.ResolutionTime(iTrial)  = FeedbackPortTimes(end,end);
elseif any(strcmp('unrewarded_Lin',statesThisTrial))
    TDTemp.ChoiceLeft(iTrial) = 1;
    TDTemp.ChoiceCorrect(iTrial) = 0;
    FeedbackPortTimes = TrialStates.unrewarded_Lin;
    TDTemp.FeedbackTime(iTrial) = FeedbackPortTimes(end,end)-FeedbackPortTimes(1,1);
    TDTemp.ResolutionTime(iTrial)  = FeedbackPortTimes(end,end);
elseif any(strcmp('unrewarded_Rin',statesThisTrial))
    TDTemp.ChoiceLeft(iTrial) = 0;
    TDTemp.ChoiceCorrect(iTrial) = 0;
    FeedbackPortTimes = TrialStates.unrewarded_Rin;
    TDTemp.FeedbackTime(iTrial) = FeedbackPortTimes(end,end)-FeedbackPortTimes(1,1);
    TDTemp.ResolutionTime(iTrial)  = FeedbackPortTimes(end,end);
elseif any(strcmp('broke_fixation',statesThisTrial))
    TDTemp.FixBroke(iTrial) = true;
elseif any(strcmp('early_withdrawal',statesThisTrial))
    TDTemp.EarlyWithdrawal(iTrial) = true;
end

if any(strcmp('missed_choice',statesThisTrial))
    TDTemp.Feedback(iTrial) = false;
end

if any(strcmp('skipped_feedback',statesThisTrial))
    TDTemp.Feedback(iTrial) = false;
end

if any(strncmp('water_',statesThisTrial,6))
    TDTemp.Rewarded(iTrial) = true;
end
% ---------------------------------------------------------------------- %


% ---------------------------------------------------------------------- %
% Updating Delays
% ---------------------------------------------------------------------- %

% stimulus delay
if GUI.StimDelayAutoincrement
    if BpodSystem.Data.Custom.FixBroke(iTrial)
        GUI.StimDelay = max(GUI.StimDelayMin,...
            min(GUI.StimDelayMax,TDTemp.StimDelay(iTrial)-GUI.StimDelayDecr));
    else
        GUI.StimDelay = min(GUI.StimDelayMax,...
            max(GUI.StimDelayMin,TDTemp.StimDelay(iTrial)+GUI.StimDelayIncr));
    end
else
    if ~TDTemp.FixBroke(iTrial)
        GUI.StimDelay = random('unif',GUI.StimDelayMin,GUI.StimDelayMax);
    else
        GUI.StimDelay = TDTemp.StimDelay(iTrial);
    end
end

% min sampling time auditory
if GUI.MinSampleAudAutoincrement
    History = 50;
    Crit = 0.8;
    if sum(TDTemp.AuditoryTrial)<10
        ConsiderTrials = iTrial;
    else
        idxStart = find(cumsum(TDTemp.AuditoryTrial(iTrial:-1:1))>=History,1,'first');
        if isempty(idxStart)
            ConsiderTrials = 1:iTrial;
        else
            ConsiderTrials = iTrial-idxStart+1:iTrial;
        end
    end
    ConsiderTrials = ConsiderTrials((~isnan(TDTemp.ChoiceLeft(ConsiderTrials))...
        |TDTemp.EarlyWithdrawal(ConsiderTrials))&TDTemp.AuditoryTrial(ConsiderTrials)); %choice + early withdrawal + auditory trials
    if ~isempty(ConsiderTrials) && TDTemp.AuditoryTrial(iTrial)
        if mean(TDTemp.SampleLength(ConsiderTrials)>GUI.MinSampleAud) > Crit
            if ~TDTemp.EarlyWithdrawal(iTrial)
                GUI.MinSampleAud = min(GUI.MinSampleAudMax,...
                    max(GUI.MinSampleAudMin,TDTemp.MinSampleAud(iTrial) + GUI.MinSampleAudIncr));
            end
        elseif mean(TDTemp.SampleLength(ConsiderTrials)>GUI.MinSampleAud) < Crit/2
            if TDTemp.EarlyWithdrawal(iTrial)
                GUI.MinSampleAud = max(GUI.MinSampleAudMin,...
                    min(GUI.MinSampleAudMax,TDTemp.MinSampleAud(iTrial) - GUI.MinSampleAudDecr));
            end
        else
            GUI.MinSampleAud = max(GUI.MinSampleAudMin,...
                min(GUI.MinSampleAudMax,TDTemp.MinSampleAud(iTrial)));
        end
    else
        GUI.MinSampleAud = max(GUI.MinSampleAudMin,...
            min(GUI.MinSampleAudMax,TDTemp.MinSampleAud(iTrial)));
    end
else
    GUI.MinSampleAud = GUI.MinSampleAudMin;
end  % if AutoIncrement

%feedback delay
switch TaskParameters.GUIMeta.FeedbackDelaySelection.String{GUI.FeedbackDelaySelection}
    case 'AutoIncr'
        if ~TDTemp.Feedback(iTrial)
            GUI.FeedbackDelay = max(GUI.FeedbackDelayMin,...
                min(GUI.FeedbackDelayMax,TDTemp.FeedbackDelay(iTrial)-GUI.FeedbackDelayDecr));
        else
            GUI.FeedbackDelay = min(GUI.FeedbackDelayMax,...
                max(GUI.FeedbackDelayMin,TDTemp.FeedbackDelay(iTrial)+GUI.FeedbackDelayIncr));
        end
    case 'TruncExp'
        GUI.FeedbackDelay = TruncatedExponential(GUI.FeedbackDelayMin,...
            GUI.FeedbackDelayMax,GUI.FeedbackDelayTau);
    case 'Fix'
        %     ATTEMPT TO GRAY OUT FIELDS
        %     if ~strcmp('edit',TaskParameters.GUIMeta.FeedbackDelay.Style)
        %         TaskParameters.GUIMeta.FeedbackDelay.Style = 'edit';
        %     end
        GUI.FeedbackDelay = GUI.FeedbackDelayMax;
end % switch

% Write temporary data containers to Custom Data
BpodSystem.Data.Custom.TrialData = TDTemp;
TaskParameters.GUI = GUI;

end % UpdateCustomDataFields()