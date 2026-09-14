function settings = projectSettings()
% projectSettings Return the single active project configuration boundary.

settings.samplingFrequencyHz = 4;
settings.analysis.reportingBandHz = [0.02 0.35];
settings.analysis.pathwayCalibrationBandHz = [0.02 0.35];
settings.analysis.frequencyBandEdgesHz = ...
    [0.02; 0.070; 0.200; 0.350];
settings.analysis.frequencyBandNames = ["VLF"; "LF"; "HF"];
settings.analysis.nyquistFrequencyHz = ...
    settings.samplingFrequencyHz/2;
settings.analysis.primaryEstimand = ...
    "conditional pathway recovery error";
settings.analysis.secondaryEstimand = ...
    "SISO own-population-target error diagnostic";
settings.analysis.primaryAdvantage = ...
    "log10(mean SISO error / mean MISO error)";
settings.analysis.coherenceRole = ...
    "secondary diagnostic with empirical null reference";
settings.simulation.factors = simulationFactors();

settings = validateProjectSettings(settings);

end
