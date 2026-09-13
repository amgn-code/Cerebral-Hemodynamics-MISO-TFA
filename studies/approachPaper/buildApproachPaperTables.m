function tableResults = buildApproachPaperTables( ...
    paperResults, outputFolder)
% buildApproachPaperTables Create manuscript-ready CSV and Excel tables.

    tableFolder = fullfile(outputFolder, "Tables");
    if ~exist(tableFolder, "dir")
        mkdir(tableFolder);
    end
    workbookFile = fullfile(tableFolder, "approach_paper_tables.xlsx");
    if exist(workbookFile, "file")
        delete(workbookFile);
    end

    tableResults = struct();

    if isfield(paperResults, "empirical") && ...
            ~isempty(fieldnames(paperResults.empirical))
        statistics = paperResults.empirical.statisticalResults;
        tableResults.participantCharacteristics = ...
            statistics.participantCharacteristics;
        tableResults.modelComparisons = ...
            statistics.modelComparisons;
        if isfield(statistics, "frequencyModelComparisons") && ...
                ~isempty(statistics.frequencyModelComparisons)
            phaseRows = statistics.frequencyModelComparisons.Metric == ...
                "Phase";
            tableResults.frequencyPhaseComparisons = ...
                statistics.frequencyModelComparisons(phaseRows, :);
        end
        tableResults.solverDiagnostics = createSolverDiagnosticTable( ...
            paperResults.empirical.groupResults);
    end

    if isfield(paperResults, "simulation") && ...
            ~isempty(fieldnames(paperResults.simulation))
        tableResults.simulationFactors = createSimulationFactorTable( ...
            paperResults.simulation.settings);
        tableResults.simulationFamilyDesign = ...
            paperResults.simulation.familyDesign;
        tableResults.simulationObservationPlan = ...
            paperResults.simulation.observationPlan;
        tableResults.simulationSummary = createSimulationSummary( ...
            paperResults.simulation.observations);
        tableResults.simulationReferenceStatistics = ...
            createSimulationReferenceStatistics( ...
                paperResults.simulation);
        if ~isempty(paperResults.simulation.ridge)
            tableResults.simulationRidge = ...
                paperResults.simulation.ridge;
        end
        if isfield(paperResults.simulation, "estimatorSettings") && ...
                ~isempty(paperResults.simulation.estimatorSettings)
            tableResults.simulationEstimatorSettings = ...
                paperResults.simulation.estimatorSettings;
        end
        if isfield(paperResults, "simulationAudit") && ...
                ~isempty(fieldnames(paperResults.simulationAudit))
            audit = paperResults.simulationAudit;
            tableResults.simulationAuditOverview = audit.overview;
            tableResults.simulationMarginalBalance = ...
                audit.marginalBalance;
            tableResults.simulationPairwiseBalance = ...
                audit.pairwiseBalance;
            tableResults.simulationRealizedBinOccupancy = ...
                audit.realizedBinOccupancy;
            tableResults.simulationRealizedPairOccupancy = ...
                audit.realizedPairOccupancy;
            tableResults.simulationValidityAudit = audit.validity;
            tableResults.simulationCheckpointStability = ...
                audit.stability;
        end
    end

    if isfield(paperResults, "robustness") && ...
            ~isempty(fieldnames(paperResults.robustness))
        tableResults.influence = paperResults.robustness.influence;
        tableResults.robustnessRunLog = ...
            paperResults.robustness.subjectRunLog;
        tableResults.sensitivityRunLog = ...
            paperResults.robustness.sensitivityRunLog;
    end

    tableNames = fieldnames(tableResults);
    savedFiles = strings(numel(tableNames), 1);
    numSavedFiles = 0;
    for tableIndex = 1:numel(tableNames)
        tableName = tableNames{tableIndex};
        currentTable = tableResults.(tableName);
        if ~istable(currentTable) || isempty(currentTable)
            continue
        end

        csvFile = fullfile( ...
            tableFolder, lower(string(tableName)) + ".csv");
        writetable(currentTable, csvFile);
        numSavedFiles = numSavedFiles + 1;
        savedFiles(numSavedFiles) = string(csvFile);

        sheetName = string(tableName);
        if strlength(sheetName) > 31
            sheetName = extractBefore(sheetName, 32);
        end
        writetable(currentTable, workbookFile, "Sheet", sheetName);
    end
    savedFiles = savedFiles(1:numSavedFiles);

    tableResults.savedFiles = savedFiles;
    tableResults.workbookFile = string(workbookFile);

