function batchResults = runBatchTFA( ...
    subjectList, analysisSettings, outputSettings, batchSettings)
% runBatchTFA
%
% Runs TFA for every subject in subjectList and writes a batch summary file.

if nargin < 4
    batchSettings.batchRunMode = "all";
    batchSettings.numSubjectsPerGroup = Inf;
    batchSettings.groupsToRun = unique(string(subjectList.Group), 'stable');
end

if ~exist(outputSettings.baseOutputFolder, "dir")
    mkdir(outputSettings.baseOutputFolder);
end

statusTable = table();
misoBandTable = table();
sisoBandTable = table();
comparisonTable = table();
groupSummaryCell = {};
fullFrequencyTables = struct();
fullFrequencyStatusTable = table();
batchFigureFiles = strings(0,1);

subjectResults = cell(height(subjectList), 1);
successfulOutputCounts = initializeSuccessfulOutputCounts(batchSettings);

for i = 1:height(subjectList)

    subjectInfo = subjectInfoFromTableRow(subjectList(i,:));

    if groupHasEnoughSuccessfulOutputs(subjectInfo.group, successfulOutputCounts, batchSettings)
        continue
    end

    try

        subjectResults{i} = runSingleSubjectTFA( ...
            subjectInfo, analysisSettings, outputSettings);

        subjectInfo = subjectResults{i}.subjectInfo;
        runStatus = subjectResults{i}.runStatus;

        statusTable = [statusTable; makeBatchStatusRow(subjectInfo, runStatus)];

        if runStatus.analysisSucceeded

            successfulOutputCounts = incrementSuccessfulOutputCount( ...
                subjectInfo.group, successfulOutputCounts);

            tfaResults = subjectResults{i}.tfaResults;
            misoRows = addSubjectMetadataToBandAverages( ...
                tfaResults.bandAverages, tfaResults.welchInfo, subjectInfo);
            misoBandTable = [misoBandTable; misoRows];

            comparisonRows = makeMISOComparisonRows( ...
                subjectInfo, tfaResults.bandAverages);
            comparisonTable = [comparisonTable; comparisonRows];

            if analysisSettings.runSISO
                sisoResults = subjectResults{i}.sisoResults;
                sisoRows = addSubjectMetadataToBandAverages( ...
                    sisoResults.bandAverages, sisoResults.welchInfo, subjectInfo);
                sisoBandTable = [sisoBandTable; sisoRows];

                comparisonRows = makeSISOComparisonRows( ...
                    subjectInfo, sisoResults.bandAverages);
                comparisonTable = [comparisonTable; comparisonRows];
            end
        end

    catch errorInfo

        runStatus = makeFailedRunStatus(errorInfo, analysisSettings);
        statusTable = [statusTable; makeBatchStatusRow(subjectInfo, runStatus)];

        fprintf("Subject %s failed: %s\n", ...
            string(subjectInfo.subjectID), string(errorInfo.message));

    end

    close all

    if allRequestedGroupsHaveEnoughSuccessfulOutputs( ...
            successfulOutputCounts, batchSettings)
        break
    end

end

if ~isempty(comparisonTable)
    groupSummaryCell = makeGroupSummaryCell(comparisonTable);
end

if outputSettings.saveFullFrequencyData
    [fullFrequencyTables, fullFrequencyStatusTable] = ...
        makeFullFrequencyBatchSummaries(subjectResults, analysisSettings.runSISO);
end

if outputSettings.saveFullFrequencyData && outputSettings.saveFigures
    batchFigureFiles = saveBatchFullFrequencyFigures( ...
        fullFrequencyTables, outputSettings.baseOutputFolder);
end

if outputSettings.saveBatchSummaryExcel
    batchSummaryFile = fullfile( ...
        outputSettings.baseOutputFolder, ...
        outputSettings.batchSummaryExcelFileName);

    saveBatchSummaryToExcel( ...
        batchSummaryFile, statusTable, ...
        misoBandTable, sisoBandTable, comparisonTable, groupSummaryCell, ...
        fullFrequencyTables, fullFrequencyStatusTable, ...
        analysisSettings.runSISO);
end

