classdef calculateFrequencyTruthErrorsTest < matlab.unittest.TestCase
    % calculateFrequencyTruthErrorsTest Verify the truth-error contract.

    methods (TestClassSetup)
        function addSourceFolder(testCase)
            projectFolder = fileparts(fileparts(mfilename('fullpath')));
            testCase.applyFixture( ...
                matlab.unittest.fixtures.PathFixture( ...
                    projectFolder, IncludingSubfolders=true));
        end
    end

    methods (Test)
        function normalizationUsesTruthEvenWhenEstimateIsMissing(testCase)
            truth = [1; 0.5];
            completeEstimate = [0.8; 0.4];
            incompleteEstimate = [0.8; NaN];

            completeErrors = calculateFrequencyTruthErrors( ...
                completeEstimate, truth, 1e-12);
            incompleteErrors = calculateFrequencyTruthErrors( ...
                incompleteEstimate, truth, 1e-12);

            expectedNormalization = mean(truth.^2);
            expectedError = (1 - 0.8)^2/expectedNormalization;
            testCase.verifyEqual( ...
                completeErrors.complex(1), expectedError, AbsTol=1e-12);
            testCase.verifyEqual( ...
                incompleteErrors.complex(1), expectedError, AbsTol=1e-12);
            testCase.verifyEqual( ...
                completeErrors.truthBandRmsGain, ...
                incompleteErrors.truthBandRmsGain, AbsTol=1e-12);
            testCase.verifyEqual( ...
                completeErrors.complexNormalization, "truth-band-rms");
        end

        function zeroTruthUsesAbsoluteComplexError(testCase)
            errors = calculateFrequencyTruthErrors( ...
                [1; 0], [0; 0], 1e-12);

            testCase.verifyEqual(errors.complex, [1; 0]);
            testCase.verifyEqual(errors.complexNormalization, "absolute");
            testCase.verifyTrue(all(isnan(errors.phase)));
        end
    end
end
