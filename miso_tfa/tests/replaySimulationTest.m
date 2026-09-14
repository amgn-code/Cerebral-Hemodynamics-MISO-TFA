classdef replaySimulationTest < matlab.unittest.TestCase
    % replaySimulationTest Verify that a saved simulation can be rerun.

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
        function savedSettingsCanReplay(testCase)
            temporaryFolder = string(tempname);
            mkdir(temporaryFolder);
            testCase.addTeardown(@() rmdir(temporaryFolder, "s"));

            interfaceSettings = simulationSettings("simple");
            interfaceSettings.simulation.observations.durationSeconds = 300;
            interfaceSettings.simulation.observations.runAlignmentExperiment = false;
            interfaceSettings.simulation.observations.runInputNoiseExperiment = false;
            interfaceSettings.simulation.estimatorSensitivity.enabled = false;

            outputSettings = defaultSimulationOutputSettings("off");
            outputSettings.createFigures = false;
            outputSettings.savePng = false;
            outputSettings.saveCsv = false;
            outputSettings.saveMat = true;
            outputSettings.outputFolder = temporaryFolder;

            original = runSimulation(interfaceSettings, outputSettings);
            replayed = replaySimulation( ...
                fullfile(temporaryFolder, "simulation_results.mat"));

            testCase.verifyEqual( ...
                replayed.numFamilies, original.numFamilies);
            testCase.verifyEqual( ...
                replayed.numObservations, original.numObservations);
            testCase.verifyEqual( ...
                height(replayed.observations), height(original.observations));
            testCase.verifyEqual( ...
                replayed.observations.MISOPredictionError, ...
                original.observations.MISOPredictionError, AbsTol=1e-12);
        end
    end
end