batchResults.subjectList = subjectList;
batchResults.subjectResults = subjectResults;
batchResults.statusTable = statusTable;
batchResults.misoBandTable = misoBandTable;
batchResults.sisoBandTable = sisoBandTable;
batchResults.comparisonTable = comparisonTable;
batchResults.groupSummaryCell = groupSummaryCell;
batchResults.fullFrequencyTables = fullFrequencyTables;
batchResults.fullFrequencyStatusTable = fullFrequencyStatusTable;
batchResults.batchFigureFiles = batchFigureFiles;
batchResults.successfulOutputCounts = successfulOutputCounts;

end


function successfulOutputCounts = initializeSuccessfulOutputCounts(batchSettings)

groupsToRun = upper(string(batchSettings.groupsToRun(:)));
successfulOutputCounts = table( ...
    groupsToRun, ...
    zeros(numel(groupsToRun), 1), ...
    'VariableNames', {'Group', 'SuccessfulOutputs'});

end


function isComplete = groupHasEnoughSuccessfulOutputs( ...
    groupName, successfulOutputCounts, batchSettings)

if lower(string(batchSettings.batchRunMode)) ~= "firstn"
    isComplete = false;
    return
end

groupIndex = successfulOutputCounts.Group == upper(string(groupName));
isComplete = successfulOutputCounts.SuccessfulOutputs(groupIndex) >= ...
    batchSettings.numSubjectsPerGroup;

end


function successfulOutputCounts = incrementSuccessfulOutputCount( ...
    groupName, successfulOutputCounts)

groupIndex = successfulOutputCounts.Group == upper(string(groupName));
successfulOutputCounts.SuccessfulOutputs(groupIndex) = ...
    successfulOutputCounts.SuccessfulOutputs(groupIndex) + 1;

end


function isComplete = allRequestedGroupsHaveEnoughSuccessfulOutputs( ...
    successfulOutputCounts, batchSettings)

if lower(string(batchSettings.batchRunMode)) ~= "firstn"
    isComplete = false;
    return
end

isComplete = all(successfulOutputCounts.SuccessfulOutputs >= ...
    batchSettings.numSubjectsPerGroup);

end


function subjectInfo = subjectInfoFromTableRow(subjectRow)

subjectInfo.subjectID = string(subjectRow.SubjectID);
subjectInfo.group = string(subjectRow.Group);
subjectInfo.session = string(subjectRow.Session);
subjectInfo.sourceFile = string(subjectRow.SourceFile);

end


function runStatus = makeFailedRunStatus(errorInfo, analysisSettings)

runStatus.analysisSucceeded = false;
runStatus.runStage = classifyFailureStage(errorInfo);
runStatus.statusMessage = "Failed: " + string(errorInfo.message);
runStatus.isTooShortForWelch = "";
runStatus.numWelchWindows = NaN;
if isfield(analysisSettings, 'minimumWelchWindows')
    runStatus.minimumWelchWindows = analysisSettings.minimumWelchWindows;
else
    runStatus.minimumWelchWindows = 1;
end
runStatus.signalDurationSeconds = NaN;
runStatus.windowLengthSeconds = analysisSettings.windowLengthSeconds;
runStatus.windowOverlap = analysisSettings.windowOverlap;
runStatus.runSISO = analysisSettings.runSISO;
runStatus.misoUsedDefaultCoherenceThreshold = "";
runStatus.sisoUsedDefaultCoherenceThreshold = "";
runStatus.misoCoherenceThreshold = NaN;
runStatus.sisoCoherenceThreshold = NaN;

end


function runStage = classifyFailureStage(errorInfo)

switch string(errorInfo.identifier)
    case "TFA:LoadDataFailed"
        runStage = "LoadDataFailed";
    case "TFA:PreprocessingFailed"
        runStage = "PreprocessingFailed";
    case "TFA:MISOFailed"
        runStage = "MISOFailed";
    case "TFA:SISOFailed"
        runStage = "SISOFailed";
    case "TFA:ExcelSaveFailed"
        runStage = "ExcelSaveFailed";
    case "TFA:FigureSaveFailed"
        runStage = "FigureSaveFailed";
    otherwise
        runStage = "UnknownFailed";
