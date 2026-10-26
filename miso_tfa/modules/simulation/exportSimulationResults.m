function exportResults = exportSimulationResults( ...
    simulationResults, outputFolder, outputSettings)
% exportSimulationResults Save heatmaps, tables, and reproducibility data.

    if nargin < 2 || strlength(string(outputFolder)) == 0
        error("TFA:MissingSimulationOutputFolder", ...
            "Choose an output folder for the simulation results.");
    end
    if nargin < 3 || isempty(outputSettings)
        outputSettings = defaultSimulationOutputSettings("off");
    else
        outputSettings = completeSimulationOutputSettings(outputSettings);
    end
    outputFolder = string(outputFolder);
    if ~isscalar(outputFolder)
        error("TFA:InvalidSimulationOutputFolder", ...
            "outputFolder must be one folder path.");
    end

    if isfield(simulationResults, "outputs") && ...
            isfield(simulationResults.outputs, "maps")
        outputs = simulationResults.outputs;
    else
        outputs = createSimulationOutputs(simulationResults, outputSettings);
    end
    manifest = createSimulationRunManifest( ...
        simulationResults, outputSettings, outputs.maps);

    if ~exist(outputFolder, "dir")
        mkdir(outputFolder);
    end
    savedFiles = strings(0, 1);

    for mapNumber = 1:numel(outputs.maps)
        map = outputs.maps(mapNumber);
        fileStem = fullfile(outputFolder, map.name);
        if outputSettings.savePng
            if isempty(map.figureHandle) || ~isgraphics(map.figureHandle)
                error("TFA:MissingSimulationFigure", ...
                    "Map %s has no figure available to export.", map.name);
            end
            pngFile = fileStem + ".png";
            exportgraphics(map.figureHandle, pngFile, "Resolution", 300);
            savedFiles(end + 1, 1) = pngFile; %#ok<AGROW>
        end
        if outputSettings.saveCsv
            csvFile = fileStem + "_frequency_map.csv";
            writetable(map.frequencyTable, csvFile);
            savedFiles(end + 1, 1) = csvFile; %#ok<AGROW>
            if isfield(map, "companions") && ...
                    isfield(map.companions, "analyticReference")
                referenceFile = fileStem + "_analytic_reference.csv";
                snrFile = fileStem + "_realized_output_snr.csv";
                writetable(map.companions.analyticReference, referenceFile);
                writetable(map.companions.realizedOutputSnr, snrFile);
                savedFiles(end + 1, 1) = referenceFile; %#ok<AGROW>
                savedFiles(end + 1, 1) = snrFile; %#ok<AGROW>
            end
        end
    end

    if outputSettings.saveCsv
        manifestFile = fullfile(outputFolder, "simulation_manifest.csv");
        mapIndexFile = fullfile(outputFolder, "simulation_map_index.csv");
        writetable(manifest.summary, manifestFile);
        writetable(manifest.mapIndex, mapIndexFile);
        savedFiles(end + 1, 1) = string(manifestFile);
        savedFiles(end + 1, 1) = string(mapIndexFile);
    else
        manifestFile = "";
        mapIndexFile = "";
    end

    if outputSettings.saveMat
        matFile = fullfile(outputFolder, "simulation_results.mat");
        resultsCopy = removeFigureHandles(simulationResults, outputs);
        save(matFile, "resultsCopy", "manifest", "-v7.3");
        savedFiles(end + 1, 1) = string(matFile);
    else
        matFile = "";
    end

    exportResults.outputFolder = outputFolder;
    exportResults.savedFiles = savedFiles;
    exportResults.manifest = manifest;
    exportResults.manifestFile = string(manifestFile);
    exportResults.mapIndexFile = string(mapIndexFile);
    exportResults.matFile = string(matFile);

end

function resultsCopy = removeFigureHandles(simulationResults, outputs)
% removeFigureHandles Keep the MAT archive numerical and reloadable.

    for mapNumber = 1:numel(outputs.maps)
        outputs.maps(mapNumber).figureHandle = [];
    end
    for mapNumber = 1:numel(outputs.primaryMaps)
        outputs.primaryMaps(mapNumber).figureHandle = [];
    end
    for mapNumber = 1:numel(outputs.diagnosticMaps)
        outputs.diagnosticMaps(mapNumber).figureHandle = [];
    end
    resultsCopy = simulationResults;
    resultsCopy.outputs = outputs;

end
