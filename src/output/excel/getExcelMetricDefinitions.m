function metrics = getExcelMetricDefinitions( ...
    excelMetrics, runMISO, runSISO)
% getExcelMetricDefinitions List the enabled metrics written to Excel.
%
% Each definition tells the exporter which result array to use, how to
% summarize it, and what to call its worksheet.

    metricTemplate = struct( ...
        'enabled', false, ...
        'sheetName', "", ...
        'modelName', "", ...
        'field', "", ...
        'conversion', "none", ...
        'statistic', "arithmetic", ...
        'wrappedField', "", ...
        'coherenceField', "");

    metrics = repmat(metricTemplate, 30, 1);

    %% Signal and Input Metrics Shared by Both Models

    metrics(1) = metricTemplate;
    metrics(1).enabled = excelMetrics.signals.mapPower;
    metrics(1).sheetName = "MAP_Power";
    metrics(1).modelName = "shared";
    metrics(1).field = "map.power";
    metrics(1).conversion = "powerToDb";

    metrics(2) = metricTemplate;
    metrics(2).enabled = excelMetrics.signals.co2Power;
    metrics(2).sheetName = "CO2_Power";
    metrics(2).modelName = "shared";
    metrics(2).field = "co2.power";
    metrics(2).conversion = "powerToDb";

    metrics(3) = metricTemplate;
    metrics(3).enabled = excelMetrics.signals.cbvPower;
    metrics(3).sheetName = "CBV_Power";
    metrics(3).modelName = "shared";
    metrics(3).field = "cbv.power";
    metrics(3).conversion = "powerToDb";

    metrics(4) = metricTemplate;
    metrics(4).enabled = excelMetrics.inputs.coherence;
    metrics(4).sheetName = "Input_Coherence";
    metrics(4).modelName = "shared";
    metrics(4).field = "inputRelationship.coherence";

    metrics(5) = metricTemplate;
    metrics(5).enabled = excelMetrics.inputs.phaseWrapped;
    metrics(5).sheetName = "Input_PhaseW";
    metrics(5).modelName = "shared";
    metrics(5).field = "inputRelationship.phase.wrapped";
    metrics(5).statistic = "phaseWrapped";
    metrics(5).wrappedField = "inputRelationship.phase.wrapped";
    metrics(5).coherenceField = "inputRelationship.coherence";

    metrics(6) = metricTemplate;
    metrics(6).enabled = excelMetrics.inputs.phaseUnwrapped;
    metrics(6).sheetName = "Input_PhaseU";
    metrics(6).modelName = "shared";
    metrics(6).field = "inputRelationship.phase.unwrapped";
    metrics(6).statistic = "phaseUnwrapped";
    metrics(6).wrappedField = "inputRelationship.phase.wrapped";
    metrics(6).coherenceField = "inputRelationship.coherence";

    %% MISO Metrics

    metrics(7) = metricTemplate;
    metrics(7).enabled = excelMetrics.miso.mapGain;
    metrics(7).sheetName = "MISO_MAP_Gain";
    metrics(7).modelName = "miso";
    metrics(7).field = "map.gain";

    metrics(8) = metricTemplate;
    metrics(8).enabled = excelMetrics.miso.mapPhaseWrapped;
    metrics(8).sheetName = "MISO_MAP_PhaseW";
    metrics(8).modelName = "miso";
    metrics(8).field = "map.phase.wrapped";
    metrics(8).statistic = "phaseWrapped";
    metrics(8).wrappedField = "map.phase.wrapped";
    metrics(8).coherenceField = "map.coherence.partial";

    metrics(9) = metricTemplate;
    metrics(9).enabled = excelMetrics.miso.mapPhaseUnwrapped;
    metrics(9).sheetName = "MISO_MAP_PhaseU";
    metrics(9).modelName = "miso";
    metrics(9).field = "map.phase.unwrapped";
    metrics(9).statistic = "phaseUnwrapped";
    metrics(9).wrappedField = "map.phase.wrapped";
    metrics(9).coherenceField = "map.coherence.partial";

    metrics(10) = metricTemplate;
    metrics(10).enabled = excelMetrics.miso.co2Gain;
    metrics(10).sheetName = "MISO_CO2_Gain";
    metrics(10).modelName = "miso";
    metrics(10).field = "co2.gain";

    metrics(11) = metricTemplate;
    metrics(11).enabled = excelMetrics.miso.co2PhaseWrapped;
    metrics(11).sheetName = "MISO_CO2_PhaseW";
    metrics(11).modelName = "miso";
    metrics(11).field = "co2.phase.wrapped";
    metrics(11).statistic = "phaseWrapped";
    metrics(11).wrappedField = "co2.phase.wrapped";
    metrics(11).coherenceField = "co2.coherence.partial";

    metrics(12) = metricTemplate;
    metrics(12).enabled = excelMetrics.miso.co2PhaseUnwrapped;
    metrics(12).sheetName = "MISO_CO2_PhaseU";
    metrics(12).modelName = "miso";
    metrics(12).field = "co2.phase.unwrapped";
    metrics(12).statistic = "phaseUnwrapped";
    metrics(12).wrappedField = "co2.phase.wrapped";
    metrics(12).coherenceField = "co2.coherence.partial";

    metrics(13) = metricTemplate;
    metrics(13).enabled = excelMetrics.miso.multipleCoherence;
    metrics(13).sheetName = "MISO_Multiple_Coh";
    metrics(13).modelName = "miso";
    metrics(13).field = "system.multipleCoherence";

    metrics(14) = metricTemplate;
    metrics(14).enabled = excelMetrics.miso.mapPartialCoherence;
    metrics(14).sheetName = "MISO_MAP_Partial_Coh";
    metrics(14).modelName = "miso";
    metrics(14).field = "map.coherence.partial";

    metrics(15) = metricTemplate;
    metrics(15).enabled = excelMetrics.miso.co2PartialCoherence;
    metrics(15).sheetName = "MISO_CO2_Partial_Coh";
    metrics(15).modelName = "miso";
    metrics(15).field = "co2.coherence.partial";

    metrics(16) = metricTemplate;
    metrics(16).enabled = excelMetrics.miso.unexplainedFraction;
    metrics(16).sheetName = "MISO_Unexplained";
    metrics(16).modelName = "miso";
    metrics(16).field = "system.unexplainedFraction";

    metrics(17) = metricTemplate;
    metrics(17).enabled = excelMetrics.miso.residualPower;
    metrics(17).sheetName = "MISO_Residual_Power";
    metrics(17).modelName = "miso";
    metrics(17).field = "system.residualPower";
    metrics(17).conversion = "powerToDb";

    metrics(18) = metricTemplate;
    metrics(18).enabled = excelMetrics.miso.conditionNumber;
    metrics(18).sheetName = "MISO_Condition_Number";
    metrics(18).modelName = "miso";
    metrics(18).field = "diagnostics.conditionNumber";

    %% SISO Metrics

    metrics(19) = metricTemplate;
    metrics(19).enabled = excelMetrics.siso.mapGain;
    metrics(19).sheetName = "SISO_MAP_Gain";
    metrics(19).modelName = "siso";
    metrics(19).field = "map.gain";

    metrics(20) = metricTemplate;
    metrics(20).enabled = excelMetrics.siso.mapPhaseWrapped;
    metrics(20).sheetName = "SISO_MAP_PhaseW";
    metrics(20).modelName = "siso";
    metrics(20).field = "map.phase.wrapped";
    metrics(20).statistic = "phaseWrapped";
    metrics(20).wrappedField = "map.phase.wrapped";
    metrics(20).coherenceField = "map.coherence.pairwise";

    metrics(21) = metricTemplate;
    metrics(21).enabled = excelMetrics.siso.mapPhaseUnwrapped;
    metrics(21).sheetName = "SISO_MAP_PhaseU";
    metrics(21).modelName = "siso";
    metrics(21).field = "map.phase.unwrapped";
    metrics(21).statistic = "phaseUnwrapped";
    metrics(21).wrappedField = "map.phase.wrapped";
    metrics(21).coherenceField = "map.coherence.pairwise";

    metrics(22) = metricTemplate;
    metrics(22).enabled = excelMetrics.siso.mapCoherence;
    metrics(22).sheetName = "SISO_MAP_Coh";
    metrics(22).modelName = "siso";
    metrics(22).field = "map.coherence.pairwise";

    metrics(23) = metricTemplate;
    metrics(23).enabled = excelMetrics.siso.mapUnexplainedFraction;
    metrics(23).sheetName = "SISO_MAP_Unexplained";
    metrics(23).modelName = "siso";
    metrics(23).field = "map.unexplainedFraction";

    metrics(24) = metricTemplate;
    metrics(24).enabled = excelMetrics.siso.mapResidualPower;
    metrics(24).sheetName = "SISO_MAP_Residual";
    metrics(24).modelName = "siso";
    metrics(24).field = "map.residualPower";
    metrics(24).conversion = "powerToDb";

    metrics(25) = metricTemplate;
    metrics(25).enabled = excelMetrics.siso.co2Gain;
    metrics(25).sheetName = "SISO_CO2_Gain";
    metrics(25).modelName = "siso";
    metrics(25).field = "co2.gain";

    metrics(26) = metricTemplate;
    metrics(26).enabled = excelMetrics.siso.co2PhaseWrapped;
    metrics(26).sheetName = "SISO_CO2_PhaseW";
    metrics(26).modelName = "siso";
    metrics(26).field = "co2.phase.wrapped";
    metrics(26).statistic = "phaseWrapped";
    metrics(26).wrappedField = "co2.phase.wrapped";
    metrics(26).coherenceField = "co2.coherence.pairwise";

    metrics(27) = metricTemplate;
    metrics(27).enabled = excelMetrics.siso.co2PhaseUnwrapped;
    metrics(27).sheetName = "SISO_CO2_PhaseU";
    metrics(27).modelName = "siso";
    metrics(27).field = "co2.phase.unwrapped";
    metrics(27).statistic = "phaseUnwrapped";
    metrics(27).wrappedField = "co2.phase.wrapped";
    metrics(27).coherenceField = "co2.coherence.pairwise";

    metrics(28) = metricTemplate;
    metrics(28).enabled = excelMetrics.siso.co2Coherence;
    metrics(28).sheetName = "SISO_CO2_Coh";
    metrics(28).modelName = "siso";
    metrics(28).field = "co2.coherence.pairwise";

    metrics(29) = metricTemplate;
    metrics(29).enabled = excelMetrics.siso.co2UnexplainedFraction;
    metrics(29).sheetName = "SISO_CO2_Unexplained";
    metrics(29).modelName = "siso";
    metrics(29).field = "co2.unexplainedFraction";

    metrics(30) = metricTemplate;
    metrics(30).enabled = excelMetrics.siso.co2ResidualPower;
    metrics(30).sheetName = "SISO_CO2_Residual";
    metrics(30).modelName = "siso";
    metrics(30).field = "co2.residualPower";
    metrics(30).conversion = "powerToDb";

    %% Keep Only Metrics That Can Be Exported

    keepMetric = false(numel(metrics), 1);

    for metricIndex = 1:numel(metrics)
        modelIsEnabled = ...
            metrics(metricIndex).modelName == "shared" || ...
            (metrics(metricIndex).modelName == "miso" && runMISO) || ...
            (metrics(metricIndex).modelName == "siso" && runSISO);

        keepMetric(metricIndex) = ...
            metrics(metricIndex).enabled && modelIsEnabled;
    end

    metrics = metrics(keepMetric);

end
