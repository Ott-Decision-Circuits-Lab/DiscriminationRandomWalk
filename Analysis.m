function FigHandle = Analysis(SessionData)
% Analysis.m
% Handles three cases:
%   1) Automatic on rig: Analysis() - uses global BpodSystem
%   2) Manual single: Analysis('filepath.mat') - loads one session
%   3) Manual pooled: Analysis(SessionData) or Analysis('pooledfile.mat')

    %% ---- Step 1: Get SessionData into workspace ----
    
    if nargin < 1
        % Case 1: Automatic on rig
        global BpodSystem
        global TaskParameters
        if isempty(BpodSystem)
            [datafile, datapath] = uigetfile();
            loaded = load(fullfile(datapath, datafile));
            SessionData = loaded.SessionData;
        else
            SessionData = BpodSystem.Data;
            SessionData.SettingsFile.GUI = TaskParameters.GUI;
        end
    elseif ischar(SessionData) || isstring(SessionData)
        % Case 2 or 3: File path provided
        loaded = load(SessionData);
        SessionData = loaded.SessionData;
    end
    % else: SessionData is already a struct (Case 3)
    
    %% ---- Step 2: Normalize to unified format ----
    
    if ~isfield(SessionData, 'TrialWiseData')
        SessionData = NormalizeSingleSession(SessionData);
    end
    
    %% ---- Step 3: Extract unified variables ----
    
    nSessions = SessionData.SessionWiseData.nSessions;
    nTrials = numel(SessionData.TrialWiseData.DecisionVariable);
    
    DV = SessionData.TrialWiseData.DecisionVariable;
    ChoiceLeft = SessionData.TrialWiseData.ChoiceLeft;
    Feedback = SessionData.TrialWiseData.Feedback;
    Correct = SessionData.TrialWiseData.ChoiceCorrect;
    AudBias = SessionData.TrialWiseData.AudBias;
    CompletedTrials = (Feedback & Correct == 1) | (Correct == 0);
    nTrialsCompleted = sum(CompletedTrials);
    
    %% ---- Step 4: Build title ----
    
    RatIDs = unique(SessionData.SessionWiseData.Subject);
    RatID = str2double(RatIDs{1});
    if isnan(RatID), RatID = -1; end
    
    if nSessions == 1
        dateString = string(SessionData.SessionWiseData.SessionDate{1});
        TotalClicks = SessionData.SessionWiseData.SumRates(1);
        AudStimTime = SessionData.SessionWiseData.AuditoryStimulusTime(1);
        
        % Random Walk parameters
        RW_Sigma = SessionData.SessionWiseData.RandomWalkSigma;
        RW_Kappa = SessionData.SessionWiseData.RandomWalkKappa;
        RW_Bounds = SessionData.SessionWiseData.RandomWalkBounds;
        
        if isfield(SessionData.SessionWiseData, 'Pharmacology') && ~isempty(SessionData.SessionWiseData.Pharmacology)
            pharm = SessionData.SessionWiseData.Pharmacology{1};
            figtitle = sprintf("RandomWalk, R%d on %s with %s %s %s, Clicks=%d, StimTime=%s, Sigma=%.2f, Kappa=%.2f, Bounds=%.1f", ...
                RatID, dateString, pharm{1}, pharm{2}, pharm{3}, TotalClicks, num2str(AudStimTime), RW_Sigma, RW_Kappa, RW_Bounds);
        else
            figtitle = sprintf("RandomWalk, R%d on %s, Clicks=%d, StimTime=%s, Sigma=%.2f, Kappa=%.2f, Bounds=%.1f", ...
                RatID, dateString, TotalClicks, num2str(AudStimTime), RW_Sigma, RW_Kappa, RW_Bounds);
        end
    else
        dateString = strcat(string(SessionData.SessionWiseData.SessionDate{1}), " - ", ...
                           string(SessionData.SessionWiseData.SessionDate{end}));
        figtitle = sprintf("RandomWalk: R%d on %s (%d sessions, n=%d trials)", ...
            RatID, dateString, nSessions, nTrialsCompleted);
    end
    
    %% ---- Step 5: Setup figure ----
    
    FigHandle = figure('Name', figtitle, 'Position', [50 75 1400 800]);
    sgtitle(figtitle, 'FontSize', 14, 'FontWeight', 'bold');
    
    %% ---- Step 6: Psychometric Plot (Binned by AudBias) ----
    
    subplot(3, 2, 1);
    hold on;
        
    AudBin = 7;
    DV_Completed = DV(CompletedTrials);
    commonBinEdges = linspace(min(DV_Completed)-10*eps, max(DV_Completed)+10*eps, AudBin+1);
    
    % Color scheme
    unbiasedColor = [0, 0, 0];
    leftBiasColor = [1, 0, 0];
    rightBiasColor = [0, 0, 1];
    Colors = [unbiasedColor; leftBiasColor; rightBiasColor];
    
    % Bin trials by AudBias: 1=Unbiased (0.4-0.6), 2=Left (>0.6), 3=Right (<0.4)
    FitIdx = zeros(size(AudBias));
    FitIdx(AudBias < 0.4) = 3;
    FitIdx(AudBias >= 0.4 & AudBias <= 0.6) = 1;
    FitIdx(AudBias > 0.6) = 2;
    
    AllDVs = cell(1, 3);
    AllChoices = cell(1, 3);
    for i = 1:3
        AllDVs{i} = DV(CompletedTrials & FitIdx == i);
        AllChoices{i} = ChoiceLeft(CompletedTrials & FitIdx == i);
    end
    
    beta_Left = [];
    beta_Right = [];
    
    for i = 1:3
        if ~isempty(AllDVs{i}) && sum(~isnan(AllDVs{i})) > 4
            BinIdx = discretize(AllDVs{i}, commonBinEdges);
            
            validData = ~isnan(AllDVs{i}) & ~isnan(AllChoices{i}) & ~isnan(BinIdx);
            DV_valid = AllDVs{i}(validData);
            Ch_valid = AllChoices{i}(validData);
            Bin_valid = BinIdx(validData);
            
            uniqueBins = unique(Bin_valid);
            nBins = numel(uniqueBins);
            PsycX = zeros(nBins, 1);
            PsycY = zeros(nBins, 1);
            PsycXSEM = zeros(nBins, 1);
            PsycYSEM = zeros(nBins, 1);
            
            for ib = 1:nBins
                mask = Bin_valid == uniqueBins(ib);
                n = sum(mask);
                PsycX(ib) = mean(DV_valid(mask));
                PsycY(ib) = mean(Ch_valid(mask));
                if n > 1
                    PsycXSEM(ib) = std(DV_valid(mask)) / sqrt(n);
                    PsycYSEM(ib) = std(Ch_valid(mask)) / sqrt(n);
                end
            end
            
            errorbar(PsycX, PsycY, PsycYSEM, PsycXSEM, 'LineStyle', 'none', ...
                 'Marker', 'o', 'MarkerFaceColor', Colors(i,:), ...
                 'MarkerEdgeColor', 'w', 'MarkerSize', 6, ...
                 'Color', Colors(i,:), 'LineWidth', 1);
            
            XFit = linspace(min(AllDVs{i})-10*eps, max(AllDVs{i})+10*eps, 100);
            beta = glmfit(AllDVs{i}, AllChoices{i}', 'binomial');
            YFit = glmval(beta, XFit, 'logit');
            plot(XFit, YFit, '-', 'Color', Colors(i,:), 'LineWidth', 1.5);
            
            if i == 2, beta_Left = beta; end
            if i == 3, beta_Right = beta; end
        end
    end
    
    if ~isempty(beta_Left) && ~isempty(beta_Right)
        PSE_L = -beta_Left(1) / beta_Left(2);
        PSE_R = -beta_Right(1) / beta_Right(2);
        deltaPSE = PSE_L - PSE_R;
        
        x_grid = linspace(-1, 1, 1000);
        y_L = glmval(beta_Left, x_grid, 'logit');
        y_R = glmval(beta_Right, x_grid, 'logit');
        ABC = trapz(x_grid, abs(y_L - y_R));
        
        metricsStr = sprintf('ΔPSE (L-R): %.3f\nABC (L vs R): %.3f', deltaPSE, ABC);
        text(0.98, 0.02, metricsStr, 'Units', 'normalized', ...
             'HorizontalAlignment', 'right', 'VerticalAlignment', 'bottom', ...
             'FontSize', 9, 'EdgeColor', [0.8 0.8 0.8], 'BackgroundColor', 'w', ...
             'Margin', 2);
    end
    
    xlabel('DV');
    ylabel('p left');
    title('Psychometric (Binned by Bias)');
    text(0.95*min(get(gca,'XLim')), 0.96*max(get(gca,'YLim')), ...
         ['n=', num2str(nTrialsCompleted)]);
    hold off

    %% ---- Step 6a: Random Walk Trajectory ----
    
    subplot(3, 2, 2);
    hold on;
    plot(1:numel(AudBias), AudBias, '-k', 'LineWidth', 1.5);
    yline(0.5, ':', 'Color', [0.5 0.5 0.5], 'LineWidth', 1);
    yline(0.4, '--', 'Color', [0.7 0.7 0.7], 'LineWidth', 0.5);
    yline(0.6, '--', 'Color', [0.7 0.7 0.7], 'LineWidth', 0.5);
    xlabel('Trial');
    ylabel('P(Left Bias)');
    title('Random Walk Trajectory');
    ylim([0 1]);
    hold off
    
    %% ---- Step 7: DV Distribution Plot ----
    
    subplot(3, 2, 3);
    hold on
    
    % Color points by their AudBias bin
    pointColors = zeros(numel(DV), 3);
    pointColors(FitIdx == 1, :) = repmat(unbiasedColor, sum(FitIdx == 1), 1);
    pointColors(FitIdx == 2, :) = repmat(leftBiasColor, sum(FitIdx == 2), 1);
    pointColors(FitIdx == 3, :) = repmat(rightBiasColor, sum(FitIdx == 3), 1);
    
    % Plot valid DVs
    validDVIdx = ~isnan(DV);
    scatter(1:numel(DV), DV, 5, pointColors, 'filled', 'MarkerFaceAlpha', 0.6);
    
    xlabel('Trial');
    ylabel('Aud DV');
    title('DV Distribution over Trials');
    hold off
    
    %% ---- Step 8: Bias Tracking & Cross-Correlation ----
    
    % Subplot 4: Rolling Choice Bias vs True Bias
    subplot(3, 2, 4);
    hold on;
    windowSize = 10;
    RollingChoice = movmean(ChoiceLeft, windowSize, 'omitnan');
    
    plot(1:numel(AudBias), AudBias, '-k', 'LineWidth', 1.5, 'DisplayName', 'True Bias');
    plot(1:numel(RollingChoice), RollingChoice, '-r', 'LineWidth', 1.5, 'DisplayName', 'Rolling Choice (win=10)');
    yline(0.5, ':', 'Color', [0.5 0.5 0.5], 'HandleVisibility', 'off');
    xlabel('Trial');
    ylabel('P(Left)');
    title('Bias Tracking');
    legend('Location', 'best');
    ylim([0 1]);
    hold off;
    
    % Subplot 5: Cross-Correlation
    subplot(3, 2, 5);
    hold on;
    
    % Prepare signals (remove NaNs)
    validIdx = ~isnan(RollingChoice) & ~isnan(AudBias);
    sigChoice = RollingChoice(validIdx) - mean(RollingChoice(validIdx));
    sigBias = AudBias(validIdx) - mean(AudBias(validIdx));
    
    if numel(sigChoice) > 20
        [acor, lags] = xcorr(sigChoice, sigBias, 'coeff');
        maxLag = 50;
        lagMask = abs(lags) <= maxLag;
        plot(lags(lagMask), acor(lagMask), '-b', 'LineWidth', 1.5);
        
        [maxAcor, maxIdx] = max(acor(lagMask));
        peakLag = lags(lagMask);
        peakLag = peakLag(maxIdx);
        
        plot(peakLag, maxAcor, 'ro', 'MarkerFaceColor', 'r', 'MarkerSize', 8);
        xlabel('Lag (Trials)');
        ylabel('Correlation');
        title(sprintf('Cross-Correlation (Peak Lag: %d trials)', peakLag));
        grid on;
    else
        text(0.5, 0.5, 'Not enough data for cross-correlation', 'Units', 'normalized', 'HorizontalAlignment', 'center');
    end
    hold off;
    
    %% ---- Step 9: History-Dependent Logistic Regression ----
    
    subplot(3, 2, 6);
    hold on;
    
    % Shift variables
    Choice_prev = [NaN, ChoiceLeft(1:end-1)];
    Reward_prev = [NaN, Correct(1:end-1)]; % 1 if prev correct, 0 if incorrect
    
    % Filter for valid rows (no NaNs in any column)
    regMask = CompletedTrials & ~isnan(DV) & ~isnan(AudBias) & ~isnan(Choice_prev) & ~isnan(Reward_prev);
    
    if sum(regMask) > 20
        y = ChoiceLeft(regMask)';
        X = [DV(regMask)', AudBias(regMask)', Choice_prev(regMask)', Reward_prev(regMask)'];
        
        % Fit logistic regression
        [b, ~, stats] = glmfit(X, y, 'binomial', 'link', 'logit');
        
        % Extract coefficients and standard errors
        coefs = b(2:5);
        se = stats.se(2:5);
        
        % Plot bar chart
        barHandles = bar(coefs, 'FaceColor', 'flat', 'EdgeColor', 'none');
        
        % Color bars based on significance (p < 0.05)
        pvals = stats.p(2:5);
        barColors = zeros(4, 3);
        for i = 1:4
            if pvals(i) < 0.05
                barColors(i, :) = [0.2, 0.6, 0.8]; % Significant (blue)
            else
                barColors(i, :) = [0.8, 0.8, 0.8]; % Not significant (gray)
            end
        end
        barHandles.CData = barColors;
        
        % Add error bars
        errorbar(1:4, coefs, se, 'LineStyle', 'none', 'Color', 'k', 'LineWidth', 1);
        
        % Add p-values as text
        for i = 1:4
            if pvals(i) < 0.001
                text(i, coefs(i) + se(i) + 0.2, '***', 'HorizontalAlignment', 'center', 'FontSize', 10);
            elseif pvals(i) < 0.01
                text(i, coefs(i) + se(i) + 0.2, '**', 'HorizontalAlignment', 'center', 'FontSize', 10);
            elseif pvals(i) < 0.05
                text(i, coefs(i) + se(i) + 0.2, '*', 'HorizontalAlignment', 'center', 'FontSize', 10);
            end
        end
        
        xticks(1:4);
        xticklabels({'DV', 'AudBias', 'Choice_{t-1}', 'Reward_{t-1}'});
        ylabel('Coefficient (log-odds)');
        title('History-Dependent Logistic Regression');
        grid on;
    else
        text(0.5, 0.5, 'Not enough data for regression', 'Units', 'normalized', 'HorizontalAlignment', 'center');
    end
    hold off;

end % Analysis()


%% ---- Helper Function: Normalize single session to pooled format ----

function SessionData = NormalizeSingleSession(SessionData)
% Converts a single-session struct into the same TrialWiseData/SessionWiseData
% format used by pooled analysis, enabling unified downstream code.

    nTrials = SessionData.nTrials;
    
    % --- TrialWiseData ---
    TD = SessionData.Custom.TrialData;
    fields = {'DecisionVariable', 'ChoiceLeft', 'SampleLength', ...
              'CatchTrial', 'Feedback', 'ChoiceCorrect', ...
              'LaserTrial', 'AudBias', 'TrueLambda'};
    
    TrialWiseData.nTrialsArray = nTrials - 1;  % Last trial typically aborted
    
    for k = 1:numel(fields)
        f = fields{k};
        if isfield(TD, f)
            val = TD.(f);
            if isvector(val) && ~iscell(val)
                val = val(:)';
            end
            TrialWiseData.(f) = val(1:end-1);
        else
            if iscell(val)
                TrialWiseData.(f) = cell(1, nTrials - 1);
            else
                TrialWiseData.(f) = nan(1, nTrials - 1);
            end
        end
    end
    
    % --- SessionWiseData ---
    SessionWiseData.nSessions = 1;
    SessionWiseData.Subject = {SessionData.Info.Subject};
    SessionWiseData.SessionDate = {SessionData.Info.SessionDate};
    SessionWiseData.SumRates = SessionData.SettingsFile.GUI.SumRates;
    SessionWiseData.AuditoryStimulusTime = SessionData.SettingsFile.GUI.AuditoryStimulusTime;
    
    % Random Walk parameters
    if isfield(SessionData.SettingsFile.GUI, 'RandomWalkSigma')
        SessionWiseData.RandomWalkSigma = SessionData.SettingsFile.GUI.RandomWalkSigma;
        SessionWiseData.RandomWalkKappa = SessionData.SettingsFile.GUI.RandomWalkKappa;
        SessionWiseData.RandomWalkBounds = SessionData.SettingsFile.GUI.RandomWalkBounds;
    else
        SessionWiseData.RandomWalkSigma = NaN;
        SessionWiseData.RandomWalkKappa = NaN;
        SessionWiseData.RandomWalkBounds = NaN;
    end
    
    if isfield(SessionData.Custom, 'Pharmacology')
        SessionWiseData.Pharmacology = {SessionData.Custom.Pharmacology};
    else
        SessionWiseData.Pharmacology = {};
    end
    
    % --- Merge ---
    SessionData.TrialWiseData = TrialWiseData;
    SessionData.SessionWiseData = SessionWiseData;
end