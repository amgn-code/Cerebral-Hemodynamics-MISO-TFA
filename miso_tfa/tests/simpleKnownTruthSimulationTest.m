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
                settings.families.targetCoherenceValues, [0 0.15 0.5 0.95]);
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
                settings.families.inputPhaseLagSecondsValues, 0);
            testCase.verifyEqual( ...
                settings.secondary.inputPhaseLagSecondsValues, [-6 0 4]);
            testCase.verifyEqual( ...
                settings.observations.inputNoiseSnrDb, [Inf 10 0]);
            testCase.verifyEqual( ...
                settings.observations.noiseSpectrum, "signalShaped");
            testCase.verifyEqual( ...
                settings.frequencyRangeHz, [0.02 0.35]);
        end

        function fullFactorialDesignContainsAllTwelvePairs(testCase)
            settings = defaultKnownTruthSimulationSettings("simple");
            design = createKnownTruthFamilyDesign(settings);

            testCase.verifyEqual(height(design), 12);
            pairs = unique([ ...
                design.TargetInputCoherence, ...
                design.PETCO2ToMAPBandGainRatio], "rows");
            testCase.verifyEqual(size(pairs), [12 2]);
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

        function phaseLagIsAnExplicitFamilyFactor(testCase)
            settings = defaultKnownTruthSimulationSettings("simple");
            settings.families.inputPhaseLagSecondsValues = [-2 0 2];
            settings.families.numFamilies = 27;
            design = createKnownTruthFamilyDesign(settings);

            testCase.verifyEqual( ...
                unique(design.InputPhaseLagSeconds)', [-2 0 2]);
            testCase.verifyTrue( ...
                all(ismember("InputPhaseLagSeconds", design.Properties.VariableNames)));
        end

        function inputNoiseExperimentsKeepInputsSeparate(testCase)
            settings = defaultKnownTruthSimulationSettings("simple");
            settings.observations.experimentSet = "all";
            plan = createKnownTruthObservationPlan(settings);

            mapRows = plan.Experiment == "MAP input noise";
            co2Rows = plan.Experiment == "CO2 input noise";
            testCase.verifyEqual( ...
                plan.MAPInputSNRdB(mapRows), [Inf; 10; 0]);
            testCase.verifyEqual( ...
                plan.CO2InputSNRdB(co2Rows), [Inf; 10; 0]);
            testCase.verifyTrue(all(isinf(plan.CO2InputSNRdB(mapRows))));
            testCase.verifyTrue(all(isinf(plan.MAPInputSNRdB(co2Rows))));
            testCase.verifyTrue(all( ...
                plan.NoiseSpectrum(plan.Experiment == "Main") == ...
                "signalShaped"));
            testCase.verifyTrue(all( ...
                plan.NoiseSpectrum(plan.Experiment == "White output noise") == ...
                "white"));
        end

        function simpleRunStoresThreeNoiseLevels(testCase)
            results = runSimpleKnownTruthSimulation(1);

            testCase.verifyEqual(results.numFamilies, 12);
            testCase.verifyEqual(results.numObservations, 72);
            testCase.verifyEqual( ...
                unique(results.observations.Experiment), "Main");
            testCase.verifyTrue(all(ismember( ...
                [Inf; 10; 0], results.observationPlan.OutputSNRdB)));
            testCase.verifyEqual( ...
                size(results.frequency.multipleMinusMapCoherence, 2), ...
                results.numObservations);
            testCase.verifyEqual( ...
                size(results.frequency.multipleMinusPartialMapCoherence, 2), ...
                results.numObservations);
        end


        function signalShapedNoiseKeepsInBandSnrFlat(testCase)
            settings = defaultKnownTruthSimulationSettings("simple");
            design = createKnownTruthFamilyDesign(settings);
            plan = createKnownTruthObservationPlan(settings);
            plan = plan(plan.Experiment == "Main" & ...
                plan.DurationSeconds == 600 & plan.OutputSNRdB == 10, :);
            realized = [];
            for repetition = 1:8
                scenario = familyScenario(design(1,:));
                realization = generateKnownTruthRealization( ...
                    scenario, settings, 4000 + repetition, ...
                    settings.generator.realizationLengthSeconds);
                observation = createKnownTruthObservation(realization, plan);
                analysis = analyzeKnownTruthObservation( ...
                    observation, observation, settings);
                % The first analysis determines the retained frequency grid.
                realized(:, repetition) = ...
                    analysis.diagnostics.realizedInBandSnrDb.output; %#ok<AGROW>
            end
            averageSnr = mean(realized, 2, "omitnan");

            testCase.verifyLessThanOrEqual( ...
                max(abs(averageSnr - 10)), 2);
        end
    end
end


function scenario = familyScenario(familyRow)
% familyScenario Convert one design row for a focused generator test.

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
