function paperResults = renderApproachPaperOutputs( ...
    paperResults, outputSettings)
% renderApproachPaperOutputs Create requested figures from saved results.
%
% No empirical or simulation analysis is performed in this stage.

    analysisSettings = validateTfaSettings(outputSettings.analysis);

    if outputSettings.steps.createFigures
        fprintf("Creating organized plot groups.\n");
        paperResults.plotResults = exportApproachPaperPlotGroups( ...
            paperResults, analysisSettings, outputSettings);
        paperResults.figureFiles = ...
            paperResults.plotResults.savedFiles;
    else
        paperResults.plotResults = struct();
        paperResults.figureFiles = strings(0, 1);
    end

    paperResults.completedStage = "Rendered outputs";

end
