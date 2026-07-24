function savedFiles = exportApproachPaperFigure( ...
    figureHandle, outputBasePath, exportSettings)
% exportApproachPaperFigure Save one fixed-size publication figure.

    outputBasePath = string(outputBasePath);
    outputFolder = fileparts(outputBasePath);
    if ~exist(outputFolder, "dir")
        mkdir(outputFolder);
    end

    figureHandle.Color = "white";
    figureHandle.Units = "inches";
    figureHandle.Position(3:4) = [ ...
        exportSettings.widthInches, ...
        exportSettings.heightInches];
    drawnow

    savedFiles = strings(0, 1);
    if exportSettings.savePdf
        pdfFile = outputBasePath + ".pdf";
        exportgraphics( ...
            figureHandle, pdfFile, "ContentType", "vector", ...
            "BackgroundColor", "white");
        savedFiles(end + 1,1) = pdfFile;
    end
    if exportSettings.savePng
        pngFile = outputBasePath + ".png";
        exportgraphics( ...
            figureHandle, pngFile, ...
            "Resolution", exportSettings.pngResolution, ...
            "BackgroundColor", "white");
        savedFiles(end + 1,1) = pngFile;
    end

end
