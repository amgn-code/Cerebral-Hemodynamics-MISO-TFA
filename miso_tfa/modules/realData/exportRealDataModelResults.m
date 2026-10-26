function exportResults = exportRealDataModelResults(results, outputSettings)
% exportRealDataModelResults Export one MISO or SISO model-page result.

    settings = completeExportSettings(outputSettings);
    outputFolder = string(settings.outputFolder);
    if ~isscalar(outputFolder) || strlength(outputFolder) == 0
        error( ...
            "TFA:MissingRealDataOutputFolder", ...
            "Set displaySettings.outputFolder to a nonempty folder path.");
    end
    if ~exist(outputFolder, "dir")
        mkdir(outputFolder);
    end

    modelName = lower(string(results.interfaceModel));
    fileStem = modelName + "_frequency_results";
    sourceData = results.frequencyTable;
    savedFiles = strings(0, 1);
    figureHandle = results.figureHandle;
    createdFigureForExport = false;

    if settings.saveFigure
        if isempty(figureHandle) || ~isgraphics(figureHandle)
            figureSettings = settings;
            figureSettings.createFigure = true;
            figureSettings.visible = "off";
            [figureHandle, ~] = ...
                plotRealDataModelSummary(results, figureSettings);
            createdFigureForExport = true;
        end
        figureFile = fullfile(outputFolder, fileStem + ".png");
        exportgraphics(figureHandle, figureFile, "Resolution", 150);
        savedFiles(end + 1, 1) = string(figureFile);
    end

    if settings.saveCsv
        csvFile = fullfile(outputFolder, fileStem + ".csv");
        writetable(sourceData, csvFile);
        savedFiles(end + 1, 1) = string(csvFile);
    end

    if settings.saveMat
        matFile = fullfile(outputFolder, fileStem + ".mat");
        save(matFile, "sourceData");
        savedFiles(end + 1, 1) = string(matFile);
    end

    if isgraphics(figureHandle) && ...
            (settings.closeFigureAfterExport || createdFigureForExport)
        close(figureHandle);
    end

    exportResults.outputFolder = outputFolder;
    exportResults.sourceData = sourceData;
    exportResults.savedFiles = savedFiles;

end

function settings = completeExportSettings(settings)
% completeExportSettings Fill export fields from the public defaults.

    defaults = defaultRealDataDisplaySettings("off");
    fieldNames = [ ...
        "outputFolder", "saveFigure", "saveCsv", "saveMat", ...
        "closeFigureAfterExport"];
    for fieldNumber = 1:numel(fieldNames)
        fieldName = fieldNames(fieldNumber);
        if ~isfield(settings, fieldName)
            settings.(fieldName) = defaults.(fieldName);
        end
    end

    logicalFields = [ ...
        "saveFigure", "saveCsv", "saveMat", ...
        "closeFigureAfterExport"];
    for fieldNumber = 1:numel(logicalFields)
        fieldName = logicalFields(fieldNumber);
        if ~islogical(settings.(fieldName)) || ...
                ~isscalar(settings.(fieldName))
            error( ...
                "TFA:InvalidRealDataExportSetting", ...
                "%s must be true or false.", fieldName);
        end
    end

end
