function simulationResults = runKnownTruthSimulationGrid(settings)
% runKnownTruthSimulationGrid Run the family-based known-truth simulation.
%
% The historical function name is retained so existing scripts continue to
% work. The implementation now uses paired family observations rather than
% generating an unrelated random signal for every factor combination.

    if nargin < 1
        settings = defaultKnownTruthSimulationSettings("quick");
    end

    familyDesign = createKnownTruthFamilyDesign(settings);
    observationPlan = createKnownTruthObservationPlan(settings);
    numFamilies = height(familyDesign);
    numPlans = height(observationPlan);
    numObservations = numFamilies*numPlans;

    fprintf( ...
        "Known-truth simulation: %d families x %d paired observation plans = %d primary analyses.\n", ...
        numFamilies, numPlans, numObservations);

    observationRows = repmat( ...
        createEmptyObservationRow(), numObservations, 1);
    ridgeTables = cell(numFamilies, 1);
    ridgeFrequencyTables = cell(numFamilies, 1);
    estimatorSettingTables = cell(numFamilies, 1);
    estimatorFrequencyTables = cell(numFamilies, 1);
    frequencyResults = struct();
    exampleFamily = struct();
    referencePlan = observationPlan( ...
        observationPlan.IsReferenceObservation, :);

    observationIndex = 0;
    for familyIndex = 1:numFamilies
        if shouldReportProgress( ...
                familyIndex, settings.families.progressEvery)
            fprintf( ...
                "Generating family %d of %d.\n", ...
                familyIndex, numFamilies);
        end

        familyRow = familyDesign(familyIndex, :);
        family = createKnownTruthFamily(familyRow, settings);
        if familyIndex == 1 && ...
                settings.storage.retainExampleFamily
            exampleFamily = family;
        end

        familyRidgeTables = cell(0, 1);
        familyRidgeFrequencyTables = cell(0, 1);
        for planIndex = 1:numPlans
            observationIndex = observationIndex + 1;
            planRow = observationPlan(planIndex, :);

            training = createKnownTruthObservation( ...
                family.training, planRow);
            validation = createKnownTruthObservation( ...
                family.validation, planRow);
            analysis = analyzeKnownTruthObservation( ...
                training, validation, settings, planRow.RunRidge);

            observationRows(observationIndex) = ...
                createKnownTruthObservationResultRow( ...
                    observationIndex, familyRow, planRow, ...
                    analysis, settings);

            if settings.storage.retainFrequencyResults
                if isempty(fieldnames(frequencyResults))
                    frequencyResults = ...
                        initializeKnownTruthFrequencyResults( ...
                            analysis.frequencyHz, numObservations);
                end
                frequencyResults = storeKnownTruthFrequencyResult( ...
                    frequencyResults, observationIndex, ...
                    observationIndex, analysis);
            end

            if ~isempty(analysis.ridge)
                ridgeTable = analysis.ridge;
                ridgeTable.ObservationID = repmat( ...
                    observationIndex, height(ridgeTable), 1);
                ridgeTable.FamilyID = repmat( ...
                    familyRow.FamilyID, height(ridgeTable), 1);
                ridgeTable.ScenarioID = repmat( ...
                    familyRow.ScenarioID, height(ridgeTable), 1);
                ridgeTable.TargetInputCoherence = repmat( ...
                    familyRow.TargetInputCoherence, ...
                    height(ridgeTable), 1);
                ridgeTable.DesignedPSDShapeOverlap = repmat( ...
                    familyRow.DesignedPSDShapeOverlap, ...
                    height(ridgeTable), 1);
                ridgeTable.RealizedInputCoherence = repmat( ...
                    observationRows(observationIndex). ...
                    RealizedInputCoherence, ...
                    height(ridgeTable), 1);
                ridgeTable.RealizedPSDShapeOverlap = repmat( ...
                    observationRows(observationIndex). ...
                    RealizedPSDShapeOverlap, ...
                    height(ridgeTable), 1);
                familyRidgeTables{end + 1,1} = ridgeTable; %#ok<AGROW>
                ridgeFrequencyTable = analysis.ridgeFrequency;
                ridgeFrequencyTable.ObservationID = repmat( ...
                    observationIndex, height(ridgeFrequencyTable), 1);
                ridgeFrequencyTable.FamilyID = repmat( ...
                    familyRow.FamilyID, ...
                    height(ridgeFrequencyTable), 1);
                familyRidgeFrequencyTables{end + 1,1} = ...
                    ridgeFrequencyTable; %#ok<AGROW>
            end
        end

        if ~isempty(familyRidgeTables)
            ridgeTables{familyIndex} = vertcat( ...
                familyRidgeTables{:});
        end
        if ~isempty(familyRidgeFrequencyTables)
            ridgeFrequencyTables{familyIndex} = vertcat( ...
                familyRidgeFrequencyTables{:});
        end

        if settings.estimatorSensitivity.enabled
            [estimatorSettingTables{familyIndex}, ...
                estimatorFrequencyTables{familyIndex}] = ...
                runKnownTruthEstimatorSettingExperiment( ...
                    family, familyRow, referencePlan, settings);
        end
    end

    observationTable = struct2table(observationRows);
    observationTable = attachFamilyCharacteristics(observationTable);
    completedRidgeTables = ridgeTables(~cellfun(@isempty, ridgeTables));
    if isempty(completedRidgeTables)
        ridgeTable = table();
    else
        ridgeTable = vertcat(completedRidgeTables{:});
    end
    completedRidgeFrequencyTables = ridgeFrequencyTables( ...
        ~cellfun(@isempty, ridgeFrequencyTables));
    if isempty(completedRidgeFrequencyTables)
        ridgeFrequencyTable = table();
    else
        ridgeFrequencyTable = vertcat(completedRidgeFrequencyTables{:});
    end
    completedEstimatorTables = estimatorSettingTables( ...
        ~cellfun(@isempty, estimatorSettingTables));
    if isempty(completedEstimatorTables)
        estimatorSettingTable = table();
    else
        estimatorSettingTable = vertcat( ...
            completedEstimatorTables{:});
    end
    completedEstimatorFrequencyTables = estimatorFrequencyTables( ...
        ~cellfun(@isempty, estimatorFrequencyTables));
    if isempty(completedEstimatorFrequencyTables)
        estimatorFrequencyTable = table();
    else
        estimatorFrequencyTable = vertcat( ...
            completedEstimatorFrequencyTables{:});
    end

    simulationResults.settings = settings;
    simulationResults.familyDesign = familyDesign;
    simulationResults.observationPlan = observationPlan;
    simulationResults.observations = observationTable;
    simulationResults.ridge = ridgeTable;
    simulationResults.ridgeFrequency = ridgeFrequencyTable;
    simulationResults.estimatorSettings = estimatorSettingTable;
    simulationResults.estimatorFrequency = estimatorFrequencyTable;
    simulationResults.frequency = frequencyResults;
    simulationResults.exampleFamily = exampleFamily;
    simulationResults.numFamilies = numFamilies;
    simulationResults.numObservationPlans = numPlans;
    simulationResults.numObservations = numObservations;
    simulationResults.numEstimatorSettingAnalyses = ...
        height(estimatorSettingTable);

