function settings = defaultSimulationOutputSettings(visibility)
% defaultSimulationOutputSettings Return simulation figure/export settings.

    if nargin < 1
        visibility = "on";
    end

    settings.createFigures = true;
    settings.visible = lower(string(visibility));
    settings.advantageColorLimit = 1.5;
    settings.diagnosticBinEdges = 0:0.1:1;

    settings.bootstrap.enabled = true;
    settings.bootstrap.numSamples = 1000;
    settings.bootstrap.randomSeed = 2027;
    settings.bootstrap.confidenceLevel = 0.95;

    settings.outputFolder = "";
    settings.savePng = true;
    settings.saveCsv = true;
    settings.saveMat = true;

    settings = completeSimulationOutputSettings(settings);

end
