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
        function syntheticModeRunsOneSubject(testCase)
            outputFolder = tempname();
            testCase.addTeardown(@() rmdir(outputFolder, "s"));
            [analysisSettings, outputSettings] = ...
                createWorkflowTestSettings(outputFolder, true, true);

            runResults = runTFA( ...
                "synthetic", struct(), struct(), ...
                analysisSettings, outputSettings);

            testCase.verifyEqual(runResults.runType, "synthetic");
            testCase.verifyEqual(height(runResults.subjectList), 1);
            testCase.verifyEqual(numel(runResults.subjectResults), 1);
            testCase.verifyEmpty(fieldnames(runResults.groupResults));
        end

        function runsMisoOnly(testCase)
            outputFolder = tempname();
            testCase.addTeardown(@() rmdir(outputFolder, "s"));
            subjectResults = runSelectedWorkflow( ...
                outputFolder, true, false);

            testCase.verifyNotEmpty(subjectResults.misoResults);
            testCase.verifyEmpty(subjectResults.sisoResults);
        end

        function runsSisoOnly(testCase)
            outputFolder = tempname();
            testCase.addTeardown(@() rmdir(outputFolder, "s"));
            subjectResults = runSelectedWorkflow( ...
                outputFolder, false, true);

            testCase.verifyEmpty(subjectResults.misoResults);
            testCase.verifyNotEmpty(subjectResults.sisoResults);
        end

        function runsBothModels(testCase)
            outputFolder = tempname();
            testCase.addTeardown(@() rmdir(outputFolder, "s"));
            subjectResults = runSelectedWorkflow( ...
                outputFolder, true, true);
            groupResults = createGroupResults( ...
                {subjectResults}, "Test", true, true, ...
                createTestPhaseSettings("standard"));

            testCase.verifyNotEmpty(subjectResults.misoResults);
            testCase.verifyNotEmpty(subjectResults.sisoResults);
            testCase.verifyTrue(isfield(groupResults, "TEST"));
            testCase.verifyTrue(isfield(groupResults.TEST, "miso"));
            testCase.verifyTrue(isfield(groupResults.TEST, "siso"));
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
            testCase.verifyFalse(any( ...
                string(subjectList.Properties.VariableNames) == "Session"));
        end

        function discoveryPreservesGroupOrderAndSortsNumericIds(testCase)
            dataFolder = tempname();
            mciFolder = fullfile(dataFolder, "MCI");
            lcFolder = fullfile(dataFolder, "LC");
            mkdir(mciFolder);
            mkdir(lcFolder);
            testCase.addTeardown(@() rmdir(dataFolder, "s"));
            firstFile = fopen( ...
                fullfile(lcFolder, "10_baseline.xlsx"), "w");
            fclose(firstFile);
            secondFile = fopen( ...
                fullfile(lcFolder, "2_baseline.xlsx"), "w");
            fclose(secondFile);
            thirdFile = fopen( ...
                fullfile(mciFolder, "5_baseline.xlsx"), "w");
            fclose(thirdFile);

            subjectList = findIEEMSubjects( ...
                dataFolder, ["MCI"; "LC"]);

            testCase.verifyEqual( ...
                subjectList.Group, ["MCI"; "LC"; "LC"]);
            testCase.verifyEqual( ...
                subjectList.SubjectID, ["5"; "2"; "10"]);
        end

        function duplicateSubjectFilesAreRejected(testCase)
            dataFolder = tempname();
            ncFolder = fullfile(dataFolder, "NC");
            mkdir(ncFolder);
            testCase.addTeardown(@() rmdir(dataFolder, "s"));
            baselineFile = fopen( ...
                fullfile(ncFolder, "1001_baseline.xlsx"), "w");
            fclose(baselineFile);
            duplicateFile = fopen( ...
                fullfile(ncFolder, "1001_repeat.xlsx"), "w");
            fclose(duplicateFile);

            testCase.verifyError( ...
                @() findIEEMSubjects(dataFolder, "NC"), ...
                'TFA:DuplicateSubjectFiles');
        end

        function previewIdentifiesReadyAndShortSubjects(testCase)
            dataFolder = tempname();
            lcFolder = fullfile(dataFolder, "LC");
            mkdir(lcFolder);
            testCase.addTeardown(@() rmdir(dataFolder, "s"));

            signalData = createSyntheticSignal(4);
            readyData = table( ...
                signalData.t(:), signalData.map(:), ...
                signalData.co2(:), signalData.cbv(:), ...
                'VariableNames', {'Time', 'MAP', 'CO2', 'CBV'});
            shortData = readyData(1:400, :);

            writetable( ...
                readyData, fullfile(lcFolder, "1054_baseline.xlsx"), ...
                "Sheet", "Sheet1");
            writetable( ...
                shortData, fullfile(lcFolder, "1055_baseline.xlsx"), ...
                "Sheet", "Sheet1");

            [analysisSettings, outputSettings] = ...
                createWorkflowTestSettings( ...
                    fullfile(dataFolder, "output"), true, true);
            batchSettings.dataFolder = dataFolder;
            batchSettings.groupsToRun = "LC";
            batchSettings.previewOnly = true;

            runResults = runTFA( ...
                "batch", struct(), batchSettings, ...
                analysisSettings, outputSettings);
            previewTable = runResults.previewTable;

            testCase.verifyEqual( ...
                previewTable.IsReadyForTFA, [true; false]);
            testCase.verifyEqual( ...
                previewTable.ReadinessStage, ...
                ["Ready"; "TooShortForWelch"]);
            testCase.verifyEqual(previewTable.NumWelchWindows(1), 3);
            testCase.verifyFalse(any( ...
                string(previewTable.Properties.VariableNames) == ...
                "AnalysisSucceeded"));
        end

        function batchMasterToggleDisablesSubjectFigures(testCase)
            dataFolder = tempname();
            outputFolder = fullfile(dataFolder, "output");
            ncFolder = fullfile(dataFolder, "NC");
            mkdir(ncFolder);
            testCase.addTeardown(@() rmdir(dataFolder, "s"));
            signalData = createSyntheticSignal(4);
            subjectData = table( ...
                signalData.t(:), signalData.map(:), ...
                signalData.co2(:), signalData.cbv(:), ...
                'VariableNames', {'Time', 'MAP', 'CO2', 'CBV'});
            writetable( ...
                subjectData, ...
                fullfile(ncFolder, "1001_baseline.xlsx"), ...
                "Sheet", "Sheet1");
            [analysisSettings, outputSettings] = ...
                createWorkflowTestSettings( ...
                    outputFolder, true, false);
            outputSettings.saveSubjectFigures = false;
            batchSettings.dataFolder = dataFolder;
            batchSettings.groupsToRun = "NC";
            batchSettings.targetSuccessfulSubjectsPerGroup = Inf;
            batchSettings.previewOnly = false;
            batchSettings.numSubjectFiguresPerGroup = 1;

            runResults = runTFA( ...
                "batch", struct(), batchSettings, ...
                analysisSettings, outputSettings);

            testCase.verifyEqual( ...
                runResults.subjectFigureCounts.SavedSubjectFigures, 0);
            testCase.verifyEmpty( ...
                runResults.subjectResults{1}.subjectFigureFiles);
        end

        function identifiesCo2StartupThatMakesRecordingTooShort(testCase)
            outputFolder = tempname();
            mkdir(outputFolder);
            testCase.addTeardown(@() rmdir(outputFolder, "s"));
            signalData = createSyntheticSignal(4);
            numSamples = 260*4;
            signalData.t = signalData.t(1:numSamples);
            signalData.map = signalData.map(1:numSamples);
            signalData.co2 = signalData.co2(1:numSamples);
            signalData.cbv = signalData.cbv(1:numSamples);
            signalData.co2(1:40) = 0;
            subjectInfo.subjectID = "startup";
            subjectInfo.group = "NC";
            subjectInfo.sourceFile = "synthetic";
            [analysisSettings, outputSettings] = ...
                createWorkflowTestSettings(outputFolder, true, true);

            subjectResult = analyzeSubjectTFA( ...
                signalData, subjectInfo, ...
                analysisSettings, outputSettings);

            testCase.verifyFalse( ...
                subjectResult.runStatus.analysisSucceeded);
            testCase.verifyEqual( ...
                subjectResult.runStatus.runStage, "LateCO2Startup");
        end
    end
end
