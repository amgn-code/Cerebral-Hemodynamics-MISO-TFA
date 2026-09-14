classdef ncBootstrapTest < matlab.unittest.TestCase
    % ncBootstrapTest Verify the NC bootstrap page and protocol.

    methods (TestClassSetup)
        function addProjectFolders(testCase)
            projectRoot = fileparts(fileparts(mfilename("fullpath")));
            testCase.applyFixture( ...
                matlab.unittest.fixtures.PathFixture( ...
                projectRoot, IncludingSubfolders=true));
            setup();
        end
    end

    methods (Test)
        function defaultProtocolUsesIndependentTrainingSegments(testCase)
            settings = defaultNcBootstrapSettings();

            testCase.verifyEqual( ...
                settings.validation.blockLengthSeconds, 90);
            testCase.verifyEqual(settings.validation.numFolds, 3);
            testCase.verifyEqual( ...
                settings.analysis.pwelch.windowLengthSeconds, 90);
            testCase.verifyEqual(settings.analysis.pwelch.windowOverlap, 0);
            testCase.verifyEqual(settings.analysis.frequencyRangeHz, ...
                [0.02 0.35]);
            testCase.verifyEqual( ...
                settings.analysis.frequencyBandEdgesHz, ...
                [0.02; 0.07; 0.20; 0.35]);
        end

        function pageReturnsFrequencyAdvantageAndAuditTables(testCase)
            [temporaryFolder, dataFolder] = createNcFixture(2, false);
            testCase.addTeardown(@() rmdir(temporaryFolder, "s"));
            settings = createTestNcSettings();

            results = ncBootstrap(dataFolder, settings);

            testCase.verifyEqual(results.interfaceName, "ncBootstrap");
            testCase.verifyEqual(height(results.statusTable), 2);
            testCase.verifyTrue(all( ...
                results.statusTable.Status == "Completed"));
            testCase.verifyGreaterThan(height(results.frequencyTable), 0);
            testCase.verifyTrue(all( ...
                results.frequencyTable.ValidSubjectN == 2));
            testCase.verifyEqual( ...
                [results.subjectResults.welchWindowCountForTraining], ...
                [2 2]);
            testCase.verifyTrue(isempty(results.figureHandle));
            testCase.verifyEqual( ...
                results.frequencyTable.FrequencyHz(2) - ...
                results.frequencyTable.FrequencyHz(1), ...
                1/90, AbsTol=1e-12);
        end

        function plotReturnsAdvantageFigure(testCase)
            [temporaryFolder, dataFolder] = createNcFixture(2, false);
            testCase.addTeardown(@() rmdir(temporaryFolder, "s"));
            settings = createTestNcSettings();
            settings.plot.enabled = true;
            settings.plot.visible = "off";

            results = ncBootstrap(dataFolder, settings);

            testCase.verifyTrue(isgraphics(results.figureHandle, "figure"));
            testCase.verifyEqual( ...
                height(results.plotSourceData), height(results.frequencyTable));
            close(results.figureHandle);
        end

        function exportReturnsSummaryAndAuditFiles(testCase)
            [temporaryFolder, dataFolder] = createNcFixture(2, false);
            testCase.addTeardown(@() rmdir(temporaryFolder, "s"));
            settings = createTestNcSettings();
            settings.plot.enabled = false;
            results = ncBootstrap(dataFolder, settings);

            reportFolder = fullfile(temporaryFolder, "report");
            exportResults = exportNcBootstrapResults( ...
                results, reportFolder);

            testCase.verifyEqual( ...
                height(exportResults.frequencyTable), ...
                height(results.frequencyTable));
            testCase.verifyEqual( ...
                height(exportResults.statusTable), ...
                height(results.statusTable));
            testCase.verifyEqual( ...
                height(exportResults.subjectErrorTable), ...
                2 * height(results.frequencyTable));
            testCase.verifyEqual(numel(exportResults.savedFiles), 9);
            testCase.verifyTrue(all(isfile(exportResults.savedFiles)));
        end

        function bootstrapIsRepeatable(testCase)
            [temporaryFolder, dataFolder] = createNcFixture(2, false);
            testCase.addTeardown(@() rmdir(temporaryFolder, "s"));
            settings = createTestNcSettings();

            first = ncBootstrap(dataFolder, settings);
            second = ncBootstrap(dataFolder, settings);

            testCase.verifyEqual( ...
                first.frequencyTable.Advantage, ...
                second.frequencyTable.Advantage, AbsTol=1e-12);
            testCase.verifyEqual( ...
                first.frequencyTable.BootstrapSD, ...
                second.frequencyTable.BootstrapSD, AbsTol=1e-12);
            testCase.verifyEqual( ...
                first.frequencyTable.CILower, ...
                second.frequencyTable.CILower, AbsTol=1e-12);
            testCase.verifyEqual( ...
                first.frequencyTable.CIUpper, ...
                second.frequencyTable.CIUpper, AbsTol=1e-12);
        end

        function inputCharacterizationReturnsProtocolDeliverables(testCase)
            [temporaryFolder, dataFolder] = createNcFixture(2, false);
            testCase.addTeardown(@() rmdir(temporaryFolder, "s"));
            settings = createTestNcSettings();

            results = ncBootstrap(dataFolder, settings);

            testCase.verifyTrue(isfield(results, "inputCharacterization"));
            characterization = results.inputCharacterization;
            testCase.verifyEqual( ...
                characterization.coherence.suggestedCoreLevels(1), 0);
            testCase.verifyEqual( ...
                height(characterization.coherence.frequencyTable), ...
                nnz(characterization.frequencyHz >= 0.02 & ...
                characterization.frequencyHz <= 0.35));
            testCase.verifyTrue(isfield(characterization.phase, ...
                "subjectLagQuantilesSeconds"));
            testCase.verifyTrue(isfield(characterization.power, ...
                "frequencyTable"));
        end

        function shortRecordingIsReportedAlongsideCompletedSubject(testCase)
            [temporaryFolder, dataFolder] = createNcFixture(2, true);
            testCase.addTeardown(@() rmdir(temporaryFolder, "s"));
            settings = createTestNcSettings();

            results = ncBootstrap(dataFolder, settings);

            testCase.verifyEqual( ...
                nnz(results.statusTable.Status == "Completed"), 1);
            testCase.verifyEqual( ...
                nnz(results.statusTable.Status == "InsufficientBlocks"), 1);
            testCase.verifyEqual( ...
                results.frequencyTable.ValidSubjectN, ...
                ones(height(results.frequencyTable), 1));
        end
    end
