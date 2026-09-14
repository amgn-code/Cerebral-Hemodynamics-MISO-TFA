classdef platformInterfaceTest < matlab.unittest.TestCase
    % platformInterfaceTest Verify the clean platform boundary.

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
        function dataPageReturnsCanonicalData(testCase)
            [temporaryFolder, inputFile] = createInputWorkbook();
            testCase.addTeardown(@() rmdir(temporaryFolder, "s"));

            connectedData = connectData(inputFile);

            testCase.verifyEqual(connectedData.interfaceName, ...
                "dataConnection");
            testCase.verifyEqual(connectedData.subjectInfo.group, "UserData");
            testCase.verifyTrue(isfield(connectedData.signalData, "map"));
            testCase.verifyTrue(isfield(connectedData.signalData, "co2"));
            testCase.verifyTrue(isfield(connectedData.signalData, "cbv"));
        end

        function modelPagesUseConnectedData(testCase)
            [temporaryFolder, inputFile] = createInputWorkbook();
            testCase.addTeardown(@() rmdir(temporaryFolder, "s"));
            connectedData = connectData(inputFile);

            misoSettings = defaultMisoRealDataSettings();
            misoSettings.pwelch.windowLengthSeconds = 32;
            sisoSettings = defaultSisoRealDataSettings();
            sisoSettings.pwelch.windowLengthSeconds = 32;
            displaySettings = defaultRealDataDisplaySettings("off");

            miso = misoTesting( ...
                connectedData, misoSettings, displaySettings);
            siso = sisoTesting( ...
                connectedData, sisoSettings, displaySettings);
            testCase.addTeardown(@() close(miso.figureHandle));
            testCase.addTeardown(@() close(siso.figureHandle));

            testCase.verifyTrue(miso.runStatus.analysisSucceeded);
            testCase.verifyTrue(siso.runStatus.analysisSucceeded);
            testCase.verifyEqual(miso.interfaceName, "misoTesting");
            testCase.verifyEqual(siso.interfaceName, "sisoTesting");
            testCase.verifyEqual( ...
                height(miso.frequencyTable), numel(miso.misoResults.f));
            testCase.verifyEqual( ...
                height(siso.frequencyTable), numel(siso.sisoResults.f));
            testCase.verifyTrue(ismember( ...
                "MultipleCoherence", ...
                string(miso.frequencyTable.Properties.VariableNames)));
            testCase.verifyTrue(ismember( ...
                "MAPCoherence", ...
                string(siso.frequencyTable.Properties.VariableNames)));
            testCase.verifyTrue(isgraphics(miso.figureHandle));
            testCase.verifyTrue(isgraphics(siso.figureHandle));
        end

        function simulationPagesExposeSettingsAndRunner(testCase)
            settings = simulationSettings("quick");

            testCase.verifyEqual(settings.interfaceName, "simulationSettings");
            testCase.verifyEqual(settings.profileName, "quick");
            testCase.verifyTrue(isfield(settings, "simulation"));

            settings.simulation.families.numFamilies = 1;
            settings.simulation.families.progressEvery = 1;
            settings.simulation.observations.durationSeconds = 300;
            settings.simulation.observations.outputSnrDb = 15;
            settings.simulation.observations.referenceDurationSeconds = 300;
            settings.simulation.observations.referenceOutputSnrDb = 15;
            settings.simulation.observations.runInputNoiseExperiment = false;
            settings.simulation.observations.runAlignmentExperiment = false;
            outputFolder = tempname();
            mkdir(outputFolder);
            testCase.addTeardown(@() rmdir(outputFolder, "s"));
            outputSettings = defaultSimulationOutputSettings("off");
            outputSettings.outputFolder = outputFolder;
            results = runSimulation(settings, outputSettings);
            for mapNumber = 1:numel(results.outputs.maps)
                testCase.addTeardown( ...
                    @() close(results.outputs.maps(mapNumber).figureHandle));
            end

            testCase.verifyEqual(results.interfaceName, "simulationRunner");
            testCase.verifyEqual(results.numFamilies, 1);
            testCase.verifyGreaterThanOrEqual(results.numObservations, 1);
            testCase.verifyEqual(numel(results.outputs.maps), 5);
            testCase.verifyEqual( ...
                height(results.outputs.manifest.mapIndex), 5);
            testCase.verifyTrue(ismember( ...
                "Advantage", ...
                string(results.outputs.maps(1).frequencyTable. ...
                Properties.VariableNames)));
            testCase.verifyTrue(all(isfile( ...
                results.exportResults.savedFiles)));
            testCase.verifyTrue(isfile( ...
                results.exportResults.manifestFile));
            testCase.verifyTrue(isfile(results.exportResults.matFile));
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
    inputFile = fullfile(temporaryFolder, "platform_recording.xlsx");
    writetable(inputTable, inputFile, "Sheet", "Sheet1");

end
