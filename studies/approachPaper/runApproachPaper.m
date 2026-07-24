function paperResults = runApproachPaper(settings)
% runApproachPaper Run the complete NC-only MISO approach paper workflow.

    studyFolder = fileparts(mfilename("fullpath"));
    projectRoot = fileparts(fileparts(studyFolder));
    addpath(genpath(fullfile(projectRoot, "src")));
    addpath(studyFolder);

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
        fprintf("Creating publication figures.\n");
        paperResults.figureFiles = createAndSaveFigures( ...
            paperResults, analysisSettings, settings);
    else
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

function savedFiles = createAndSaveFigures( ...
    paperResults, analysisSettings, settings)
% createAndSaveFigures Build, export, and close every available figure.

    figureFolder = fullfile(settings.outputFolder, "Figures");
    sourceFolder = fullfile(figureFolder, "Source_Data");
    if ~exist(figureFolder, "dir")
        mkdir(figureFolder);
    end
    if settings.export.saveFigureSourceData && ...
            ~exist(sourceFolder, "dir")
        mkdir(sourceFolder);
    end

    savedFiles = strings(0, 1);

    figureHandle = plotApproachFigure1Concept();
    savedFiles = [savedFiles; exportApproachPaperFigure( ...
        figureHandle, fullfile(figureFolder, "figure_1_concept"), ...
        settings.export)];
    close(figureHandle);

    if ~isempty(fieldnames(paperResults.simulation))
        [figureHandle, sourceData] = ...
            plotApproachFigure2Identifiability( ...
                paperResults.simulation);
        savedFiles = [savedFiles; exportApproachPaperFigure( ...
            figureHandle, ...
            fullfile(figureFolder, "figure_2_identifiability"), ...
            settings.export)];
        if settings.export.saveFigureSourceData
            saveSourceData(sourceData, sourceFolder, "figure_2");
        end
        close(figureHandle);

        [figureHandle, sourceData] = ...
            plotApproachFigure3KnownTruth( ...
                paperResults.simulation, ...
                settings.export.figure3RidgeLambda);
        savedFiles = [savedFiles; exportApproachPaperFigure( ...
            figureHandle, ...
            fullfile(figureFolder, "figure_3_known_truth"), ...
            settings.export)];
        if settings.export.saveFigureSourceData
            saveSourceData(sourceData, sourceFolder, "figure_3");
        end
        close(figureHandle);

        [figureHandle, sourceData] = ...
            plotApproachFigure4Conditioning( ...
                paperResults.simulation);
        savedFiles = [savedFiles; exportApproachPaperFigure( ...
            figureHandle, ...
            fullfile(figureFolder, "figure_4_conditioning"), ...
            settings.export)];
        if settings.export.saveFigureSourceData
            saveSourceData(sourceData, sourceFolder, "figure_4");
        end
        close(figureHandle);
    end

    if ~isempty(fieldnames(paperResults.empirical))
        [figureHandle, sourceData] = ...
            plotApproachFigure5NcComparison( ...
                paperResults.empirical, analysisSettings);
        savedFiles = [savedFiles; exportApproachPaperFigure( ...
            figureHandle, ...
            fullfile(figureFolder, "figure_5_nc_comparison"), ...
            settings.export)];
        if settings.export.saveFigureSourceData
            saveSourceData(sourceData, sourceFolder, "figure_5");
        end
        close(figureHandle);

        frequencyResults = paperResults.empirical. ...
            statisticalResults.frequencyModelComparisons;
        hasPhaseResults = ~isempty(frequencyResults) && ...
            any(frequencyResults.Metric == "Phase");
        if hasPhaseResults
            [figureHandle, sourceData] = ...
                plotApproachFrequencyPhaseComparison( ...
                    frequencyResults);
            savedFiles = [savedFiles; exportApproachPaperFigure( ...
                figureHandle, ...
                fullfile(figureFolder, ...
                "figure_s1_frequency_phase"), ...
                settings.export)];
            if settings.export.saveFigureSourceData
                saveSourceData( ...
                    sourceData, sourceFolder, "figure_s1");
            end
            close(figureHandle);
        end
    end

    if ~isempty(fieldnames(paperResults.robustness))
        [figureHandle, sourceData] = ...
            plotApproachFigure6Robustness( ...
                paperResults.robustness);
        savedFiles = [savedFiles; exportApproachPaperFigure( ...
            figureHandle, ...
            fullfile(figureFolder, "figure_6_robustness"), ...
            settings.export)];
        if settings.export.saveFigureSourceData
            saveSourceData(sourceData, sourceFolder, "figure_6");
        end
        close(figureHandle);
    end

end

function saveSourceData(sourceData, sourceFolder, figureName)
% saveSourceData Save tables used to draw one figure.

    if istable(sourceData)
        writetable(sourceData, ...
            fullfile(sourceFolder, figureName + "_source.csv"));
        return
    end

    if ~isstruct(sourceData)
        return
    end

    fieldNames = fieldnames(sourceData);
    for fieldIndex = 1:numel(fieldNames)
        fieldName = fieldNames{fieldIndex};
        currentData = sourceData.(fieldName);
        if istable(currentData)
            filename = figureName + "_" + ...
                lower(string(fieldName)) + ".csv";
            writetable(currentData, fullfile(sourceFolder, filename));
        end
    end

end
