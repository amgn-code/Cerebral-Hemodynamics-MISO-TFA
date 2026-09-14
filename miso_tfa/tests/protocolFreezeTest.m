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
            testCase.verifyEqual(height(firstDesign), 9);
            testCase.verifyEqual(height(secondDesign), 18);
            testCase.verifyEqual(firstDesign, secondDesign(1:9,:));
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
