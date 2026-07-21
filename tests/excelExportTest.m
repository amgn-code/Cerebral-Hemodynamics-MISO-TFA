classdef excelExportTest < matlab.unittest.TestCase
    % excelExportTest Verify the unified metric-based Excel output.

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
        function metricDefinitionsRespectTogglesAndModels(testCase)
            outputFolder = tempname();
            [analysisSettings, outputSettings] = ...
                createWorkflowTestSettings(outputFolder, true, false);
            outputSettings.excelMetrics.signals.mapPower = true;
            outputSettings.excelMetrics.miso.mapGain = true;
            outputSettings.excelMetrics.siso.mapGain = true;

            metrics = getExcelMetricDefinitions( ...
                outputSettings.excelMetrics, ...
                analysisSettings.runMISO, analysisSettings.runSISO);

            testCase.verifyEqual( ...
                string({metrics.sheetName})', ...
                ["MAP_Power"; "MISO_MAP_Gain"]);
        end

        function sheetContainsFrequencyAndBandSections(testCase)
            outputFolder = tempname();
            testCase.addTeardown(@() rmdir(outputFolder, "s"));
            subjectResult = runSelectedWorkflow( ...
                outputFolder, true, false);
            subjectResult.subjectInfo.group = "NC";
            subjectResult.subjectInfo.subjectID = "1001";
            [analysisSettings, outputSettings] = ...
                createWorkflowTestSettings(outputFolder, true, false);
            outputSettings.excelMetrics.miso.mapGain = true;
            metrics = getExcelMetricDefinitions( ...
                outputSettings.excelMetrics, true, false);

            sheetCells = createExcelMetricSheet( ...
                {subjectResult}, "NC", metrics(1), analysisSettings);

            numFrequencies = numel(subjectResult.misoResults.f);
            firstBandRow = numFrequencies + 5;
            vvlfMask = subjectResult.misoResults.f >= 0.005 & ...
                subjectResult.misoResults.f < 0.024;
            expectedBandValue = mean( ...
                subjectResult.misoResults.map.gain(vvlfMask), 'omitnan');

            testCase.verifyEqual( ...
                string(sheetCells(1,1:5)), ...
                ["Band", "Frequency_Hz", "NC 1001", "Mean", "SD"]);
            testCase.verifyEqual( ...
                sheetCells{2,3}, subjectResult.misoResults.map.gain(1), ...
                AbsTol=1e-12);
            testCase.verifyEqual( ...
                sheetCells{2,4}, subjectResult.misoResults.map.gain(1), ...
                AbsTol=1e-12);
            testCase.verifyEqual(sheetCells{2,5}, "");
            testCase.verifyEqual(sheetCells{numFrequencies + 2,1}, "");
            testCase.verifyEqual( ...
                sheetCells{numFrequencies + 3,1}, "Band Averages");
            testCase.verifyEqual(sheetCells{firstBandRow,1}, "VVLF");
            testCase.verifyEqual( ...
                sheetCells{firstBandRow,3}, expectedBandValue, ...
                AbsTol=1e-12);
            testCase.verifyEqual( ...
                sheetCells{firstBandRow,4}, expectedBandValue, ...
                AbsTol=1e-12);
            testCase.verifyEqual(sheetCells{firstBandRow,5}, "");
        end

        function bandStatisticsUseSubjectBandValues(testCase)
            outputFolder = tempname();
            testCase.addTeardown(@() rmdir(outputFolder, "s"));
            firstSubject = runSelectedWorkflow( ...
                outputFolder, true, false);
            firstSubject.subjectInfo.group = "NC";
            firstSubject.subjectInfo.subjectID = "1001";
            secondSubject = firstSubject;
            secondSubject.subjectInfo.subjectID = "1002";
            secondSubject.misoResults.map.gain = ...
                2*firstSubject.misoResults.map.gain;
            [analysisSettings, outputSettings] = ...
                createWorkflowTestSettings(outputFolder, true, false);
            outputSettings.excelMetrics.miso.mapGain = true;
            metrics = getExcelMetricDefinitions( ...
                outputSettings.excelMetrics, true, false);

            sheetCells = createExcelMetricSheet( ...
                {firstSubject; secondSubject}, ...
                "NC", metrics(1), analysisSettings);

            vvlfMask = firstSubject.misoResults.f >= 0.005 & ...
                firstSubject.misoResults.f < 0.024;
            firstBandValue = mean( ...
                firstSubject.misoResults.map.gain(vvlfMask), 'omitnan');
            secondBandValue = mean( ...
                secondSubject.misoResults.map.gain(vvlfMask), 'omitnan');
            expectedMean = mean([firstBandValue, secondBandValue]);
            expectedSd = std([firstBandValue, secondBandValue]);
            firstBandRow = numel(firstSubject.misoResults.f) + 5;

            testCase.verifyEqual( ...
                sheetCells{firstBandRow,5}, expectedMean, ...
                AbsTol=1e-12);
            testCase.verifyEqual( ...
                sheetCells{firstBandRow,6}, expectedSd, ...
                AbsTol=1e-12);
        end

        function failedSubjectIsShownAndIgnored(testCase)
            outputFolder = tempname();
            testCase.addTeardown(@() rmdir(outputFolder, "s"));
            validSubject = runSelectedWorkflow( ...
                outputFolder, true, false);
            validSubject.subjectInfo.group = "NC";
            validSubject.subjectInfo.subjectID = "1001";
            failedSubject = validSubject;
            failedSubject.subjectInfo.subjectID = "1002";
            failedSubject.runStatus.analysisSucceeded = false;
            failedSubject.runStatus.runStage = ...
                "InsufficientWelchWindows";
            failedSubject.runStatus.numWelchWindows = 2;
            failedSubject.runStatus.minimumWelchWindows = 3;
            failedSubject.misoResults = [];
            failedSubject.sisoResults = [];
            [analysisSettings, outputSettings] = ...
                createWorkflowTestSettings(outputFolder, true, false);
            outputSettings.excelMetrics.miso.mapGain = true;
            metrics = getExcelMetricDefinitions( ...
                outputSettings.excelMetrics, true, false);

            sheetCells = createExcelMetricSheet( ...
                {validSubject; failedSubject}, ...
                "NC", metrics(1), analysisSettings);

            testCase.verifyEqual(sheetCells{1,4}, "NC 1002");
            testCase.verifyEqual( ...
                sheetCells{2,4}, ...
                "ERROR: 2 Welch windows; minimum is 3");
            testCase.verifyEqual( ...
                sheetCells{2,5}, validSubject.misoResults.map.gain(1), ...
                AbsTol=1e-12);
            testCase.verifyEqual(sheetCells{2,6}, "");
        end

        function wrappedPhaseUsesCircularStatistics(testCase)
            outputFolder = tempname();
            testCase.addTeardown(@() rmdir(outputFolder, "s"));
            firstSubject = runSelectedWorkflow( ...
                outputFolder, true, false);
            firstSubject.subjectInfo.group = "NC";
            firstSubject.subjectInfo.subjectID = "1001";
            firstSubject.misoResults.map.phase.wrapped(:) = pi - 0.1;
            firstSubject.misoResults.map.coherence.partial(:) = 1;
            secondSubject = firstSubject;
            secondSubject.subjectInfo.subjectID = "1002";
            secondSubject.misoResults.map.phase.wrapped(:) = -pi + 0.1;
            [analysisSettings, outputSettings] = ...
                createWorkflowTestSettings(outputFolder, true, false);
            outputSettings.excelMetrics.miso.mapPhaseWrapped = true;
            metrics = getExcelMetricDefinitions( ...
                outputSettings.excelMetrics, true, false);

            sheetCells = createExcelMetricSheet( ...
                {firstSubject; secondSubject}, ...
                "NC", metrics(1), analysisSettings);

            firstBandRow = numel(firstSubject.misoResults.f) + 5;
            testCase.verifyEqual( ...
                abs(sheetCells{2,5}), pi, AbsTol=1e-12);
            testCase.verifyGreaterThan(sheetCells{2,6}, 0);
            testCase.verifyEqual( ...
                abs(sheetCells{firstBandRow,5}), pi, AbsTol=1e-12);
            testCase.verifyGreaterThan(sheetCells{firstBandRow,6}, 0);
        end

        function unwrappedPhaseRetainsCircularGroupStatistics(testCase)
            outputFolder = tempname();
            testCase.addTeardown(@() rmdir(outputFolder, "s"));
            firstSubject = runSelectedWorkflow( ...
                outputFolder, true, false);
            firstSubject.subjectInfo.group = "NC";
            firstSubject.subjectInfo.subjectID = "1001";
            firstSubject.misoResults.map.phase.wrapped(:) = pi - 0.1;
            firstSubject.misoResults.map.coherence.partial(:) = 1;
            secondSubject = firstSubject;
            secondSubject.subjectInfo.subjectID = "1002";
            secondSubject.misoResults.map.phase.wrapped(:) = -pi + 0.1;
            [analysisSettings, outputSettings] = ...
                createWorkflowTestSettings(outputFolder, true, false);
            outputSettings.excelMetrics.miso.mapPhaseUnwrapped = true;
            metrics = getExcelMetricDefinitions( ...
                outputSettings.excelMetrics, true, false);

            sheetCells = createExcelMetricSheet( ...
                {firstSubject; secondSubject}, ...
                "NC", metrics(1), analysisSettings);
            groupResults = createGroupResults( ...
                {firstSubject; secondSubject}, "NC", true, false, ...
                analysisSettings.phase);
            firstBandRow = numel(firstSubject.misoResults.f) + 5;

            testCase.verifyEqual( ...
                sheetCells{2,5}, ...
                groupResults.NC.miso.map.phase.unwrapped.mean(1), ...
                AbsTol=1e-12);
            testCase.verifyEqual( ...
                sheetCells{2,6}, ...
                groupResults.NC.miso.map.phase.unwrapped.sd(1), ...
                AbsTol=1e-12);
            testCase.verifyEqual( ...
                abs(sheetCells{firstBandRow,5}), pi, AbsTol=1e-12);
            testCase.verifyGreaterThan(sheetCells{firstBandRow,6}, 0);
        end

        function allFailedGroupStillCreatesMetricSheet(testCase)
            outputFolder = tempname();
            mkdir(outputFolder);
            testCase.addTeardown(@() rmdir(outputFolder, "s"));
            failedSubject.subjectInfo.subjectID = "1001";
            failedSubject.subjectInfo.group = "NC";
            failedSubject.subjectInfo.sourceFile = "missing.xlsx";
            failedSubject.runStatus.analysisSucceeded = false;
            failedSubject.runStatus.runStage = "TooShortForWelch";
            failedSubject.runStatus.statusMessage = ...
                "Skipped: signal shorter than Welch window";
            failedSubject.runStatus.numWelchWindows = 0;
            failedSubject.runStatus.minimumWelchWindows = 3;
            failedSubject.misoResults = [];
            failedSubject.sisoResults = [];
            [analysisSettings, outputSettings] = ...
                createWorkflowTestSettings(outputFolder, true, false);
            outputSettings.excelMetrics.miso.mapGain = true;
            filename = fullfile(outputFolder, "failed.xlsx");

            savedSheets = saveResultsToExcel( ...
                filename, {failedSubject}, "NC", ...
                analysisSettings, outputSettings);
            sheetData = readcell( ...
                filename, "Sheet", "NC_MISO_MAP_Gain");

            testCase.verifyEqual(savedSheets, "NC_MISO_MAP_Gain");
            testCase.verifyEqual( ...
                string(sheetData{1,3}), "NC 1001");
            testCase.verifyEqual( ...
                string(sheetData{2,3}), ...
                "ERROR: Signal shorter than Welch window");
            testCase.verifyTrue(ismissing(sheetData{2,4}));
            testCase.verifyTrue(ismissing(sheetData{2,5}));
        end

        function workbookUsesConfiguredGroupOrder(testCase)
            outputFolder = tempname();
            mkdir(outputFolder);
            testCase.addTeardown(@() rmdir(outputFolder, "s"));
            baseSubject = runSelectedWorkflow( ...
                outputFolder, true, false);
            lcSubject = baseSubject;
            lcSubject.subjectInfo.group = "LC";
            lcSubject.subjectInfo.subjectID = "3001";
            ncSubject = baseSubject;
            ncSubject.subjectInfo.group = "NC";
            ncSubject.subjectInfo.subjectID = "1001";
            mciSubject = baseSubject;
            mciSubject.subjectInfo.group = "MCI";
            mciSubject.subjectInfo.subjectID = "2001";
            [analysisSettings, outputSettings] = ...
                createWorkflowTestSettings(outputFolder, true, false);
            outputSettings.excelMetrics.signals.mapPower = true;
            outputSettings.excelMetrics.miso.mapGain = true;
            filename = fullfile(outputFolder, "ordered.xlsx");

            savedSheets = saveResultsToExcel( ...
                filename, {lcSubject; ncSubject; mciSubject}, ...
                ["MCI", "LC", "NC"], ...
                analysisSettings, outputSettings);
            workbookSheets = sheetnames(filename);

            expectedSheets = [
                "MCI_MAP_Power"
                "LC_MAP_Power"
                "NC_MAP_Power"
                "MCI_MISO_MAP_Gain"
                "LC_MISO_MAP_Gain"
                "NC_MISO_MAP_Gain"
            ];
            testCase.verifyEqual(savedSheets, expectedSheets);
            testCase.verifyEqual(workbookSheets, expectedSheets);
            testCase.verifyFalse(any(workbookSheets == "Run_Status"));
            testCase.verifyFalse(any(workbookSheets == "Metric_Definitions"));
        end

        function syntheticRunUsesTheUnifiedWorkbook(testCase)
            outputFolder = tempname();
            testCase.addTeardown(@() rmdir(outputFolder, "s"));
            [analysisSettings, outputSettings] = ...
                createWorkflowTestSettings(outputFolder, true, false);
            outputSettings.saveExcel = true;
            outputSettings.excelMetrics.miso.mapGain = true;

            runResults = runTFA( ...
                "synthetic", struct(), struct(), ...
                analysisSettings, outputSettings);
            workbookSheets = sheetnames(runResults.excelFile);
            sheetData = readcell( ...
                runResults.excelFile, ...
                "Sheet", "TEST_MISO_MAP_Gain");

            testCase.verifyEqual( ...
                workbookSheets, "TEST_MISO_MAP_Gain");
            testCase.verifyEqual( ...
                string(sheetData{1,3}), "TEST synthetic");
            testCase.verifyEqual(string(sheetData{1,4}), "Mean");
            testCase.verifyEqual(string(sheetData{1,5}), "SD");
            testCase.verifyTrue(ismissing(sheetData{2,5}));
        end

        function excelFailureDoesNotDiscardAnalysis(testCase)
            outputFolder = tempname();
            testCase.addTeardown(@() rmdir(outputFolder, "s"));
            [analysisSettings, outputSettings] = ...
                createWorkflowTestSettings(outputFolder, true, false);
            outputSettings.saveExcel = true;
            outputSettings.excelMetrics.miso.mapGain = true;
            outputSettings.excelFileName = ...
                fullfile("missing_folder", "results.xlsx");

            runResults = runTFA( ...
                "synthetic", struct(), struct(), ...
                analysisSettings, outputSettings);

            testCase.verifyTrue( ...
                runResults.subjectResults{1}.runStatus.analysisSucceeded);
            testCase.verifyNotEmpty( ...
                runResults.subjectResults{1}.misoResults);
            testCase.verifyEqual(runResults.excelFile, "");
            testCase.verifyNotEmpty(runResults.excelErrorMessage);
        end

        function shortBatchSubjectAppearsInWorkbook(testCase)
            dataFolder = tempname();
            outputFolder = fullfile(dataFolder, "output");
            ncFolder = fullfile(dataFolder, "NC");
            mkdir(ncFolder);
            testCase.addTeardown(@() rmdir(dataFolder, "s"));
            signalData = createSyntheticSignal(4);
            shortData = table( ...
                signalData.t(1:400)', ...
                signalData.map(1:400)', ...
                signalData.co2(1:400)', ...
                signalData.cbv(1:400)', ...
                'VariableNames', {'Time', 'MAP', 'CO2', 'CBV'});
            writetable( ...
                shortData, fullfile(ncFolder, "1001_baseline.xlsx"));
            [analysisSettings, outputSettings] = ...
                createWorkflowTestSettings(outputFolder, true, false);
            outputSettings.saveExcel = true;
            outputSettings.excelMetrics.miso.mapGain = true;
            batchSettings.dataFolder = dataFolder;
            batchSettings.groupsToRun = "NC";
            batchSettings.targetSuccessfulSubjectsPerGroup = Inf;
            batchSettings.previewOnly = false;
            batchSettings.numSubjectFiguresPerGroup = 0;

            runResults = runTFA( ...
                "batch", struct(), batchSettings, ...
                analysisSettings, outputSettings);
            sheetData = readcell( ...
                runResults.excelFile, ...
                "Sheet", "NC_MISO_MAP_Gain");

            testCase.verifyEqual( ...
                string(sheetData{1,3}), "NC 1001");
            testCase.verifyEqual( ...
                string(sheetData{2,3}), ...
                "ERROR: Signal shorter than Welch window");
            testCase.verifyTrue(ismissing(sheetData{2,4}));
            testCase.verifyTrue(ismissing(sheetData{2,5}));
        end
    end
end
