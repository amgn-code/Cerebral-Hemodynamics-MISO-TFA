%% MISO-TFA independent project quick start
% Run this script from the miso_tfa folder in a clean MATLAB session.

project = setup();

% Replace this path with one Excel or CSV recording.
filePath = "/path/to/recording.xlsx";

% The connection page owns file loading and returns canonical MAP, CO2, and
% CBFV signals. The model pages use the same connected data object.
connectedData = connectData(filePath);
misoResults = misoTesting(connectedData);
sisoResults = sisoTesting(connectedData);

% For the known-truth simulation, edit the returned settings before running.
simulationSettings = simulationSettings("simple");
simulationResults = runSimulation(simulationSettings);

% NC validation is a separate workflow. Supply the folder containing NC
% recordings when it is ready for the local dataset.
% ncResults = ncBootstrap("/path/to/ieem_data");

disp(project);
disp(misoResults.frequencyTable(1:min(5, height(misoResults.frequencyTable)), :));
disp(sisoResults.frequencyTable(1:min(5, height(sisoResults.frequencyTable)), :));
