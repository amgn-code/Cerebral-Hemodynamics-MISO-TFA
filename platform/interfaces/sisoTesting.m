function results = sisoTesting( ...
    connectedData, analysisSettings, displaySettings)
% sisoTesting Run the SISO testing page on connected user data.

    setupPlatform();
    if nargin < 2
        analysisSettings = defaultSisoRealDataSettings();
    end
    if nargin < 3
        displaySettings = defaultRealDataDisplaySettings();
    end

    results = runSisoRealData(connectedData, analysisSettings);
    results.interfaceName = "sisoTesting";
    results = addRealDataModelOutputs(results, displaySettings);

end
