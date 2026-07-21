function savedFigureFiles = saveSubjectFigures(outputFolder, figureNames)
% saveSubjectFigures Save the subject figures created by plotSubjectResults.

    savedFigureFiles = strings(numel(figureNames), 1);
    numSavedFigures = 0;

    for figureIndex = 1:numel(figureNames)
        figureName = figureNames(figureIndex);

        if strlength(figureName) == 0
            continue
        end

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
        figurePath = fullfile(outputFolder, figureFileName);

        exportgraphics( ...
            figureHandle, figurePath, "Resolution", 150);

        numSavedFigures = numSavedFigures + 1;
        savedFigureFiles(numSavedFigures) = string(figurePath);
    end

    savedFigureFiles = savedFigureFiles(1:numSavedFigures);

end
