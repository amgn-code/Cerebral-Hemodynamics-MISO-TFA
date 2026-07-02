function savedFigureFiles = saveBatchFullFrequencyFigures( ...
    fullFrequencyTables, outputFolder)
% saveBatchFullFrequencyFigures
%
% Saves group-average full-frequency transfer-function plots.

savedFigureFiles = strings(0,1);

if isempty(fieldnames(fullFrequencyTables))
    return
end

figureOutputFolder = fullfile(outputFolder, "Batch_Figures");

if ~exist(figureOutputFolder, "dir")
    mkdir(figureOutputFolder);
end

sheetNames = string(fieldnames(fullFrequencyTables));

for k = 1:numel(sheetNames)

    sheetName = sheetNames(k);
    summaryCell = fullFrequencyTables.(sheetName);

    if isempty(summaryCell)
        continue
    end

    [modelName, groupName] = modelGroupFromFullFrequencyName(sheetName);

    if modelName == "MISO"
        figureFiles = saveMISOPathwayFigures( ...
            summaryCell, groupName, figureOutputFolder);
    else
        figureFiles = saveSISOPathwayFigures( ...
            summaryCell, groupName, figureOutputFolder);
    end

    savedFigureFiles = [savedFigureFiles; figureFiles];

end

end


function [modelName, groupName] = modelGroupFromFullFrequencyName(sheetName)

parts = split(sheetName, "_");
modelName = parts(1);
groupName = parts(2);

end


function figureFiles = saveMISOPathwayFigures( ...
    summaryCell, groupName, figureOutputFolder)

f = getColumn(summaryCell, "Frequency_Hz");
multipleCohMean = getColumn(summaryCell, "Multiple_Coh_MeanAcrossSubjects");
multipleCohSD = getColumn(summaryCell, "Multiple_Coh_SDAcrossSubjects");

figureFiles = strings(0,1);

figureFiles(end + 1, 1) = savePathwayFigure( ...
    f, ...
    getColumn(summaryCell, "MAP_Gain_MeanAcrossSubjects"), ...
    getColumn(summaryCell, "MAP_Gain_SDAcrossSubjects"), ...
    getColumn(summaryCell, "MAP_Phase_CircularMeanAcrossSubjects"), ...
    getColumn(summaryCell, "MAP_Phase_CircularSDAcrossSubjects"), ...
    multipleCohMean, multipleCohSD, ...
    getColumn(summaryCell, "MAP|CO2_Coh_MeanAcrossSubjects"), ...
    getColumn(summaryCell, "MAP|CO2_Coh_SDAcrossSubjects"), ...
    "MISO", groupName, "MAP", "MAP|CO2 coherence", figureOutputFolder);

figureFiles(end + 1, 1) = savePathwayFigure( ...
    f, ...
    getColumn(summaryCell, "CO2_Gain_MeanAcrossSubjects"), ...
    getColumn(summaryCell, "CO2_Gain_SDAcrossSubjects"), ...
    getColumn(summaryCell, "CO2_Phase_CircularMeanAcrossSubjects"), ...
    getColumn(summaryCell, "CO2_Phase_CircularSDAcrossSubjects"), ...
    multipleCohMean, multipleCohSD, ...
    getColumn(summaryCell, "CO2|MAP_Coh_MeanAcrossSubjects"), ...
    getColumn(summaryCell, "CO2|MAP_Coh_SDAcrossSubjects"), ...
    "MISO", groupName, "CO2", "CO2|MAP coherence", figureOutputFolder);

end


function figureFiles = saveSISOPathwayFigures( ...
    summaryCell, groupName, figureOutputFolder)

f = getColumn(summaryCell, "Frequency_Hz");
figureFiles = strings(0,1);

figureFiles(end + 1, 1) = savePathwayFigure( ...
    f, ...
    getColumn(summaryCell, "MAP_Gain_MeanAcrossSubjects"), ...
    getColumn(summaryCell, "MAP_Gain_SDAcrossSubjects"), ...
    getColumn(summaryCell, "MAP_Phase_CircularMeanAcrossSubjects"), ...
    getColumn(summaryCell, "MAP_Phase_CircularSDAcrossSubjects"), ...
    [], [], ...
    getColumn(summaryCell, "MAP_Coh_MeanAcrossSubjects"), ...
    getColumn(summaryCell, "MAP_Coh_SDAcrossSubjects"), ...
    "SISO", groupName, "MAP", "MAP coherence", figureOutputFolder);

