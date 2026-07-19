function metricTable = createBatchBandMetricTable( ...
    subjectResults, groupName, modelName, metric, ...
    frequencyBandEdgesHz, frequencyBandNames, phaseSettings)
% createBatchBandMetricTable Build one batch band-average metric sheet.

    includedSubjects = cell(numel(subjectResults), 1);
    numIncludedSubjects = 0;

    for k = 1:numel(subjectResults)
        if isempty(subjectResults{k}) || ...
                ~subjectResults{k}.runStatus.analysisSucceeded || ...
                string(subjectResults{k}.subjectInfo.group) ~= groupName
            continue
        end

        if modelName == "miso"
            modelResults = subjectResults{k}.tfaResults;
        else
            modelResults = subjectResults{k}.sisoResults;
        end

        if isempty(modelResults)
            continue
        end

        numIncludedSubjects = numIncludedSubjects + 1;
        includedSubjects{numIncludedSubjects} = subjectResults{k};
    end

    includedSubjects = includedSubjects(1:numIncludedSubjects);

    if isempty(includedSubjects)
        metricTable = table();
        return
    end

    numBands = numel(frequencyBandNames);
    subjectValues = NaN(numBands, numIncludedSubjects);
    wrappedValues = NaN(numBands, numIncludedSubjects);
    coherenceValues = NaN(numBands, numIncludedSubjects);
    subjectIds = strings(numIncludedSubjects, 1);

    for subjectIndex = 1:numIncludedSubjects
        subjectResult = includedSubjects{subjectIndex};
        subjectIds(subjectIndex) = string( ...
            subjectResult.subjectInfo.subjectID);

        if modelName == "miso"
            bandAverages = subjectResult.tfaResults.bandAverages;
        else
            bandAverages = subjectResult.sisoResults.bandAverages;
        end

        for bandIndex = 1:numBands
            rowIndex = find( ...
                string(bandAverages.Band) == frequencyBandNames(bandIndex), ...
                1);

            if isempty(rowIndex)
                continue
            end

            subjectValues(bandIndex,subjectIndex) = ...
                bandAverages.(metric.field)(rowIndex);

            if metric.isPhase
                wrappedValues(bandIndex,subjectIndex) = ...
                    bandAverages.(metric.wrappedField)(rowIndex);
                coherenceValues(bandIndex,subjectIndex) = ...
                    bandAverages.(metric.coherenceField)(rowIndex);
            end
        end
    end

    if metric.isPhase
        bandCenters = mean( ...
            [frequencyBandEdgesHz(1:end - 1), ...
             frequencyBandEdgesHz(2:end)], 2);
        coherenceMean = mean(coherenceValues, 2, 'omitnan');
        phaseSummary = summarizeGroupPhase( ...
            wrappedValues, subjectValues, bandCenters, ...
            coherenceMean, phaseSettings);

        if metric.unwrapMean
            metricMean = phaseSummary.unwrapped.mean;
            metricSd = phaseSummary.unwrapped.sd;
        else
            metricMean = phaseSummary.wrapped.mean;
            metricSd = phaseSummary.wrapped.sd;
        end
    else
        metricSummary = summarizeGroupValues(subjectValues);
        metricMean = metricSummary.mean;
        metricSd = metricSummary.sd;
    end

    metricTable = table(frequencyBandNames(:), ...
        'VariableNames', {'Band'});

    for subjectIndex = 1:numIncludedSubjects
        subjectColumn = upper(groupName) + "_" + subjectIds(subjectIndex);
        metricTable = addvars( ...
            metricTable, subjectValues(:,subjectIndex), ...
            'NewVariableNames', char(subjectColumn));
    end

    metricTable = addvars( ...
        metricTable, metricMean, metricSd, ...
        'NewVariableNames', {'Mean', 'SD'});

end
