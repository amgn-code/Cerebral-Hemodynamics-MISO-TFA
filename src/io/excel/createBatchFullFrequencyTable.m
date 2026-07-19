function metricTable = createBatchFullFrequencyTable( ...
    groupModelResults, groupName, metric, ...
    frequencyBandEdgesHz, frequencyBandNames)
% createBatchFullFrequencyTable Build one batch full-frequency metric sheet.

    [metricResults, metricExists] = getNestedField( ...
        groupModelResults, char(metric.field));

    if ~metricExists
        metricTable = table();
        return
    end

    f = groupModelResults.f(:);
    band = getFrequencyBandLabels( ...
        f, frequencyBandEdgesHz, frequencyBandNames);
    subjectValues = metricResults.(metric.valuesField);
    metricMean = metricResults.(metric.meanField);
    metricSd = metricResults.(metric.sdField);

    metricTable = table(band, f, ...
        'VariableNames', {'Band', 'Frequency_Hz'});

    for subjectIndex = 1:numel(groupModelResults.subjectIds)
        subjectColumn = upper(groupName) + "_" + ...
            groupModelResults.subjectIds(subjectIndex);
        metricTable = addvars( ...
            metricTable, subjectValues(:,subjectIndex), ...
            'NewVariableNames', char(subjectColumn));
    end

    metricTable = addvars( ...
        metricTable, metricMean, metricSd, ...
        'NewVariableNames', {'Mean', 'SD'});

end
