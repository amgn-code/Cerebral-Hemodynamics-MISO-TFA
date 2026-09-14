function results = runSimulation(settings)
% runSimulation Run the known-truth simulation page.

    setupPlatform();
    if nargin < 1 || isempty(settings)
        settings = simulationSettings("simple");
    end

    results = runSimulationInterface(settings);
    results.interfaceName = "simulationRunner";

end
