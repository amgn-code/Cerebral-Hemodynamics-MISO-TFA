classdef summarizeSimulationFrequencyAdvantageTest < matlab.unittest.TestCase
    % summarizeSimulationFrequencyAdvantageTest Verify the primary score.

    methods (TestClassSetup)
        function addProjectFolders(testCase)
            projectRoot = fileparts(fileparts(mfilename("fullpath")));
            testCase.applyFixture( ...
                matlab.unittest.fixtures.PathFixture( ...
                    projectRoot, IncludingSubfolders=true));
        end
    end

    methods (Test)
        function scoreIsRatioOfMeanErrors(testCase)
            factorValues = [0; 0; 1; 1];
            sisoErrors = [1 4 2 8; 2 6 4 12];
            misoErrors = [0.5 1.5 4 4; 1 3 8 6];

            summary = summarizeSimulationFrequencyAdvantage( ...
                factorValues, sisoErrors, misoErrors, ...
                "Factor", "exact", struct());

            testCase.verifyEqual( ...
                summary.advantage(1, 1), log10(2.5), AbsTol=1e-12);
            testCase.verifyEqual( ...
                summary.sisoMean(1, 1), 2.5, AbsTol=1e-12);
            testCase.verifyEqual( ...
                summary.misoMean(1, 1), 1, AbsTol=1e-12);
            testCase.verifyEqual(summary.validN(:, 1), [2; 2]);
            testCase.verifyNotEqual( ...
                summary.advantage(1, 1), ...
                mean(log10(sisoErrors(1, 1:2)./misoErrors(1, 1:2))));
            testCase.verifyEqual( ...
                summary.scoreVersion, "frequency-ratio-of-mean-errors-v1");
        end

        function zeroMeansAreRepresentedWithoutAnArtificialFloor(testCase)
            summary = summarizeSimulationFrequencyAdvantage( ...
                [0; 1], [0 1], [0 0], "Factor", "exact", struct());

            testCase.verifyEqual(summary.advantage(1, 1), 0);
            testCase.verifyEqual(summary.advantage(2, 1), Inf);
        end

        function bootstrapUsesPairedRecordsAndIsRepeatable(testCase)
            factorValues = [0; 0; 0; 1; 1; 1];
            sisoErrors = [1 2 3 4 5 6];
            misoErrors = [1 1 2 2 3 4];
            bootstrap.enabled = true;
            bootstrap.numSamples = 200;
            bootstrap.randomSeed = 19;
            bootstrap.confidenceLevel = 0.95;

            first = summarizeSimulationFrequencyAdvantage( ...
                factorValues, sisoErrors, misoErrors, ...
                "Factor", "exact", struct(), bootstrap);
            second = summarizeSimulationFrequencyAdvantage( ...
                factorValues, sisoErrors, misoErrors, ...
                "Factor", "exact", struct(), bootstrap);

            testCase.verifyEqual(first.bootstrapSD, second.bootstrapSD);
            testCase.verifyEqual(first.ciLower, second.ciLower);
            testCase.verifyEqual(first.ciUpper, second.ciUpper);
            testCase.verifyTrue(all(isfinite(first.ciLower), "all"));
            testCase.verifyTrue(all(isfinite(first.ciUpper), "all"));
        end
    end
end
