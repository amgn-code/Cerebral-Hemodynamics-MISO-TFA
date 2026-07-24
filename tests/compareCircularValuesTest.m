classdef compareCircularValuesTest < matlab.unittest.TestCase
    % compareCircularValuesTest Verify circular comparison behavior.

    methods (TestClassSetup)
        function addSourceToPath(testCase)
            projectRoot = fileparts(fileparts(mfilename("fullpath")));
            testCase.applyFixture( ...
                matlab.unittest.fixtures.PathFixture( ...
                    fullfile(projectRoot, "src"), ...
                    "IncludingSubfolders", true));
        end
    end

    methods (TestMethodSetup)
        function setRandomSeed(testCase)
            previousRandomState = rng;
            testCase.addTeardown(@() rng(previousRandomState));
            rng(10, "twister");
        end
    end

    methods (Test)
        function pairedComparisonFindsWrappedDifference(testCase)
            secondValues = linspace(-0.2, 0.2, 12)';
            firstValues = angle(exp(1i*(secondValues + 0.6)));

            comparison = compareCircularValues( ...
                firstValues, secondValues, "paired", 2000);

            testCase.verifyEqual( ...
                comparison.difference, 0.6, AbsTol=1e-12);
            testCase.verifyLessThan(comparison.pValue, 0.05);
        end

        function independentComparisonTreatsPiAsWrapped(testCase)
            firstValues = (pi - 0.1)*ones(8, 1);
            secondValues = (-pi + 0.1)*ones(8, 1);

            comparison = compareCircularValues( ...
                firstValues, secondValues, "independent", 200);

            testCase.verifyEqual( ...
                abs(comparison.difference), 0.2, AbsTol=1e-12);
        end
    end
end
