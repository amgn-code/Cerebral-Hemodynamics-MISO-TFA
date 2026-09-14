function simulationResults = runSimpleKnownTruthSimulation( ...
    repetitionsPerCondition)
% runSimpleKnownTruthSimulation Run the small interpretable study.
%
% The default run has one realization for each combination of input
% coherence and CO2 contribution. Use repetitionsPerCondition to make an
% explicit repeated pilot after the settings have been reviewed.

    if nargin < 1
        repetitionsPerCondition = 1;
    end
    validateattributes( ...
        repetitionsPerCondition, {'numeric'}, ...
        {'scalar', 'integer', 'positive', 'finite'});

    settings = defaultKnownTruthSimulationSettings("simple");
    settings.families.repetitionsPerCondition = repetitionsPerCondition;

    simulationResults = runKnownTruthSimulationGrid(settings);

end
