function results = sisoTesting(connectedData, analysisSettings)
% sisoTesting Run the SISO testing page on connected user data.

    setupPlatform();
    if nargin < 2
        analysisSettings = defaultSisoRealDataSettings();
    end

    results = runSisoRealData(connectedData, analysisSettings);
    results.interfaceName = "sisoTesting";

end
