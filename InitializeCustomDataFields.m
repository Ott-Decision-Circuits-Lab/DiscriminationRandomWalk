function InitializeCustomDataFields(iTrial)
%{ 
Initializing data (trial type) vectors and first values
%}

global BpodSystem
global TaskParameters

if iTrial == 1
    BpodSystem.Data.Custom.TrialData = [];
    % Initialize random walk state
    BpodSystem.Data.Custom.CurrentLambda = TaskParameters.GUI.RandomWalkInit;
end

TDTemp = BpodSystem.Data.Custom.TrialData; % temporary container

% Ensure TrueLambda and AudBias exist for this trial before use
if ~isfield(TDTemp, 'TrueLambda')
    TDTemp.TrueLambda = NaN(iTrial,1);
end
if ~isfield(TDTemp, 'AudBias')
    TDTemp.AudBias = NaN(iTrial,1);
end

% Resize arrays to fit current trial index
if length(TDTemp.TrueLambda) < iTrial
    TDTemp.TrueLambda(iTrial) = NaN;
    TDTemp.AudBias(iTrial) = NaN;
end

TDTemp.TrialNumber(iTrial) = iTrial;


% ---------------------Sample and Choice variables-------------------- %
TDTemp.EarlyWithdrawal(iTrial) = false;
TDTemp.StimDelay(iTrial) = TaskParameters.GUI.StimDelay;
TDTemp.SampleLength(iTrial) = NaN;  %previously ST

TDTemp.ChoiceLeft(iTrial) = NaN;
TDTemp.MoveTime(iTrial) = NaN; %previously MT
TDTemp.ResolutionTime(iTrial) = NaN;
TDTemp.FixBroke(iTrial) = false;
TDTemp.FixDur(iTrial) = NaN;

TDTemp.Feedback(iTrial) = true;
TDTemp.FeedbackTime(iTrial) = NaN;
TDTemp.FeedbackDelay(iTrial) = TaskParameters.GUI.FeedbackDelay;

% determine if catch trial
if iTrial > TaskParameters.GUI.StartEasyTrials
    TDTemp.CatchTrial(iTrial) = rand(1,1)*100 < TaskParameters.GUI.PercentCatch;
else
    TDTemp.CatchTrial(iTrial) = false;
end

% ---------------------------------------------------------------------- %


% -----------------------Reward variables------------------------------ %
TDTemp.LeftRewarded(iTrial) = rand<0.5;
TDTemp.ChoiceCorrect(iTrial) = NaN;
TDTemp.Rewarded(iTrial) = false;
% ---------------------------------------------------------------------- %


% -----------------------Random Walk (Ornstein-Uhlenbeck)---------------- %
% Update the logit-space random walk
if iTrial > 1
    % Get previous lambda
    prevLambda = BpodSystem.Data.Custom.CurrentLambda;
    
    % Optional auto-reset on miss
    if TaskParameters.GUI.RandomWalkAutoReset && ~TDTemp.Rewarded(iTrial-1)
        prevLambda = 0;
    end
    
    % OU update: lambda_t = lambda_{t-1} - kappa*lambda_{t-1} + noise
    newLambda = prevLambda - (TaskParameters.GUI.RandomWalkKappa * prevLambda) + ...
                randn(1) * TaskParameters.GUI.RandomWalkSigma;
    
    % Apply bounds (hard clamp)
    bound = TaskParameters.GUI.RandomWalkBounds;
    newLambda = min(max(newLambda, -bound), bound);
    
    BpodSystem.Data.Custom.CurrentLambda = newLambda;
else
    % First trial: use initial value
    BpodSystem.Data.Custom.CurrentLambda = TaskParameters.GUI.RandomWalkInit;
end

% Convert logit to probability
currentLambda = BpodSystem.Data.Custom.CurrentLambda;
currentAudBias = 1 / (1 + exp(-currentLambda));

% Override for early trials (force 0.5)
if iTrial <= TaskParameters.GUI.StartEasyTrials
    currentAudBias = 0.5;
    BpodSystem.Data.Custom.CurrentLambda = 0;
end

% Store the true values
TDTemp.TrueLambda(iTrial) = currentLambda;
TDTemp.AudBias(iTrial) = currentAudBias;

TDTemp.RewardMagnitudeL(iTrial) = TaskParameters.GUI.RewardAmount;
TDTemp.RewardMagnitudeR(iTrial) = TaskParameters.GUI.RewardAmount;


% -----------------------Stimulus-specific----------------------------- %
TDTemp.DecisionVariable(iTrial) = NaN;  % e.g., relative click rate

% -----Odor----- %
TDTemp.OdorFracA(iTrial) = NaN;
TDTemp.OdorID(iTrial) = NaN;
TDTemp.OdorPair(iTrial) = NaN;

% -----Laser----- %
if iTrial > TaskParameters.GUI.StartEasyTrials
    TDTemp.LaserTrial(iTrial) = rand(1,1) < TaskParameters.GUI.LaserTrials;
else
    TDTemp.LaserTrial(iTrial) = false;
end

TDTemp.LaserTrialTrainStart(iTrial) = NaN;
if TDTemp.LaserTrial(iTrial)
    if TaskParameters.GUI.LaserTrainRandStart
        TDTemp.LaserTrialTrainStart(iTrial) = rand(1,1)*(TaskParameters.GUI.LaserTrainStartMax_s-TaskParameters.GUI.LaserTrainStartMin_s) + TaskParameters.GUI.LaserTrainStartMin_s;
        TDTemp.LaserTrialTrainStart(iTrial) = round(TDTemp.LaserTrialTrainStart(iTrial)*10000)/10000;
    else
        TDTemp.LaserTrialTrainStart(iTrial) = TaskParameters.GUI.LaserTrainStartMin_s;
    end
end

% -----Auditory----- %
TDTemp.AuditoryTrial(iTrial) = rand(1,1) < TaskParameters.GUI.PercentAuditory;
TDTemp.ClickTask(iTrial) = TaskParameters.GUI.AuditoryStimulusType == 1;
TDTemp.AuditoryOmega(iTrial) = NaN;

TDTemp.LeftClickRate(iTrial) = NaN;
TDTemp.RightClickRate(iTrial) = NaN;
TDTemp.LeftClickTrain{iTrial} = [];
TDTemp.RightClickTrain{iTrial} = [];

TDTemp.AudFracHigh(iTrial) = NaN;
TDTemp.AudCloud{iTrial} = [];
TDTemp.AudSound{iTrial} = [];
TDTemp.MinSampleAud(iTrial) = TaskParameters.GUI.MinSampleAud;

% Write temporary data container to Custom Data
BpodSystem.Data.Custom.TrialData = TDTemp;

end %InitializeCustomDataFields