function subjectList = findIEEMSubjects(dataFolder, groupsToRun)
% findIEEMSubjects Find subject Excel files in the selected group folders.
%
% Finds IEEM subject Excel files from folders like:
%   dataFolder/MCI/528_baseline.xlsx
%   dataFolder/NC/101_baseline.xlsx
%   dataFolder/LC/1054_baseline.xlsx

groupsToRun = upper(string(groupsToRun));
groupsToRun = groupsToRun(:);

if isempty(groupsToRun) || any(strlength(groupsToRun) == 0)
    error("groupsToRun must contain at least one group folder name.");
end

groupFileLists = cell(numel(groupsToRun), 1);
maximumNumSubjects = 0;

for g = 1:numel(groupsToRun)
    groupName = groupsToRun(g);
    groupFolder = fullfile(dataFolder, groupName);

    if ~exist(groupFolder, "dir")
        warning("Group folder does not exist: %s", groupFolder);
        continue
    end

    groupFileLists{g} = dir(fullfile(groupFolder, "*.xlsx"));
    maximumNumSubjects = maximumNumSubjects + numel(groupFileLists{g});
end

subjectIDs = strings(maximumNumSubjects, 1);
subjectGroups = strings(maximumNumSubjects, 1);
subjectSessions = strings(maximumNumSubjects, 1);
sourceFiles = strings(maximumNumSubjects, 1);
numSubjects = 0;

for g = 1:numel(groupsToRun)
    groupName = groupsToRun(g);
    files = groupFileLists{g};

    for k = 1:numel(files)
        fileName = string(files(k).name);

        if startsWith(fileName, "~$")
            continue
        end

        tokens = regexp(fileName, '^(\d+)_(.+)\.xlsx$', 'tokens', 'once');

        if isempty(tokens)
            warning("Skipping file with unexpected name: %s", fileName);
            continue
        end

        numSubjects = numSubjects + 1;
        subjectIDs(numSubjects) = string(tokens{1});
        subjectGroups(numSubjects) = groupName;
        subjectSessions(numSubjects) = string(tokens{2});
        sourceFiles(numSubjects) = ...
            string(fullfile(files(k).folder, files(k).name));
    end
end

if numSubjects == 0
    error("No subject Excel files were found.");
end

subjectList = table( ...
    subjectIDs(1:numSubjects), ...
    subjectGroups(1:numSubjects), ...
    subjectSessions(1:numSubjects), ...
    sourceFiles(1:numSubjects), ...
    'VariableNames', {'SubjectID', 'Group', 'Session', 'SourceFile'});

subjectList = sortrows(subjectList, {'Group', 'SubjectID', 'Session'});

end
