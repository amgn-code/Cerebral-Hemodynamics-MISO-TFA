function exportResults = exportRealDataResults( ...
    results, outputFolder, exportSettings)
% exportRealDataResults Save a compact descriptive real-data report.
%
% Real-data exports contain frequency-wise model and coherence quantities.
% They do not calculate a truth-based MISO advantage because no generating
% transfer function is available for an observed recording.

    if nargin < 2 || isempty(outputFolder)
        error( ...
            "TFA:MissingRealDataOutputFolder", ...
            "Choose an output folder for the real-data report.");
    end
    outputFolder = string(outputFolder);
    if ~isscalar(outputFolder) || strlength(outputFolder) == 0
        error( ...
            "TFA:MissingRealDataOutputFolder", ...
            "outputFolder must contain one nonempty folder path.");
    end

    defaultExportSettings.saveFigure = true;
    defaultExportSettings.saveCsv = true;
    defaultExportSettings.saveMat = true;
    defaultExportSettings.closeFigure = true;
    if nargin < 3 || isempty(exportSettings)
        exportSettings = defaultExportSettings;
    else
        exportFields = fieldnames(defaultExportSettings);
        for fieldIndex = 1:numel(exportFields)
            fieldName = exportFields{fieldIndex};
            if ~isfield(exportSettings, fieldName)
                exportSettings.(fieldName) = ...
                    defaultExportSettings.(fieldName);
            end
        end
    end

    sourceData = createRealDataFrequencyTable(results);
    if ~exist(outputFolder, "dir")
        mkdir(outputFolder);
    end

    [figureHandle, ~] = plotRealDataFrequencyDiagnostics(results);
    exportResults.outputFolder = outputFolder;
    exportResults.sourceData = sourceData;
    exportResults.savedFiles = strings(0, 1);

    if exportSettings.saveFigure
        figureFile = fullfile( ...
            outputFolder, "real_data_frequency_diagnostics.png");
        exportgraphics(figureHandle, figureFile, "Resolution", 150);
        exportResults.savedFiles(end + 1, 1) = string(figureFile);
    end

    if exportSettings.saveCsv
        csvFile = fullfile( ...
            outputFolder, "real_data_frequency_metrics.csv");
        writetable(sourceData, csvFile);
        exportResults.savedFiles(end + 1, 1) = string(csvFile);
    end

    if exportSettings.saveMat
        matFile = fullfile( ...
            outputFolder, "real_data_frequency_metrics.mat");
        save(matFile, "sourceData", "-v7.3");
        exportResults.savedFiles(end + 1, 1) = string(matFile);
    end

    if exportSettings.closeFigure
        close(figureHandle);
    end

end