end

end


function statusRow = makeBatchStatusRow(subjectInfo, runStatus)

statusRow = table( ...
    string(subjectInfo.subjectID), ...
    string(subjectInfo.group), ...
    string(subjectInfo.session), ...
    string(subjectInfo.sourceFile), ...
    statusValueToString(runStatus.analysisSucceeded), ...
    string(runStatus.runStage), ...
    string(runStatus.statusMessage), ...
    statusValueToString(runStatus.isTooShortForWelch), ...
    runStatus.numWelchWindows, ...
    runStatus.minimumWelchWindows, ...
    runStatus.signalDurationSeconds, ...
    runStatus.windowLengthSeconds, ...
    runStatus.windowOverlap, ...
    statusValueToString(runStatus.runSISO), ...
    statusValueToString(runStatus.misoUsedDefaultCoherenceThreshold), ...
    statusValueToString(runStatus.sisoUsedDefaultCoherenceThreshold), ...
    runStatus.misoCoherenceThreshold, ...
    runStatus.sisoCoherenceThreshold, ...
    'VariableNames', { ...
        'SubjectID', ...
        'Group', ...
        'Session', ...
        'SourceFile', ...
        'AnalysisSucceeded', ...
        'RunStage', ...
        'StatusMessage', ...
        'IsTooShortForWelch', ...
        'NumWelchWindows', ...
        'MinimumWelchWindows', ...
        'SignalDurationSeconds', ...
        'WindowLengthSeconds', ...
        'WindowOverlap', ...
        'RunSISO', ...
        'MISO_UsedDefaultCoherenceThreshold', ...
        'SISO_UsedDefaultCoherenceThreshold', ...
        'MISO_CoherenceThreshold', ...
        'SISO_CoherenceThreshold' ...
    });

end


function comparisonRows = makeMISOComparisonRows(subjectInfo, misoBands)

numBands = height(misoBands);

comparisonRows = table( ...
    string(misoBands.Band), ...
    repmat(string(subjectInfo.subjectID), numBands, 1), ...
    repmat(string(subjectInfo.group), numBands, 1), ...
    repmat(string(subjectInfo.session), numBands, 1), ...
    repmat(string(subjectInfo.sourceFile), numBands, 1), ...
    repmat("MISO", numBands, 1), ...
    misoBands.MAP_Gain_Mean, ...
    misoBands.MAP_Phase_CircularMean_rad, ...
    misoBands.CO2_Gain_Mean, ...
    misoBands.CO2_Phase_CircularMean_rad, ...
    misoBands.Multiple_Coh_Mean, ...
    misoBands.Partial_Coh_MAP_Mean, ...
    misoBands.Partial_Coh_CO2_Mean, ...
    misoBands.Percent_Passed_Multiple_Coh, ...
    misoBands.Percent_Passed_Partial_MAP_Coh, ...
    misoBands.Percent_Passed_Partial_CO2_Coh, ...
    'VariableNames', comparisonVariableNames());

end


function comparisonRows = makeSISOComparisonRows(subjectInfo, sisoBands)

numBands = height(sisoBands);

comparisonRows = table( ...
    string(sisoBands.Band), ...
    repmat(string(subjectInfo.subjectID), numBands, 1), ...
    repmat(string(subjectInfo.group), numBands, 1), ...
    repmat(string(subjectInfo.session), numBands, 1), ...
    repmat(string(subjectInfo.sourceFile), numBands, 1), ...
    repmat("SISO", numBands, 1), ...
    sisoBands.MAP_Gain_Mean, ...
    sisoBands.MAP_Phase_CircularMean_rad, ...
    sisoBands.CO2_Gain_Mean, ...
    sisoBands.CO2_Phase_CircularMean_rad, ...
    NaN(numBands, 1), ...
    sisoBands.MAP_CBV_Coh_Mean, ...
    sisoBands.CO2_CBV_Coh_Mean, ...
    NaN(numBands, 1), ...
    sisoBands.Percent_Passed_MAP_CBV_Coh, ...
    sisoBands.Percent_Passed_CO2_CBV_Coh, ...
    'VariableNames', comparisonVariableNames());

