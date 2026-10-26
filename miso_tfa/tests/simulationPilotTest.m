classdef simulationPilotTest < matlab.unittest.TestCase
    % simulationPilotTest Verify pilot precision and primary output behavior.

    methods (TestClassSetup)
        function addProjectFolders(testCase)
            projectRoot = fileparts(fileparts(mfilename("fullpath")));
            testCase.applyFixture( ...
                matlab.unittest.fixtures.PathFixture( ...
                projectRoot, IncludingSubfolders=true));
        end
    end

    methods (Test)
        function primaryMapsMatchFrozenFactorSet(testCase)
            settings = defaultKnownTruthSimulationSettings("simple");
            settings.families.repetitionsPerCondition = 1;
            simulation = runKnownTruthSimulationGrid(settings);
            outputSettings = defaultSimulationOutputSettings("off");
            outputSettings.createFigures = false;
            outputs = createSimulationOutputs(simulation, outputSettings);

            testCase.verifyEqual(numel(outputs.primaryMaps), 4);
            testCase.verifyEqual( ...
                string({outputs.primaryMaps.variableName})', ...
                ["TargetInputCoherence"; ...
                 "AssignedPETCO2ToMAPBandGainRatio"; ...
                 "DurationSeconds"; "OutputSNRdB"]);
            testCase.verifyEqual(numel(outputs.diagnosticMaps), 2);
            testCase.verifyTrue(isfinite( ...
                outputs.settings.resolvedAdvantageColorLimit));
        end

        function pilotReturnsPrecisionPlanningTable(testCase)
            pilot = runSimulationPilot(1);

            testCase.verifyEqual(height(pilot.precisionTable), 4);
            testCase.verifyEqual(pilot.targetStandardError, 0.05);
            testCase.verifyEqual( ...
                pilot.scoreVersion, "frequency-ratio-of-mean-errors-v1");
            testCase.verifyTrue(ismember( ...
                "ProjectedRepetitions", ...
                string(pilot.precisionTable.Properties.VariableNames)));
        end
    end
end
