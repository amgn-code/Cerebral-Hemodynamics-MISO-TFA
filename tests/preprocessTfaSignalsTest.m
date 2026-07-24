classdef preprocessTfaSignalsTest < matlab.unittest.TestCase
    % preprocessTfaSignalsTest Regression tests for preprocessing.

    methods (TestClassSetup)
        function addSourceToPath(testCase)
            projectRoot = fileparts(fileparts(mfilename('fullpath')));
            testCase.applyFixture(matlab.unittest.fixtures.PathFixture( ...
                projectRoot, IncludingSubfolders=true));
        end
    end

    methods (Test)
        function removesOnlyZerosAndSingleStartupTransition(testCase)
            co2 = [zeros(1, 7), 24.008, createStableCo2(280)];
            signalData = createPreprocessingTestSignal(co2);

            result = preprocessTfaSignals( ...
                signalData, 4, preprocessingTestSettings());

            testCase.verifyEqual(result.t(1), 8, AbsTol=1e-12);
            testCase.verifyGreaterThanOrEqual(numel(result.t), 1024);
        end

        function laterOutlierDoesNotHideStartupTransition(testCase)
            stableValues = createStableCo2(280);
            stableValues(150) = stableValues(150) + 20;
            co2 = [zeros(1, 7), 24.008, stableValues];
            signalData = createPreprocessingTestSignal(co2);

            result = preprocessTfaSignals( ...
                signalData, 4, preprocessingTestSettings());

            testCase.verifyEqual(result.t(1), 8, AbsTol=1e-12);
        end

        function cleanStartupRemovesOnlyLeadingZeros(testCase)
            co2 = [zeros(1, 7), createStableCo2(281)];
            signalData = createPreprocessingTestSignal(co2);

            result = preprocessTfaSignals( ...
                signalData, 4, preprocessingTestSettings());

            testCase.verifyEqual(result.t(1), 7, AbsTol=1e-12);
        end

        function reportsLateCo2StartupDuration(testCase)
            co2 = [zeros(1, 29), createStableCo2(281)];
            signalData = createPreprocessingTestSignal(co2);

            result = preprocessTfaSignals( ...
                signalData, 4, preprocessingTestSettings());

            testCase.verifyEqual( ...
                result.co2Startup.stableStartTimeSeconds, 29, ...
                AbsTol=1e-12);
            testCase.verifyEqual( ...
                result.co2Startup.removedDurationSeconds, 29, ...
                AbsTol=1e-12);
        end

        function returnsHorizontalArrays(testCase)
            signalData = createPreprocessingTestSignal( ...
                createStableCo2(281));

            result = preprocessTfaSignals( ...
                signalData, 4, preprocessingTestSettings());

            testCase.verifySize(result.t, [1 numel(result.t)]);
            testCase.verifySize(result.map, [1 numel(result.map)]);
            testCase.verifySize(result.co2, [1 numel(result.co2)]);
            testCase.verifySize(result.cbv, [1 numel(result.cbv)]);
        end

        function canKeepCbvInCmPerSec(testCase)
            signalData = createPreprocessingTestSignal( ...
                createStableCo2(281));
            settings = preprocessingTestSettings();
            settings.normalizeCbv = false;

            result = preprocessTfaSignals(signalData, 4, settings);

            testCase.verifyEqual(result.cbv, 50*ones(size(result.cbv)), ...
                AbsTol=1e-12);
            testCase.verifyEqual(result.cbvUnits, "cm/s");
        end

        function canNormalizeCbvToPercentBaseline(testCase)
            signalData = createPreprocessingTestSignal( ...
                createStableCo2(281));

            result = preprocessTfaSignals( ...
                signalData, 4, preprocessingTestSettings());

            testCase.verifyEqual(result.cbv, 100*ones(size(result.cbv)), ...
                AbsTol=1e-12);
            testCase.verifyEqual(result.cbvUnits, "% baseline CBV");
        end

        function preservesPhysiologicalSubjectSummaries(testCase)
            signalData = createPreprocessingTestSignal( ...
                createStableCo2(281));

            result = preprocessTfaSignals( ...
                signalData, 4, preprocessingTestSettings());

            testCase.verifyEqual( ...
                result.physiology.meanMapMmHg, 90, AbsTol=1e-12);
            testCase.verifyEqual( ...
                result.physiology.meanCbvCmPerSec, 50, AbsTol=1e-12);
            testCase.verifyEqual( ...
                result.physiology.cvri, 1.8, AbsTol=1e-12);
        end

        function usesUserSelectedSamplingFrequency(testCase)
            signalData = createPreprocessingTestSignal( ...
                createStableCo2(281));

            result = preprocessTfaSignals( ...
                signalData, 2, preprocessingTestSettings());

            testCase.verifyEqual(result.fs, 2, AbsTol=1e-12);
            testCase.verifyEqual(diff(result.t), ...
                0.5*ones(size(diff(result.t))), AbsTol=1e-12);
        end
    end
end
