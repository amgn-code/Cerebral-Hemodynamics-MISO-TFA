classdef robustnessAnalysisTest < matlab.unittest.TestCase
    % robustnessAnalysisTest Verify empirical robustness utilities.

    methods (TestClassSetup)
        function addProjectFolders(testCase)
            projectRoot = fileparts(fileparts(mfilename('fullpath')));
            testCase.applyFixture( ...
                matlab.unittest.fixtures.PathFixture( ...
                    projectRoot, IncludingSubfolders=true));
        end
    end

    methods (Test)
        function circularShiftPreservesSamplesAndPower(testCase)
            signal = (1:20)';
            shifted = circularShiftSignal(signal, 7);

            testCase.verifyEqual(sort(shifted), signal);
            testCase.verifyEqual(sum(shifted.^2), sum(signal.^2));
            testCase.verifyNotEqual(shifted, signal);
        end

        function positiveDelayAdvancesCo2(testCase)
            map = [1; 0; 0; 0; 0];
            co2 = [0; 0; 1; 0; 0];
            cbv = map;

            [alignedMap, alignedCo2, alignedCbv] = ...
                alignCo2ByDelay(map, co2, cbv, 1, 2);

            testCase.verifyEqual(alignedMap, [1; 0; 0]);
            testCase.verifyEqual(alignedCo2, [1; 0; 0]);
            testCase.verifyEqual(alignedCbv, [1; 0; 0]);
        end

        function surrogateAnalysisRefitsEveryShift(testCase)
            signalData = createSyntheticSignal(4);
            analysisInput.map = signalData.map(:);
            analysisInput.co2 = signalData.co2(:);
            analysisInput.cbv = signalData.cbv(:);
            analysisInput.fs = signalData.fs;
            [analysisSettings, ~] = createWorkflowTestSettings( ...
                tempname(), true, true);
            analysisSettings = validateTfaSettings(analysisSettings);

            surrogateSettings.numSurrogates = 2;
            surrogateSettings.randomSeed = 42;
            surrogateSettings.minimumShiftSeconds = 20;
            results = runCo2CircularShiftSurrogates( ...
                analysisInput, analysisSettings, surrogateSettings);

            expectedBandRows = ...
                3*2*numel(analysisSettings.frequencyBandNames);
            testCase.verifyEqual( ...
                height(results.summary), expectedBandRows);
            testCase.verifyEqual( ...
                results.shiftLog.ShiftSamples(1), 0);
            testCase.verifyTrue(all( ...
                results.shiftLog.ShiftSamples(2:end) > 0));
        end

        function influenceRanksLargestChangeFirst(testCase)
            values = table( ...
                ["1"; "2"; "3"], repmat("NC", 3, 1), ...
                repmat("MAP", 3, 1), repmat("Gain", 3, 1), ...
                repmat("VLF", 3, 1), [1; 1; 5], ...
                'VariableNames', { ...
                    'SubjectID', 'Group', 'Pathway', 'Metric', ...
                    'Band', 'MISOminusSISO'});

            influence = calculateLeaveOneOutInfluence(values);
            mostInfluential = influence( ...
                influence.InfluenceRank == 1, :);

            testCase.verifyEqual(mostInfluential.SubjectID, "3");
        end
    end
end
