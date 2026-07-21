classdef circularPhaseStatisticsTest < matlab.unittest.TestCase
    % circularPhaseStatisticsTest Tests standard circular phase summaries.

    methods (TestClassSetup)
        function addSourceToPath(testCase)
            projectRoot = fileparts(fileparts(mfilename("fullpath")));
            testCase.applyFixture( ...
                matlab.unittest.fixtures.PathFixture( ...
                    fullfile(projectRoot, "src"), ...
                    IncludingSubfolders=true));
        end
    end

    methods (Test)
        function meanCrossesWrappedBoundary(testCase)
            phaseValues = deg2rad([179, -179]);

            meanPhase = circularMeanPhase(phaseValues);

            testCase.verifyEqual(abs(meanPhase), pi, AbsTol=1e-12);
        end

        function standardDeviationUsesResultantLength(testCase)
            phaseValues = [0, pi/2];
            resultantLength = abs(mean(exp(1i*phaseValues)));
            expectedSd = sqrt(-2*log(resultantLength));

            actualSd = circularStdPhase(phaseValues);

            testCase.verifyEqual(actualSd, expectedSd, AbsTol=1e-12);
        end
    end
end
