function settings = projectSettings()
% projectSettings Return the single active project configuration boundary.

settings.samplingFrequencyHz = 4;
settings.analysis.reportingBandHz = [0.005 0.35];
settings.analysis.pathwayCalibrationBandHz = [0.005 0.35];
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

end
