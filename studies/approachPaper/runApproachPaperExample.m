function paperResults = runApproachPaperExample( ...
    dataFolder, outputFolder)
% runApproachPaperExample Run the beginner-friendly quick profile.
%
% After the quick run looks correct, create settings with the "paper"
% profile and run runApproachPaper again for the final analysis.

    settings = approachPaperSettings( ...
        dataFolder, outputFolder, "quick");
    paperResults = runApproachPaper(settings);

end
