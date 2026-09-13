function [manifestRow, savedFiles] = exportApproachPaperPlot( ...
    figureHandle, sourceData, figuresFolder, groupNumber, ...
    plotName, plotTitle, exportSettings, captionDetails)
% exportApproachPaperPlot Export one plot, source data, and full caption.

    if nargin < 8
        captionDetails = struct();
    end

    plotFolder = fullfile(figuresFolder, "Plots");
    sourceFolder = fullfile(figuresFolder, "Source_Data");
    captionFolder = fullfile(figuresFolder, "Captions");
    ensureFolder(plotFolder);
    ensureFolder(sourceFolder);
    ensureFolder(captionFolder);

    imageFiles = exportApproachPaperFigure( ...
        figureHandle, fullfile(plotFolder, plotName), ...
        exportSettings);
    if exportSettings.saveFigureSourceData
        sourceFiles = saveApproachFigureSourceData( ...
            sourceData, sourceFolder, plotName);
    else
        sourceFiles = strings(0, 1);
    end

    captionInfo = createApproachPaperFigureCaption( ...
        groupNumber, plotName, plotTitle, sourceData, ...
        exportSettings, captionDetails);
    if shouldSaveCaptionFiles(exportSettings)
        captionFile = fullfile( ...
            captionFolder, string(plotName) + "_caption.txt");
        writeCaptionFile(captionFile, captionInfo);
    else
        captionFile = "";
    end

    captionFiles = string(captionFile);
    captionFiles(strlength(captionFiles) == 0) = [];
    savedFiles = [imageFiles; sourceFiles; captionFiles];

    manifestRow = table( ...
        groupNumber, string(plotName), string(plotTitle), ...
        captionInfo.Caption, captionInfo.EvidenceLevel, ...
        captionInfo.ReferenceContext, ...
        captionInfo.GroupingDescription, ...
        captionInfo.AdjustmentFamily, ...
        string(captionFile), ...
        join(imageFiles, "; "), join(sourceFiles, "; "), ...
        'VariableNames', { ...
            'GroupNumber', 'PlotName', 'Title', 'Caption', ...
            'EvidenceLevel', 'ReferenceContext', ...
            'GroupingDescription', 'AdjustmentFamily', ...
            'CaptionFile', 'ImageFiles', 'SourceDataFiles'});

end

function ensureFolder(folderPath)
% ensureFolder Create an output subfolder when it does not exist.

    if ~exist(folderPath, "dir")
        mkdir(folderPath);
    end

end

function saveCaptions = shouldSaveCaptionFiles(exportSettings)
% shouldSaveCaptionFiles Preserve compatibility with older settings.

    if isfield(exportSettings, "saveCaptionFiles")
        saveCaptions = exportSettings.saveCaptionFiles;
    else
        saveCaptions = true;
    end

end

function writeCaptionFile(captionFile, captionInfo)
% writeCaptionFile Save a readable title-and-caption text document.

    lines = [ ...
        captionInfo.Title
        ""
        captionInfo.Caption];
    writelines(lines, captionFile);

end
