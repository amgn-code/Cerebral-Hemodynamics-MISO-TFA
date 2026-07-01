function subjectList = findIEEMSubjects( ...
    dataFolder, groupsToRun, batchRunMode, singleSubjectID, ~)
% findIEEMSubjects
%
% Finds IEEM subject Excel files from folders like:
%   dataFolder/MCI/528_baseline.xlsx
%   dataFolder/NC/101_baseline.xlsx

if nargin < 2 || isempty(groupsToRun)
    groupsToRun = ["MCI"; "NC"];
end

if nargin < 3 || isempty(batchRunMode)
    batchRunMode = "all";
end

if nargin < 4
    singleSubjectID = "";
end

groupsToRun = upper(string(groupsToRun(:)));
batchRunMode = lower(string(batchRunMode));
singleSubjectID = string(singleSubjectID);

validGroups = ["MCI"; "NC"];
validRunModes = ["single"; "firstn"; "all"];

if ~all(ismember(groupsToRun, validGroups))
    error('groupsToRun must contain "MCI", "NC", or both.');
end

if ~any(batchRunMode == validRunModes)
    error('batchRunMode must be "single", "firstN", or "all".');
end

subjectList = table( ...
    strings(0,1), ...
    strings(0,1), ...
    strings(0,1), ...
    strings(0,1), ...
    'VariableNames', {'SubjectID', 'Group', 'Session', 'SourceFile'});

for g = 1:numel(groupsToRun)

    groupName = groupsToRun(g);
    groupFolder = fullfile(dataFolder, groupName);

    if ~exist(groupFolder, "dir")
        warning("Group folder does not exist: %s", groupFolder);
        continue
    end

    files = dir(fullfile(groupFolder, "*.xlsx"));

    for k = 1:numel(files)

        fileName = string(files(k).name);

        if startsWith(fileName, "~$")
            continue
        end

        [subjectID, sessionLabel] = parseIEEMFileName(fileName);

        if strlength(subjectID) == 0
            warning("Skipping file with unexpected name: %s", fileName);
            continue
        end

        sourceFile = fullfile(files(k).folder, files(k).name);

        subjectRow = table( ...
            subjectID, ...
            groupName, ...
            sessionLabel, ...
            string(sourceFile), ...
            'VariableNames', {'SubjectID', 'Group', 'Session', 'SourceFile'});

        subjectList = [subjectList; subjectRow];

    end
end

if isempty(subjectList)
    error("No subject Excel files were found.");
end

subjectList = sortrows(subjectList, {'Group', 'SubjectID', 'Session'});

if batchRunMode == "single"

    if strlength(singleSubjectID) == 0
        error('singleSubjectID is required when batchRunMode is "single".');
    end

    subjectList = subjectList(subjectList.SubjectID == singleSubjectID, :);

    if isempty(subjectList)
        error("Subject %s was not found in the selected groups.", singleSubjectID);
    end

end

end


function [subjectID, sessionLabel] = parseIEEMFileName(fileName)

tokens = regexp(fileName, '^(\d+)_(.+)\.xlsx$', 'tokens', 'once');

if isempty(tokens)
    subjectID = "";
    sessionLabel = "";
    return
end

subjectID = string(tokens{1});
sessionLabel = string(tokens{2});

end
