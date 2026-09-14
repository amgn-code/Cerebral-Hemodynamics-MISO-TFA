function simulationResults = runSimulationInterface(interfaceSettings)
% runSimulationInterface Run the simulation from editable interface settings.
%
% This interface owns the handoff from a reviewed settings structure to the
% known-truth simulation runner. It does not load real recordings or write
% plots and workbooks implicitly.

    if nargin < 1 || isempty(interfaceSettings)
        interfaceSettings = defaultSimulationInterfaceSettings("simple");
    end

    if ~isstruct(interfaceSettings) || ...
            ~isfield(interfaceSettings, "simulation")
        error( ...
            "TFA:InvalidSimulationInterfaceSettings", ...
            "Settings must contain a simulation field.");
    end

    simulationResults = runKnownTruthSimulationGrid( ...
        interfaceSettings.simulation);
    simulationResults.interfaceSettings = interfaceSettings;

end
