classdef protocolFreezeTest < matlab.unittest.TestCase
    % protocolFreezeTest Verify the Step 1 reproducibility contract.

    methods (TestClassSetup)
        function addProjectFolders(testCase)
            projectRoot = fileparts(fileparts(mfilename("fullpath")));
            testCase.applyFixture( ...
                matlab.unittest.fixtures.PathFixture( ...
                projectRoot, IncludingSubfolders=true));
        end
    end

    methods (Test)
        function reportingBandDoesNotChangeTruth(testCase)
            settings = defaultKnownTruthSimulationSettings("simple");
            design = createKnownTruthFamilyDesign(settings);
            first = generateKnownTruthRealization( ...
                familyScenario(design(1,:)), settings, 9945, ...
                settings.generator.realizationLengthSeconds);
            alternateSettings = settings;
            alternateSettings.frequencyRangeHz = [0.05 0.30];
            second = generateKnownTruthRealization( ...
                familyScenario(design(1,:)), alternateSettings, 9945, ...
                alternateSettings.generator.realizationLengthSeconds);
            testCase.verifyEqual(first.map, second.map);
            testCase.verifyEqual(first.co2, second.co2);
            testCase.verifyEqual(first.truth.mapImpulseResponse, ...
                second.truth.mapImpulseResponse);
            testCase.verifyEqual(first.truth.co2ImpulseResponse, ...
                second.truth.co2ImpulseResponse);
        end

        function fullFactorialDesignIsAppendStable(testCase)
            settings = defaultKnownTruthSimulationSettings("simple");
            settings.families.repetitionsPerCondition = 1;
            firstDesign = createKnownTruthFamilyDesign(settings);
            settings.families.repetitionsPerCondition = 2;
            secondDesign = createKnownTruthFamilyDesign(settings);
            testCase.verifyEqual(height(firstDesign), 12);
            testCase.verifyEqual(height(secondDesign), 24);
            testCase.verifyEqual(firstDesign, secondDesign(1:12,:));
        end

        function durationSelectionDoesNotRedrawFamily(testCase)
            settings = defaultKnownTruthSimulationSettings("simple");
            settings.observations.durationSeconds = [300 600];
            design = createKnownTruthFamilyDesign(settings);
            first = createKnownTruthFamily(design(1,:), settings);
            settings.observations.durationSeconds = [300 600 900];
            second = createKnownTruthFamily(design(1,:), settings);
            testCase.verifyEqual(first.training.map, second.training.map);
            testCase.verifyEqual(first.validation.co2, second.validation.co2);
        end

        function frequencyEdgesAreReachable(testCase)
            settings = defaultKnownTruthSimulationSettings("simple");
            testCase.verifyGreaterThanOrEqual( ...
                settings.frequencyBandEdgesHz, ...
                1/settings.welch.windowLengthSeconds);
        end

        function analyticPopulationTargetsAreReturned(testCase)
            settings = defaultKnownTruthSimulationSettings("simple");
            settings.families.repetitionsPerCondition = 1;
            design = createKnownTruthFamilyDesign(settings);
            family = createKnownTruthFamily(design(1,:), settings);
            plan = createKnownTruthObservationPlan(settings);
            row = plan(plan.IsReferenceObservation, :);
            observation = createKnownTruthObservation(family.training, row);
            analysis = analyzeKnownTruthObservation( ...
                observation, observation, settings);
            testCase.verifyTrue(isfield(analysis, "population"));
            testCase.verifyEqual( ...
                numel(analysis.population.siso.map), ...
                numel(analysis.frequencyHz));
            testCase.verifyTrue(isfield(analysis, "secondaryEstimand"));
            testCase.verifyTrue(isfield( ...
                analysis.diagnostics, "realizedInBandSnrDb"));
        end

        function longNoiselessRecordApproachesAnalyticSisoBias(testCase)
            settings = defaultKnownTruthSimulationSettings("simple");
            settings.generator.realizationLengthSeconds = 7200;
            design = createKnownTruthFamilyDesign(settings);
            selected = design.TargetInputCoherence == 0.50 & ...
                design.PETCO2ToMAPBandGainRatio == 1;
            family = createKnownTruthFamily(design(find(selected, 1), :), ...
                settings);
            plan = table(7200, Inf, Inf, Inf, 0, "signalShaped", ...
                'VariableNames', {'DurationSeconds', 'OutputSNRdB', ...
                'MAPInputSNRdB', 'CO2InputSNRdB', ...
                'AlignmentErrorSeconds', 'NoiseSpectrum'});
            training = createKnownTruthObservation(family.training, plan);
            validation = createKnownTruthObservation(family.validation, plan);
            analysis = analyzeKnownTruthObservation( ...
                training, validation, settings);
            empiricalSisoError = ...
                analysis.frequencyError.map.siso.complex;
            analyticSisoBias = ...
                analysis.population.sisoTruthError.map.complex;
            finite = empiricalSisoError > 0 & analyticSisoBias > 0;
            logDifference = log10( ...
                empiricalSisoError(finite)./analyticSisoBias(finite));

            testCase.verifyLessThan( ...
                median(abs(logDifference), "omitnan"), 0.20);
        end
    end
end

function scenario = familyScenario(familyRow)
    scenario.targetInputCoherence = familyRow.TargetInputCoherence;
    scenario.spectralSimilarityControl = familyRow.SpectralSimilarityControl;
    scenario.petco2ToMapFluctuationSdRatio = ...
        familyRow.PETCO2ToMAPFluctuationSDRatio;
    scenario.petco2ToMapBandGainRatio = ...
        familyRow.PETCO2ToMAPBandGainRatio;
    scenario.co2DelaySeconds = familyRow.CO2DelaySeconds;
    scenario.inputPhaseLagSeconds = familyRow.InputPhaseLagSeconds;
    scenario.mapPathwayTimeConstantSeconds = ...
        familyRow.MAPPathwayTimeConstantSeconds;
    scenario.co2PathwayTimeConstantSeconds = ...
        familyRow.CO2PathwayTimeConstantSeconds;
end
