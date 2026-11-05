function Sound = GetFreqStimulus(iTrial, SoundLevel)

global TaskParameters
global BpodSystem

if nargin < 2
    SoundLevel = 0.8;
end

StimulusSettings=struct();
StimulusSettings.SamplingRate = TaskParameters.GUI.Aud_SamplingRate; % Sound card sampling rate;
StimulusSettings.ramp = TaskParameters.GUI.Aud_Ramp;
StimulusSettings.nFreq = TaskParameters.GUI.Aud_nFreq; % Number of different frequencies to sample from
StimulusSettings.ToneOverlap = TaskParameters.GUI.Aud_ToneOverlap;
StimulusSettings.ToneDuration = TaskParameters.GUI.Aud_ToneDuration;
StimulusSettings.Noevidence=TaskParameters.GUI.Aud_NoEvidence;
StimulusSettings.minFreq = TaskParameters.GUI.Aud_minFreq ;
StimulusSettings.maxFreq = TaskParameters.GUI.Aud_maxFreq ;
StimulusSettings.UseMiddleOctave = TaskParameters.GUI.Aud_UseMiddleOctave;
StimulusSettings.Volume = TaskParameters.GUI.Aud_Volume;
StimulusSettings.nTones = floor((TaskParameters.GUI.AuditoryStimulusTime-StimulusSettings.ToneDuration*StimulusSettings.ToneOverlap)/(StimulusSettings.ToneDuration*(1-StimulusSettings.ToneOverlap))); %number of tones
       
if iTrial > TaskParameters.GUI.StartEasyTrials
    newFracHigh = randsample(TaskParameters.GUI.Aud_Levels.AudFracHigh,1,1,TaskParameters.GUI.Aud_Levels.AudPFrac)';
    %include Fifty50 Trials
    if rand(1,1) < TaskParameters.GUI.Percent50Fifty
        newFracHigh = 50;
    end
else
    EasyProb = zeros(numel(TaskParameters.GUI.Aud_Levels.AudPFrac),1);
    EasyProb(1) = 0.5;
    EasyProb(end)= 0.5;
    newFracHigh = randsample(TaskParameters.GUI.Aud_Levels.AudFracHigh,1,1,EasyProb)';
end
      
[Sound, Cloud, ~] = GenerateToneCloudDual(newFracHigh/100, StimulusSettings);
Sound = Sound * SoundLevel;

newFracHigh(~newAuditoryTrial) = nan(sum(~newAuditoryTrial),1);

BpodSystem.Data.Custom.TrialData.AudFracHigh(iTrial) = newFracHigh;
BpodSystem.Data.Custom.TrialData.AudCloud{iTrial} = Cloud;
BpodSystem.Data.Custom.TrialData.AudSound{iTrial} = Sound;

if newFracHigh > 50
    BpodSystem.Data.Custom.TrialData.LeftRewarded(iTrial) = True;
elseif newFracHigh < 50
    BpodSystem.Data.Custom.TrialData.LeftRewarded(iTrial) = False;
elseif newFracHigh == 50
    BpodSystem.Data.Custom.TrialData.LeftRewarded(iTrial) = rand<0.5;
end

BpodSystem.Data.Custom.TrialData.DV(iTrial) = (2*BpodSystem.Data.Custom.TrialData.AudFracHigh(iTrial)-100)/100;

end