end


function variableNames = comparisonVariableNames()

variableNames = { ...
    'Band', ...
    'SubjectID', ...
    'Group', ...
    'Session', ...
    'SourceFile', ...
    'Model', ...
    'MAP_Gain_Mean', ...
    'MAP_Phase_CircularMean_rad', ...
    'CO2_Gain_Mean', ...
    'CO2_Phase_CircularMean_rad', ...
    'Multiple_Coh_Mean', ...
    'MAP_Coh_Mean', ...
    'CO2_Coh_Mean', ...
    'Percent_Passed_Multiple_Coh', ...
    'Percent_Passed_MAP_Coh', ...
    'Percent_Passed_CO2_Coh' ...
};

end


function [metricMean, metricSD, metricN] = summarizeGroupMetric( ...
    comparisonTable, groupName, modelName, bandName, metricName)

rowMask = string(comparisonTable.Group) == groupName & ...
    string(comparisonTable.Model) == modelName & ...
    string(comparisonTable.Band) == bandName;

values = comparisonTable{rowMask, metricName};
values = values(~isnan(values));

if isempty(values)
    metricMean = NaN;
    metricSD = NaN;
    metricN = 0;
else
    metricMean = mean(values, 'omitnan');
    metricN = numel(values);

    if metricN < 2
        metricSD = NaN;
    else
        metricSD = std(values, 'omitnan');
    end
end

end


function groupSummaryCell = makeGroupSummaryCell(comparisonTable)

bands = unique(string(comparisonTable.Band), 'stable');
models = unique(string(comparisonTable.Model), 'stable');
groups = ["MCI"; "NC"];

groupSummaryCell = {};

for m = 1:numel(models)
    for g = 1:numel(groups)

        sectionRows = makeGroupSummarySection( ...
            comparisonTable, models(m), groups(g), bands);

        if isempty(groupSummaryCell)
            groupSummaryCell = sectionRows;
        else
            blankRow = cell(1, size(sectionRows, 2));
            groupSummaryCell = [
                groupSummaryCell;
                blankRow;
                sectionRows
            ];
        end
    end
end

end


function sectionRows = makeGroupSummarySection(comparisonTable, modelName, groupName, bands)

headers = groupSummaryHeaders(modelName);
sectionRows = cell(numel(bands) + 2, numel(headers));

sectionRows{1,1} = modelName + " " + groupName;
sectionRows(2,:) = cellstr(headers);

for b = 1:numel(bands)

    bandName = bands(b);
    nSubjects = countSubjectsForSection(comparisonTable, modelName, groupName, bandName);

    sectionRows{b + 2, 1} = char(bandName);
    sectionRows{b + 2, 2} = nSubjects;

    sectionRows(b + 2, 3:4) = meanSdCells( ...
        comparisonTable, groupName, modelName, bandName, "MAP_Gain_Mean");

    sectionRows(b + 2, 5:6) = meanSdCells( ...
        comparisonTable, groupName, modelName, bandName, "CO2_Gain_Mean");

    sectionRows(b + 2, 7:8) = meanSdCells( ...
        comparisonTable, groupName, modelName, bandName, "Multiple_Coh_Mean");

    sectionRows(b + 2, 9:10) = meanSdCells( ...
        comparisonTable, groupName, modelName, bandName, "MAP_Coh_Mean");

    sectionRows(b + 2, 11:12) = meanSdCells( ...
        comparisonTable, groupName, modelName, bandName, "CO2_Coh_Mean");

end

end


function headers = groupSummaryHeaders(modelName)

if modelName == "MISO"
    mapCohName = "MAP|CO2_Coh";
    co2CohName = "CO2|MAP_Coh";
else
    mapCohName = "MAP_Coh";
    co2CohName = "CO2_Coh";
end

