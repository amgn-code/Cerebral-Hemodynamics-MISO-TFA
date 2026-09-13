function audit = auditApproachPaperSimulation(simulation)
% auditApproachPaperSimulation Audit a completed known-truth simulation.
%
% The audit separates design checks from descriptive coverage checks. A
% sparse realized-value cell is reported, but it is not treated as a design
% failure because realized characteristics are not assigned factor levels.

    validateSimulationStructure(simulation);

    settings = simulation.settings;
    design = simulation.familyDesign;
    observations = simulation.observations;
    familyRows = selectFamilyCharacterizationRows(observations);

    audit.profileName = string(settings.profileName);
    audit.evidenceLevel = describeEvidenceLevel(audit.profileName);
    audit.elapsedSeconds = getStoredScalar(simulation, ...
        "elapsedSeconds", NaN);
    audit.marginalBalance = createMarginalBalanceTable(design);
    audit.pairwiseBalance = createPairwiseBalanceTable( ...
        design, settings);
    audit.realizedBinOccupancy = createRealizedBinOccupancyTable( ...
        familyRows, settings.grouping);
    audit.realizedPairOccupancy = ...
        createRealizedPairOccupancyTable( ...
            familyRows, settings.grouping);
    audit.validity = createObservationValidityTable( ...
        observations, simulation.observationPlan, ...
        settings.grouping.minimumValidN);
    audit.stability = createCheckpointStabilityTable( ...
        observations, design, settings.grouping.minimumValidN);
    audit.overview = createOverviewTable(simulation, audit);
    audit.allCoreChecksPass = all(audit.overview.Pass);

end

function validateSimulationStructure(simulation)
% validateSimulationStructure Give a clear error for incomplete inputs.

    requiredFields = [ ...
        "settings"
        "familyDesign"
        "observationPlan"
        "observations"
        "ridge"
        "estimatorSettings"];
    missingFields = requiredFields(~isfield(simulation, requiredFields));
    if ~isempty(missingFields)
        error( ...
            "TFA:IncompleteSimulationAuditInput", ...
            "Simulation audit input is missing: " + ...
                join(missingFields, ", "));
    end

end

