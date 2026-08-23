function paperResults = runApproachPaper(settings)
% runApproachPaper Run the complete NC-only MISO approach paper workflow.

    studyFolder = fileparts(mfilename("fullpath"));
    projectRoot = fileparts(fileparts(studyFolder));
    addpath(genpath(fullfile(projectRoot, "src")));
    addpath(genpath(studyFolder));

    validateApproachPaperPaths(settings);
    if ~exist(settings.outputFolder, "dir")
        mkdir(settings.outputFolder);
    end

    paperResults = struct();
    paperResults.settings = settings;
    paperResults.empirical = struct();
    paperResults.simulation = struct();
    paperResults.robustness = struct();

    fprintf("\nApproach paper profile: %s\n", settings.profileName);

    if settings.steps.runEmpiricalAnalysis
        fprintf("Running NC empirical SISO and MISO analysis.\n");
        analysisSettings = validateTfaSettings(settings.analysis);
        paperResults.empirical = runTFA( ...
            "batch", struct(), settings.batch, ...
            analysisSettings, settings.output);
        saveApproachCheckpoint( ...
            paperResults, settings.outputFolder, "Empirical analysis");
    else
        analysisSettings = validateTfaSettings(settings.analysis);
    end

    if settings.steps.runKnownTruthSimulation
        fprintf("Running known-truth validation simulation.\n");
        paperResults.simulation = runKnownTruthSimulationGrid( ...
            settings.simulation);
        saveApproachCheckpoint( ...
            paperResults, settings.outputFolder, ...
            "Known-truth simulation");
    end

    if settings.steps.runRobustnessAnalysis
        if isempty(fieldnames(paperResults.empirical))
            error( ...
                "TFA:RobustnessNeedsEmpiricalResults", ...
                ['The robustness analysis requires empirical results. ' ...
                 'Enable steps.runEmpiricalAnalysis.']);
        end
        fprintf("Running NC empirical robustness checks.\n");
        paperResults.robustness = runApproachPaperRobustness( ...
            paperResults.empirical.subjectResults, ...
            paperResults.empirical.statisticalResults, ...
            analysisSettings, settings.robustness);
        saveApproachCheckpoint( ...
            paperResults, settings.outputFolder, ...
            "Empirical robustness");
    end

    manifest = createApproachPaperManifest(settings);
    manifestFile = fullfile( ...
        settings.outputFolder, "reproducibility_manifest.csv");
    writetable(manifest, manifestFile);
    paperResults.manifest = manifest;
    paperResults.manifestFile = string(manifestFile);

    if settings.steps.createTables
        fprintf("Creating paper tables.\n");
        paperResults.tables = buildApproachPaperTables( ...
            paperResults, settings.outputFolder);
    end

    if settings.steps.createFigures
        fprintf("Creating organized plot groups.\n");
        paperResults.plotResults = exportApproachPaperPlotGroups( ...
            paperResults, analysisSettings, settings);
        paperResults.figureFiles = ...
            paperResults.plotResults.savedFiles;
    else
        paperResults.plotResults = struct();
        paperResults.figureFiles = strings(0, 1);
    end

    resultFile = fullfile( ...
        settings.outputFolder, "approach_paper_results.mat");
    save(resultFile, "paperResults", "-v7.3");
    paperResults.resultFile = string(resultFile);

    fprintf("Approach paper outputs saved to:\n%s\n", ...
        settings.outputFolder);

end

function saveApproachCheckpoint(paperResults, outputFolder, completedStage)
% saveApproachCheckpoint Preserve completed long-running stages.

    paperResults.completedStage = string(completedStage);
    checkpointFile = fullfile( ...
        outputFolder, "approach_paper_checkpoint.mat");
    save(checkpointFile, "paperResults", "-v7.3");

end

function validateApproachPaperPaths(settings)
% validateApproachPaperPaths Catch missing path choices before a long run.

    if strlength(settings.outputFolder) == 0
        error( ...
            "TFA:MissingApproachPaperOutputFolder", ...
            "Choose settings.outputFolder before running the paper.");
    end
    if settings.steps.runEmpiricalAnalysis
        if strlength(settings.dataFolder) == 0 || ...
                ~isfolder(settings.dataFolder)
            error( ...
                "TFA:MissingApproachPaperDataFolder", ...
                ['Choose an existing settings.dataFolder before running ' ...
                 'the NC empirical analysis.']);
        end
    end

end
