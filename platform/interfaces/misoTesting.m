function results = misoTesting(connectedData, analysisSettings)
% misoTesting Run the MISO testing page on connected user data.

    setupPlatform();
    if nargin < 2
        analysisSettings = defaultMisoRealDataSettings();
    end

    results = runMisoRealData(connectedData, analysisSettings);
    results.interfaceName = "misoTesting";

end
