function DrawFutureTrials(iTrial)

%create future trials
if iTrial > numel(BpodSystem.Data.Custom.DV) - 5
    
%     lastidx = numel(BpodSystem.Data.Custom.DV);
%     newAuditoryTrial = rand(1,5) < TaskParameters.GUI.PercentAuditory;
%     BpodSystem.Data.Custom.AuditoryTrial = [BpodSystem.Data.Custom.AuditoryTrial,newAuditoryTrial];
%     if TaskParameters.GUI.AuditoryStimulusType == 1 %click stimuli
%         BpodSystem.Data.Custom.ClickTask = [BpodSystem.Data.Custom.ClickTask ,true(1,5)];
%     elseif TaskParameters.GUI.AuditoryStimulusType == 2 %freq stimuli
%         BpodSystem.Data.Custom.ClickTask = [BpodSystem.Data.Custom.ClickTask ,false(1,5)];
%     end
    
    switch TaskParameters.GUIMeta.TrialSelection.String{TaskParameters.GUI.TrialSelection}
        case 'Flat'
            TaskParameters.GUI.OdorTable.OdorProb = ones(size(TaskParameters.GUI.OdorTable.OdorProb));
            TaskParameters.GUI.LeftBiasAud = 0.5;
        case 'Manual'
            
        case 'Competitive'
            ndxValid = ~isnan(BpodSystem.Data.Custom.ChoiceLeft); ndxValid = ndxValid(:);
            for iStim = reshape(TaskParameters.GUI.OdorTable.OdorFracA,1,[])
                ndxOdor = BpodSystem.Data.Custom.OdorFracA(1:iTrial) == iStim; ndxOdor = ndxOdor(:);
                if sum(ndxOdor&ndxValid) >= 8 % P(odor) = fraction of completed but unrewarded trials.
                    TaskParameters.GUI.OdorTable.OdorProb(iStim == TaskParameters.GUI.OdorTable.OdorFracA) = ...
                        sum(BpodSystem.Data.Custom.Rewarded(ndxOdor&ndxValid)==0)/sum(ndxOdor&ndxValid);
                else % If too few trials of this type, P(odor) is arbitrary non-zero.
                    TaskParameters.GUI.OdorTable.OdorProb(iStim == TaskParameters.GUI.OdorTable.OdorFracA) = 0.5;
                end
            end
            if any(TaskParameters.GUI.OdorTable.OdorProb==0)
                TaskParameters.GUI.OdorTable.OdorProb(TaskParameters.GUI.OdorTable.OdorProb==0) = ...
                    min(TaskParameters.GUI.OdorTable.OdorProb(TaskParameters.GUI.OdorTable.OdorProb>0))/2;
            end
            TaskParameters.GUI.LeftBiasAud = 0.5;%auditory not implemented
        case 'BiasCorrecting' % Favors side with fewer rewards. Contrast drawn flat & independently.
            %olfactory
            ndxRewd = BpodSystem.Data.Custom.Rewarded(1:iTrial) == 1 & ~BpodSystem.Data.Custom.AuditoryTrial(1:iTrial); ndxRewd = ndxRewd(:);
            oldOdorID = BpodSystem.Data.Custom.OdorID(1:numel(ndxRewd)); oldOdorID = oldOdorID(:);
            if any(ndxRewd) % To prevent division by zero
                TaskParameters.GUI.OdorTable.OdorProb(TaskParameters.GUI.OdorTable.OdorFracA<50) = 1-sum(oldOdorID==2 & ndxRewd)/sum(ndxRewd);
                TaskParameters.GUI.OdorTable.OdorProb(TaskParameters.GUI.OdorTable.OdorFracA>50) = 1-sum(oldOdorID==1 & ndxRewd)/sum(ndxRewd);
            else
                TaskParameters.GUI.OdorTable.OdorProb(TaskParameters.GUI.OdorTable.OdorFracA<50) = .5;
                TaskParameters.GUI.OdorTable.OdorProb(TaskParameters.GUI.OdorTable.OdorFracA>50) = .5;
            end
            %auditory
            ndxRewd = BpodSystem.Data.Custom.Rewarded(1:iTrial) == 1 & BpodSystem.Data.Custom.AuditoryTrial(1:iTrial);
            if sum(ndxRewd)>10
                TaskParameters.GUI.LeftBiasAud = sum(BpodSystem.Data.Custom.LeftRewarded(1:iTrial)==1&ndxRewd)/sum(ndxRewd);
            else
                TaskParameters.GUI.LeftBiasAud = 0.5;
            end
            if sum(ndxRewd)>10
                TaskParameters.GUI.Aud_Levels.AudPFrac(TaskParameters.GUI.Aud_Levels.AudFracHigh<50) = TaskParameters.GUI.LeftBiasAud;
                TaskParameters.GUI.Aud_Levels.AudPFrac(TaskParameters.GUI.Aud_Levels.AudFracHigh>50) = 1 - TaskParameters.GUI.LeftBiasAud;
            end
    end
    
    if sum(TaskParameters.GUI.OdorTable.OdorProb) == 0
        TaskParameters.GUI.OdorTable.OdorProb = ones(size(TaskParameters.GUI.OdorTable.OdorProb));
    end
    TaskParameters.GUI.OdorTable.OdorProb = TaskParameters.GUI.OdorTable.OdorProb/sum(TaskParameters.GUI.OdorTable.OdorProb);
    
    % make future olfactory trials
    if iTrial > TaskParameters.GUI.StartEasyTrials
        newFracA = randsample(TaskParameters.GUI.OdorTable.OdorFracA,5,1,TaskParameters.GUI.OdorTable.OdorProb);
        %include Fifty50 Trials
        NewFifty50 = rand(5,1) < TaskParameters.GUI.Percent50Fifty;
        newFracA(NewFifty50) = 50;
    else
        EasyProb = zeros(numel(TaskParameters.GUI.OdorTable.OdorProb),1);
        EasyProb(1) = 0.5; EasyProb(end)=0.5;
        newFracA = randsample(TaskParameters.GUI.OdorTable.OdorFracA,5,1,EasyProb);
    end
    
    newOdorID =  2 - double(newFracA > 50);
    if any(abs(newFracA-50)<(10*eps))
        ndxZeroInf = abs(newFracA-50)<(10*eps);
        newOdorID(ndxZeroInf) = randsample(2,sum(ndxZeroInf),1);
    end
    newOdorPair = ones(1,5)*2;
    newFracA(newAuditoryTrial) = nan(sum(newAuditoryTrial),1);
    newOdorID(newAuditoryTrial) = nan(sum(newAuditoryTrial),1);
    newOdorPair(newAuditoryTrial) = nan(1,sum(newAuditoryTrial));
    BpodSystem.Data.Custom.OdorFracA = [BpodSystem.Data.Custom.OdorFracA; newFracA];
    BpodSystem.Data.Custom.OdorID = [BpodSystem.Data.Custom.OdorID; newOdorID];
    BpodSystem.Data.Custom.OdorPair = [BpodSystem.Data.Custom.OdorPair, newOdorPair];
    
