classdef workflowSettingsTest < matlab.unittest.TestCase
    % workflowSettingsTest Verify model selection and dynamic group support.

    methods (TestClassSetup)
        function addProjectFolders(testCase)
            projectRoot = fileparts(fileparts(mfilename("fullpath")));
            testCase.applyFixture( ...
                matlab.unittest.fixtures.PathFixture( ...
                    fullfile(projectRoot, "src"), ...
                    "IncludingSubfolders", true));
            testCase.applyFixture( ...
                matlab.unittest.fixtures.PathFixture( ...
                    fullfile(projectRoot, "tests", "helpers")));
        end
    end

    methods (Test)
        function runsMisoOnly(testCase)
            outputFolder = tempname();
            testCase.addTeardown(@() rmdir(outputFolder, "s"));
            subjectResults = runSelectedWorkflow( ...
                outputFolder, true, false);

            testCase.verifyNotEmpty(subjectResults.tfaResults);
            testCase.verifyEmpty(subjectResults.sisoResults);
            testCase.verifyTrue(subjectResults.runStatus.runMISO);
            testCase.verifyFalse(subjectResults.runStatus.runSISO);
        end

        function runsSisoOnly(testCase)
            outputFolder = tempname();
            testCase.addTeardown(@() rmdir(outputFolder, "s"));
            subjectResults = runSelectedWorkflow( ...
                outputFolder, false, true);

            testCase.verifyEmpty(subjectResults.tfaResults);
            testCase.verifyNotEmpty(subjectResults.sisoResults);
            testCase.verifyFalse(subjectResults.runStatus.runMISO);
            testCase.verifyTrue(subjectResults.runStatus.runSISO);
        end

        function runsBothModels(testCase)
            outputFolder = tempname();
            testCase.addTeardown(@() rmdir(outputFolder, "s"));
            subjectResults = runSelectedWorkflow( ...
                outputFolder, true, true);
            groupResults = createGroupResults( ...
                {subjectResults}, "LC", true, true, ...
                createTestPhaseSettings("standard"));

            testCase.verifyNotEmpty(subjectResults.tfaResults);
            testCase.verifyNotEmpty(subjectResults.sisoResults);
            testCase.verifyTrue(isfield(groupResults, "LC"));
            testCase.verifyTrue(isfield(groupResults.LC, "miso"));
            testCase.verifyTrue(isfield(groupResults.LC, "siso"));
        end

        function discoversLcSubjects(testCase)
            dataFolder = tempname();
            lcFolder = fullfile(dataFolder, "LC");
            mkdir(lcFolder);
            testCase.addTeardown(@() rmdir(dataFolder, "s"));

            fileId = fopen(fullfile(lcFolder, "1054_baseline.xlsx"), "w");
            fclose(fileId);

            subjectList = findIEEMSubjects(dataFolder, 'LC');

            testCase.verifyEqual(subjectList.Group, "LC");
            testCase.verifyEqual(subjectList.SubjectID, "1054");
            testCase.verifyEqual(subjectList.Session, "baseline");
        end
    end
end