function overview = createOverviewTable(simulation, audit)
% createOverviewTable Summarize checks that must pass before interpretation.

    settings = simulation.settings;
    design = simulation.familyDesign;
    observationPlan = simulation.observationPlan;
    observations = simulation.observations;
    configuredFamilies = settings.families.numFamilies;
    actualFamilies = height(design);
    actualPlans = height(observationPlan);
    expectedObservations = actualFamilies*actualPlans;
    actualObservations = height(observations);
    expectedRidgeRows = actualFamilies* ...
        numel(settings.estimators.ridgeLambdas);
    actualRidgeRows = height(simulation.ridge);
    expectedEstimatorRows = actualFamilies* ...
        getEstimatorRowsPerFamily(settings);
    actualEstimatorRows = height(simulation.estimatorSettings);
    designMode = lower(string(settings.families.designMode));
    completeBlocks = designMode ~= "pairwisefivelevel" || ...
        (mod(actualFamilies, 25) == 0 && ...
         numel(unique(design.DesignBlockID)) == actualFamilies/25);
    marginalPass = all(audit.marginalBalance.Pass);
    pairwisePass = isempty(audit.pairwiseBalance) || ...
        all(audit.pairwiseBalance.Pass);
    validityPass = isempty(audit.validity) || ...
        all(audit.validity.MeetsMinimumN);
    stabilityPass = isempty(audit.stability) || ...
        all(audit.stability.MeetsMinimumN);
    familyRows = selectFamilyCharacterizationRows(observations);

    check = [ ...
        "Named analysis profile"
        "Configured family count"
        "Stored family count"
        "One characterization row per family"
        "Complete pairwise design blocks"
        "Assigned marginal balance"
        "Assigned pairwise balance"
        "Primary observation count"
        "Stored primary observation count"
        "Ridge-analysis count"
        "Estimator-sensitivity count"
        "Minimum valid N by observation condition"
        "Minimum valid N at stability checkpoints"
        "Elapsed time recorded"];
    observed = [ ...
        string(settings.profileName)
        string(actualFamilies)
        string(getStoredScalar(simulation, "numFamilies", NaN))
        string(height(familyRows))
        describeBlockCount(design, designMode)
        describePassCount(audit.marginalBalance.Pass)
        describePassCount(audit.pairwiseBalance.Pass)
        string(actualObservations)
        string(getStoredScalar(simulation, "numObservations", NaN))
        string(actualRidgeRows)
        string(actualEstimatorRows)
        describePassCount(audit.validity.MeetsMinimumN)
        describePassCount(audit.stability.MeetsMinimumN)
        compose("%.3f s", audit.elapsedSeconds)];
    expected = [ ...
        "quick, designSmoke, proof250, or paper1000"
        string(configuredFamilies)
        string(actualFamilies)
        string(actualFamilies)
        describeExpectedBlocks(actualFamilies, designMode)
        "all factor levels"
        "all factor-level pairs"
        string(expectedObservations)
        string(actualObservations)
        string(expectedRidgeRows)
        string(expectedEstimatorRows)
        "all planned metric-condition groups"
        "all checkpoint metrics"
        "positive finite duration"];
    pass = [ ...
        ismember(lower(string(settings.profileName)), ...
            ["quick" "designsmoke" "proof250" "paper1000"])
        actualFamilies == configuredFamilies
        getStoredScalar(simulation, "numFamilies", NaN) == ...
            actualFamilies
        height(familyRows) == actualFamilies
        completeBlocks
        marginalPass
        pairwisePass
        actualObservations == expectedObservations
        getStoredScalar(simulation, "numObservations", NaN) == ...
            actualObservations
        actualRidgeRows == expectedRidgeRows
        actualEstimatorRows == expectedEstimatorRows
        validityPass
        stabilityPass
        isfinite(audit.elapsedSeconds) && audit.elapsedSeconds > 0];
    notes = [ ...
        audit.evidenceLevel
        "The named profile controls the intended family count."
        "The saved scalar agrees with the family-design table."
        "Realized characteristics come from the long clean record."
        "Each complete block contains 25 families."
        "Every assigned level must have equal support."
        "Every assigned 5-by-5 pair must have equal support."
        "Every family receives every paired observation plan."
        "The saved scalar agrees with the observation table."
        "One ridge row is expected per family and lambda."
        "Counts include window, overlap, and duration-by-window sweeps."
        "This is a support check, not a claim of statistical precision."
        "Checkpoints retain complete balanced design blocks."
        "Elapsed time supports planning for the final paper run."];

    overview = table( ...
        check, observed, expected, logical(pass), notes, ...
        'VariableNames', { ...
            'Check', 'Observed', 'Expected', 'Pass', 'Notes'});

end

function balance = createMarginalBalanceTable(design)
% createMarginalBalanceTable Count each level of every assigned factor.

    [levelNames, valueNames, labels] = getAssignedFactorMetadata();
    numFactors = numel(levelNames);
    tableParts = cell(numFactors, 1);
    for factorIndex = 1:numFactors
        levels = design.(levelNames(factorIndex));
        values = design.(valueNames(factorIndex));
        uniqueLevels = unique(levels, "sorted");
        numLevels = numel(uniqueLevels);
        expectedN = height(design)/numLevels;
        observedN = zeros(numLevels, 1);
        assignedValue = zeros(numLevels, 1);
        for levelIndex = 1:numLevels
            rows = levels == uniqueLevels(levelIndex);
            observedN(levelIndex) = nnz(rows);
            levelValues = unique(values(rows), "stable");
            assignedValue(levelIndex) = levelValues(1);
        end
        factor = repmat(labels(factorIndex), numLevels, 1);
        expected = repmat(expectedN, numLevels, 1);
        pass = observedN == expected;
        tableParts{factorIndex} = table( ...
            factor, uniqueLevels, assignedValue, observedN, ...
            expected, pass, ...
            'VariableNames', { ...
                'Factor', 'LevelIndex', 'AssignedValue', ...
                'ObservedN', 'ExpectedN', 'Pass'});
    end
    balance = vertcat(tableParts{:});

end

