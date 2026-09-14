function results = runSimulation(settings, outputSettings)
% runSimulation Run the known-truth simulation and build its main outputs.

    setupPlatform();
    if nargin < 1 || isempty(settings)
        settings = simulationSettings("simple");
    end
    if nargin < 2 || isempty(outputSettings)
        outputSettings = defaultSimulationOutputSettings();
    else
        outputSettings = completeSimulationOutputSettings(outputSettings);
    end

    results = runSimulationInterface(settings);
    results.interfaceName = "simulationRunner";
    results.outputs = createSimulationOutputs(results, outputSettings);
    results.exportResults = struct();

    if strlength(outputSettings.outputFolder) > 0
        results.exportResults = exportSimulationResults( ...
            results, outputSettings.outputFolder, outputSettings);
    end

end
