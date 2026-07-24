function sheetCells = createExcelMetricSheet( ...
    subjectResults, groupName, metric, analysisSettings)
% createExcelMetricSheet Build one group's full and band metric sections.

    groupName = upper(string(groupName));

    %% Select Every Attempted Subject in the Group

    groupSubjects = cell(numel(subjectResults), 1);
    numGroupSubjects = 0;

    for subjectIndex = 1:numel(subjectResults)
        currentSubject = subjectResults{subjectIndex};

        if isempty(currentSubject)
            continue
        end

        subjectGroup = upper(string(currentSubject.subjectInfo.group));
        if subjectGroup ~= groupName
            continue
        end

        numGroupSubjects = numGroupSubjects + 1;
        groupSubjects{numGroupSubjects} = currentSubject;
    end

    groupSubjects = groupSubjects(1:numGroupSubjects);

    if numGroupSubjects == 0
        sheetCells = cell(0, 0);
        return
    end

    %% Select the Results Used by This Metric

    selectedModelResults = cell(numGroupSubjects, 1);
    subjectHeaders = strings(numGroupSubjects, 1);
    subjectErrors = strings(numGroupSubjects, 1);

    for subjectIndex = 1:numGroupSubjects
        currentSubject = groupSubjects{subjectIndex};
        subjectHeaders(subjectIndex) = groupName + " " + ...
            string(currentSubject.subjectInfo.subjectID);

        if metric.modelName == "miso"
            modelResults = currentSubject.misoResults;
        elseif metric.modelName == "siso"
            modelResults = currentSubject.sisoResults;
        elseif ~isempty(currentSubject.misoResults)
            modelResults = currentSubject.misoResults;
        else
            modelResults = currentSubject.sisoResults;
        end

        selectedModelResults{subjectIndex} = modelResults;

        if ~isempty(modelResults)
            continue
        end

        runStatus = currentSubject.runStatus;
        runStage = string(runStatus.runStage);

        if runStage == "TooShortForWelch"
            subjectErrors(subjectIndex) = ...
                "ERROR: Signal shorter than Welch window";
        elseif runStage == "LateCO2Startup"
            subjectErrors(subjectIndex) = ...
                "ERROR: CO2 stabilized too late for required Welch windows";
        elseif runStage == "InsufficientWelchWindows"
            subjectErrors(subjectIndex) = ...
                "ERROR: " + string(runStatus.numWelchWindows) + ...
                " Welch windows; minimum is " + ...
                string(runStatus.minimumWelchWindows);
        elseif runStage == "LoadDataFailed"
            subjectErrors(subjectIndex) = "ERROR: Data loading failed";
        elseif runStage == "PreprocessingFailed"
            subjectErrors(subjectIndex) = "ERROR: Preprocessing failed";
        elseif runStage == "WelchFailed"
            subjectErrors(subjectIndex) = ...
                "ERROR: Welch calculation failed";
        elseif runStage == "MISOFailed"
            subjectErrors(subjectIndex) = "ERROR: MISO analysis failed";
        elseif runStage == "SISOFailed"
            subjectErrors(subjectIndex) = "ERROR: SISO analysis failed";
        elseif runStatus.analysisSucceeded
            subjectErrors(subjectIndex) = ...
                "ERROR: " + upper(metric.modelName) + ...
                " results were not computed";
        else
            statusMessage = string(runStatus.statusMessage);
            statusMessage = erase(statusMessage, "Skipped: ");
            statusMessage = erase(statusMessage, "Failed: ");
            subjectErrors(subjectIndex) = "ERROR: " + statusMessage;
        end
    end

    %% Find the Shared Frequency Array

    frequencyHz = zeros(0, 1);

    for subjectIndex = 1:numGroupSubjects
        modelResults = selectedModelResults{subjectIndex};

        if isempty(modelResults)
            continue
        end

        frequencyHz = modelResults.f(:);
        break
    end

    numFrequencies = numel(frequencyHz);
    subjectValues = NaN(numFrequencies, numGroupSubjects);
    wrappedValues = NaN(numFrequencies, numGroupSubjects);
    coherenceValues = NaN(numFrequencies, numGroupSubjects);
    isPhase = metric.statistic == "phaseWrapped" || ...
        metric.statistic == "phaseUnwrapped";

    %% Collect Each Subject's Frequency Values

    for subjectIndex = 1:numGroupSubjects
        modelResults = selectedModelResults{subjectIndex};

        if isempty(modelResults)
            continue
        end

        subjectFrequencyHz = modelResults.f(:);

        if ~isequal(subjectFrequencyHz, frequencyHz)
            error( ...
                'TFA:InconsistentFrequencyBins', ...
                ['Subjects in one Excel sheet must use the same ' ...
                 'frequency bins.']);
        end

        fieldNames = split(metric.field, ".");
        metricValues = modelResults;

        for fieldIndex = 1:numel(fieldNames)
            fieldName = char(fieldNames(fieldIndex));

            if ~isstruct(metricValues) || ...
                    ~isfield(metricValues, fieldName)
                error( ...
                    'TFA:MissingExcelMetric', ...
                    'The result field "%s" is missing.', metric.field);
            end

            metricValues = metricValues.(fieldName);
        end

        metricValues = metricValues(:);

        if metric.conversion == "powerToDb"
            metricValues = powerToDb(metricValues);
        end

        subjectValues(:,subjectIndex) = metricValues;

        if ~isPhase
            continue
        end

        wrappedFieldNames = split(metric.wrappedField, ".");
        subjectWrappedValues = modelResults;

        for fieldIndex = 1:numel(wrappedFieldNames)
            fieldName = char(wrappedFieldNames(fieldIndex));
            subjectWrappedValues = subjectWrappedValues.(fieldName);
        end

        coherenceFieldNames = split(metric.coherenceField, ".");
        subjectCoherenceValues = modelResults;

        for fieldIndex = 1:numel(coherenceFieldNames)
            fieldName = char(coherenceFieldNames(fieldIndex));
            subjectCoherenceValues = subjectCoherenceValues.(fieldName);
        end

        wrappedValues(:,subjectIndex) = subjectWrappedValues(:);
        coherenceValues(:,subjectIndex) = subjectCoherenceValues(:);
    end

    %% Calculate Frequency-by-Frequency Group Statistics

    frequencyMean = NaN(numFrequencies, 1);
    frequencySd = NaN(numFrequencies, 1);

    if numFrequencies > 0
        if isPhase
            meanCoherence = mean(coherenceValues, 2, 'omitnan');
            phaseSummary = summarizeGroupPhase( ...
                wrappedValues, subjectValues, frequencyHz, ...
                meanCoherence, analysisSettings.phase);

            if metric.statistic == "phaseUnwrapped"
                frequencyMean = phaseSummary.unwrapped.mean;
                frequencySd = phaseSummary.unwrapped.sd;
            else
                frequencyMean = phaseSummary.wrapped.mean;
                frequencySd = phaseSummary.wrapped.sd;
            end
        else
            frequencySummary = summarizeGroupValues(subjectValues);
            frequencyMean = frequencySummary.mean;
            frequencySd = frequencySummary.sd;
        end
    end

    %% Calculate One Band Value Per Subject

    frequencyBandEdgesHz = analysisSettings.frequencyBandEdgesHz(:);
    frequencyBandNames = string( ...
        analysisSettings.frequencyBandNames(:));
    numBands = numel(frequencyBandNames);
    bandResults = calculateSubjectBandValues( ...
        frequencyHz, subjectValues, analysisSettings, ...
        metric.statistic, wrappedValues, coherenceValues);

    bandSubjectValues = bandResults.values;
    bandWrappedValues = bandResults.wrappedValues;
    bandUnwrappedValues = bandResults.unwrappedValues;
    bandCoherenceValues = bandResults.coherenceValues;
    bandCentersHz = bandResults.centersHz;

    %% Calculate Group Statistics Across Subject Band Values

    bandMean = NaN(numBands, 1);
    bandSd = NaN(numBands, 1);

    if numFrequencies > 0
        if isPhase
            meanBandCoherence = mean( ...
                bandCoherenceValues, 2, 'omitnan');
            bandPhaseSummary = summarizeGroupPhase( ...
                bandWrappedValues, bandUnwrappedValues, bandCentersHz, ...
                meanBandCoherence, analysisSettings.phase);

            if metric.statistic == "phaseUnwrapped"
                bandMean = bandPhaseSummary.unwrapped.mean;
                bandSd = bandPhaseSummary.unwrapped.sd;
            else
                bandMean = bandPhaseSummary.wrapped.mean;
                bandSd = bandPhaseSummary.wrapped.sd;
            end
        else
            bandSummary = summarizeGroupValues(bandSubjectValues);
            bandMean = bandSummary.mean;
            bandSd = bandSummary.sd;
        end
    end

    %% Build the Two Worksheet Sections

    numColumns = numGroupSubjects + 4;
    numFrequencyRows = max(numFrequencies, 1);
    frequencyHeaderRow = 1;
    frequencyFirstRow = 2;
    frequencyLastRow = frequencyFirstRow + numFrequencyRows - 1;
    bandTitleRow = frequencyLastRow + 2;
    bandHeaderRow = bandTitleRow + 1;
    bandFirstRow = bandHeaderRow + 1;
    totalRows = bandHeaderRow + numBands;

    sheetCells = repmat({""}, totalRows, numColumns);
    sheetCells{frequencyHeaderRow,1} = "Band";
    sheetCells{frequencyHeaderRow,2} = "Frequency_Hz";

    for subjectIndex = 1:numGroupSubjects
        subjectColumn = subjectIndex + 2;
        sheetCells{frequencyHeaderRow,subjectColumn} = ...
            subjectHeaders(subjectIndex);
    end

    meanColumn = numColumns - 1;
    sdColumn = numColumns;
    sheetCells{frequencyHeaderRow,meanColumn} = "Mean";
    sheetCells{frequencyHeaderRow,sdColumn} = "SD";

    if numFrequencies > 0
        bandLabels = getFrequencyBandLabels( ...
            frequencyHz, frequencyBandEdgesHz, frequencyBandNames);
        bandLabels(bandLabels == "") = "Outside Bands";

        for frequencyIndex = 1:numFrequencies
            outputRow = frequencyFirstRow + frequencyIndex - 1;
            sheetCells{outputRow,1} = bandLabels(frequencyIndex);
            sheetCells{outputRow,2} = frequencyHz(frequencyIndex);

            for subjectIndex = 1:numGroupSubjects
                value = subjectValues(frequencyIndex,subjectIndex);

                if isfinite(value)
                    sheetCells{outputRow,subjectIndex + 2} = value;
                end
            end

            if isfinite(frequencyMean(frequencyIndex))
                sheetCells{outputRow,meanColumn} = ...
                    frequencyMean(frequencyIndex);
            end

            if isfinite(frequencySd(frequencyIndex))
                sheetCells{outputRow,sdColumn} = ...
                    frequencySd(frequencyIndex);
            end
        end
    end

    for subjectIndex = 1:numGroupSubjects
        if strlength(subjectErrors(subjectIndex)) > 0
            sheetCells{frequencyFirstRow,subjectIndex + 2} = ...
                subjectErrors(subjectIndex);
        end
    end

    sheetCells{bandTitleRow,1} = "Band Averages";
    sheetCells{bandHeaderRow,1} = "Band";
    sheetCells{bandHeaderRow,2} = "Frequency_Range_Hz";

    for subjectIndex = 1:numGroupSubjects
        sheetCells{bandHeaderRow,subjectIndex + 2} = ...
            subjectHeaders(subjectIndex);
    end

    sheetCells{bandHeaderRow,meanColumn} = "Mean";
    sheetCells{bandHeaderRow,sdColumn} = "SD";

    for bandIndex = 1:numBands
        outputRow = bandFirstRow + bandIndex - 1;
        lowerFrequencyHz = frequencyBandEdgesHz(bandIndex);
        upperFrequencyHz = frequencyBandEdgesHz(bandIndex + 1);

        sheetCells{outputRow,1} = frequencyBandNames(bandIndex);

        if bandIndex == numBands
            sheetCells{outputRow,2} = sprintf( ...
                "%.3f-%.3f", lowerFrequencyHz, upperFrequencyHz);
        else
            sheetCells{outputRow,2} = sprintf( ...
                "%.3f-<%.3f", lowerFrequencyHz, upperFrequencyHz);
        end

        for subjectIndex = 1:numGroupSubjects
            value = bandSubjectValues(bandIndex,subjectIndex);

            if isfinite(value)
                sheetCells{outputRow,subjectIndex + 2} = value;
            end
        end

        if isfinite(bandMean(bandIndex))
            sheetCells{outputRow,meanColumn} = bandMean(bandIndex);
        end

        if isfinite(bandSd(bandIndex))
            sheetCells{outputRow,sdColumn} = bandSd(bandIndex);
        end
    end

end
