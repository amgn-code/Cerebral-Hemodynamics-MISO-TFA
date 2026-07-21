classdef runSISOTFATest < matlab.unittest.TestCase
    % runSISOTFATest Tests the SISO analysis interface.

    methods (TestClassSetup)
        function addSourceFolder(testCase)
            projectFolder = fileparts(fileparts(mfilename('fullpath')));
            testCase.applyFixture(matlab.unittest.fixtures.PathFixture( ...
                projectFolder, IncludingSubfolders=true));
        end
    end

    methods (Test)
        function returnsNestedResults(testCase)
            signalData = createSyntheticSignal(4);
            results = runSisoTestAnalysis(signalData, "standard");

            testCase.verifyTrue(isfield(results, 'map'));
            testCase.verifyTrue(isfield(results, 'co2'));
            testCase.verifyTrue(isfield(results, 'cbv'));
            testCase.verifyTrue(isfield(results, 'inputRelationship'));
            testCase.verifyFalse(isfield(results, 'system'));
            testCase.verifyFalse(isfield(results, 'diagnostics'));
            testCase.verifyFalse(isfield(results, 'mapCbvGain'));
            testCase.verifyFalse(isfield(results.map.phase, 'display'));
            testCase.verifyFalse(isfield(results.co2.phase, 'display'));
            testCase.verifyFalse(isfield(results.map.phase, 'unwrapMethod'));
            testCase.verifyFalse(isfield(results.co2.phase, 'unwrapMethod'));
            testCase.verifyFalse( ...
                isfield(results.inputRelationship.phase, 'unwrapMethod'));
            testCase.verifyFalse(isfield(results, 'settings'));
            testCase.verifyFalse( ...
                isfield(results.welchInfo, 'phaseUnwrapMethod'));
            testCase.verifyEqual(results.phaseUnwrapMethod, "standard");
            testCase.verifyEqual( ...
                results.map.gain, abs(results.map.transferFunction));
            testCase.verifyEqual( ...
                results.co2.gain, abs(results.co2.transferFunction));
            testCase.verifyEqual( ...
                results.map.unexplainedFraction, ...
                1 - results.map.coherence.pairwise);
            testCase.verifyEqual( ...
                results.co2.unexplainedFraction, ...
                1 - results.co2.coherence.pairwise);
            testCase.verifyEqual( ...
                results.map.residualPower, ...
                real(results.cbv.power) .* ...
                results.map.unexplainedFraction);
        end

        function standardPhaseIsStoredExplicitly(testCase)
            signalData = createSyntheticSignal(4);
            results = runSisoTestAnalysis(signalData, "standard");

            testCase.verifyEqual( ...
                results.map.phase.wrapped, ...
                angle(results.map.transferFunction));
            testCase.verifyEqual( ...
                results.map.phase.unwrapped, ...
                unwrap(results.map.phase.wrapped));
            testCase.verifyEqual( ...
                results.co2.phase.unwrapped, ...
                unwrap(results.co2.phase.wrapped));
        end

        function limitsEveryNestedFrequencyArray(testCase)
            signalData = createSyntheticSignal(4);
            fullResults = runSisoTestAnalysis(signalData, "standard");
            results = limitResultsToFrequencyRange( ...
                fullResults, "siso", [0, 0.35]);
            numFrequencies = numel(results.f);

            testCase.verifyEqual(numel(results.map.gain), numFrequencies);
            testCase.verifyEqual( ...
                numel(results.co2.transferFunction), numFrequencies);
            testCase.verifyEqual( ...
                numel(results.map.residualPower), numFrequencies);
            testCase.verifyEqual( ...
                numel(results.inputRelationship.phase.unwrapped), numFrequencies);
            testCase.verifyLessThanOrEqual(max(results.f), 0.35);
        end

        function customPhaseMethodRuns(testCase)
            signalData = createSyntheticSignal(4);
            results = runSisoTestAnalysis(signalData, "custom");

            circularDifference = angle(exp(1i*( ...
                results.map.phase.unwrapped - results.map.phase.wrapped)));

            testCase.verifyEqual( ...
                size(results.map.phase.unwrapped), size(results.f));
            testCase.verifyEqual( ...
                circularDifference, zeros(size(circularDifference)), ...
                AbsTol=1e-12);
            testCase.verifyEqual(results.phaseUnwrapMethod, "custom");
        end
    end
end