function balance = createPairwiseBalanceTable(design, settings)
% createPairwiseBalanceTable Count every assigned factor-level pair.

    if lower(string(settings.families.designMode)) ~= ...
            "pairwisefivelevel"
        balance = emptyPairwiseBalanceTable();
        return
    end

    [levelNames, ~, labels] = getAssignedFactorMetadata();
    factorPairs = nchoosek(1:numel(levelNames), 2);
    tableParts = cell(size(factorPairs, 1), 1);
    for pairIndex = 1:size(factorPairs, 1)
        xIndex = factorPairs(pairIndex, 1);
        yIndex = factorPairs(pairIndex, 2);
        xLevels = unique(design.(levelNames(xIndex)), "sorted");
        yLevels = unique(design.(levelNames(yIndex)), "sorted");
        expectedN = height(design)/(numel(xLevels)*numel(yLevels));
        [xGrid, yGrid] = ndgrid(xLevels, yLevels);
        observedN = zeros(numel(xGrid), 1);
        for cellIndex = 1:numel(xGrid)
            observedN(cellIndex) = nnz( ...
                design.(levelNames(xIndex)) == xGrid(cellIndex) & ...
                design.(levelNames(yIndex)) == yGrid(cellIndex));
        end
        factorX = repmat(labels(xIndex), numel(xGrid), 1);
        factorY = repmat(labels(yIndex), numel(xGrid), 1);
        expected = repmat(expectedN, numel(xGrid), 1);
        pass = observedN == expected;
        tableParts{pairIndex} = table( ...
            factorX, factorY, xGrid(:), yGrid(:), observedN, ...
            expected, pass, ...
            'VariableNames', { ...
                'FactorX', 'FactorY', 'XLevelIndex', ...
                'YLevelIndex', 'ObservedN', 'ExpectedN', 'Pass'});
    end
    balance = vertcat(tableParts{:});

end

function occupancy = createRealizedBinOccupancyTable( ...
    familyRows, grouping)
% createRealizedBinOccupancyTable Count families in fixed display bins.

    [fields, labels, edgeFields] = getRealizedFactorMetadata();
    numFactors = numel(fields);
    tableParts = cell(numFactors, 1);
    for factorIndex = 1:numFactors
        values = familyRows.(fields(factorIndex));
        edges = double(grouping.(edgeFields(factorIndex)));
        groups = discretize(values, edges);
        numBins = numel(edges) - 1;
        familyN = zeros(numBins, 1);
        for binIndex = 1:numBins
            familyN(binIndex) = nnz(groups == binIndex);
        end
        characteristic = repmat(labels(factorIndex), numBins, 1);
        field = repmat(fields(factorIndex), numBins, 1);
        lowerEdge = edges(1:end-1)';
        upperEdge = edges(2:end)';
        interval = composeIntervals(lowerEdge, upperEdge);
        percent = 100*familyN/height(familyRows);
        displayMinimumN = repmat( ...
            grouping.minimumValidN, numBins, 1);
        meetsDisplayMinimum = familyN >= displayMinimumN;
        nonfiniteN = repmat(nnz(~isfinite(values)), numBins, 1);
        outsideRangeN = repmat(nnz( ...
            isfinite(values) & isnan(groups)), numBins, 1);
        tableParts{factorIndex} = table( ...
            characteristic, field, (1:numBins)', lowerEdge, ...
            upperEdge, interval, familyN, percent, displayMinimumN, ...
            meetsDisplayMinimum, nonfiniteN, outsideRangeN, ...
            'VariableNames', { ...
                'Characteristic', 'Field', 'BinIndex', 'LowerEdge', ...
                'UpperEdge', 'Interval', 'FamilyN', 'Percent', ...
                'DisplayMinimumN', 'MeetsDisplayMinimum', ...
                'NonfiniteN', 'OutsideRangeN'});
    end
    occupancy = vertcat(tableParts{:});

end

function occupancy = createRealizedPairOccupancyTable( ...
    familyRows, grouping)
