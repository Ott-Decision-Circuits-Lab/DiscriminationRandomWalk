function LoadTrialDependentWaveform(Player, iTrial, SoundLevel, ClickLength)

global BpodSystem
global TaskParameters

if ~BpodSystem.EmulatorMode
    if nargin <3
        SoundLevel = 1;
    end
    
    if nargin <4
        ClickLength = 2; % in sampling frame
    end

    % load auditory stimuli
    fs = Player.SamplingRate;
    
    if TaskParameters.GUI.AuditoryStimulusType == 1  % Click task
        % Get current random walk bias from TrialData
        if isfield(BpodSystem.Data.Custom, 'TrialData') && ...
           isfield(BpodSystem.Data.Custom.TrialData, 'AudBias') && ...
           iTrial <= length(BpodSystem.Data.Custom.TrialData.AudBias)
            CurrentAudBias = BpodSystem.Data.Custom.TrialData.AudBias(iTrial);
        else
            CurrentAudBias = 0.5;  % Fallback to unbiased
        end

        % Generate click trains with random walk bias
        TotalClicks = TaskParameters.GUI.SumRates;
        [LeftClickTrain, RightClickTrain] = GetClickStimulus(iTrial, TaskParameters.GUI.AuditoryStimulusTime, fs, ClickLength, SoundLevel, 'biasedUniform', CurrentAudBias, TotalClicks);

        % Load waveforms
        Player.loadWaveform(3, LeftClickTrain);   % Left channel
        Player.loadWaveform(4, RightClickTrain);  % Right channel
    elseif TaskParameters.GUI.AuditoryStimulusType == 2 % freq task
        warning('Error: Frequency stimulus has not been implemented.');
    end
end

end %LoadTrialDependentWaveform()