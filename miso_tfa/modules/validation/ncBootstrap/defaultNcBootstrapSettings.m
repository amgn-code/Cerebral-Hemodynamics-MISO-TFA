function settings = defaultNcBootstrapSettings()
% defaultNcBootstrapSettings Return the NC bootstrap configuration.
%
% The temporal validation design uses three non-overlapping 90-second
% blocks. Each fold estimates the transfer functions from two blocks and
% evaluates them on the remaining block. This gives every current NC file
% at least two training Welch segments for the two-input MISO solve.

    analysis = defaultTfaAnalysisSettings("NC");
    analysis.frequencyRangeHz = [0.02 0.35];
    analysis.frequencyBandEdgesHz = [0.02; 0.07; 0.20; 0.35];
    analysis.frequencyBandNames = ["VLF"; "LF"; "HF"];
    analysis.pwelch.windowLengthSeconds = 90;
    analysis.pwelch.windowOverlap = 0;
    analysis.pwelch.minimumWindows = 2;
    analysis.statistics.enabled = false;
    analysis.plot = defaultPlotSettings("none");
    analysis.retainAnalysisInput = false;

    settings.dataFolder = "";
    settings.group = "NC";
    settings.analysis = analysis;

    settings.validation.blockLengthSeconds = 90;
    settings.validation.numFolds = 3;
    settings.validation.discardRemainder = true;

    settings.bootstrap.numSamples = 2000;
    settings.bootstrap.randomSeed = 2026;
    settings.bootstrap.confidenceLevel = 0.95;
    settings.errorFloor = 1e-12;
    settings.execution.stopOnSubjectError = false;

    settings.plot.enabled = true;
    settings.plot.visible = "on";

end