% createRealizedPairOccupancyTable Count joint fixed-bin support.

    [fields, labels, edgeFields] = getRealizedFactorMetadata();
    factorPairs = nchoosek(1:numel(fields), 2);
    tableParts = cell(size(factorPairs, 1), 1);
    for pairIndex = 1:size(factorPairs, 1)
        xIndex = factorPairs(pairIndex, 1);
        yIndex = factorPairs(pairIndex, 2);
        xEdges = double(grouping.(edgeFields(xIndex)));
        yEdges = double(grouping.(edgeFields(yIndex)));
        xGroups = discretize(familyRows.(fields(xIndex)), xEdges);
        yGroups = discretize(familyRows.(fields(yIndex)), yEdges);
        [xGrid, yGrid] = ndgrid( ...
            1:(numel(xEdges) - 1), 1:(numel(yEdges) - 1));
        familyN = zeros(numel(xGrid), 1);
        for cellIndex = 1:numel(xGrid)
            familyN(cellIndex) = nnz( ...
                xGroups == xGrid(cellIndex) & ...
                yGroups == yGrid(cellIndex));
        end
        xCharacteristic = repmat( ...
            labels(xIndex), numel(xGrid), 1);
        yCharacteristic = repmat( ...
            labels(yIndex), numel(xGrid), 1);
        xInterval = composeIntervals( ...
            xEdges(xGrid(:))', xEdges(xGrid(:) + 1)');
        yInterval = composeIntervals( ...
            yEdges(yGrid(:))', yEdges(yGrid(:) + 1)');
        percent = 100*familyN/height(familyRows);
        displayMinimumN = repmat( ...
            grouping.minimumValidN, numel(xGrid), 1);
        meetsDisplayMinimum = familyN >= displayMinimumN;
        tableParts{pairIndex} = table( ...
            xCharacteristic, yCharacteristic, xGrid(:), ...
            yGrid(:), xInterval, yInterval, familyN, percent, ...
            displayMinimumN, meetsDisplayMinimum, ...
            'VariableNames', { ...
                'XCharacteristic', 'YCharacteristic', ...
                'XBinIndex', 'YBinIndex', 'XInterval', 'YInterval', ...
                'FamilyN', 'Percent', 'DisplayMinimumN', ...
                'MeetsDisplayMinimum'});
    end
    occupancy = vertcat(tableParts{:});

end

function validity = createObservationValidityTable( ...
    observations, observationPlan, minimumValidN)
% createObservationValidityTable Retain support for every planned outcome.

    metricNames = [ ...
        "MAPSISOComplexError"
        "MAPMISOComplexError"
        "MAPComplexAdvantage"
        "MAPGainAdvantage"
        "MAPPhaseAdvantage"
        "CO2SISOComplexError"
        "CO2MISOComplexError"
        "CO2ComplexAdvantage"
        "CO2GainAdvantage"
        "CO2PhaseAdvantage"
        "PredictionAdvantage"];
    metricNames = metricNames(ismember( ...
        metricNames, string(observations.Properties.VariableNames)));
    tableParts = cell(height(observationPlan)*numel(metricNames), 1);
    rowIndex = 0;
    for planIndex = 1:height(observationPlan)
        plan = observationPlan(planIndex, :);
        rows = observations.PlanID == plan.PlanID;
        totalN = nnz(rows);
        for metricIndex = 1:numel(metricNames)
            rowIndex = rowIndex + 1;
            values = observations.(metricNames(metricIndex))(rows);
            validN = nnz(isfinite(values));
            invalidN = totalN - validN;
            validFraction = validN/max(totalN, 1);
            tableParts{rowIndex} = table( ...
                plan.PlanID, string(plan.Experiment), ...
                plan.DurationSeconds, plan.OutputSNRdB, ...
                plan.MAPInputSNRdB, plan.CO2InputSNRdB, ...
                plan.AlignmentErrorSeconds, metricNames(metricIndex), ...
                totalN, validN, invalidN, validFraction, ...
                minimumValidN, validN >= minimumValidN, ...
                'VariableNames', { ...
                    'PlanID', 'Experiment', 'DurationSeconds', ...
                    'OutputSNRdB', 'MAPInputSNRdB', ...
                    'CO2InputSNRdB', 'AlignmentErrorSeconds', ...
                    'Metric', 'TotalN', 'ValidN', 'InvalidN', ...
                    'ValidFraction', 'MinimumValidN', ...
                    'MeetsMinimumN'});
        end
    end
    validity = vertcat(tableParts{1:rowIndex});

end

function stability = createCheckpointStabilityTable( ...
    observations, design, minimumValidN)
