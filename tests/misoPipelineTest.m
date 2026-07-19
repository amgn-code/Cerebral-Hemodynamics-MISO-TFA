classdef misoPipelineTest < matlab.unittest.TestCase
    % misoPipelineTest Tests the results-only MISO analysis interface.

    methods (TestClassSetup)
        function addSourceFolder(testCase)
            projectFolder = fileparts(fileparts(mfilename('fullpath')));
            testCase.applyFixture(matlab.unittest.fixtures.PathFixture( ...
                projectFolder, IncludingSubfolders=true));
        end
    end

    methods (Test)
        function returnsNestedResults(testCase)
            signalData = createTestSignal(4);
            results = runMisoTestAnalysis(signalData, "standard");

            testCase.verifyTrue(isfield(results, 'map'));
            testCase.verifyTrue(isfield(results, 'co2'));
            testCase.verifyTrue(isfield(results, 'cbv'));
            testCase.verifyTrue(isfield(results, 'system'));
            testCase.verifyTrue(isfield(results, 'inputRelationship'));
            testCase.verifyTrue(isfield(results, 'diagnostics'));
            testCase.verifyFalse(isfield(results.map.phase, 'anchored'));
            testCase.verifyFalse(isfield(results.co2.phase, 'anchored'));
            testCase.verifyFalse(isfield(results.map.phase, 'display'));
            testCase.verifyFalse(isfield(results.co2.phase, 'display'));
            testCase.verifyFalse(isfield(results.map.phase, 'unwrapMethod'));
            testCase.verifyFalse(isfield(results.co2.phase, 'unwrapMethod'));
            testCase.verifyFalse( ...
                isfield(results.inputRelationship.phase, 'unwrapMethod'));
            testCase.verifyFalse(isfield(results.map.coherence, 'pairwise'));
            testCase.verifyFalse(isfield(results.co2.coherence, 'pairwise'));
            testCase.verifyFalse(isfield(results, 'settings'));
            testCase.verifyFalse( ...
                isfield(results.welchInfo, 'phaseUnwrapMethod'));
            testCase.verifyEqual(results.phaseUnwrapMethod, "standard");
            testCase.verifyFalse(isfield(results.diagnostics, 'coherence'));
            testCase.verifyFalse( ...
                isfield(results.diagnostics, 'regularizationLambda'));
            testCase.verifyEqual( ...
                results.map.gain, abs(results.map.transferFunction));
            testCase.verifyEqual( ...
                results.co2.gain, abs(results.co2.transferFunction));
            testCase.verifyEqual( ...
                results.system.unexplainedFraction, ...
                1 - results.system.multipleCoherence);
            testCase.verifyEqual( ...
                results.system.residualPower, ...
                real(results.cbv.power) .* ...
                results.system.unexplainedFraction);
        end

        function standardPhaseIsStoredExplicitly(testCase)
            signalData = createTestSignal(4);
            results = runMisoTestAnalysis(signalData, "standard");

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

        function calculatesBandAveragesFromStoredResults(testCase)
            signalData = createTestSignal(4);
            results = runMisoTestAnalysis(signalData, "standard");
            bandAverages = computeMISOBandAverages( ...
                results, [0.005; 0.024; 0.070; 0.200; 0.350], ...
                ["VVLF"; "VLF"; "LF"; "HF"]);

            testCase.verifyEqual(height(bandAverages), 4);
            testCase.verifyTrue(any( ...
                bandAverages.Properties.VariableNames == ...
                "MAP_Phase_Unwrapped_Mean_rad"));
            testCase.verifyFalse(any(contains( ...
                bandAverages.Properties.VariableNames, "Anchored")));
        end

        function limitsEveryNestedFrequencyArray(testCase)
            signalData = createTestSignal(4);
            fullResults = runMisoTestAnalysis(signalData, "standard");
            results = limitMisoResultsToFrequencyRange( ...
                fullResults, [0, 0.35]);
            numFrequencies = numel(results.f);

            testCase.verifyEqual(numel(results.map.gain), numFrequencies);
            testCase.verifyEqual( ...
                numel(results.co2.transferFunction), numFrequencies);
            testCase.verifyEqual( ...
                numel(results.system.multipleCoherence), numFrequencies);
            testCase.verifyEqual( ...
                numel(results.inputRelationship.phase.unwrapped), numFrequencies);
            testCase.verifyEqual( ...
                numel(results.diagnostics.conditionNumber), numFrequencies);
            testCase.verifyLessThanOrEqual(max(results.f), 0.35);
        end

        function customPhaseMethodRuns(testCase)
            signalData = createTestSignal(4);
            results = runMisoTestAnalysis(signalData, "custom");

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