end

function report = shouldReportProgress(familyIndex, progressEvery)
% shouldReportProgress Decide whether to print the current family number.

    report = familyIndex == 1 || ...
        mod(familyIndex, progressEvery) == 0;

end

function row = createEmptyObservationRow()
% createEmptyObservationRow Obtain the stable observation result schema.

    dummyFamily = table( ...
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0, ...
        'VariableNames', { ...
            'FamilyID', 'ScenarioID', 'TargetInputCoherence', ...
            'SpectralSimilarityControl', ...
            'DesignedPSDShapeOverlap', ...
            'PETCO2ToMAPFluctuationSDRatio', ...
            'PETCO2ToMAPBandGainRatio', 'CO2DelaySeconds', ...
            'MAPPathwayTimeConstantSeconds', ...
            'CO2PathwayTimeConstantSeconds'});
    dummyPlan = table( ...
        0, "Main", 0, Inf, Inf, Inf, 0, false, ...
        'VariableNames', { ...
            'PlanID', 'Experiment', 'DurationSeconds', ...
            'OutputSNRdB', 'MAPInputSNRdB', 'CO2InputSNRdB', ...
            'AlignmentErrorSeconds', 'RunRidge'});
    dummyPlan.IsReferenceObservation = false;
    dummyPlan.IsFamilyCharacterizationObservation = false;

    dummyAnalysis.diagnostics.analyzedDurationSeconds = 0;
    dummyAnalysis.diagnostics.inputCoherence = NaN;
    dummyAnalysis.diagnostics.realizedPSDShapeOverlap = NaN;
    dummyAnalysis.diagnostics. ...
        realizedPETCO2ToMAPFluctuationSDRatio = NaN;
    dummyAnalysis.diagnostics. ...
        achievedPETCO2ToMAPBandGainRatio = NaN;
    dummyAnalysis.diagnostics. ...
        realizedPETCO2ContributionPowerShare = NaN;
    dummyAnalysis.diagnostics.rawConditionNumber = NaN;
    dummyAnalysis.diagnostics.normalizedConditionNumber = NaN;
    dummyAnalysis.diagnostics.normalizedDeterminant = NaN;
    dummyAnalysis.diagnostics.numWelchWindows = 0;
    dummyAnalysis.diagnostics.numAnalyzedSamples = 0;

    metric = struct( ...
        'normalizedComplexError', NaN, ...
        'meanAbsoluteGainError', NaN, ...
        'meanAbsolutePhaseErrorRadians', NaN, ...
        'failureRate', NaN, ...
        'extremeCoefficientRate', NaN);
    advantage = struct('complex', NaN, 'gain', NaN, 'phase', NaN);
    dummyAnalysis.summary.map.siso = metric;
    dummyAnalysis.summary.map.miso = metric;
    dummyAnalysis.summary.co2.siso = metric;
    dummyAnalysis.summary.co2.miso = metric;
    dummyAnalysis.summaryAdvantage.map = advantage;
    dummyAnalysis.summaryAdvantage.co2 = advantage;
    dummyAnalysis.prediction.sisoMap = NaN;
    dummyAnalysis.prediction.sisoCo2 = NaN;
    dummyAnalysis.prediction.miso = NaN;
    dummyAnalysis.prediction.advantage = NaN;

    dummySettings.observations.durationSeconds = 0;
    dummySettings.observations.referenceDurationSeconds = 1;
    dummySettings.observations.referenceOutputSnrDb = Inf;
    row = createKnownTruthObservationResultRow( ...
        0, dummyFamily, dummyPlan, dummyAnalysis, dummySettings);

end

function observations = attachFamilyCharacteristics(observations)
% attachFamilyCharacteristics Copy long clean diagnostics to every row.

    characterization = observations( ...
        observations.IsFamilyCharacterizationObservation, :);
    if height(characterization) ~= numel(unique(observations.FamilyID))
        error( ...
            "TFA:InvalidFamilyCharacterization", ...
            ['Expected exactly one long, clean characterization row ' ...
             'for every simulated family.']);
    end

    [isFound, location] = ismember( ...
        observations.FamilyID, characterization.FamilyID);
    if ~all(isFound)
        error( ...
            "TFA:MissingFamilyCharacterization", ...
            "A simulated observation has no family characterization.");
    end

    observations.FamilyInputCoherence = ...
        characterization.RealizedInputCoherence(location);
    observations.FamilyPSDShapeOverlap = ...
        characterization.RealizedPSDShapeOverlap(location);
    observations.FamilyPETCO2ToMAPFluctuationSDRatio = ...
        characterization. ...
        RealizedPETCO2ToMAPFluctuationSDRatio(location);
    observations.FamilyPETCO2ContributionPowerShare = ...
        characterization. ...
        RealizedPETCO2ContributionPowerShare(location);

end