% createCheckpointStabilityTable Compare complete balanced block checkpoints.

    metricNames = [ ...
        "MAPComplexAdvantage"
        "MAPGainAdvantage"
        "MAPPhaseAdvantage"
        "CO2ComplexAdvantage"
        "CO2GainAdvantage"
        "CO2PhaseAdvantage"];
    referenceRows = observations.IsReferenceObservation;
    reference = observations(referenceRows, :);
    finiteBlocks = unique(design.DesignBlockID( ...
        isfinite(design.DesignBlockID)), "sorted");
    if isempty(finiteBlocks)
        checkpointBlocks = NaN;
        checkpointFamilyIds = {design.FamilyID};
    else
        numBlocks = numel(finiteBlocks);
        checkpointBlocks = unique( ...
            [min(5, numBlocks), min(8, numBlocks), numBlocks], ...
            "stable");
        checkpointFamilyIds = cell(numel(checkpointBlocks), 1);
        for checkpointIndex = 1:numel(checkpointBlocks)
            includedBlocks = finiteBlocks( ...
                1:checkpointBlocks(checkpointIndex));
            checkpointFamilyIds{checkpointIndex} = ...
                design.FamilyID(ismember( ...
                    design.DesignBlockID, includedBlocks));
        end
    end

    numCheckpoints = numel(checkpointFamilyIds);
    finalFamilyIds = checkpointFamilyIds{end};
    finalMeans = zeros(numel(metricNames), 1);
    for metricIndex = 1:numel(metricNames)
        finalValues = reference.(metricNames(metricIndex))( ...
            ismember(reference.FamilyID, finalFamilyIds));
        finalMeans(metricIndex) = mean(finalValues, "omitnan");
    end

    tableParts = cell(numCheckpoints*numel(metricNames), 1);
    rowIndex = 0;
    for checkpointIndex = 1:numCheckpoints
        familyIds = checkpointFamilyIds{checkpointIndex};
        for metricIndex = 1:numel(metricNames)
            rowIndex = rowIndex + 1;
            values = reference.(metricNames(metricIndex))( ...
                ismember(reference.FamilyID, familyIds));
            values = values(isfinite(values));
            meanValue = mean(values, "omitnan");
            sdValue = std(values, 0, "omitnan");
            validN = numel(values);
            changeFromFinal = meanValue - finalMeans(metricIndex);
            tableParts{rowIndex} = table( ...
                checkpointBlocks(checkpointIndex), ...
                numel(familyIds), metricNames(metricIndex), ...
                meanValue, sdValue, validN, minimumValidN, ...
                validN >= minimumValidN, changeFromFinal, ...
                abs(changeFromFinal), 10.^meanValue, ...
                'VariableNames', { ...
                    'CheckpointBlocks', 'FamiliesUsed', 'Metric', ...
                    'Mean', 'SD', 'ValidN', 'MinimumValidN', ...
                    'MeetsMinimumN', 'ChangeFromFinal', ...
                    'AbsoluteChangeFromFinal', ...
                    'GeometricSISOToMISOErrorRatio'});
        end
    end
    stability = vertcat(tableParts{:});

end

function familyRows = selectFamilyCharacterizationRows(observations)
% selectFamilyCharacterizationRows Return one realized record per family.

    if ismember( ...
            "IsFamilyCharacterizationObservation", ...
            string(observations.Properties.VariableNames)) && ...
            any(observations.IsFamilyCharacterizationObservation)
        familyRows = observations( ...
            observations.IsFamilyCharacterizationObservation, :);
        return
    end
    if ismember( ...
            "IsReferenceObservation", ...
            string(observations.Properties.VariableNames)) && ...
            any(observations.IsReferenceObservation)
        familyRows = observations(observations.IsReferenceObservation, :);
        return
    end
    [~, firstRows] = unique(observations.FamilyID, "stable");
    familyRows = observations(firstRows, :);

end

function rowsPerFamily = getEstimatorRowsPerFamily(settings)
% getEstimatorRowsPerFamily Reproduce the configured sensitivity count.

    if ~settings.estimatorSensitivity.enabled
        rowsPerFamily = 0;
        return
    end
    numWindows = numel( ...
        settings.estimatorSensitivity.windowLengthSeconds);
    numOverlaps = numel( ...
        settings.estimatorSensitivity.windowOverlap);
    numDurations = numel(settings.observations.durationSeconds);
    rowsPerFamily = numWindows + numOverlaps + ...
        numDurations*numWindows;

