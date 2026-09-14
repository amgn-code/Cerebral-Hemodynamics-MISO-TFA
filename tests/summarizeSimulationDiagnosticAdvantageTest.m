classdef summarizeSimulationDiagnosticAdvantageTest < matlab.unittest.TestCase
    % summarizeSimulationDiagnosticAdvantageTest Verify dynamic binning.

    methods (TestClassSetup)
        function addProjectFolders(testCase)
            projectRoot = fileparts(fileparts(mfilename("fullpath")));
            testCase.applyFixture( ...
                matlab.unittest.fixtures.PathFixture( ...
                    projectRoot, IncludingSubfolders=true));
        end
    end

    methods (Test)
        function binsUseDiagnosticValuesAtEachFrequency(testCase)
            diagnosticValues = [ ...
                0.1 0.2 0.8 0.9; ...
                0.2 0.2 0.8 0.9];
            sisoErrors = [1 3 2 4; 2 4 4 8];
            misoErrors = [1 1 1 2; 1 2 2 4];

            summary = summarizeSimulationDiagnosticAdvantage( ...
                diagnosticValues, sisoErrors, misoErrors, ...
                "Diagnostic", 0:0.5:1, "Diagnostic", struct());

            testCase.verifyEqual(summary.validN(:, 1), [2; 2]);
            testCase.verifyEqual(summary.sisoMean(:, 1), [2; 3]);
            testCase.verifyEqual(summary.misoMean(:, 1), [1; 1.5]);
            testCase.verifyEqual( ...
                summary.advantage(1, 1), log10(2), AbsTol=1e-12);
            testCase.verifyEqual( ...
                summary.advantage(2, 1), log10(2), AbsTol=1e-12);
        end

        function bootstrapIsRepeatable(testCase)
            diagnosticValues = repmat([0.1 0.2 0.8 0.9], 2, 1);
            sisoErrors = repmat([1 2 3 4], 2, 1);
            misoErrors = repmat([1 1 2 2], 2, 1);
            bootstrap.enabled = true;
            bootstrap.numSamples = 100;
            bootstrap.randomSeed = 2027;
            bootstrap.confidenceLevel = 0.95;

            first = summarizeSimulationDiagnosticAdvantage( ...
                diagnosticValues, sisoErrors, misoErrors, ...
                "Diagnostic", 0:0.5:1, "Diagnostic", bootstrap);
            second = summarizeSimulationDiagnosticAdvantage( ...
                diagnosticValues, sisoErrors, misoErrors, ...
                "Diagnostic", 0:0.5:1, "Diagnostic", bootstrap);

            testCase.verifyEqual(first.bootstrapSD, second.bootstrapSD);
            testCase.verifyEqual(first.ciLower, second.ciLower);
            testCase.verifyEqual(first.ciUpper, second.ciUpper);
            testCase.verifyTrue(all(isfinite(first.ciLower), "all"));
            testCase.verifyTrue(all(isfinite(first.ciUpper), "all"));
        end
    end
end