figureFiles(end + 1, 1) = savePathwayFigure( ...
    f, ...
    getColumn(summaryCell, "CO2_Gain_MeanAcrossSubjects"), ...
    getColumn(summaryCell, "CO2_Gain_SDAcrossSubjects"), ...
    getColumn(summaryCell, "CO2_Phase_CircularMeanAcrossSubjects"), ...
    getColumn(summaryCell, "CO2_Phase_CircularSDAcrossSubjects"), ...
    [], [], ...
    getColumn(summaryCell, "CO2_Coh_MeanAcrossSubjects"), ...
    getColumn(summaryCell, "CO2_Coh_SDAcrossSubjects"), ...
    "SISO", groupName, "CO2", "CO2 coherence", figureOutputFolder);

end


function figureFile = savePathwayFigure( ...
    f, gainMean, gainSD, phaseMean, phaseSD, ...
    multipleCohMean, multipleCohSD, pathwayCohMean, pathwayCohSD, ...
    modelName, groupName, pathwayName, pathwayCohLabel, figureOutputFolder)

figureName = modelName + "_" + groupName + "_" + pathwayName + ...
    "_AverageTransferFunction";
figureTitle = modelName + " " + groupName + " " + pathwayName + ...
    " Average Transfer Function";

[f, gainMean, gainSD, phaseMean, phaseSD, ...
    multipleCohMean, multipleCohSD, pathwayCohMean, pathwayCohSD] = ...
    keepDisplayFrequencyRange( ...
        f, gainMean, gainSD, phaseMean, phaseSD, ...
        multipleCohMean, multipleCohSD, pathwayCohMean, pathwayCohSD);

fig = figure('Name', figureName, 'NumberTitle', 'off');
plotLayout = tiledlayout(fig, 1, 2);

nexttile(plotLayout)
plotPathwayPanel( ...
    f, gainMean, gainSD, ...
    multipleCohMean, multipleCohSD, pathwayCohMean, pathwayCohSD, ...
    pathwayName + " gain", "Magnitude", ...
    pathwayCohLabel)

nexttile(plotLayout)
plotPathwayPanel( ...
    f, phaseMean, phaseSD, ...
    multipleCohMean, multipleCohSD, pathwayCohMean, pathwayCohSD, ...
    pathwayName + " phase", "Phase (rad)", ...
    pathwayCohLabel)

title(plotLayout, figureTitle)

figureFileName = lower(figureName) + ".png";
figureFileName = regexprep(figureFileName, '[^a-z0-9.]+', '_');
figureFile = string(fullfile(figureOutputFolder, figureFileName));

hideAxesToolbars(fig)
waitForFigureRender(fig)
exportgraphics(fig, figureFile, "Resolution", 150);
close(fig)

end


function plotPathwayPanel( ...
    f, transferMean, transferSD, ...
    multipleCohMean, multipleCohSD, pathwayCohMean, pathwayCohSD, ...
    transferLabel, yLabelText, pathwayCohLabel)

yyaxis left
hold on
plotShadedBand(f, transferMean, transferSD, [0 0.4470 0.7410]);
hTransfer = stem(f, transferMean, 'filled', ...
    'Color', [0 0.4470 0.7410], ...
    'MarkerSize', 3, ...
    'LineWidth', 0.7);
ylabel(yLabelText)
xlabel('Frequency (Hz)')
title(transferLabel)
grid on
xlim([0 0.5])

leftMin = min([0; transferMean(:) - transferSD(:)], [], 'omitnan');
leftMax = max([0; transferMean(:) + transferSD(:)], [], 'omitnan');
[leftMin, leftMax] = widenLimitsIfNeeded(leftMin, leftMax);

yyaxis right
hold on
coherenceHandles = plotCoherenceOverlays( ...
    f, multipleCohMean, multipleCohSD, pathwayCohMean, pathwayCohSD);
ylabel('Coherence')
xlim([0 0.5])

rightMax = maxCoherenceLimit( ...
    multipleCohMean, multipleCohSD, pathwayCohMean, pathwayCohSD);
alignRightYAxisZero(leftMin, leftMax, rightMax)

legendHandles = [hTransfer, coherenceHandles];

