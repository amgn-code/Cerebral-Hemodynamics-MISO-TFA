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
        tableResults.simulationSummary = createSimulationSummary( ...
            paperResults.simulation.trials);
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
    savedFiles = strings(0, 1);
    for tableIndex = 1:numel(tableNames)
        tableName = tableNames{tableIndex};
        currentTable = tableResults.(tableName);
        if ~istable(currentTable) || isempty(currentTable)
            continue
        end

        csvFile = fullfile( ...
            tableFolder, lower(string(tableName)) + ".csv");
        writetable(currentTable, csvFile);
        savedFiles(end + 1,1) = string(csvFile);

        sheetName = string(tableName);
        if strlength(sheetName) > 31
            sheetName = extractBefore(sheetName, 32);
        end
        writetable(currentTable, workbookFile, "Sheet", sheetName);
    end

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
        "Input correlation"
        "CO2 input SD"
        "CO2 pathway scale"
        "Output SNR (dB)"
        "Duration (s)"
        "CO2 delay (s)"
        "Misspecification strength"
        "Ridge lambda"
        "Replicates"];
    values = [ ...
        join(string(settings.inputCorrelations), ", ")
        join(string(settings.co2InputSds), ", ")
        join(string(settings.co2PathwayScales), ", ")
        join(string(settings.outputSnrDb), ", ")
        join(string(settings.durationSeconds), ", ")
        join(string(settings.co2DelaysSeconds), ", ")
        join(string(settings.misspecificationStrengths), ", ")
        join(string(settings.ridgeLambdas), ", ")
        string(settings.numReplicates)];
    factorTable = table(factor, values, ...
        'VariableNames', {'Factor', 'Values'});

end

function summaryTable = createSimulationSummary(trials)
% createSimulationSummary Average main errors by estimator and pathway.

    data = trials;
    lambdaLabel = repmat("Not applicable", height(data), 1);
    hasLambda = isfinite(data.Lambda);
    lambdaLabel(hasLambda) = string(data.Lambda(hasLambda));
    data.LambdaLabel = lambdaLabel;

    summaryTable = groupsummary( ...
        data, {'Estimator', 'LambdaLabel', 'Pathway'}, ...
        {'mean', 'median'}, ...
        {'NormalizedComplexError', ...
         'OutOfSampleNormalizedError', ...
         'MedianNormalizedConditionNumber'});

end
