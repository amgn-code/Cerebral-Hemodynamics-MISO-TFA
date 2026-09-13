function settings = defaultTfaOutputSettings( ...
    baseOutputFolder, excelMetricPreset)
% defaultTfaOutputSettings Return output settings with a metric preset.
%
% excelMetricPreset is "all" or "none". Individual metrics can still be
% changed after this function returns, for example:
%   settings.excelMetrics.miso.mapGain = false;

    if nargin < 1
        baseOutputFolder = "";
    end
    if nargin < 2
        excelMetricPreset = "all";
    end

    excelMetricPreset = lower(string(excelMetricPreset));
    if ~isscalar(excelMetricPreset) || ...
            ~any(excelMetricPreset == ["all", "none"])
        error( ...
            "TFA:UnknownExcelMetricPreset", ...
            'excelMetricPreset must be "all" or "none".');
    end
    metricEnabled = excelMetricPreset == "all";

    settings.baseOutputFolder = string(baseOutputFolder);
    settings.saveSubjectFigures = true;
    settings.saveBatchFigures = true;
    settings.saveExcel = true;
    settings.excelFileName = "tfa_results.xlsx";
    settings.excelStatistics = true;

    settings.excelMetrics.signals.mapPower = metricEnabled;
    settings.excelMetrics.signals.co2Power = metricEnabled;
    settings.excelMetrics.signals.cbvPower = metricEnabled;
    settings.excelMetrics.inputs.coherence = metricEnabled;
    settings.excelMetrics.inputs.phaseWrapped = metricEnabled;
    settings.excelMetrics.inputs.phaseUnwrapped = metricEnabled;

    settings.excelMetrics.miso.mapGain = metricEnabled;
    settings.excelMetrics.miso.mapPhaseWrapped = metricEnabled;
    settings.excelMetrics.miso.mapPhaseUnwrapped = metricEnabled;
    settings.excelMetrics.miso.co2Gain = metricEnabled;
    settings.excelMetrics.miso.co2PhaseWrapped = metricEnabled;
    settings.excelMetrics.miso.co2PhaseUnwrapped = metricEnabled;
    settings.excelMetrics.miso.multipleCoherence = metricEnabled;
    settings.excelMetrics.miso.mapPartialCoherence = metricEnabled;
    settings.excelMetrics.miso.co2PartialCoherence = metricEnabled;
    settings.excelMetrics.miso.unexplainedFraction = metricEnabled;
    settings.excelMetrics.miso.residualPower = metricEnabled;
    settings.excelMetrics.miso.conditionNumber = metricEnabled;

    settings.excelMetrics.siso.mapGain = metricEnabled;
    settings.excelMetrics.siso.mapPhaseWrapped = metricEnabled;
    settings.excelMetrics.siso.mapPhaseUnwrapped = metricEnabled;
    settings.excelMetrics.siso.mapCoherence = metricEnabled;
    settings.excelMetrics.siso.mapUnexplainedFraction = metricEnabled;
    settings.excelMetrics.siso.mapResidualPower = metricEnabled;
    settings.excelMetrics.siso.co2Gain = metricEnabled;
    settings.excelMetrics.siso.co2PhaseWrapped = metricEnabled;
    settings.excelMetrics.siso.co2PhaseUnwrapped = metricEnabled;
    settings.excelMetrics.siso.co2Coherence = metricEnabled;
    settings.excelMetrics.siso.co2UnexplainedFraction = metricEnabled;
    settings.excelMetrics.siso.co2ResidualPower = metricEnabled;

end