if isempty(multipleCohMean)
    legendLabels = ["Transfer function", pathwayCohLabel];
else
    legendLabels = ["Transfer function", "Multiple coherence", pathwayCohLabel];
end

legend(legendHandles, cellstr(legendLabels), 'Location', 'best')

end


function coherenceHandles = plotCoherenceOverlays( ...
    f, multipleCohMean, multipleCohSD, pathwayCohMean, pathwayCohSD)

coherenceHandles = gobjects(0);

if ~isempty(multipleCohMean)
    plotShadedBand(f, multipleCohMean, multipleCohSD, [0.4940 0.1840 0.5560]);
    coherenceHandles(end + 1) = plot(f, multipleCohMean, ...
        'Color', [0.4940 0.1840 0.5560], ...
        'LineWidth', 1.0);
end

plotShadedBand(f, pathwayCohMean, pathwayCohSD, [0.9290 0.6940 0.1250]);
coherenceHandles(end + 1) = plot(f, pathwayCohMean, ...
    'Color', [0.9290 0.6940 0.1250], ...
    'LineStyle', '--', ...
    'LineWidth', 1.0);

end


function plotShadedBand(f, yMean, ySD, colorValue)

ySD(isnan(ySD)) = 0;
lowerBound = yMean - ySD;
upperBound = yMean + ySD;

fill([f; flipud(f)], [lowerBound; flipud(upperBound)], colorValue, ...
    'FaceAlpha', 0.15, ...
    'EdgeColor', 'none', ...
    'HandleVisibility', 'off');

end


function rightMax = maxCoherenceLimit( ...
    multipleCohMean, multipleCohSD, pathwayCohMean, pathwayCohSD)

coherenceValues = pathwayCohMean(:) + pathwayCohSD(:);

if ~isempty(multipleCohMean)
    coherenceValues = [
        coherenceValues
        multipleCohMean(:) + multipleCohSD(:)
    ];
end

rightMax = max([1; coherenceValues], [], 'omitnan');
rightMax = 1.05 * rightMax;

end


function [f, gainMean, gainSD, phaseMean, phaseSD, ...
    multipleCohMean, multipleCohSD, pathwayCohMean, pathwayCohSD] = ...
    keepDisplayFrequencyRange( ...
        f, gainMean, gainSD, phaseMean, phaseSD, ...
        multipleCohMean, multipleCohSD, pathwayCohMean, pathwayCohSD)

freqIndex = f >= 0 & f <= 0.5;

f = f(freqIndex);
gainMean = gainMean(freqIndex);
gainSD = gainSD(freqIndex);
phaseMean = phaseMean(freqIndex);
phaseSD = phaseSD(freqIndex);
pathwayCohMean = pathwayCohMean(freqIndex);
pathwayCohSD = pathwayCohSD(freqIndex);

if ~isempty(multipleCohMean)
    multipleCohMean = multipleCohMean(freqIndex);
    multipleCohSD = multipleCohSD(freqIndex);
end

end


function values = getColumn(summaryCell, columnName)

headers = string(summaryCell(1,:));
columnIndex = find(headers == columnName, 1);

if isempty(columnIndex)
    error("Missing full-frequency column: %s", columnName);
end

values = summaryCell(2:end, columnIndex);
values = cellfun(@numericValueOrNaN, values);

end


function value = numericValueOrNaN(cellValue)

if isnumeric(cellValue)
    value = cellValue;
elseif ismissing(string(cellValue)) || string(cellValue) == "-"
    value = NaN;
else
    value = str2double(string(cellValue));
end

end


function [lowerLimit, upperLimit] = widenLimitsIfNeeded(lowerLimit, upperLimit)

if isnan(lowerLimit) || isnan(upperLimit)
    lowerLimit = -1;
    upperLimit = 1;
elseif lowerLimit == upperLimit
    lowerLimit = lowerLimit - 1;
    upperLimit = upperLimit + 1;
end

end


function hideAxesToolbars(fig)

axesHandles = findall(fig, 'Type', 'axes');

for k = 1:numel(axesHandles)
    if isprop(axesHandles(k), 'Toolbar')
        axesHandles(k).Toolbar.Visible = 'off';
    end
end

end


function waitForFigureRender(fig)

figure(fig)
drawnow
pause(0.5)
drawnow

end
