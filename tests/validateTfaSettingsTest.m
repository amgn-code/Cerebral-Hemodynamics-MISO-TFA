classdef validateTfaSettingsTest < matlab.unittest.TestCase
    % validateTfaSettingsTest Tests user-facing analysis settings.

    methods (TestClassSetup)
        function addSourceToPath(testCase)
            projectRoot = fileparts(fileparts(mfilename('fullpath')));
            testCase.applyFixture(matlab.unittest.fixtures.PathFixture( ...
                projectRoot, IncludingSubfolders=true));
        end
    end

    methods (Test)
        function rangeControlsPlotLimits(testCase)
            [settings, ~] = createWorkflowTestSettings( ...
                tempname(), true, false);

            settings = validateTfaSettings(settings);

            testCase.verifyEqual( ...
                settings.frequencyRangeHz, [0 0.35], AbsTol=1e-12);
            testCase.verifyEqual( ...
                settings.plot.frequencyLimitsHz, [0 0.35], ...
                AbsTol=1e-12);
        end

        function rejectsBandsOutsideRange(testCase)
            [settings, ~] = createWorkflowTestSettings( ...
                tempname(), true, false);
            settings.frequencyRangeHz = [0.01 0.35];

            testCase.verifyError( ...
                @() validateTfaSettings(settings), ...
                'TFA:FrequencyBandsOutsideAnalysisRange');
        end

        function rejectsEvenSmoothingKernel(testCase)
            [settings, ~] = createWorkflowTestSettings( ...
                tempname(), true, false);
            settings.pwelch.smoothingKernel = [0.5 0.5];

            testCase.verifyError( ...
                @() validateTfaSettings(settings), ...
                'TFA:EvenSmoothingKernel');
        end

        function rejectsSmoothingKernelThatChangesScale(testCase)
            [settings, ~] = createWorkflowTestSettings( ...
                tempname(), true, false);
            settings.pwelch.smoothingKernel = [0.25 0.25 0.25];

            testCase.verifyError( ...
                @() validateTfaSettings(settings), ...
                'TFA:SmoothingKernelDoesNotSumToOne');
        end

    end
end
