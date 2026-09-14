function settings = simulationSettings(profileName)
% simulationSettings Create the editable simulation settings page.

    setup();
    if nargin < 1
        profileName = "simple";
    end

    settings = defaultSimulationInterfaceSettings(profileName);
    settings.interfaceName = "simulationSettings";

end