headers = [
    "Band"
    "N"
    "MAP_Gain_MeanAcrossSubjects"
    "MAP_Gain_SDAcrossSubjects"
    "CO2_Gain_MeanAcrossSubjects"
    "CO2_Gain_SDAcrossSubjects"
    "Multiple_Coh_MeanAcrossSubjects"
    "Multiple_Coh_SDAcrossSubjects"
    mapCohName + "_MeanAcrossSubjects"
    mapCohName + "_SDAcrossSubjects"
    co2CohName + "_MeanAcrossSubjects"
    co2CohName + "_SDAcrossSubjects"
]';

end


function nSubjects = countSubjectsForSection(comparisonTable, modelName, groupName, bandName)

rowMask = string(comparisonTable.Group) == groupName & ...
    string(comparisonTable.Model) == modelName & ...
    string(comparisonTable.Band) == bandName;

nSubjects = numel(unique(string(comparisonTable.SubjectID(rowMask))));

end


function cells = meanSdCells(comparisonTable, groupName, modelName, bandName, metricName)

[metricMean, metricSD, metricN] = summarizeGroupMetric( ...
    comparisonTable, groupName, modelName, bandName, metricName);

if metricN == 0
    cells = {"-", "-"};
else
    cells = {metricMean, valueOrDash(metricSD)};
end

end


function [fullFrequencyTables, fullFrequencyStatusTable] = ...
    makeFullFrequencyBatchSummaries(subjectResults, runSISO)

groups = ["MCI"; "NC"];
fullFrequencyTables = struct();
fullFrequencyStatusTable = initializeFullFrequencyStatusTable();

for g = 1:numel(groups)

    groupName = groups(g);

    [misoCell, statusRows] = makeFullFrequencySummaryForGroup( ...
        subjectResults, groupName, "MISO");
    fullFrequencyStatusTable = [fullFrequencyStatusTable; statusRows];

    if ~isempty(misoCell)
        fullFrequencyTables.("MISO_" + groupName + "_FullFrequency") = misoCell;
    end

    if runSISO
        [sisoCell, statusRows] = makeFullFrequencySummaryForGroup( ...
            subjectResults, groupName, "SISO");
        fullFrequencyStatusTable = [fullFrequencyStatusTable; statusRows];

        if ~isempty(sisoCell)
            fullFrequencyTables.("SISO_" + groupName + "_FullFrequency") = sisoCell;
        end
    end
end

end


function statusTable = initializeFullFrequencyStatusTable()

statusTable = table( ...
    strings(0,1), ...
    strings(0,1), ...
    strings(0,1), ...
    strings(0,1), ...
    strings(0,1), ...
    zeros(0,1), ...
    'VariableNames', { ...
        'SubjectID', ...
        'Group', ...
        'Model', ...
        'IncludedInFullFrequency', ...
        'Reason', ...
        'NumFrequencyBins' ...
    });

end


function [summaryCell, statusTable] = makeFullFrequencySummaryForGroup( ...
    subjectResults, groupName, modelName)

summaryCell = {};
statusTable = initializeFullFrequencyStatusTable();
referenceF = [];
metricData = struct();
numIncludedSubjects = 0;

for i = 1:numel(subjectResults)

    if isempty(subjectResults{i})
        continue
    end

    subjectInfo = subjectResults{i}.subjectInfo;
    runStatus = subjectResults{i}.runStatus;

    if string(subjectInfo.group) ~= groupName
        continue
    end

    if ~runStatus.analysisSucceeded
        continue
    end

    [modelResults, hasModelResults] = getModelResults(subjectResults{i}, modelName);

    if ~hasModelResults
        statusTable = [statusTable; makeFullFrequencyStatusRow( ...
            subjectInfo, modelName, false, "NoSuccessfulResults", 0)];
        continue
    end

    f = modelResults.f(:);

    if isempty(referenceF)
        referenceF = f;
        metricData = initializeFullFrequencyMetricData(modelName, numel(f));
    elseif ~frequencyVectorsMatch(referenceF, f)
        statusTable = [statusTable; makeFullFrequencyStatusRow( ...
            subjectInfo, modelName, false, "FrequencyVectorMismatch", numel(f))];
        continue
    end

    metricData = addSubjectFullFrequencyMetrics(metricData, modelResults, modelName);
    numIncludedSubjects = numIncludedSubjects + 1;

    statusTable = [statusTable; makeFullFrequencyStatusRow( ...
        subjectInfo, modelName, true, "Included", numel(f))];

