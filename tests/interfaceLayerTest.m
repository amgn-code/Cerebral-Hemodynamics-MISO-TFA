classdef interfaceLayerTest < matlab.unittest.TestCase
    % interfaceLayerTest Verify the public workflow boundaries.

    methods (TestClassSetup)
        function addProjectFolders(testCase)
            projectRoot = fileparts(fileparts(mfilename("fullpath")));
            testCase.applyFixture( ...
                matlab.unittest.fixtures.PathFixture( ...
                    projectRoot, IncludingSubfolders=true));
        end
    end

    methods (Test)
        function realDataDefaultsKeepModelSettingsSeparate(testCase)
            settings = defaultRealDataInterfaceSettings();

            testCase.verifyTrue(settings.miso.runMISO);
            testCase.verifyFalse(settings.miso.runSISO);
            testCase.verifyFalse(settings.siso.runMISO);
            testCase.verifyTrue(settings.siso.runSISO);
            testCase.verifyEqual(settings.filePath, "");
            testCase.verifyFalse(isfield(settings.miso, "plot"));
            testCase.verifyFalse(isfield(settings.siso, "plot"));
        end

        function connectionInterfaceReturnsCanonicalData(testCase)
            [temporaryFolder, inputFile] = createInputWorkbook();
            testCase.addTeardown(@() rmdir(temporaryFolder, "s"));

            connectedData = connectTfaData(inputFile);

            testCase.verifyEqual(connectedData.filePath, string(inputFile));
            testCase.verifyEqual( ...
                connectedData.subjectInfo.subjectID, "user_recording");
            testCase.verifyEqual(connectedData.subjectInfo.group, "UserData");
            testCase.verifyTrue(isfield(connectedData.signalData, "map"));
            testCase.verifyTrue(isfield(connectedData.signalData, "co2"));
            testCase.verifyTrue(isfield(connectedData.signalData, "cbv"));
        end

        function modelInterfacesRunOnTheSameConnectedData(testCase)
            [temporaryFolder, inputFile] = createInputWorkbook();
            testCase.addTeardown(@() rmdir(temporaryFolder, "s"));
            connectedData = connectTfaData(inputFile);

            misoSettings = defaultMisoRealDataSettings();
            sisoSettings = defaultSisoRealDataSettings();
            misoSettings.pwelch.windowLengthSeconds = 32;
            sisoSettings.pwelch.windowLengthSeconds = 32;

            miso = runMisoRealData(connectedData, misoSettings);
            siso = runSisoRealData(connectedData, sisoSettings);

            testCase.verifyTrue(miso.runStatus.analysisSucceeded);
            testCase.verifyTrue(siso.runStatus.analysisSucceeded);
            testCase.verifyEqual(miso.interfaceModel, "MISO");
            testCase.verifyEqual(siso.interfaceModel, "SISO");
            testCase.verifyTrue(isfield( ...
                miso.misoResults, "diagnostics"));
            testCase.verifyTrue(isempty(siso.misoResults));
            testCase.verifyTrue(isempty(miso.sisoResults));
            testCase.verifyTrue(isfield(siso.sisoResults, "map"));
        end

        function simulationInterfacePassesSettingsToRunner(testCase)
            interfaceSettings = defaultSimulationInterfaceSettings("quick");
            interfaceSettings.simulation.families.numFamilies = 1;
            interfaceSettings.simulation.families.progressEvery = 1;
            interfaceSettings.simulation.observations.durationSeconds = 300;
            interfaceSettings.simulation.observations.outputSnrDb = 15;
            interfaceSettings.simulation.observations.referenceDurationSeconds = 300;
            interfaceSettings.simulation.observations.referenceOutputSnrDb = 15;
            interfaceSettings.simulation.observations.runInputNoiseExperiment = false;
            interfaceSettings.simulation.observations.runAlignmentExperiment = false;
            interfaceSettings.simulation.estimatorSensitivity.enabled = false;
            interfaceSettings.simulation.estimators.runRidge = false;

            results = runSimulationInterface(interfaceSettings);

            testCase.verifyEqual(results.numFamilies, 1);
            testCase.verifyEqual( ...
                results.settings.profileName, "quick");
            testCase.verifyEqual( ...
                results.interfaceSettings.profileName, "quick");
            testCase.verifyGreaterThanOrEqual(results.numObservations, 1);
        end

        function realDataExportCreatesDescriptiveFrequencyReport(testCase)
            [temporaryFolder, inputFile] = createInputWorkbook();
            testCase.addTeardown(@() rmdir(temporaryFolder, "s"));
            connectedData = connectTfaData(inputFile);
            settings = defaultRealDataInterfaceSettings();
            settings.miso.pwelch.windowLengthSeconds = 32;
            settings.siso.pwelch.windowLengthSeconds = 32;
            results = runMisoSisoRealData(connectedData, settings);

            reportFolder = fullfile(temporaryFolder, "report");
            exportResults = exportRealDataResults( ...
                results, reportFolder);

            testCase.verifyEqual(height(exportResults.sourceData), ...
                numel(results.misoResults.f));
            testCase.verifyTrue(ismember( ...
                "MISOMinusPartialMapCoherence", ...
                string(exportResults.sourceData.Properties.VariableNames)));
            testCase.verifyEqual(numel(exportResults.savedFiles), 3);
            testCase.verifyTrue(all(isfile(exportResults.savedFiles)));
        end
    end
end

function [temporaryFolder, inputFile] = createInputWorkbook()
% createInputWorkbook Create one deterministic Excel fixture.

    temporaryFolder = tempname();
    mkdir(temporaryFolder);
    signalData = createSyntheticSignal(4);
    inputTable = table( ...
        signalData.t(:), signalData.map(:), ...
        signalData.co2(:), signalData.cbv(:), ...
        'VariableNames', {'Time', 'MAP', 'CO2', 'CBV'});
    inputFile = fullfile(temporaryFolder, "user_recording.xlsx");
    writetable(inputTable, inputFile, "Sheet", "Sheet1");

end
