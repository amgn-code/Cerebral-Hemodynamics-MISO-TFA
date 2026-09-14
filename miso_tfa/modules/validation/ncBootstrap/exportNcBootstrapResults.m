function exportResults = exportNcBootstrapResults( ...
    results, outputFolder, exportSettings)
% exportNcBootstrapResults Save the NC bootstrap summary and audit data.
%
% The frequency table is the compact user-facing result. The subject
% frequency table and status table preserve the information needed to audit
% the population bootstrap and blocked validation.

    validateNcBootstrapResults(results);

    if nargin < 2 || isempty(outputFolder)
        error( ...
            "TFA:MissingNCBootstrapOutputFolder", ...
            "Choose an output folder for the NC bootstrap report.");
    end
    outputFolder = string(outputFolder);
    if ~isscalar(outputFolder) || strlength(outputFolder) == 0
        error( ...
            "TFA:MissingNCBootstrapOutputFolder", ...
            "outputFolder must contain one nonempty folder path.");
    end

    defaultExportSettings.saveFigure = true;
    defaultExportSettings.saveFrequencyCsv = true;
    defaultExportSettings.saveStatusCsv = true;
    defaultExportSettings.saveSubjectErrorsCsv = true;
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

    if ~exist(outputFolder, "dir")
        mkdir(outputFolder);
    end

    frequencyTable = results.frequencyTable;
    statusTable = results.statusTable;
    subjectErrorTable = createNcSubjectErrorTable(results);

    exportResults.outputFolder = outputFolder;
    exportResults.frequencyTable = frequencyTable;
    exportResults.statusTable = statusTable;
    exportResults.subjectErrorTable = subjectErrorTable;
    exportResults.savedFiles = strings(0, 1);

    if exportSettings.saveFigure
        plotSettings.enabled = true;
        plotSettings.visible = "off";
        [figureHandle, ~] = plotNcBootstrapAdvantage(results, plotSettings);
        figureFile = fullfile( ...
            outputFolder, "nc_bootstrap_advantage.png");
        exportgraphics(figureHandle, figureFile, "Resolution", 150);
        exportResults.savedFiles(end + 1, 1) = string(figureFile);
        if exportSettings.closeFigure
            close(figureHandle);
        end
    end

    if exportSettings.saveFrequencyCsv
        frequencyFile = fullfile( ...
            outputFolder, "nc_bootstrap_frequency_table.csv");
        writetable(frequencyTable, frequencyFile);
        exportResults.savedFiles(end + 1, 1) = string(frequencyFile);
    end

    if exportSettings.saveStatusCsv
        statusFile = fullfile( ...
            outputFolder, "nc_bootstrap_subject_status.csv");
        writetable(statusTable, statusFile);
        exportResults.savedFiles(end + 1, 1) = string(statusFile);
    end

    if exportSettings.saveSubjectErrorsCsv
        subjectErrorFile = fullfile( ...
            outputFolder, "nc_bootstrap_subject_frequency_errors.csv");
        writetable(subjectErrorTable, subjectErrorFile);
        exportResults.savedFiles(end + 1, 1) = string(subjectErrorFile);
    end

    if exportSettings.saveMat
        resultCopy = results;
        resultCopy.figureHandle = [];
        if isfield(resultCopy, "plotSourceData")
            resultCopy.plotSourceData = [];
        end
        matFile = fullfile( ...
            outputFolder, "nc_bootstrap_results.mat");
        save(matFile, "resultCopy", "frequencyTable", "statusTable", ...
            "subjectErrorTable", "-v7.3");
        exportResults.savedFiles(end + 1, 1) = string(matFile);
    end

end

function subjectErrorTable = createNcSubjectErrorTable(results)
% createNcSubjectErrorTable Flatten subject-by-frequency audit arrays.

    numSubjects = height(results.subjectList);
    numFrequencies = numel(results.frequencyHz);
    subjectIDs = repelem(string(results.subjectList.SubjectID), ...
        numFrequencies, 1);
    frequencyHz = repmat(results.frequencyHz(:), numSubjects, 1);
    sisoError = reshape(results.subjectSisoError.', [], 1);
    misoError = reshape(results.subjectMisoError.', [], 1);
    advantage = calculateErrorAdvantage(sisoError, misoError, ...
        results.settings.errorFloor);
    isValid = isfinite(sisoError) & isfinite(misoError);

    subjectErrorTable = table( ...
        subjectIDs, frequencyHz, sisoError, misoError, advantage, isValid, ...
        'VariableNames', { ...
            'SubjectID', 'FrequencyHz', 'SISOError', 'MISOError', ...
            'Advantage', 'IsValid'});

end

function validateNcBootstrapResults(results)
% validateNcBootstrapResults Check the public NC result shape.

    requiredFields = { ...
        "frequencyTable", "statusTable", "subjectList", ...
        "frequencyHz", "subjectSisoError", "subjectMisoError", ...
        "settings"};
    if ~isstruct(results)
        error( ...
            "TFA:InvalidNCBootstrapResults", ...
            "Provide results returned by ncBootstrap.");
    end
    for fieldIndex = 1:numel(requiredFields)
        if ~isfield(results, requiredFields{fieldIndex})
            error( ...
                "TFA:InvalidNCBootstrapResults", ...
                "The NC result is missing the %s field.", ...
                requiredFields{fieldIndex});
        end
    end

end
