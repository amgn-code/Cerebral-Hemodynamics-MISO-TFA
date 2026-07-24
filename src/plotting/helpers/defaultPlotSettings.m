function plotSettings = defaultPlotSettings()
% defaultPlotSettings
%
% User-facing plotting controls for subject and batch figures.

plotSettings.transferFunctionStyle = "stem";      % "stem" or "line"
% This is a backwards-compatible plotting default. The pipeline replaces it
% with analysisSettings.frequencyRangeHz so analysis, plots, and exports use
% one user-selected range.
plotSettings.frequencyLimitsHz = [0 0.35];
plotSettings.showFrequencyBandLines = true;
plotSettings.showSisoCoherenceReference = true;

plotSettings.show.overview = false;
plotSettings.show.miso.map = false;
plotSettings.show.miso.co2 = false;
plotSettings.show.siso.map = false;
plotSettings.show.siso.co2 = false;
plotSettings.show.misoPartitioned.map = false;
plotSettings.show.misoPartitioned.co2 = false;
plotSettings.show.sisoPartitioned.map = false;
plotSettings.show.sisoPartitioned.co2 = false;
plotSettings.show.statistics.modelComparison = false;
plotSettings.show.statistics.groupComparison = false;
plotSettings.show.statistics.pathwayBalance = false;
plotSettings.show.statistics.inputAssociation = false;
plotSettings.show.statistics.frequencyWiseComparison = false;

plotSettings.colors.transferFunction = [0 0.4470 0.7410];
plotSettings.colors.map = [0 0.4470 0.7410];
plotSettings.colors.co2 = [0.8500 0.3250 0.0980];
plotSettings.colors.cbv = [0.4660 0.6740 0.1880];
plotSettings.colors.multipleCoherence = [0.4940 0.1840 0.5560];
plotSettings.colors.mapCoherence = [0.3010 0.7450 0.9330];
plotSettings.colors.co2Coherence = [0.9290 0.4940 0.1250];
plotSettings.colors.inputCoherence = [0.2000 0.6000 0.5000];
plotSettings.colors.sdBand = [0 0.4470 0.7410];
plotSettings.colors.residual = [0.6350 0.0780 0.1840];
plotSettings.colors.conditionNumber = [0.2500 0.2500 0.2500];
plotSettings.colors.inputPower = [0.4660 0.6740 0.1880];
plotSettings.colors.coherenceReference = [0.3500 0.3500 0.3500];
% Rows are used in the same order as statistics.groupsToCompare.
plotSettings.colors.groupComparison = [
    0.0000 0.4470 0.7410
    0.8500 0.3250 0.0980
    0.4660 0.6740 0.1880
    0.4940 0.1840 0.5560
];

plotSettings.lineWidth.transferFunction = 0.9;
plotSettings.lineWidth.coherence = 1.2;
plotSettings.lineWidth.coherenceReference = 1.0;
plotSettings.markerSize = 3;

end
