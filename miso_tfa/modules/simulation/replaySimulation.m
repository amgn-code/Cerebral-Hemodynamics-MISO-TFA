function replayedResults = replaySimulation(matFile, outputFolder)
% replaySimulation Re-run a saved simulation from its MAT archive.
%
% The archive written by exportSimulationResults contains the exact
% interface settings and manifest. This function deliberately reuses those
% settings instead of silently applying today's defaults.

if nargin < 1 || isempty(matFile) || ~isfile(matFile)
    error("TFA:MissingSimulationArchive", ...
        "Provide an existing simulation_results.mat archive.");
end

archive = load(matFile, "resultsCopy", "manifest");
if ~isfield(archive, "resultsCopy") || ...
        ~isfield(archive.resultsCopy, "interfaceSettings")
    error("TFA:IncompleteSimulationArchive", ...
        "The archive does not contain interface settings for replay.");
end

interfaceSettings = archive.resultsCopy.interfaceSettings;
if nargin >= 2 && ~isempty(outputFolder)
    outputSettings = archive.manifest.outputSettings;
    outputSettings.outputFolder = string(outputFolder);
else
    outputSettings = archive.manifest.outputSettings;
    outputSettings.outputFolder = "";
    outputSettings.savePng = false;
    outputSettings.saveCsv = false;
    outputSettings.saveMat = false;
end

replayedResults = runSimulation(interfaceSettings, outputSettings);

end
