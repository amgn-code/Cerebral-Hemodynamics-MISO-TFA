function simulationSettings = applyTfaAnalysisSettingsToSimulation( ...
    simulationSettings, analysisSettings)
% applyTfaAnalysisSettingsToSimulation Keep both workflows method-aligned.
%
% The ordinary TFA and known-truth simulation should use the same sampling
% frequency, analyzed frequencies, Welch estimator, and phase convention.

    simulationSettings.samplingFrequencyHz = ...
        analysisSettings.fsTarget;
    simulationSettings.frequencyRangeHz = ...
        analysisSettings.frequencyRangeHz;
    simulationSettings.frequencyBandEdgesHz = ...
        analysisSettings.frequencyBandEdgesHz;
    simulationSettings.frequencyBandNames = ...
        analysisSettings.frequencyBandNames;
    simulationSettings.welch = analysisSettings.pwelch;
    simulationSettings.phase = analysisSettings.phase;

end
