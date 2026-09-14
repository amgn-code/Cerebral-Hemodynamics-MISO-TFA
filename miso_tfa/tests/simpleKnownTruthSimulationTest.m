classdef simpleKnownTruthSimulationTest < matlab.unittest.TestCase
    % simpleKnownTruthSimulationTest Verify the small study profile.

    methods (TestClassSetup)
        function addProjectFolders(testCase)
            projectRoot = fileparts(fileparts(mfilename("fullpath")));
            testCase.applyFixture( ...
                matlab.unittest.fixtures.PathFixture( ...
                    projectRoot, IncludingSubfolders=true));
        end
    end

    methods (Test)
        function simpleProfileHasOnlyDeclaredVaryingLevels(testCase)
            settings = defaultKnownTruthSimulationSettings("simple");

            testCase.verifyEqual( ...
                settings.families.designMode, "fullFactorial");
            testCase.verifyEqual( ...
                settings.families.targetCoherenceValues, [0 0.5 0.95]);
            testCase.verifyEqual( ...
                settings.families.petco2ToMapBandGainRatioValues, ...
                [0 0.25 1]);
            testCase.verifyEqual( ...
                settings.families.spectralSimilarityValues, 1);
            testCase.verifyEqual( ...
                settings.families.petco2ToMapFluctuationSdRatioValues, 1);
            testCase.verifyEqual( ...
                settings.families.co2DelaySecondsValues, 3);
            testCase.verifyEqual( ...
                settings.frequencyRangeHz, [0.02 0.5]);
        end

        function fullFactorialDesignContainsAllNinePairs(testCase)
            settings = defaultKnownTruthSimulationSettings("simple");
            design = createKnownTruthFamilyDesign(settings);

            testCase.verifyEqual(height(design), 9);
            pairs = unique([ ...
                design.TargetInputCoherence, ...
                design.PETCO2ToMAPBandGainRatio], "rows");
            testCase.verifyEqual(size(pairs), [9 2]);
            testCase.verifyTrue(all( ...
                design.MAPPathwayTimeConstantSeconds == 3));
            testCase.verifyTrue(all( ...
                design.CO2PathwayTimeConstantSeconds == 5));
        end

        function zeroCo2PathwayIsRepresentedExactly(testCase)
            settings = defaultKnownTruthSimulationSettings("simple");
            design = createKnownTruthFamilyDesign(settings);
            zeroPathway = design( ...
                design.PETCO2ToMAPBandGainRatio == 0, :);
            family = createKnownTruthFamily(zeroPathway(1,:), settings);

            testCase.verifyEqual( ...
                family.training.truth.co2ImpulseResponse, ...
                zeros(size(family.training.truth.co2ImpulseResponse)));
            testCase.verifyEqual( ...
                family.training.truth.achievedPETCO2ToMAPBandGainRatio, 0);
        end

        function simpleRunStoresThreeNoiseLevels(testCase)
            results = runSimpleKnownTruthSimulation(1);

            testCase.verifyEqual(results.numFamilies, 9);
            testCase.verifyEqual(results.numObservations, 81);
            testCase.verifyTrue(all(ismember( ...
                [Inf; 10; 0], results.observationPlan.OutputSNRdB)));
            testCase.verifyEqual( ...
                size(results.frequency.multipleMinusMapCoherence, 2), ...
                results.numObservations);
            testCase.verifyEqual( ...
                size(results.frequency.multipleMinusPartialMapCoherence, 2), ...
                results.numObservations);
        end
    end
end