end

if numIncludedSubjects > 0
    summaryCell = makeFullFrequencySummaryCell(referenceF, metricData, modelName);
end

end


function [modelResults, hasModelResults] = getModelResults(subjectResult, modelName)

if modelName == "MISO"
    modelResults = subjectResult.tfaResults;
else
    modelResults = subjectResult.sisoResults;
end

hasModelResults = ~isempty(modelResults);

end


function isMatch = frequencyVectorsMatch(referenceF, f)

frequencyTolerance = 1e-12;
isMatch = numel(referenceF) == numel(f) && ...
    max(abs(referenceF(:) - f(:))) <= frequencyTolerance;

end


function metricData = initializeFullFrequencyMetricData(modelName, numFrequencies)

metricNames = fullFrequencyInternalMetricNames(modelName);

for k = 1:numel(metricNames)
    metricData.(metricNames(k)) = NaN(numFrequencies, 0);
end

end


function metricNames = fullFrequencyInternalMetricNames(modelName)

if modelName == "MISO"
    metricNames = [
        "mapGain"
        "mapPhase"
        "co2Gain"
        "co2Phase"
        "multipleCoh"
        "mapCoh"
        "co2Coh"
    ];
else
    metricNames = [
        "mapGain"
        "mapPhase"
        "co2Gain"
        "co2Phase"
        "mapCoh"
        "co2Coh"
    ];
end

end


function metricData = addSubjectFullFrequencyMetrics(metricData, modelResults, modelName)

metricData.mapGain(:, end + 1) = modelResults.mapCbvGain(:);
metricData.mapPhase(:, end + 1) = modelResults.mapCbvPhase(:);
metricData.co2Gain(:, end + 1) = modelResults.co2CbvGain(:);
metricData.co2Phase(:, end + 1) = modelResults.co2CbvPhase(:);

if modelName == "MISO"
    metricData.multipleCoh(:, end + 1) = modelResults.multipleCoh(:);
    metricData.mapCoh(:, end + 1) = modelResults.partialCohMap(:);
    metricData.co2Coh(:, end + 1) = modelResults.partialCohCo2(:);
else
    metricData.mapCoh(:, end + 1) = modelResults.mapCbvCoh(:);
    metricData.co2Coh(:, end + 1) = modelResults.co2CbvCoh(:);
end

end


function statusRow = makeFullFrequencyStatusRow( ...
    subjectInfo, modelName, included, reason, numFrequencyBins)

statusRow = table( ...
    string(subjectInfo.subjectID), ...
    string(subjectInfo.group), ...
    modelName, ...
    string(included), ...
    reason, ...
    numFrequencyBins, ...
    'VariableNames', { ...
        'SubjectID', ...
        'Group', ...
        'Model', ...
        'IncludedInFullFrequency', ...
        'Reason', ...
        'NumFrequencyBins' ...
    });

end


function summaryCell = makeFullFrequencySummaryCell(f, metricData, modelName)

headers = fullFrequencyHeaders(modelName);
numFrequencies = numel(f);
summaryCell = cell(numFrequencies + 1, numel(headers));
summaryCell(1,:) = cellstr(headers);

for k = 1:numFrequencies
    summaryCell{k + 1, 1} = f(k);
    summaryCell{k + 1, 2} = countNonNan(metricData.mapGain(k,:));

    summaryCell(k + 1, 3:4) = meanSdFromRow(metricData.mapGain(k,:));
    summaryCell(k + 1, 5:6) = circularMeanSdFromRow(metricData.mapPhase(k,:));
    summaryCell(k + 1, 7:8) = meanSdFromRow(metricData.co2Gain(k,:));
    summaryCell(k + 1, 9:10) = circularMeanSdFromRow(metricData.co2Phase(k,:));

    if modelName == "MISO"
        summaryCell(k + 1, 11:12) = meanSdFromRow(metricData.multipleCoh(k,:));
        summaryCell(k + 1, 13:14) = meanSdFromRow(metricData.mapCoh(k,:));
        summaryCell(k + 1, 15:16) = meanSdFromRow(metricData.co2Coh(k,:));
    else
        summaryCell(k + 1, 11:12) = meanSdFromRow(metricData.mapCoh(k,:));
        summaryCell(k + 1, 13:14) = meanSdFromRow(metricData.co2Coh(k,:));
    end
