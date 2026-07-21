function savedFigureFiles = saveGroupFigures( ...
    groupResults, groupOrder, outputFolder, analysisSettings)
% saveGroupFigures Plot and save the selected group-average figures.

    if isempty(fieldnames(groupResults))
        savedFigureFiles = strings(0, 1);
        return
    end

    figureOutputFolder = fullfile(outputFolder, "Batch_Figures");

    if ~exist(figureOutputFolder, "dir")
        mkdir(figureOutputFolder);
    end

    groupNames = upper(string(groupOrder(:)));
    maxFiguresPerGroup = 9;
    savedFigureFiles = strings( ...
        maxFiguresPerGroup*numel(groupNames), 1);
    numSavedFigures = 0;

    for groupIndex = 1:numel(groupNames)
        groupName = groupNames(groupIndex);

        if ~isfield(groupResults, char(groupName))
            continue
        end

        % plotGroupResults draws the group means and standard deviations.
        figureNames = plotGroupResults( ...
            groupResults.(groupName), groupName, analysisSettings);

        for figureIndex = 1:numel(figureNames)
            figureName = figureNames(figureIndex);
            figureHandle = findall( ...
                0, ...
                "Type", "figure", ...
                "Name", char(figureName));

            if isempty(figureHandle)
                continue
            end

            figureHandle = figureHandle(1);
            figureFileName = lower(figureName);
            figureFileName = regexprep(figureFileName, '[^a-z0-9]+', '_');
            figureFileName = ...
                regexprep(figureFileName, '^_|_$', '') + ".png";
            figurePath = fullfile( ...
                figureOutputFolder, figureFileName);

            drawnow
            exportgraphics( ...
                figureHandle, figurePath, "Resolution", 150);
            close(figureHandle)

            numSavedFigures = numSavedFigures + 1;
            savedFigureFiles(numSavedFigures) = string(figurePath);
        end
    end

    savedFigureFiles = savedFigureFiles(1:numSavedFigures);

end
