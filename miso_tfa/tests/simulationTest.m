classdef simulationTest < matlab.unittest.TestCase
    % simulationTest Generation, condition design, pairing, and accuracy scores.

    methods (TestClassSetup)
        function addProject(testCase)
            folder = fileparts(fileparts(mfilename("fullpath")));
            testCase.applyFixture(matlab.unittest.fixtures.PathFixture(folder, IncludingSubfolders=true));
            runAnalysis("settings");
        end
    end

    methods (Test)
        function generationIsRepeatableAndRestoresRandomState(testCase)
            [settings, generator, scenario] = simulationFixture();
            previous = rng;
            first = generateKnownTruthRealization(scenario, generator, 2042, 1200);
            second = generateKnownTruthRealization(scenario, generator, 2042, 1200);
            after = rng;
            testCase.verifyEqual(first.map, second.map, AbsTol=0);
            testCase.verifyEqual(first.cleanCbv, second.cleanCbv, AbsTol=0);
            testCase.verifyEqual(after.State, previous.State);
            testCase.verifyEqual(settings.mode, "simulation");
        end

        function fluctuationRatioAlsoWorksWhenMapSDChanges(testCase)
            [~, generator, scenario] = simulationFixture();
            generator.inputs.mapStandardDeviation = 3;
            scenario.petco2ToMapFluctuationSdRatio = 0.25;
            recording = generateKnownTruthRealization(scenario, generator, 2042, 1200);
            testCase.verifyEqual(std(recording.co2)/std(recording.map), 0.25, RelTol=0.03);
        end

        function fractionalSampleLagPreservesTheRequestedPhase(testCase)
            [settings, generator, scenario] = simulationFixture();
            scenario.targetInputCoherence = 1;
            scenario.inputPhaseLagSeconds = 0.375;
            recording = generateKnownTruthRealization(scenario, generator, 4910, 1200);
            spectra = estimateWelchSpectra(recording.map, recording.co2, ...
                recording.cleanCbv, 4, settings.analysis.pwelch);
            [~, index] = min(abs(spectra.f - 0.1));
            testCase.verifyEqual(angle(spectra.cross.mapCo2(index)), ...
                -2*pi*spectra.f(index)*0.375, AbsTol=0.04);
            testCase.verifyTrue(isreal(recording.co2));
        end

        function zeroPathwayHasZeroContributionAndUndefinedPhase(testCase)
            [settings, ~, ~] = simulationFixture();
            settings.simulation.baseline.co2GainRatio = 0;
            results = runAnalysis(settings);
            testCase.verifyEqual(results.example.co2Contribution, ...
                zeros(size(results.example.co2Contribution)), AbsTol=0);
            testCase.verifyTrue(all(isnan(results.simulation.advantage.co2.phase.advantage)));
            testCase.verifyTrue(all(isnan(results.recordings(1).truth.co2.phaseDegrees)));
            testCase.verifyEqual(results.simulation.advantage.co2.phase.validPairs, ...
                zeros(size(results.recordings(1).frequencyHz)));
        end

        function oneAtATimeKeepsTheReferenceAndOtherFieldsFixed(testCase)
            [settings, ~, ~] = simulationFixture();
            settings.simulation.vary = ["inputCoherence", "co2GainRatio"];
            settings.simulation.ranges.inputCoherence = [0 0.15 0.5];
            settings.simulation.ranges.co2GainRatio = [0 0.25 1];
            conditions = createSimulationConditions(settings.simulation);
            changed = sum(conditions{:, ["inputCoherence", "co2GainRatio"]} ~= [0.15 1], 2);
            testCase.verifyEqual(height(conditions), 5);
            testCase.verifyEqual(sum(conditions.isReference), 1);
            testCase.verifyLessThanOrEqual(changed, ones(5, 1));
        end

        function factorialCrossesConditionsWithoutPoolingThem(testCase)
            [settings, ~, ~] = simulationFixture();
            settings.simulation.design = "factorial";
            settings.simulation.vary = ["inputCoherence", "co2GainRatio"];
            settings.simulation.ranges.inputCoherence = [0 0.15 0.5];
            settings.simulation.ranges.co2GainRatio = [0 0.25 1];
            conditions = createSimulationConditions(settings.simulation);
            testCase.verifyEqual(height(conditions), 9);
            testCase.verifyEqual(height(unique(conditions(:, ["inputCoherence", "co2GainRatio"]))), 9);
        end

        function durationUsesTheSameMasterRecordingPrefix(testCase)
            [settings, generator, scenario] = simulationFixture();
            realization = generateKnownTruthRealization(scenario, generator, 2042, 1200);
            condition = settings.simulation.baseline;
            condition.outputSnrDb = Inf;
            short = observeSimulation(realization, condition, settings.simulation, settings.analysis);
            condition.durationSeconds = 600;
            long = observeSimulation(realization, condition, settings.simulation, settings.analysis);
            testCase.verifyEqual(short.map, long.map(1:numel(short.map)), AbsTol=0);
            testCase.verifyEqual(short.cbv, long.cbv(1:numel(short.cbv)), AbsTol=0);
        end

        function inputNoiseAndMisalignmentDoNotChangeGeneratedCbv(testCase)
            [settings, generator, scenario] = simulationFixture();
            realization = generateKnownTruthRealization(scenario, generator, 2042, 1200);
            condition = settings.simulation.baseline;
            condition.alignmentErrorSeconds = 2;
            clean = observeSimulation(realization, condition, settings.simulation, settings.analysis);
            condition.co2InputSnrDb = 0;
            noisy = observeSimulation(realization, condition, settings.simulation, settings.analysis);
            testCase.verifyEqual(noisy.cbv, clean.cbv, AbsTol=0);
            testCase.verifyEqual(noisy.cleanCo2, clean.cleanCo2, AbsTol=0);
            testCase.verifyGreaterThan(std(noisy.co2 - noisy.cleanCo2), 0);
        end

        function moreRepetitionsPreserveTheExistingRecordings(testCase)
            [settings, ~, ~] = simulationFixture();
            first = runAnalysis(settings);
            settings.simulation.repetitions = 3;
            extended = runAnalysis(settings);
            testCase.verifyEqual(first.recordings(2).miso.map.transferFunction, ...
                extended.recordings(2).miso.map.transferFunction, AbsTol=0);
            testCase.verifyEqual(extended.simulation.seeds(1:2), first.simulation.seeds);
        end

        function advantageUsesMeanPairedErrorsRatherThanMeanRatios(testCase)
            summary = summarizeAdvantage([1 9 100], [1 1 NaN], 0, 0.95, 1);
            testCase.verifyEqual(summary.advantage, log10(5), AbsTol=1e-12);
            testCase.verifyEqual(summary.validPairs, 2);
            testCase.verifyEqual(summary.misoInvalid, 1);
        end

        function zeroErrorsAreReportedWithoutAnArtificialFloor(testCase)
            equal = summarizeAdvantage([0 0], [0 0], 0, 0.95, 1);
            perfectMiso = summarizeAdvantage([1 1], [0 0], 0, 0.95, 1);
            testCase.verifyEqual(equal.advantage, 0, AbsTol=0);
            testCase.verifyEqual(perfectMiso.advantage, Inf);
        end

        function bootstrapIsRepeatableAndDoesNotDisturbTheCaller(testCase)
            previous = rng;
            first = summarizeAdvantage([1 2 5 9], [1 1 2 3], 100, 0.95, 17);
            second = summarizeAdvantage([1 2 5 9], [1 1 2 3], 100, 0.95, 17);
            after = rng;
            testCase.verifyEqual(first.monteCarloSE, second.monteCarloSE, AbsTol=0);
            testCase.verifyGreaterThan(first.monteCarloSE, 0);
            testCase.verifyEqual(after.State, previous.State);
        end

        function knownCorrelatedTwoPathwayCaseShowsRecoveryBenefit(testCase)
            [settings, ~, ~] = simulationFixture();
            settings.simulation.baseline.inputCoherence = 0.5;
            settings.simulation.baseline.outputSnrDb = Inf;
            settings.simulation.baseline.durationSeconds = 600;
            settings.simulation.repetitions = 4;
            results = runAnalysis(settings);
            advantage = results.simulation.advantage.map.gain.advantage;
            testCase.verifyGreaterThan(median(advantage, "omitnan"), 0);
        end

        function degenerateBootstrapDoesNotHideInfiniteErrorRatios(testCase)
            summary = summarizeAdvantage([1 1], [0 1], 100, 0.95, 1);
            testCase.verifyLessThan(summary.bootstrapFiniteFraction, 1);
            testCase.verifyTrue(isnan(summary.monteCarloSE));
            testCase.verifyTrue(isnan(summary.ciUpper));
        end

        function delayCorrectionCanUndoAnAppliedAlignmentError(testCase)
            [settings, generator, scenario] = simulationFixture();
            realization = generateKnownTruthRealization(scenario, generator, 2042, 1200);
            condition = settings.simulation.baseline;
            expected = observeSimulation(realization, condition, settings.simulation, settings.analysis);
            condition.alignmentErrorSeconds = 2;
            settings.analysis.preprocessing.co2DelayCorrectionSeconds = -2;
            corrected = observeSimulation(realization, condition, settings.simulation, settings.analysis);
            testCase.verifyEqual(corrected.map, expected.map, AbsTol=0);
            testCase.verifyEqual(corrected.co2, expected.co2, AbsTol=0);
        end

        function optionalComplexScoreHandlesAZeroPathway(testCase)
            [settings, ~, ~] = simulationFixture();
            settings.simulation.metrics = "complex";
            settings.simulation.baseline.co2GainRatio = 0;
            results = runAnalysis(settings);
            testCase.verifyTrue(all(isfinite(results.simulation.advantage.co2.complex.advantage)));
        end

        function existingGaussianAndWhiteNoiseOptionsRemainRunnable(testCase)
            [settings, ~, ~] = simulationFixture();
            settings.simulation.inputs.spectrumModel = "gaussian";
            settings.simulation.noiseSpectrum = "white";
            settings.simulation.vary = "spectralSimilarity";
            settings.simulation.ranges.spectralSimilarity = [0 1];
            results = runAnalysis(settings);
            testCase.verifyEqual(height(results.simulation.conditions), 2);
            testCase.verifyEqual(numel(results.recordings), 4);
            testCase.verifyTrue(all(isfinite(results.recordings(3).miso.map.gain)));
        end
    end
end

function [settings, generator, scenario] = simulationFixture()
    settings = runAnalysis("settings");
    settings.simulation.vary = strings(1, 0);
    settings.simulation.repetitions = 2;
    settings.simulation.bootstrapSamples = 0;
    settings.plots.createFigures = false;
    settings.output.saveMat = false;
    settings.output.saveCsv = false;
    settings.output.saveFigures = false;
    generator = settings.simulation;
    generator.samplingFrequencyHz = settings.analysis.fsTarget;
    scenario.targetInputCoherence = 0.15;
    scenario.spectralSimilarityControl = 1;
    scenario.petco2ToMapFluctuationSdRatio = 1;
    scenario.petco2ToMapBandGainRatio = 1;
    scenario.mapPathwayTimeConstantSeconds = 3;
    scenario.co2PathwayTimeConstantSeconds = 5;
    scenario.co2DelaySeconds = 3;
    scenario.inputPhaseLagSeconds = 0;
end
