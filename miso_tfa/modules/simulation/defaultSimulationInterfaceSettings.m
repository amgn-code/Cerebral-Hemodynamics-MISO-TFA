function interfaceSettings = defaultSimulationInterfaceSettings(profileName)
% defaultSimulationInterfaceSettings Return settings for the simulation UI.
%
% The returned structure is the editable boundary for a simulation run.
% The numerical runner receives interfaceSettings.simulation and does not
% depend on a legacy main.m workflow or on any real-data file path.

    if nargin < 1
        profileName = "simple";
    end

    simulationSettings = ...
        defaultKnownTruthSimulationSettings(profileName);

    interfaceSettings.profileName = simulationSettings.profileName;
    interfaceSettings.simulation = simulationSettings;

end
