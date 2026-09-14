classdef projectSettingsTest < matlab.unittest.TestCase
    % projectSettingsTest Verify one source for core frequency settings.

    methods (TestClassSetup)
        function addProjectFolders(testCase)
            projectRoot = fileparts(fileparts(mfilename("fullpath")));
            testCase.applyFixture( ...
                matlab.unittest.fixtures.PathFixture( ...
                projectRoot, IncludingSubfolders=true));
        end
    end

    methods (Test)
        function projectSettingsExposeSamplingAndBands(testCase)
            project = projectSettings();

            testCase.verifyEqual(project.samplingFrequencyHz, 4);
            testCase.verifyEqual(project.analysis.nyquistFrequencyHz, 2);
            testCase.verifyEqual( ...
                project.analysis.reportingBandHz, [0.005 0.35]);
            testCase.verifyEqual( ...
                project.analysis.pathwayCalibrationBandHz, [0.005 0.35]);
            testCase.verifyEqual( ...
                numel(project.analysis.frequencyBandNames), ...
                numel(project.analysis.frequencyBandEdgesHz) - 1);
        end

        function numericalDefaultsUseProjectBands(testCase)
            project = projectSettings();
            numerical = defaultTfaNumericalSettings();

            testCase.verifyEqual( ...
                numerical.fsTarget, project.samplingFrequencyHz);
            testCase.verifyEqual( ...
                numerical.frequencyRangeHz, ...
                project.analysis.reportingBandHz);
            testCase.verifyEqual( ...
                numerical.frequencyBandEdgesHz, ...
                project.analysis.frequencyBandEdgesHz);
            testCase.verifyEqual( ...
                numerical.frequencyBandNames, ...
                project.analysis.frequencyBandNames);
        end
    end
end
