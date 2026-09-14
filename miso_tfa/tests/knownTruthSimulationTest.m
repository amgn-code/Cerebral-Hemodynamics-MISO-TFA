classdef knownTruthSimulationTest < matlab.unittest.TestCase
    % knownTruthSimulationTest Verify the independent simulation core.

    methods (TestClassSetup)
        function addProjectFolders(testCase)
            projectRoot = fileparts(fileparts(mfilename("fullpath")));
            testCase.applyFixture( ...
                matlab.unittest.fixtures.PathFixture( ...
                projectRoot, IncludingSubfolders=true));
        end
    end

    methods (Test)
        function familyGeneratorIsReproducible(testCase)
            settings = smallSettings();
            design = createKnownTruthFamilyDesign(settings);

            first = createKnownTruthFamily(design(1,:), settings);
            second = createKnownTruthFamily(design(1,:), settings);

            testCase.verifyEqual(first.training.map, second.training.map);
            testCase.verifyEqual(first.training.co2, second.training.co2);
            testCase.verifyEqual( ...
                first.training.cleanCbv, second.training.cleanCbv);
            testCase.verifyEqual( ...
                first.training.truth.co2ImpulseResponse, ...
                second.training.truth.co2ImpulseResponse);
        end

        function shorterObservationIsPrefixOfSameFamily(testCase)
            settings = smallSettings();
            settings.observations.durationSeconds = [256 512];
            design = createKnownTruthFamilyDesign(settings);
            family = createKnownTruthFamily(design(1,:), settings);
            plan = createKnownTruthObservationPlan(settings);
            cleanRows = plan.Experiment == "Main" & ...
                isinf(plan.OutputSNRdB);
            shortPlan = plan(cleanRows & ...
                plan.DurationSeconds == 256, :);
            longPlan = plan(cleanRows & ...
                plan.DurationSeconds == 512, :);

            short = createKnownTruthObservation( ...
                family.training, shortPlan(1,:));
            long = createKnownTruthObservation( ...
                family.training, longPlan(1,:));

            testCase.verifyEqual( ...
                short.map, long.map(1:numel(short.map)));
            testCase.verifyEqual( ...
                short.co2, long.co2(1:numel(short.co2)));
        end

        function pairwiseDesignKeepsFixedPhaseExplicit(testCase)
            settings = defaultKnownTruthSimulationSettings("designSmoke");
            design = createKnownTruthFamilyDesign(settings);

            testCase.verifyEqual(height(design), 25);
            testCase.verifyEqual(unique(design.InputPhaseLagSeconds), 0);
            testCase.verifyEqual(unique(design.InputPhaseLagLevel), 1);
            testCase.verifyEqual(unique(design.DesignBlockID), 1);
            testCase.verifyEqual( ...
                numel(unique(design.TargetInputCoherence)), 5);
        end

        function gridStoresPrimaryResultsWithoutRidge(testCase)
            settings = smallSettings();
            settings.families.numFamilies = 1;
            results = runKnownTruthSimulationGrid(settings);

            testCase.verifyEqual(height(results.observations), 1);
            testCase.verifyTrue(isempty(results.ridge));
            testCase.verifyTrue(isempty(results.ridgeFrequency));
            testCase.verifyTrue(ismember( ...
                "MAPComplexAdvantage", ...
                string(results.observations.Properties.VariableNames)));
            testCase.verifyEqual( ...
                size(results.frequency.map.complexAdvantage, 2), 1);
            testCase.verifyTrue(all(isfinite( ...
                results.observations.MedianNormalizedConditionNumber)));
        end

        function inputPhaseIsStoredAsASeparateDesignFactor(testCase)
            settings = defaultKnownTruthSimulationSettings("simple");
            settings.families.inputPhaseLagSecondsValues = [-2 0 2];
            settings.families.numFamilies = 27;
            design = createKnownTruthFamilyDesign(settings);

            testCase.verifyEqual( ...
                unique(design.InputPhaseLagSeconds)', [-2 0 2]);
            testCase.verifyTrue(ismember( ...
                "InputPhaseLagSeconds", ...
                design.Properties.VariableNames));
        end

        function knownTruthFrequencyErrorsRespectPhaseMask(testCase)
            truth = [1; 0.001];
            estimate = [0.8; 0.2];
            errors = calculateFrequencyTruthErrors( ...
                estimate, truth, 1e-12, 0.05);

            testCase.verifyTrue(all(isfinite(errors.complex)));
            testCase.verifyTrue(isfinite(errors.phase(1)));
            testCase.verifyTrue(isnan(errors.phase(2)));
        end
    end
end

function settings = smallSettings()
% smallSettings Return one short, deterministic primary observation.

    settings = defaultKnownTruthSimulationSettings("quick");
    settings.families.numFamilies = 2;
    settings.families.progressEvery = 100;
    settings.observations.durationSeconds = 256;
    settings.observations.referenceDurationSeconds = 256;
    settings.observations.outputSnrDb = Inf;
    settings.observations.referenceOutputSnrDb = Inf;
    settings.observations.runInputNoiseExperiment = false;
    settings.observations.runAlignmentExperiment = false;
    settings.estimators.runRidge = false;
    settings.estimators.ridgeLambdas = [];
    settings.estimatorSensitivity.enabled = false;

end
