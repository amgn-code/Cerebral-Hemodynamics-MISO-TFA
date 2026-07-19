function savedFigureFiles = saveBatchFullFrequencyFigures( ...
    groupResults, outputFolder, analysisSettings)
% saveBatchFullFrequencyFigures Plot and save selected group-average figures.

    if isempty(fieldnames(groupResults))
        savedFigureFiles = strings(0, 1);
        return
    end

    figureOutputFolder = fullfile(outputFolder, "Batch_Figures");

    if ~exist(figureOutputFolder, "dir")
        mkdir(figureOutputFolder);
    end

    groupNames = string(fieldnames(groupResults));
    maxFiguresPerGroup = 9;
    savedFigureFiles = strings( ...
        maxFiguresPerGroup*numel(groupNames), 1);
    numSavedFigures = 0;

    for groupIndex = 1:numel(groupNames)
        groupName = groupNames(groupIndex);
        figureNames = plotGroupResults( ...
            groupResults.(groupName), groupName, analysisSettings);

        for figureIndex = 1:numel(figureNames)
            figureName = figureNames(figureIndex);
            fig = findobj( ...
                findall(0, "Type", "figure"), ...
                "Type", "figure", ...
                "Name", char(figureName));

            if isempty(fig)
                continue
            end

            fig = fig(1);
            figureFileName = lower(figureName);
            figureFileName = regexprep(figureFileName, '[^a-z0-9]+', '_');
            figureFileName = regexprep(figureFileName, '^_|_$', '');
            figurePath = fullfile( ...
                figureOutputFolder, figureFileName + ".png");

            drawnow
            exportgraphics(fig, figurePath, "Resolution", 150);
            close(fig)

            numSavedFigures = numSavedFigures + 1;
            savedFigureFiles(numSavedFigures) = string(figurePath);
        end
    end

    savedFigureFiles = savedFigureFiles(1:numSavedFigures);

end
