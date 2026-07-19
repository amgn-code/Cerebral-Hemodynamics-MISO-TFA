function saveSubjectFigures(outputFolder, figureNames)
% saveSubjectFigures Save the subject figures created by plotSubjectResults.

for k = 1:numel(figureNames)

    if strlength(figureNames(k)) == 0
        continue
    end

    fig = findobj( ...
        findall(0, "Type", "figure"), ...
        "Type", "figure", ...
        "Name", char(figureNames(k)));

    if isempty(fig)
        continue
    end

    fig = fig(1);
    figure(fig)

    figureFileName = lower(string(figureNames(k)));
    figureFileName = regexprep(figureFileName, '[^a-z0-9]+', '_');
    figureFileName = regexprep(figureFileName, '^_|_$', '') + ".png";
    figurePath = fullfile(outputFolder, figureFileName);

    exportgraphics(fig, figurePath, "Resolution", 150);

end

end
