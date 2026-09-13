function paperResults = runApproachPaper(settings)
% runApproachPaper Run analyses once, then build all requested outputs.
%
% The numerical result file is saved before any tables or figures are
% created. Use regenerateApproachPaperOutputs to rebuild those outputs
% later without repeating the empirical or simulation analyses.

    addApproachPaperPaths();
    validateApproachPaperPaths(settings);
    ensureOutputFolder(settings.outputFolder);

    fprintf("\nApproach paper profile: %s\n", settings.profileName);
    paperResults = runApproachPaperAnalyses(settings);

    analysisResultFile = fullfile( ...
        settings.outputFolder, "approach_paper_analysis_results.mat");
    paperResults.analysisResultFile = string(analysisResultFile);
    paperResults.completedStage = "Numerical analyses";
    save(analysisResultFile, "paperResults", "-v7.3");
    fprintf("Saved reusable numerical results to:\n%s\n", ...
        analysisResultFile);

    paperResults.outputSettings = settings;
    paperResults = summarizeApproachPaperResults( ...
        paperResults, settings);
    paperResults = renderApproachPaperOutputs( ...
        paperResults, settings);

    resultFile = fullfile( ...
        settings.outputFolder, "approach_paper_results.mat");
    paperResults.resultFile = string(resultFile);
    paperResults.completedStage = "Requested outputs";
    save(resultFile, "paperResults", "-v7.3");

    fprintf("Approach paper outputs saved to:\n%s\n", ...
        settings.outputFolder);

end

function addApproachPaperPaths()
% addApproachPaperPaths Make study and reusable source functions visible.

    studyFolder = fileparts(mfilename("fullpath"));
    projectRoot = fileparts(fileparts(studyFolder));
    addpath(genpath(fullfile(projectRoot, "src")));
    addpath(genpath(studyFolder));

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

function ensureOutputFolder(outputFolder)
% ensureOutputFolder Create the selected output folder when necessary.

    if ~exist(outputFolder, "dir")
        mkdir(outputFolder);
    end

end
