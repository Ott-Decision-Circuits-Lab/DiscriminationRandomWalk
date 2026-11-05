function ParameterMatrix=configurePulsePalLaser_CustomTrain(Params)
%generates pulse train for laser stimulation with pulsepal
%ramp is only added at end
%ramp will be INCLUDED in overall length
%for continous laser stimulation
%in Dual2AFC protocol, starts from default PulsePalMatrix

%

global BpodSystem

if ~isfield(Params,'Length'), Params.Length=2; end
if ~isfield(Params,'Ramp'), Params.Ramp=1; end
if ~isfield(Params,'Amp'), Params.Amp=5; end
if ~isfield(Params,'LaserOutChan'), Params.LaserOutChan=4; end
if ~isfield(Params,'TriggerOutChan'), Params.TriggerOutChan=3; end
if ~isfield(Params,'TriggerInChan'), Params.TriggerInChan=2; end
if ~isfield(Params,'CustomPulseTrainID'), Params.CustomPulseTrainID=1; end
if ~isfield(Params,'DelayStart'), Params.DelayStart=0; end

singlepulse = 0.005; %5ms resolution

% load PulsePalParamStimulus
% load('PulsePalParamStimulus.mat');
ParameterMatrix = BpodSystem.Data.Custom.PulsePalParamStimulus;

%% TriggerOutChan --> for recording system. pulse at train onset.
%single pulse duration
ParameterMatrix(5,Params.TriggerOutChan+1)={0.1};
%Inter-pulse interval
ParameterMatrix(8,Params.TriggerOutChan+1)={10};
%stimulus train delay
ParameterMatrix(12,Params.TriggerOutChan+1)={Params.DelayStart};
%Burst interval
ParameterMatrix(10,Params.TriggerOutChan+1)={0};%burst interval
%stimulus burst and train duration
ParameterMatrix(9,Params.TriggerOutChan+1)={0.1};%burst duration
ParameterMatrix(11,Params.TriggerOutChan+1)={0.1};%train duration
%trigger in chan
ParameterMatrix(13,Params.TriggerOutChan+1)={0};
ParameterMatrix(14,Params.TriggerOutChan+1)={0};
ParameterMatrix(13 + Params.TriggerInChan - 1,Params.TriggerOutChan+1)={1};%trigger listen
%custom pulse train
ParameterMatrix(15,Params.TriggerOutChan+1)={0};%custom train
%loop
ParameterMatrix(17,Params.TriggerOutChan+1)={0};

%% LaserOutChan --> for laser
%single pulse duration
ParameterMatrix(5,Params.LaserOutChan+1)= {singlepulse};
%Inter-pulse interval
ParameterMatrix(8,Params.LaserOutChan+1)={0};
%stimulus train delay
ParameterMatrix(12,Params.LaserOutChan+1)={Params.DelayStart};
%Burst interval
ParameterMatrix(10,Params.LaserOutChan+1)={0};%burst interval
%stimulus burst and train duration (long)
ParameterMatrix(9,Params.LaserOutChan+1)={10};%burst duration
ParameterMatrix(11,Params.LaserOutChan+1)={0};%train duration
%trigger in chan
ParameterMatrix(13,Params.LaserOutChan+1)={0};
ParameterMatrix(14,Params.LaserOutChan+1)={0};
ParameterMatrix(13 + Params.TriggerInChan - 1,Params.LaserOutChan+1)={1};%trigger listen
%custom pulse train
ParameterMatrix(15,Params.LaserOutChan+1)={Params.CustomPulseTrainID};%custom train
%loop
ParameterMatrix(17,Params.LaserOutChan+1)={0};

%% trigger mode
% depends on how it's coded in Dual2AFC protocol!
ParameterMatrix(2,8)={2}; %0=normal, 1=toggle, 2=gated
ParameterMatrix(2,9)={2}; %0=normal, 1=toggle, 2=gated

%% build custom pulse train
train = 0:singlepulse:(Params.Length-singlepulse);
volts = Params.Amp.*ones(size(train));
lramp = ceil(Params.Ramp/singlepulse);
iramp = (length(train)-lramp+1):length(train);
aramp = linspace(0,Params.Amp,lramp);
volts(iramp)=aramp(end:-1:1);

ProgramPulsePal(ParameterMatrix);
SendCustomPulseTrain(Params.CustomPulseTrainID,train,volts);