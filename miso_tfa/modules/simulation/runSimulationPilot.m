function pilot = runSimulationPilot(repetitionsPerCondition, outputSettings)
% runSimulationPilot Run the frozen simple design and quantify MC precision.
%
% The pilot is deliberately a wrapper around the same simulation runner used
% for the final study. It changes only the number of independent families
% per 3-by-3 core condition, then estimates the Monte Carlo uncertainty of
% the primary MAP truth-recovery advantage from paired bootstrap resamples.
% The projected repetition count is a planning result, not a post-hoc
% change to the scientific factor grid.

    if nargin < 1 || isempty(repetitionsPerCondition)
        repetitionsPerCondition = 20;
    end
    validateattributes(repetitionsPerCondition, {'numeric'}, ...
        {'scalar', 'integer', 'positive', 'finite'});

    if nargin < 2 || isempty(outputSettings)
        outputSettings = defaultSimulationOutputSettings("off");
        outputSettings.createFigures = false;
        outputSettings.savePng = false;
        outputSettings.saveCsv = false;
        outputSettings.saveMat = false;
    else
        outputSettings = completeSimulationOutputSettings(outputSettings);
    end

    settings = defaultKnownTruthSimulationSettings("simple");
    settings.families.repetitionsPerCondition = repetitionsPerCondition;
    simulationResults = runKnownTruthSimulationGrid(settings);
    outputs = createSimulationOutputs(simulationResults, outputSettings);

    primaryMaps = outputs.primaryMaps;
    numPrimaryMaps = numel(primaryMaps);
    worstRows = repmat(emptyPrecisionRow(), numPrimaryMaps, 1);
    for mapIndex = 1:numPrimaryMaps
        source = primaryMaps(mapIndex).frequencyTable;
        valid = isfinite(source.BootstrapSD) & source.PairedValidN >= ...
            settings.grouping.minimumValidN;
        if ~any(valid)
            continue
        end

        candidateRows = source(valid, :);
        [~, rowIndex] = max(candidateRows.BootstrapSD);
        selected = candidateRows(rowIndex, :);
        worstRows(mapIndex).Factor = primaryMaps(mapIndex).variableName;
        worstRows(mapIndex).FactorLabel = primaryMaps(mapIndex).label;
        worstRows(mapIndex).FactorGroup = selected.FactorGroup;
        worstRows(mapIndex).FrequencyHz = selected.FrequencyHz;
        worstRows(mapIndex).PairedValidN = selected.PairedValidN;
        worstRows(mapIndex).BootstrapSD = selected.BootstrapSD;
        worstRows(mapIndex).CurrentRepetitions = repetitionsPerCondition;
        targetSE = settings.production.targetMonteCarloSE;
        worstRows(mapIndex).TargetStandardError = targetSE;
        worstRows(mapIndex).ProjectedRepetitions = projectRepetitions( ...
            repetitionsPerCondition, selected.BootstrapSD, targetSE);
    end

    precisionTable = struct2table(worstRows);
    finiteProjection = precisionTable.ProjectedRepetitions(isfinite( ...
        precisionTable.ProjectedRepetitions));
    if isempty(finiteProjection)
        projected = NaN;
    else
        projected = max(finiteProjection);
    end

    pilot.simulation = simulationResults;
    pilot.outputs = outputs;
    pilot.settings = settings;
    pilot.precisionTable = precisionTable;
    pilot.targetStandardError = settings.production.targetMonteCarloSE;
    pilot.projectedRepetitionsPerCondition = projected;
    pilot.scoreVersion = "frequency-ratio-of-mean-errors-v1";
    pilot.interpretation = ...
        "Projected repetition count uses the noisiest primary MAP cell " + ...
        "and assumes Monte Carlo standard error decreases as 1/sqrt(R).";

end

function projected = projectRepetitions(current, observedSD, targetSD)
% projectRepetitions Solve the 1/sqrt(R) precision planning relation.

    if ~isfinite(observedSD) || observedSD <= 0
        projected = current;
        return
    end
    projected = ceil(current*(observedSD/targetSD)^2);

end

function row = emptyPrecisionRow()
% emptyPrecisionRow Define the stable planning table schema.

    row = struct( ...
        'Factor', "", ...
        'FactorLabel', "", ...
        'FactorGroup', "", ...
        'FrequencyHz', NaN, ...
        'PairedValidN', NaN, ...
        'BootstrapSD', NaN, ...
        'CurrentRepetitions', NaN, ...
        'TargetStandardError', NaN, ...
        'ProjectedRepetitions', NaN);

end