end

function [levelNames, valueNames, labels] = getAssignedFactorMetadata()
% getAssignedFactorMetadata Define the five assigned design factors.

    levelNames = [ ...
        "TargetInputCoherenceLevel"
        "SpectralSimilarityLevel"
        "PETCO2ToMAPFluctuationSDRatioLevel"
        "PETCO2ToMAPBandGainRatioLevel"
        "CO2DelayLevel"];
    valueNames = [ ...
        "TargetInputCoherence"
        "SpectralSimilarityControl"
        "PETCO2ToMAPFluctuationSDRatio"
        "PETCO2ToMAPBandGainRatio"
        "CO2DelaySeconds"];
    labels = [ ...
        "Target MAP-PETCO2 coherence"
        "Spectral-similarity control"
        "PETCO2-to-MAP fluctuation SD ratio"
        "PETCO2-to-MAP pathway band-gain ratio"
        "True PETCO2 pathway delay"];

end

function [fields, labels, edgeFields] = getRealizedFactorMetadata()
% getRealizedFactorMetadata Define continuous realized display factors.

    fields = [ ...
        "FamilyInputCoherence"
        "FamilyPSDShapeOverlap"
        "FamilyPETCO2ContributionPowerShare"];
    labels = [ ...
        "Realized MAP-PETCO2 coherence"
        "Realized PSD-shape overlap"
        "Realized PETCO2 contribution-power share"];
    edgeFields = [ ...
        "inputCoherenceEdges"
        "psdShapeOverlapEdges"
        "petco2ContributionPowerShareEdges"];

end

function tableValue = emptyPairwiseBalanceTable()
% emptyPairwiseBalanceTable Preserve a stable schema when not applicable.

    tableValue = table( ...
        strings(0, 1), strings(0, 1), zeros(0, 1), zeros(0, 1), ...
        zeros(0, 1), zeros(0, 1), false(0, 1), ...
        'VariableNames', { ...
            'FactorX', 'FactorY', 'XLevelIndex', 'YLevelIndex', ...
            'ObservedN', 'ExpectedN', 'Pass'});

end

function text = composeIntervals(lowerEdge, upperEdge)
% composeIntervals Format prespecified bin boundaries.

    lowerEdge = lowerEdge(:);
    upperEdge = upperEdge(:);
    text = compose("[%.3g, %.3g)", lowerEdge, upperEdge);
    finalInterval = upperEdge == max(upperEdge);
    text(finalInterval) = compose("[%.3g, %.3g]", ...
        lowerEdge(finalInterval), upperEdge(finalInterval));

end

function value = getStoredScalar(structure, fieldName, defaultValue)
% getStoredScalar Read optional scalar provenance fields.

    if isfield(structure, fieldName)
        value = structure.(fieldName);
    else
        value = defaultValue;
    end

end

function countText = describePassCount(pass)
% describePassCount Format a compact support-check count.

    if isempty(pass)
        countText = "not applicable";
    else
        countText = compose("%d of %d", nnz(pass), numel(pass));
    end

end

function countText = describeBlockCount(design, designMode)
% describeBlockCount Report the number of complete design blocks.

    if designMode ~= "pairwisefivelevel"
        countText = "not applicable";
    else
        countText = compose("%d blocks", ...
            numel(unique(design.DesignBlockID)));
    end

end

function expectedText = describeExpectedBlocks(numFamilies, designMode)
% describeExpectedBlocks Report the block count implied by family count.

    if designMode ~= "pairwisefivelevel"
        expectedText = "not applicable";
    else
        expectedText = compose("%g complete blocks", numFamilies/25);
    end

end

function evidence = describeEvidenceLevel(profileName)
% describeEvidenceLevel Prevent proof results from being mislabeled.

    switch lower(profileName)
        case "proof250"
            evidence = ...
                "Presentation proof-of-concept evidence; not final-paper " + ...
                "evidence.";
        case "paper1000"
            evidence = ...
                "Candidate final-paper analysis; interpretation still " + ...
                "requires the completed audit.";
        case "designsmoke"
            evidence = "Balanced workflow smoke test; not result evidence.";
        otherwise
            evidence = "Quick implementation check; not result evidence.";
    end

end
