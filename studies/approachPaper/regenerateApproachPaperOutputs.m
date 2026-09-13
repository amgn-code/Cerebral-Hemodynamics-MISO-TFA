function paperResults = regenerateApproachPaperOutputs( ...
    sourceResultFile, overrides)
% regenerateApproachPaperOutputs Rebuild outputs without rerunning analyses.
%
% Allowed overrides are intentionally limited to outputFolder,
% createTables, createFigures, and fields already present in export. This
% prevents a render-only call from silently changing numerical settings.

    arguments
        sourceResultFile (1,1) string
        overrides (1,1) struct = struct()
    end

    addApproachPaperPaths();
    validateSourceFile(sourceResultFile);
    loadedResults = load(sourceResultFile);
    validateLoadedResults(loadedResults, sourceResultFile);

    paperResults = loadedResults.paperResults;
    outputSettings = applyOutputOverrides( ...
        paperResults.settings, overrides);
    ensureOutputFolder(outputSettings.outputFolder);

    paperResults.sourceAnalysisResultFile = sourceResultFile;
    paperResults.outputSettings = outputSettings;
    paperResults = summarizeApproachPaperResults( ...
        paperResults, outputSettings);
    paperResults = renderApproachPaperOutputs( ...
        paperResults, outputSettings);

    resultFile = fullfile( ...
        outputSettings.outputFolder, "approach_paper_results.mat");
    paperResults.resultFile = string(resultFile);
    paperResults.completedStage = "Regenerated outputs";
    save(resultFile, "paperResults", "-v7.3");

    fprintf("Regenerated approach paper outputs from:\n%s\n", ...
        sourceResultFile);
    fprintf("Outputs saved to:\n%s\n", outputSettings.outputFolder);

end

function addApproachPaperPaths()
% addApproachPaperPaths Make study and reusable source functions visible.

    studyFolder = fileparts(mfilename("fullpath"));
    projectRoot = fileparts(fileparts(studyFolder));
    addpath(genpath(fullfile(projectRoot, "src")));
    addpath(genpath(studyFolder));

end

function validateSourceFile(sourceResultFile)
% validateSourceFile Give a workflow-specific missing-file error.

    if ~isfile(sourceResultFile)
        error( ...
            "TFA:MissingApproachPaperResultFile", ...
            "The saved result file does not exist: %s", ...
            sourceResultFile);
    end

end

function validateLoadedResults(loadedResults, sourceResultFile)
% validateLoadedResults Confirm that the file contains reusable results.

    if ~isfield(loadedResults, "paperResults") || ...
            ~isstruct(loadedResults.paperResults) || ...
            ~isfield(loadedResults.paperResults, "settings")
        error( ...
            "TFA:MissingApproachPaperResults", ...
            ['The file %s does not contain a paperResults structure ' ...
             'with saved analysis settings.'], ...
            sourceResultFile);
    end

end

function outputSettings = applyOutputOverrides(analysisSettings, overrides)
% applyOutputOverrides Restrict regeneration to presentation choices.

    allowedFields = [ ...
        "outputFolder", "createTables", "createFigures", "export"];
    overrideFields = string(fieldnames(overrides));
    invalidFields = setdiff(overrideFields, allowedFields);
    if ~isempty(invalidFields)
        error( ...
            "TFA:InvalidRenderOverride", ...
            ['Regeneration cannot change numerical settings. Invalid ' ...
             'override field(s): %s'], ...
            join(invalidFields, ", "));
    end

    outputSettings = analysisSettings;
    if isfield(overrides, "outputFolder")
        outputSettings.outputFolder = string(overrides.outputFolder);
        if isfield(outputSettings, "output")
            outputSettings.output.baseOutputFolder = ...
                outputSettings.outputFolder;
        end
    end
    if isfield(overrides, "createTables")
        validateattributes( ...
            overrides.createTables, "logical", {"scalar"});
        outputSettings.steps.createTables = overrides.createTables;
    end
    if isfield(overrides, "createFigures")
        validateattributes( ...
            overrides.createFigures, "logical", {"scalar"});
        outputSettings.steps.createFigures = overrides.createFigures;
    end
    if isfield(overrides, "export")
        outputSettings.export = mergeExportSettings( ...
            outputSettings.export, overrides.export);
    end

    if strlength(outputSettings.outputFolder) == 0
        error( ...
            "TFA:MissingApproachPaperOutputFolder", ...
            "Choose an outputFolder for regenerated outputs.");
    end

end

function exportSettings = mergeExportSettings(exportSettings, overrides)
% mergeExportSettings Allow only known figure-export fields.

    if ~isstruct(overrides) || ~isscalar(overrides)
        error( ...
            "TFA:InvalidRenderOverride", ...
            "The export override must be a scalar structure.");
    end

    overrideFields = string(fieldnames(overrides));
    allowedFields = string(fieldnames(exportSettings));
    invalidFields = setdiff(overrideFields, allowedFields);
    if ~isempty(invalidFields)
        error( ...
            "TFA:InvalidRenderOverride", ...
            "Unknown export override field(s): %s", ...
            join(invalidFields, ", "));
    end

    for fieldIndex = 1:numel(overrideFields)
        fieldName = overrideFields(fieldIndex);
        exportSettings.(fieldName) = overrides.(fieldName);
    end

end

function ensureOutputFolder(outputFolder)
% ensureOutputFolder Create the selected output folder when necessary.

    if ~exist(outputFolder, "dir")
        mkdir(outputFolder);
    end

end
