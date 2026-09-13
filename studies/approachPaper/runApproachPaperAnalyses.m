function paperResults = runApproachPaperAnalyses(settings)
% runApproachPaperAnalyses Run only the numerical workflow stages.
%
% This function deliberately does not build tables or figures. The
% returned structure can be saved once and reused by the output stages.

    analysisSettings = validateTfaSettings(settings.analysis);

    paperResults = struct();
    paperResults.settings = settings;
    paperResults.empirical = struct();
    paperResults.simulation = struct();
    paperResults.robustness = struct();

    if settings.steps.runEmpiricalAnalysis
        fprintf("Running NC empirical SISO and MISO analysis.\n");
        paperResults.empirical = runTFA( ...
            "batch", struct(), settings.batch, ...
            analysisSettings, settings.output);
        saveApproachCheckpoint( ...
            paperResults, settings.outputFolder, "Empirical analysis");
    end

    if settings.steps.runKnownTruthSimulation
        fprintf("Running known-truth validation simulation.\n");
        paperResults.simulation = runApproachPaperSimulation( ...
            settings.simulation);
        saveApproachCheckpoint( ...
            paperResults, settings.outputFolder, ...
            "Known-truth simulation");
    end

    if settings.steps.runRobustnessAnalysis
        requireEmpiricalResults(paperResults.empirical);
        fprintf("Running NC empirical robustness checks.\n");
        paperResults.robustness = runApproachPaperRobustness( ...
            paperResults.empirical.subjectResults, ...
            paperResults.empirical.statisticalResults, ...
            analysisSettings, settings.robustness);
        saveApproachCheckpoint( ...
            paperResults, settings.outputFolder, ...
            "Empirical robustness");
    end

    paperResults.completedStage = "Numerical analyses";

end

function requireEmpiricalResults(empiricalResults)
% requireEmpiricalResults Keep robustness dependencies explicit.

    if isempty(fieldnames(empiricalResults))
        error( ...
            "TFA:RobustnessNeedsEmpiricalResults", ...
            ['The robustness analysis requires empirical results. ' ...
             'Enable steps.runEmpiricalAnalysis.']);
    end

end

function saveApproachCheckpoint(paperResults, outputFolder, completedStage)
% saveApproachCheckpoint Preserve completed long-running stages.

    paperResults.completedStage = string(completedStage);
    checkpointFile = fullfile( ...
        outputFolder, "approach_paper_checkpoint.mat");
    save(checkpointFile, "paperResults", "-v7.3");

end
