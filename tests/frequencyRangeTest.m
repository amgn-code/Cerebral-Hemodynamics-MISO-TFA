classdef frequencyRangeTest < matlab.unittest.TestCase
    % frequencyRangeTest Regression tests for the user-facing frequency range.

    methods (TestClassSetup)
        function addSourceToPath(testCase)
            projectRoot = fileparts(fileparts(mfilename('fullpath')));
            testCase.applyFixture(matlab.unittest.fixtures.PathFixture( ...
                projectRoot, IncludingSubfolders=true));
        end
    end

    methods (Test)
        function rangeControlsPlotLimits(testCase)
            settings.frequencyRangeHz = [0 0.35];
            settings.frequencyBandEdgesHz = [0.005 0.024 0.070 0.200 0.350];
            settings.plot = defaultPlotSettings();

            settings = normalizeAnalysisFrequencyRange(settings);

            testCase.verifyEqual(settings.frequencyRangeHz, [0 0.35]);
            testCase.verifyEqual(settings.plot.frequencyLimitsHz, [0 0.35]);
        end

        function rejectsBandsOutsideRange(testCase)
            settings.frequencyRangeHz = [0.01 0.35];
            settings.frequencyBandEdgesHz = [0.005 0.024 0.070 0.200 0.350];

            testCase.verifyError( ...
                @() normalizeAnalysisFrequencyRange(settings), ...
                'TFA:FrequencyBandsOutsideAnalysisRange');
        end

    end
end
