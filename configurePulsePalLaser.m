function ParameterMatrix = configurePulsePalLaser(PulsePalMatrix)
%configure channel 3+4 of PulsePal configuration Matrix to play laser
%stimulus according to settings

global TaskParameters
global BpodSystem

OutputChannels = [3,4];

ParameterMatrix = PulsePalMatrix;
StimFreq = TaskParameters.GUI.LaserStimFreq;

if StimFreq == 0 %special case: continuous stimulation
    %Inter-pulse interval
    ParameterMatrix(8,OutputChannels+1)={0};
    %single pulse duration
    ParameterMatrix(5,OutputChannels+1)={10};
else
    %Inter-pulse interval
    ParameterMatrix(8,OutputChannels+1)={1./StimFreq - TaskParameters.GUI.LaserPulseDuration_ms/1000};
    %single pulse duration
    ParameterMatrix(5,OutputChannels+1)={TaskParameters.GUI.LaserPulseDuration_ms/1000};
end

%stimulus burst and train duration
if TaskParameters.GUI.LaserTrainDuration_ms>0
    ParameterMatrix(9,OutputChannels+1)={TaskParameters.GUI.LaserTrainDuration_ms/1000};%burst duration
    ParameterMatrix(11,OutputChannels+1)={TaskParameters.GUI.LaserTrainDuration_ms/1000};%train duration
    if StimFreq == 0
        ParameterMatrix(5,OutputChannels+1)={TaskParameters.GUI.LaserTrainDuration_ms/1000};
    end
else
    %if==0 --> ongoing (long)
    ParameterMatrix(9,OutputChannels+1)={10};%burst duration
    ParameterMatrix(11,OutputChannels+1)={10};%train duration
end

%stimulus train delay
if TaskParameters.GUI.LaserTrainRandStart
    ParameterMatrix(12,OutputChannels+1)={BpodSystem.Data.Custom.LaserTrialTrainStart(end)};
else
    ParameterMatrix(12,OutputChannels+1)={0};
end

%Burst interval
ParameterMatrix(10,OutputChannels+1)={0};%burst interval

%amplitude
ParameterMatrix(3,OutputChannels+1) = {TaskParameters.GUI.LaserAmp};