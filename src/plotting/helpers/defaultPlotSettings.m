function plotSettings = defaultPlotSettings(visibilityPreset)
% defaultPlotSettings Return subject and batch plotting controls.
%
% visibilityPreset is "none" (the backwards-compatible default) or "all".

if nargin < 1
    visibilityPreset = "none";
end
visibilityPreset = lower(string(visibilityPreset));
if ~isscalar(visibilityPreset) || ...
        ~any(visibilityPreset == ["none", "all"])
    error( ...
        "TFA:UnknownPlotVisibilityPreset", ...
        'visibilityPreset must be "none" or "all".');
end
showFigures = visibilityPreset == "all";

plotSettings.transferFunctionStyle = "stem";      % "stem" or "line"
% This is a backwards-compatible plotting default. The pipeline replaces it
% with analysisSettings.frequencyRangeHz so analysis, plots, and exports use
% one user-selected range.
plotSettings.frequencyLimitsHz = [0 0.35];
plotSettings.showFrequencyBandLines = true;
plotSettings.showSisoCoherenceReference = true;

plotSettings.show.overview = showFigures;
plotSettings.show.miso.map = showFigures;
plotSettings.show.miso.co2 = showFigures;
plotSettings.show.siso.map = showFigures;
plotSettings.show.siso.co2 = showFigures;
plotSettings.show.misoPartitioned.map = showFigures;
plotSettings.show.misoPartitioned.co2 = showFigures;
plotSettings.show.sisoPartitioned.map = showFigures;
plotSettings.show.sisoPartitioned.co2 = showFigures;
plotSettings.show.statistics.modelComparison = showFigures;
plotSettings.show.statistics.groupComparison = showFigures;
plotSettings.show.statistics.pathwayBalance = showFigures;
plotSettings.show.statistics.inputAssociation = showFigures;
plotSettings.show.statistics.frequencyWiseComparison = showFigures;

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
