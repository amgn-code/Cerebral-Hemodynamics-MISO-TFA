function connectedData = connectData(filePath)
% connectData Connect one user recording to the platform.
%
% The returned structure contains canonical time, MAP, CO2, and CBV arrays,
% the source path, and subject metadata. Plotting and model execution belong
% to later interface pages.

    setupPlatform();
    connectedData = connectTfaData(filePath);
    connectedData.interfaceName = "dataConnection";

end
