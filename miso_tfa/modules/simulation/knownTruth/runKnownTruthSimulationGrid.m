function simulationResults = runKnownTruthSimulationGrid(settings)
% runKnownTruthSimulationGrid Run the family-based known-truth simulation.
%
% The historical function name is retained so existing scripts continue to
% work. The implementation now uses paired family observations rather than
% generating an unrelated random signal for every factor combination.

    if nargin < 1
        settings = defaultKnownTruthSimulationSettings("quick");
    end

    simulationTimer = tic;

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
    frequencyResults = struct();
    exampleFamily = struct();

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

        for planIndex = 1:numPlans
            observationIndex = observationIndex + 1;
            planRow = observationPlan(planIndex, :);

            training = createKnownTruthObservation( ...
                family.training, planRow);
            validation = createKnownTruthObservation( ...
                family.validation, planRow);
            analysis = analyzeKnownTruthObservation( ...
                training, validation, settings);

            observationRows(observationIndex) = ...
                createKnownTruthObservationResultRow( ...
                    observationIndex, familyRow, planRow, ...
                    analysis);

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

        end
    end

    observationTable = struct2table(observationRows);
    observationTable = attachFamilyCharacteristics(observationTable);

    simulationResults.settings = settings;
    simulationResults.familyDesign = familyDesign;
    simulationResults.observationPlan = observationPlan;
    simulationResults.observations = observationTable;
    simulationResults.frequency = frequencyResults;
    simulationResults.exampleFamily = exampleFamily;
    simulationResults.numFamilies = numFamilies;
    simulationResults.numObservationPlans = numPlans;
    simulationResults.numObservations = numObservations;
    simulationResults.elapsedSeconds = toc(simulationTimer);

    fprintf( ...
        "Known-truth numerical simulation completed in %.1f minutes.\n", ...
        simulationResults.elapsedSeconds/60);

end

function report = shouldReportProgress(familyIndex, progressEvery)
% shouldReportProgress Decide whether to print the current family number.

    report = familyIndex == 1 || ...
        mod(familyIndex, progressEvery) == 0;

end

function row = createEmptyObservationRow()
% createEmptyObservationRow Obtain the stable observation result schema.

    dummyFamily = table( ...
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, ...
        'VariableNames', { ...
            'FamilyID', 'ScenarioID', 'TargetInputCoherence', ...
            'SpectralSimilarityControl', ...
            'DesignedPSDShapeOverlap', ...
            'PETCO2ToMAPFluctuationSDRatio', ...
            'PETCO2ToMAPBandGainRatio', 'CO2DelaySeconds', ...
            'InputPhaseLagSeconds', ...
            'MAPPathwayTimeConstantSeconds', ...
            'CO2PathwayTimeConstantSeconds'});
    dummyPlan = table( ...
        0, "Main", 0, Inf, Inf, Inf, 0, "white", ...
        'VariableNames', { ...
            'PlanID', 'Experiment', 'DurationSeconds', ...
            'OutputSNRdB', 'MAPInputSNRdB', 'CO2InputSNRdB', ...
            'AlignmentErrorSeconds', 'NoiseSpectrum'});
    dummyPlan.IsReferenceObservation = false;
    dummyPlan.IsFamilyCharacterizationObservation = false;

    dummyAnalysis.diagnostics.analyzedDurationSeconds = 0;
    dummyAnalysis.diagnostics.inputCoherence = NaN;
    dummyAnalysis.diagnostics.multipleCoherence = NaN;
    dummyAnalysis.diagnostics.mapPairwiseCoherence = NaN;
    dummyAnalysis.diagnostics.co2PairwiseCoherence = NaN;
    dummyAnalysis.diagnostics.multipleMinusMapCoherence = NaN;
    dummyAnalysis.diagnostics.multipleMinusPartialMapCoherence = NaN;
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

    row = createKnownTruthObservationResultRow( ...
        0, dummyFamily, dummyPlan, dummyAnalysis);

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

function results = initializeKnownTruthFrequencyResults( ...
    frequencyHz, numObservations)
% initializeKnownTruthFrequencyResults Preallocate frequency result arrays.

    numFrequencies = numel(frequencyHz);
    realArray = NaN(numFrequencies, numObservations);
    complexArray = complex(realArray, realArray);

    results.frequencyHz = frequencyHz(:);
    results.observationId = NaN(1, numObservations);
    results.inputCoherence = realArray;
    results.mapPairwiseCoherence = realArray;
    results.co2PairwiseCoherence = realArray;
    results.multipleCoherence = realArray;
    results.multipleMinusMapCoherence = realArray;
    results.multipleMinusPartialMapCoherence = realArray;
    results.normalizedConditionNumber = realArray;
    results.normalizedDeterminant = realArray;
    results.realizedOutputSnrDb = realArray;
    results.realizedMapInputSnrDb = realArray;
    results.realizedCo2InputSnrDb = realArray;
    results.prediction.sisoMapError = realArray;
    results.prediction.misoError = realArray;
    results.prediction.advantage = realArray;

    results.map.truth = complexArray;
    results.map.sisoEstimate = complexArray;
    results.map.misoEstimate = complexArray;
    results.map.sisoComplexError = realArray;
    results.map.misoComplexError = realArray;
    results.map.sisoGainError = realArray;
    results.map.misoGainError = realArray;
    results.map.sisoPhaseErrorRadians = realArray;
    results.map.misoPhaseErrorRadians = realArray;
    results.map.complexAdvantage = realArray;
    results.map.truthRecoveryAdvantage = realArray;
    results.map.gainAdvantage = realArray;
    results.map.phaseAdvantage = realArray;
    results.map.populationSisoTarget = complexArray;
    results.map.populationSisoBiasError = realArray;
    results.map.populationSisoTruthError = realArray;
    results.map.sisoOwnTargetError = realArray;

    results.co2.truth = complexArray;
    results.co2.sisoEstimate = complexArray;
    results.co2.misoEstimate = complexArray;
    results.co2.sisoComplexError = realArray;
    results.co2.misoComplexError = realArray;
    results.co2.sisoGainError = realArray;
    results.co2.misoGainError = realArray;
    results.co2.sisoPhaseErrorRadians = realArray;
    results.co2.misoPhaseErrorRadians = realArray;
    results.co2.complexAdvantage = realArray;
    results.co2.truthRecoveryAdvantage = realArray;
    results.co2.gainAdvantage = realArray;
    results.co2.phaseAdvantage = realArray;
    results.co2.populationSisoTarget = complexArray;
    results.co2.populationSisoBiasError = realArray;
    results.co2.populationSisoTruthError = realArray;
    results.co2.sisoOwnTargetError = realArray;

end