end

function settings = createTestNcSettings()
% createTestNcSettings Use a small deterministic bootstrap for unit tests.

    settings = defaultNcBootstrapSettings();
    settings.bootstrap.numSamples = 40;
    settings.bootstrap.randomSeed = 11;
    settings.plot.enabled = false;

end

function [temporaryFolder, dataFolder] = createNcFixture( ...
    numSubjects, includeShortSubject)
% createNcFixture Create baseline workbooks with canonical columns.

    temporaryFolder = tempname();
    mkdir(temporaryFolder);
    dataFolder = fullfile(temporaryFolder, "data");
    ncFolder = fullfile(dataFolder, "NC");
    mkdir(ncFolder);

    signalData = createSyntheticSignal(4);
    for subjectIndex = 1:numSubjects
        currentSignal = signalData;
        if includeShortSubject && subjectIndex == numSubjects
            keepSamples = 1:(200*signalData.fs);
            currentSignal.t = currentSignal.t(keepSamples);
            currentSignal.map = currentSignal.map(keepSamples);
            currentSignal.co2 = currentSignal.co2(keepSamples);
            currentSignal.cbv = currentSignal.cbv(keepSamples);
        end

        inputTable = table( ...
            currentSignal.t(:), currentSignal.map(:), ...
            currentSignal.co2(:), currentSignal.cbv(:), ...
            'VariableNames', {'Time', 'MAP', 'CO2', 'CBV'});
        subjectID = 100 + subjectIndex;
        filePath = fullfile( ...
            ncFolder, sprintf('%d_baseline.xlsx', subjectID));
        writetable(inputTable, filePath, 'Sheet', 'Sheet1');
    end

end