%     % make future auditory trials
%     %bias correcting
%     switch TaskParameters.GUI.AuditoryStimulusType
%         case 1 %click stimuli
%             
%             if iTrial > TaskParameters.GUI.StartEasyTrials
%                 AuditoryAlpha = TaskParameters.GUI.AuditoryAlpha;
%             else
%                 AuditoryAlpha = TaskParameters.GUI.AuditoryAlpha/4;
%             end
%             
%             BetaRatio = (1 - min(0.9,max(0.1,TaskParameters.GUI.LeftBiasAud))) / min(0.9,max(0.1,TaskParameters.GUI.LeftBiasAud)); %use a = ratio*b to yield E[X] = LeftBiasAud using Beta(a,b) pdf
%             %cut off between 0.1-0.9 to prevent extreme values (only one side) and div by zero
%             BetaA =  (2*AuditoryAlpha*BetaRatio) / (1+BetaRatio); %make a,b symmetric around AuditoryAlpha to make B symmetric
%             BetaB = (AuditoryAlpha-BetaA) + AuditoryAlpha;
%             
%             for a = 1:5
%                 if BpodSystem.Data.Custom.AuditoryTrial(lastidx+a)
%                     if rand(1,1) < TaskParameters.GUI.Percent50Fifty && iTrial > TaskParameters.GUI.StartEasyTrials
%                         BpodSystem.Data.Custom.AuditoryOmega(lastidx+a) = 0.5;
%                     else
%                         BpodSystem.Data.Custom.AuditoryOmega(lastidx+a) = betarnd(max(0,BetaA),max(0,BetaB),1,1); %prevent negative parameters
%                     end
%                     BpodSystem.Data.Custom.LeftClickRate(lastidx+a) = round(BpodSystem.Data.Custom.AuditoryOmega(lastidx+a).*TaskParameters.GUI.SumRates);
%                     BpodSystem.Data.Custom.RightClickRate(lastidx+a) = round((1-BpodSystem.Data.Custom.AuditoryOmega(lastidx+a)).*TaskParameters.GUI.SumRates);
%                     stim_ok=false;
%                     while ~stim_ok %make sure 50/50 are true 50/50 trials
%                         BpodSystem.Data.Custom.LeftClickTrain{lastidx+a} = GeneratePoissonClickTrain(BpodSystem.Data.Custom.LeftClickRate(lastidx+a), TaskParameters.GUI.AuditoryStimulusTime);
%                         BpodSystem.Data.Custom.RightClickTrain{lastidx+a} = GeneratePoissonClickTrain(BpodSystem.Data.Custom.RightClickRate(lastidx+a), TaskParameters.GUI.AuditoryStimulusTime);
%                         if BpodSystem.Data.Custom.AuditoryOmega(lastidx+a) == 0.5
%                             if length(BpodSystem.Data.Custom.LeftClickTrain{lastidx+a}) == length(BpodSystem.Data.Custom.RightClickTrain{lastidx+a})
%                                 stim_ok=true;
%                             end
%                         else
%                             stim_ok=true;
%                         end
%                     end
%                     %correct left/right click train
%                     if ~isempty(BpodSystem.Data.Custom.LeftClickTrain{lastidx+a}) && ~isempty(BpodSystem.Data.Custom.RightClickTrain{lastidx+a})
%                         BpodSystem.Data.Custom.LeftClickTrain{lastidx+a}(1) = min(BpodSystem.Data.Custom.LeftClickTrain{lastidx+a}(1),BpodSystem.Data.Custom.RightClickTrain{lastidx+a}(1));
%                         BpodSystem.Data.Custom.RightClickTrain{lastidx+a}(1) = min(BpodSystem.Data.Custom.LeftClickTrain{lastidx+a}(1),BpodSystem.Data.Custom.RightClickTrain{lastidx+a}(1));
%                     elseif  isempty(BpodSystem.Data.Custom.LeftClickTrain{lastidx+a}) && ~isempty(BpodSystem.Data.Custom.RightClickTrain{lastidx+a})
%                         BpodSystem.Data.Custom.LeftClickTrain{lastidx+a}(1) = BpodSystem.Data.Custom.RightClickTrain{lastidx+a}(1);
%                     elseif ~isempty(BpodSystem.Data.Custom.LeftClickTrain{lastidx+a}) &&  isempty(BpodSystem.Data.Custom.RightClickTrain{lastidx+a})
%                         BpodSystem.Data.Custom.RightClickTrain{lastidx+a}(1) = BpodSystem.Data.Custom.LeftClickTrain{lastidx+a}(1);
%                     else
%                         BpodSystem.Data.Custom.LeftClickTrain{lastidx+a} = round(1/BpodSystem.Data.Custom.LeftClickRate*10000)/10000;
%                         BpodSystem.Data.Custom.RightClickTrain{lastidx+a} = round(1/BpodSystem.Data.Custom.RightClickRate*10000)/10000;
%                     end
%                     if length(BpodSystem.Data.Custom.LeftClickTrain{lastidx+a}) > length(BpodSystem.Data.Custom.RightClickTrain{lastidx+a})
%                         BpodSystem.Data.Custom.LeftRewarded(lastidx+a) = 1;
%                     elseif length(BpodSystem.Data.Custom.LeftClickTrain{lastidx+a}) < length(BpodSystem.Data.Custom.RightClickTrain{lastidx+a})
%                         BpodSystem.Data.Custom.LeftRewarded(lastidx+a) = 0;
%                     else
%                         BpodSystem.Data.Custom.LeftRewarded(lastidx+a) = rand<0.5;
%                     end
%                 else
%                     BpodSystem.Data.Custom.AuditoryOmega(lastidx+a) = NaN;
%                     BpodSystem.Data.Custom.LeftClickRate(lastidx+a) = NaN;
%                     BpodSystem.Data.Custom.RightClickRate(lastidx+a) = NaN;
%                     BpodSystem.Data.Custom.LeftRewarded(lastidx+a) = NaN;
%                     BpodSystem.Data.Custom.LeftClickTrain{lastidx+a} = [];
%                     BpodSystem.Data.Custom.RightClickTrain{lastidx+a} = [];
%                 end%if auditory
%             end%for a=1:5
%             
%         case 2 %freq stimuli
%             
%             StimulusSettings.SamplingRate = TaskParameters.GUI.Aud_SamplingRate; % Sound card sampling rate;
%             StimulusSettings.ramp = TaskParameters.GUI.Aud_Ramp;
%             StimulusSettings.nFreq = TaskParameters.GUI.Aud_nFreq; % Number of different frequencies to sample from
%             StimulusSettings.ToneOverlap = TaskParameters.GUI.Aud_ToneOverlap;
%             StimulusSettings.ToneDuration = TaskParameters.GUI.Aud_ToneDuration;
%             StimulusSettings.Noevidence=TaskParameters.GUI.Aud_NoEvidence;
%             StimulusSettings.minFreq = TaskParameters.GUI.Aud_minFreq ;
%             StimulusSettings.maxFreq = TaskParameters.GUI.Aud_maxFreq ;
%             StimulusSettings.UseMiddleOctave=TaskParameters.GUI.Aud_UseMiddleOctave;
%             StimulusSettings.Volume=TaskParameters.GUI.Aud_Volume;
%             StimulusSettings.nTones = floor((TaskParameters.GUI.AuditoryStimulusTime-StimulusSettings.ToneDuration*StimulusSettings.ToneOverlap)/(StimulusSettings.ToneDuration*(1-StimulusSettings.ToneOverlap))); %number of tones
%             if iTrial > TaskParameters.GUI.StartEasyTrials
%                 newFracHigh = randsample(TaskParameters.GUI.Aud_Levels.AudFracHigh,5,1,TaskParameters.GUI.Aud_Levels.AudPFrac)';
%                 %include Fifty50 Trials
%                 NewFifty50 = rand(5,1) < TaskParameters.GUI.Percent50Fifty;
%                 newFracHigh(NewFifty50) = 50;
%             else
%                 EasyProb = zeros(numel(TaskParameters.GUI.Aud_Levels.AudPFrac),1);
%                 EasyProb(1) = 0.5; EasyProb(end)=0.5;
%                 newFracHigh = randsample(TaskParameters.GUI.Aud_Levels.AudFracHigh,5,1,EasyProb)';
%             end
%             
%             newCloud = cell(1,5);
%             newSound = cell(1,5);
%             for a = 1:5
%                 if BpodSystem.Data.Custom.AuditoryTrial(lastidx+a)
%                     [Sound, Cloud, ~] = GenerateToneCloudDual(newFracHigh(a)/100, StimulusSettings);
%                     newCloud{a} = Cloud;
%                     newSound{a} = Sound;
%                 end
%             end
%             
%             LeftRewarded = newFracHigh>50;
%             LeftRewarded (newFracHigh==050) = rand<0.5;
%             newFracHigh(~newAuditoryTrial) = nan(sum(~newAuditoryTrial),1);
%             BpodSystem.Data.Custom.AudFracHigh = [BpodSystem.Data.Custom.AudFracHigh, newFracHigh];
%             BpodSystem.Data.Custom.AudCloud = [BpodSystem.Data.Custom.AudCloud, newCloud];
%             BpodSystem.Data.Custom.AudSound = [BpodSystem.Data.Custom.AudSound, newSound];
%             BpodSystem.Data.Custom.LeftRewarded = [BpodSystem.Data.Custom.LeftRewarded, LeftRewarded];
%             
%     end %switch/case auditory stimulus type
%     
%     % cross-modality difficulty for plotting
%     for a = 1 : 5
%         if BpodSystem.Data.Custom.AuditoryTrial(lastidx+a)
%             if BpodSystem.Data.Custom.ClickTask(lastidx+a)
%                 BpodSystem.Data.Custom.DV(lastidx+a) = (length(BpodSystem.Data.Custom.LeftClickTrain{lastidx+a}) - length(BpodSystem.Data.Custom.RightClickTrain{lastidx+a}))./(length(BpodSystem.Data.Custom.LeftClickTrain{lastidx+a}) + length(BpodSystem.Data.Custom.RightClickTrain{lastidx+a}));
%             else
%                 BpodSystem.Data.Custom.DV(lastidx+a) = (2*BpodSystem.Data.Custom.AudFracHigh(lastidx+a)-100)/100;
%             end
%         else
%             BpodSystem.Data.Custom.DV(lastidx+a) = (2*BpodSystem.Data.Custom.OdorFracA(lastidx+a)-100)/100;
%         end
%     end
%     
end%if trial > - 5

% %update laser params
% if ~TaskParameters.GUI.LaserSoftCode
%     %laser via programm pulsepal (without custom train via softvode)
%     BpodSystem.Data.Custom.PulsePalParamStimulus=configurePulsePalLaser(BpodSystem.Data.Custom.PulsePalParamStimulus);
%     if ~BpodSystem.EmulatorMode
%         ProgramPulsePal(BpodSystem.Data.Custom.PulsePalParamStimulus);
%     end
% end
end