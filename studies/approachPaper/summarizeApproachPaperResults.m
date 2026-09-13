function paperResults = summarizeApproachPaperResults( ...
    paperResults, outputSettings)
% summarizeApproachPaperResults Create manifests and requested tables.
%
% This stage reads completed numerical results but does not run analyses or
% create figures.

    ensureOutputFolder(outputSettings.outputFolder);

    manifest = createApproachPaperManifest(outputSettings);
    manifestFile = fullfile( ...
        outputSettings.outputFolder, "reproducibility_manifest.csv");
    writetable(manifest, manifestFile);
    paperResults.manifest = manifest;
    paperResults.manifestFile = string(manifestFile);

    if isfield(paperResults, "simulation") && ...
            ~isempty(fieldnames(paperResults.simulation))
        fprintf("Auditing completed known-truth simulation.\n");
        paperResults.simulationAudit = ...
            auditApproachPaperSimulation(paperResults.simulation);
        paperResults.simulationAudit.reportFile = ...
            writeApproachPaperSimulationAudit( ...
                paperResults.simulationAudit, ...
                outputSettings.outputFolder);
    else
        paperResults.simulationAudit = struct();
    end

    if outputSettings.steps.createTables
        fprintf("Creating paper tables.\n");
        paperResults.tables = buildApproachPaperTables( ...
            paperResults, outputSettings.outputFolder);
    else
        paperResults.tables = struct();
    end

    paperResults.completedStage = "Summaries and tables";

end

function ensureOutputFolder(outputFolder)
% ensureOutputFolder Create the selected output folder when necessary.

    if ~exist(outputFolder, "dir")
        mkdir(outputFolder);
    end

end
