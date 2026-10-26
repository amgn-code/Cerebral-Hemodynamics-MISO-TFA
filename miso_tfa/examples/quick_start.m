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

% To export one model page, set its output folder. CSV, MAT, and PNG files
% are then created by the same page that performs the analysis.
% displaySettings = defaultRealDataDisplaySettings("off");
% displaySettings.outputFolder = fullfile(project.output, "my_recording");
% misoResults = misoTesting( ...
%     connectedData, defaultMisoRealDataSettings(), displaySettings);

% For the known-truth simulation, edit the returned settings before running.
simSettings = simulationSettings("simple");
simulationResults = runSimulation(simSettings);

% Final-study wiring check. Use 500 repetitions for scientific output.
finalOutput = defaultSimulationOutputSettings("off");
finalOutput.createFigures = false;
finalStudySmoke = runFinalSimulationStudy(1, finalOutput);

% NC validation is a separate workflow. Supply the folder containing NC
% recordings when it is ready for the local dataset.
% ncResults = ncBootstrap("/path/to/ieem_data");

disp(project);
disp(misoResults.frequencyTable(1:min(5, height(misoResults.frequencyTable)), :));
disp(sisoResults.frequencyTable(1:min(5, height(sisoResults.frequencyTable)), :));