end

end


function headers = fullFrequencyHeaders(modelName)

baseHeaders = [
    "Frequency_Hz"
    "N"
    "MAP_Gain_MeanAcrossSubjects"
    "MAP_Gain_SDAcrossSubjects"
    "MAP_Phase_CircularMeanAcrossSubjects"
    "MAP_Phase_CircularSDAcrossSubjects"
    "CO2_Gain_MeanAcrossSubjects"
    "CO2_Gain_SDAcrossSubjects"
    "CO2_Phase_CircularMeanAcrossSubjects"
    "CO2_Phase_CircularSDAcrossSubjects"
];

if modelName == "MISO"
    coherenceHeaders = [
        "Multiple_Coh_MeanAcrossSubjects"
        "Multiple_Coh_SDAcrossSubjects"
        "MAP|CO2_Coh_MeanAcrossSubjects"
        "MAP|CO2_Coh_SDAcrossSubjects"
        "CO2|MAP_Coh_MeanAcrossSubjects"
        "CO2|MAP_Coh_SDAcrossSubjects"
    ];
else
    coherenceHeaders = [
        "MAP_Coh_MeanAcrossSubjects"
        "MAP_Coh_SDAcrossSubjects"
        "CO2_Coh_MeanAcrossSubjects"
        "CO2_Coh_SDAcrossSubjects"
    ];
end

headers = [baseHeaders; coherenceHeaders]';

end


function n = countNonNan(values)

n = sum(~isnan(values));

end


function cells = meanSdFromRow(values)

values = values(~isnan(values));

if isempty(values)
    cells = {"-", "-"};
    return
end

metricMean = mean(values, 'omitnan');

if numel(values) < 2
    metricSD = "-";
else
    metricSD = std(values, 'omitnan');
end

cells = {metricMean, metricSD};

end


function cells = circularMeanSdFromRow(values)

values = values(~isnan(values));

if isempty(values)
    cells = {"-", "-"};
    return
end

metricMean = circularMeanPhase(values);

if numel(values) < 2
    metricSD = "-";
else
    metricSD = circularStdPhase(values);
end

cells = {metricMean, metricSD};

end


function value = valueOrDash(metricValue)

if isnumeric(metricValue) && isnan(metricValue)
    value = "-";
else
    value = metricValue;
end

end


function saveBatchSummaryToExcel( ...
    filename, statusTable, ...
    misoBandTable, sisoBandTable, comparisonTable, groupSummaryCell, ...
    fullFrequencyTables, fullFrequencyStatusTable, runSISO)

if exist(filename, "file")
    delete(filename);
end

writetable(statusTable, filename, "Sheet", "Run_Status");

if ~isempty(misoBandTable)
    writetable(misoBandTable, filename, "Sheet", "MISO_Bands_AllSubjects");
end

if runSISO && ~isempty(sisoBandTable)
    writetable(sisoBandTable, filename, "Sheet", "SISO_Bands_AllSubjects");
end

if ~isempty(comparisonTable)
    writeComparisonTableToExcel(comparisonTable, filename, "Compare_AllSubjects");
end

if ~isempty(groupSummaryCell)
    writecell(groupSummaryCell, filename, ...
        "Sheet", "Group_Summary", ...
        "Range", "A1");
end

writeFullFrequencySheetsToExcel( ...
    filename, fullFrequencyTables, fullFrequencyStatusTable);

writeMetricDefinitionsToExcel(filename, "Metric_Definitions");

end


function writeFullFrequencySheetsToExcel( ...
    filename, fullFrequencyTables, fullFrequencyStatusTable)

if ~isempty(fullFrequencyStatusTable)
    writetable(fullFrequencyStatusTable, filename, ...
        "Sheet", "FullFrequency_Status");
end

sheetNames = string(fieldnames(fullFrequencyTables));

