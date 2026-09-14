classdef plotSimpleSimulationFrequencyMapTest < matlab.unittest.TestCase
    % plotSimpleSimulationFrequencyMapTest Verify the primary heatmap path.

    methods (TestClassSetup)
        function addProjectFolders(testCase)
            projectRoot = fileparts(fileparts(mfilename("fullpath")));
            testCase.applyFixture( ...
                matlab.unittest.fixtures.PathFixture( ...
                    projectRoot, IncludingSubfolders=true));
        end
    end

    methods (Test)
        function sourceDataMatchesThePlottedCells(testCase)
            simulationResults = createSmallPlotResults();
            [figureHandle, sourceData] = plotSimpleSimulationFrequencyMap( ...
                simulationResults, true(4, 1), ...
                "TargetInputCoherence", "Input coherence", ...
                "exact", "map", 1.5);
            testCase.addTeardown(@() close(figureHandle));

            testCase.verifyTrue(isgraphics(figureHandle));
            testCase.verifyEqual(height(sourceData.frequencyMap), 4);
            testCase.verifyTrue(ismember( ...
                "Advantage", string(sourceData.frequencyMap.Properties.VariableNames)));
            testCase.verifyTrue(all(sourceData.frequencyMap.PairedValidN == 2));
            testCase.verifyEqual( ...
                sourceData.metadata.ScoreVersion, ...
                "frequency-ratio-of-mean-errors-v1");
        end
    end
end

function simulationResults = createSmallPlotResults()
% createSmallPlotResults Create two-frequency results for the plot test.

    simulationResults.observations = table( ...
        (1:4)', [0; 0; 0.5; 0.5], ...
        'VariableNames', {'ObservationID', 'TargetInputCoherence'});
    simulationResults.frequency.frequencyHz = [0.02; 0.03];
    simulationResults.frequency.map.sisoComplexError = ...
        [1 3 2 8; 2 6 4 12];
    simulationResults.frequency.map.misoComplexError = ...
        [0.5 1.5 4 4; 1 3 8 6];
    simulationResults.settings.grouping.minimumValidN = 1;
    simulationResults.settings.frequencyRangeHz = [0.02 0.03];

end
