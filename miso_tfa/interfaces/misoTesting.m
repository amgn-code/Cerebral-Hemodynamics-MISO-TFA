function results = misoTesting( ...
    connectedData, analysisSettings, displaySettings)
% misoTesting Run the MISO testing page on connected user data.

    setup();
    if nargin < 2
        analysisSettings = defaultMisoRealDataSettings();
    end
    if nargin < 3
        displaySettings = defaultRealDataDisplaySettings();
    end

    results = runMisoRealData(connectedData, analysisSettings);
    results.interfaceName = "misoTesting";
    results = addRealDataModelOutputs(results, displaySettings);

end