end

function diagnosticTable = createSolverDiagnosticTable(groupResults)
% createSolverDiagnosticTable Summarize identifiability for each NC subject.

    if ~isfield(groupResults, "NC") || ...
            ~isfield(groupResults.NC, "miso")
        diagnosticTable = table();
        return
    end

    miso = groupResults.NC.miso;
    subjectIds = miso.subjectIds(:);
    medianRawConditionNumber = median( ...
        miso.diagnostics.conditionNumber.values, 1, "omitnan")';
    medianNormalizedConditionNumber = median( ...
        miso.diagnostics.normalizedConditionNumber.values, ...
        1, "omitnan")';
    medianNormalizedDeterminant = median( ...
        miso.diagnostics.normalizedDeterminant.values, ...
        1, "omitnan")';
    poorlyConditionedFraction = mean( ...
        miso.diagnostics.isPoorlyConditioned.values, 1, "omitnan")';
    medianInputCoherence = median( ...
        miso.inputRelationship.coherence.values, 1, "omitnan")';

    diagnosticTable = table( ...
        subjectIds, medianRawConditionNumber, ...
        medianNormalizedConditionNumber, ...
        medianNormalizedDeterminant, poorlyConditionedFraction, ...
        medianInputCoherence, ...
        'VariableNames', { ...
            'SubjectID', 'MedianRawConditionNumber', ...
            'MedianNormalizedConditionNumber', ...
            'MedianNormalizedDeterminant', ...
            'PoorlyConditionedFrequencyFraction', ...
            'MedianInputCoherence'});

end

function factorTable = createSimulationFactorTable(settings)
% createSimulationFactorTable Save every varied simulation factor.

    factor = [ ...
        "Number of families"
        "Target coherence values"
        "Spectral similarity values"
        "PETCO2-to-MAP fluctuation SD ratios"
        "PETCO2-to-MAP band-gain ratios"
        "PETCO2 pathway delay values (s)"
        "Output SNR (dB)"
        "Standard duration (s)"
        "Duration (s)"
        "Input-noise SNR (dB)"
        "Alignment error (s)"
        "Ridge lambda"
        "Primary Welch window (s)"
        "Sensitivity Welch windows (s)"
        "Sensitivity Welch overlaps"
        "Simulation inference alpha"
        "Minimum valid families for inference"
        "Frequency/cell multiple-testing method"];
    values = [ ...
        string(settings.families.numFamilies)
        formatSettingValues( ...
            settings.families.targetCoherenceValues)
        formatSettingValues( ...
            settings.families.spectralSimilarityValues)
        formatSettingValues(settings.families. ...
            petco2ToMapFluctuationSdRatioValues)
        formatSettingValues(settings.families. ...
            petco2ToMapBandGainRatioValues)
        formatSettingValues( ...
            settings.families.co2DelaySecondsValues)
        formatSettingValues(settings.observations.outputSnrDb)
        string(settings.observations.referenceDurationSeconds)
        formatSettingValues(settings.observations.durationSeconds)
        formatSettingValues(settings.observations.inputNoiseSnrDb)
        formatSettingValues( ...
            settings.observations.alignmentErrorSeconds)
        formatSettingValues(settings.estimators.ridgeLambdas)
        string(settings.welch.windowLengthSeconds)
        formatSettingValues(settings.estimatorSensitivity. ...
            windowLengthSeconds)
        formatSettingValues(settings.estimatorSensitivity. ...
            windowOverlap)
        string(settings.statistics.alpha)
        string(settings.statistics.minimumValidN)
        string(settings.statistics.multipleTestingMethod)];
    factorTable = table(factor, values, ...
        'VariableNames', {'Factor', 'Values'});

end

function valueText = formatSettingValues(values)
% formatSettingValues Convert scalar, vector, or empty settings to one row.

    if isempty(values)
        valueText = "None";
    else
        valueText = join(string(values(:)), ", ");
    end

end

function summaryTable = createSimulationSummary(observations)
% createSimulationSummary Summarize errors and advantage by experiment.

    summaryTable = groupsummary( ...
        observations, "Experiment", {'mean', 'std'}, ...
        {'MAPSISOComplexError', 'MAPMISOComplexError', ...
         'MAPComplexAdvantage', 'CO2SISOComplexError', ...
         'CO2MISOComplexError', 'CO2ComplexAdvantage', ...
         'MapSISOPredictionError', 'MISOPredictionError', ...
         'PredictionAdvantage', ...
         'MedianNormalizedConditionNumber'});

end
