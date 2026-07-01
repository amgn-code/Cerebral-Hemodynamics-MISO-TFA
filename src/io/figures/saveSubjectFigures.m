function saveSubjectFigures(outputFolder, figureMode)

if figureMode == "none"
    return
end

if figureMode == "summary"
    figureNames = [
        "MisoMapToCbvTransferFunction"
        "MisoCo2ToCbvTransferFunction"
        "MisoCoherenceDiagnostics"
        "SisoMapToCbvTransferFunction"
        "SisoCo2ToCbvTransferFunction"
    ];
else
    figures = findall(0, "Type", "figure");
    figureNames = strings(numel(figures), 1);

    for k = 1:numel(figures)
        figureNames(k) = string(figures(k).Name);
    end
end

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

    figureFileName = makeSafeFigureFileName(figureNames(k)) + ".png";
    figurePath = fullfile(outputFolder, figureFileName);

    exportgraphics(fig, figurePath, "Resolution", 300);

end

end


function fileName = makeSafeFigureFileName(figureName)

    fileName = lower(string(figureName));
    fileName = regexprep(fileName, '[^a-z0-9]+', '_');
    fileName = regexprep(fileName, '^_|_$', '');

end
