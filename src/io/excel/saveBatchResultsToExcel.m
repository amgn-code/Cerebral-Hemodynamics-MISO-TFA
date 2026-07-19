function saveBatchResultsToExcel( ...
    filename, statusTable, subjectResults, groupResults, ...
    analysisSettings, outputSettings)
% saveBatchResultsToExcel Write the batch results workbook.

    if exist(filename, "file")
        delete(filename);
    end

    writetable(statusTable, filename, "Sheet", "Run_Status");

    bandSummaryTable = createBatchBandSummaryTable(subjectResults);

    if ~isempty(bandSummaryTable)
        writetable(bandSummaryTable, filename, "Sheet", "Band_Averages");
    end

    groupNames = string(fieldnames(groupResults));

    for groupIndex = 1:numel(groupNames)
        groupName = groupNames(groupIndex);
        modelNames = string(fieldnames(groupResults.(groupName)));

        for modelIndex = 1:numel(modelNames)
            modelName = modelNames(modelIndex);
            modelResults = groupResults.(groupName).(modelName);

            if outputSettings.saveFullFrequencyData
                fullMetrics = batchMetricDefinitions(modelName, "full");

                for metricIndex = 1:numel(fullMetrics)
                    metric = fullMetrics(metricIndex);
                    metricTable = createBatchFullFrequencyTable( ...
                        modelResults, groupName, metric, ...
                        analysisSettings.frequencyBandEdgesHz, ...
                        analysisSettings.frequencyBandNames);
                    sheetName = "FF_" + upper(modelName) + "_" + ...
                        groupName + "_" + metric.name;
                    writetable(metricTable, filename, "Sheet", sheetName);
                end
            end

            bandMetrics = batchMetricDefinitions(modelName, "band");

            for metricIndex = 1:numel(bandMetrics)
                metric = bandMetrics(metricIndex);
                metricTable = createBatchBandMetricTable( ...
                    subjectResults, groupName, modelName, metric, ...
                    analysisSettings.frequencyBandEdgesHz, ...
                    analysisSettings.frequencyBandNames, ...
                    analysisSettings.phase);
                sheetName = "BA_" + upper(modelName) + "_" + ...
                    groupName + "_" + metric.name;
                writetable(metricTable, filename, "Sheet", sheetName);
            end
        end
    end

    definitionsTable = createMetricDefinitionsTable();
    writetable(definitionsTable, filename, "Sheet", "Metric_Definitions");

end
