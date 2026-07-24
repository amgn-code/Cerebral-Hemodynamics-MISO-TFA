classdef adjustPValuesBenjaminiHochbergTest < matlab.unittest.TestCase
    % adjustPValuesBenjaminiHochbergTest Verify BH adjustment.

    methods (TestClassSetup)
        function addSourceToPath(testCase)
            projectRoot = fileparts(fileparts(mfilename("fullpath")));
            testCase.applyFixture( ...
                matlab.unittest.fixtures.PathFixture( ...
                    fullfile(projectRoot, "src"), ...
                    "IncludingSubfolders", true));
        end
    end

    methods (Test)
        function matchesKnownAdjustment(testCase)
            pValues = [0.01; 0.04; 0.03; 0.002];

            adjustedPValues = ...
                adjustPValuesBenjaminiHochberg(pValues);

            testCase.verifyEqual( ...
                adjustedPValues, [0.02; 0.04; 0.04; 0.008], ...
                AbsTol=1e-12);
        end

        function keepsMissingValuesMissing(testCase)
            pValues = [0.01 NaN 0.50];

            adjustedPValues = ...
                adjustPValuesBenjaminiHochberg(pValues);

            testCase.verifySize(adjustedPValues, size(pValues));
            testCase.verifyTrue(isnan(adjustedPValues(2)));
        end
    end
end