for k = 1:numel(sheetNames)
    writecell(fullFrequencyTables.(sheetNames(k)), filename, ...
        "Sheet", sheetNames(k), ...
        "Range", "A1");
end

end


function writeComparisonTableToExcel(comparisonTable, filename, sheetName)

misoRows = comparisonTable(comparisonTable.Model == "MISO", :);
sisoRows = comparisonTable(comparisonTable.Model == "SISO", :);

comparisonCell = [
    displayComparisonHeaders("MISO");
    table2cell(misoRows)
];

if ~isempty(sisoRows)
    blankRow = cell(1, width(comparisonTable));
    comparisonCell = [
        comparisonCell;
        blankRow;
        displayComparisonHeaders("SISO");
        table2cell(sisoRows)
    ];
end

writecell(comparisonCell, filename, ...
    "Sheet", sheetName, ...
    "Range", "A1");

end


function headers = displayComparisonHeaders(modelName)

headers = comparisonVariableNames();

if modelName == "MISO"
    headers{12} = 'MAP|CO2_Coh_Mean';
    headers{13} = 'CO2|MAP_Coh_Mean';
    headers{15} = 'Percent_Passed_MAP|CO2_Coh';
    headers{16} = 'Percent_Passed_CO2|MAP_Coh';
end

end


function writeMetricDefinitionsToExcel(filename, sheetName)

metricDefinitions = table( ...
    [
        "MAP_Gain_Mean"
        "CO2_Gain_Mean"
        "Multiple_Coh_Mean"
        "MAP|CO2_Coh_Mean"
        "CO2|MAP_Coh_Mean"
        "MAP_Coh_Mean"
        "CO2_Coh_Mean"
        "Frequency_Hz"
        "MAP_Phase_CircularMeanAcrossSubjects"
        "MAP_Phase_CircularSDAcrossSubjects"
        "CO2_Phase_CircularMeanAcrossSubjects"
        "CO2_Phase_CircularSDAcrossSubjects"
        "IncludedInFullFrequency"
        "FrequencyVectorMismatch"
        "MCI_MeanAcrossSubjects"
        "MCI_SDAcrossSubjects"
        "MCI_N"
        "NC_MeanAcrossSubjects"
        "NC_SDAcrossSubjects"
        "NC_N"
    ], ...
    [
        "Average MAP to CBV transfer-function gain within the frequency band for each subject."
        "Average CO2 to CBV transfer-function gain within the frequency band for each subject."
        "For MISO, average multiple coherence within the band: CBV variability explained by MAP and CO2 together."
        "For MISO, MAP partial coherence given CO2."
        "For MISO, CO2 partial coherence given MAP."
        "For SISO, standard pairwise MAP coherence with CBV as the output."
        "For SISO, standard pairwise CO2 coherence with CBV as the output."
        "Frequency bin used for the full-frequency group summary sheets."
        "Circular mean across subjects for MAP to CBV phase at each frequency bin."
        "Circular standard deviation across subjects for MAP to CBV phase at each frequency bin."
        "Circular mean across subjects for CO2 to CBV phase at each frequency bin."
        "Circular standard deviation across subjects for CO2 to CBV phase at each frequency bin."
        "Shows whether a subject was included in the full-frequency group average."
        "Subject was not included in the full-frequency average because its frequency vector did not match the first included subject in that group/model."
        "Mean across subject-level band averages for the MCI group."
        "Standard deviation across subject-level band averages for the MCI group. Uses '-' when fewer than two subjects contribute."
        "Number of MCI subjects contributing to that group summary value."
        "Mean across subject-level band averages for the NC group."
        "Standard deviation across subject-level band averages for the NC group. Uses '-' when fewer than two subjects contribute."
        "Number of NC subjects contributing to that group summary value."
    ], ...
    'VariableNames', {'Metric', 'Meaning'});

writetable(metricDefinitions, filename, ...
    "Sheet", sheetName, ...
    "Range", "A1");

end


function valueString = statusValueToString(value)

if islogical(value)
    valueString = string(value);
elseif isnumeric(value) && isnan(value)
    valueString = "";
else
    valueString = string(value);
end

end
