function subjectList = findIEEMSubjects(dataFolder, groupsToRun)
% findIEEMSubjects Find subject Excel files in the selected group folders.
%
% Expected file organization:
%   dataFolder/MCI/528_baseline.xlsx
%   dataFolder/NC/101_baseline.xlsx
%   dataFolder/LC/1054_baseline.xlsx

    groupsToRun = upper(string(groupsToRun));
    groupsToRun = unique(groupsToRun(:), "stable");

    if isempty(groupsToRun) || any(strlength(groupsToRun) == 0)
        error("groupsToRun must contain at least one group folder name.");
    end

    %% Find Excel Files in Each Group Folder

    groupFileLists = cell(numel(groupsToRun), 1);
    maximumPossibleSubjects = 0;

    for groupIndex = 1:numel(groupsToRun)
        groupName = groupsToRun(groupIndex);
        groupFolder = fullfile(dataFolder, groupName);

        if ~exist(groupFolder, "dir")
            warning("Group folder does not exist: %s", groupFolder);
            continue
        end

        groupFileLists{groupIndex} = ...
            dir(fullfile(groupFolder, "*.xlsx"));
        maximumPossibleSubjects = maximumPossibleSubjects + ...
            numel(groupFileLists{groupIndex});
    end

    %% Read Subject Information from the Filenames

    subjectIds = strings(maximumPossibleSubjects, 1);
    subjectGroups = strings(maximumPossibleSubjects, 1);
    sourceFiles = strings(maximumPossibleSubjects, 1);
    groupOrder = NaN(maximumPossibleSubjects, 1);
    numericSubjectIds = NaN(maximumPossibleSubjects, 1);
    numSubjects = 0;

    for groupIndex = 1:numel(groupsToRun)
        groupName = groupsToRun(groupIndex);
        files = groupFileLists{groupIndex};

        for fileIndex = 1:numel(files)
            fileName = string(files(fileIndex).name);

            if startsWith(fileName, "~$")
                continue
            end

            tokens = regexp( ...
                fileName, '^(\d+)_(.+)\.xlsx$', 'tokens', 'once');

            if isempty(tokens)
                warning( ...
                    "Skipping file with unexpected name: %s", fileName);
                continue
            end

            numSubjects = numSubjects + 1;
            subjectIds(numSubjects) = string(tokens{1});
            subjectGroups(numSubjects) = groupName;
            sourceFiles(numSubjects) = string(fullfile( ...
                files(fileIndex).folder, files(fileIndex).name));
            groupOrder(numSubjects) = groupIndex;
            numericSubjectIds(numSubjects) = str2double(tokens{1});
        end
    end

    if numSubjects == 0
        error("No subject Excel files were found.");
    end

    %% Create the Subject List

    subjectList = table( ...
        subjectIds(1:numSubjects), ...
        subjectGroups(1:numSubjects), ...
        sourceFiles(1:numSubjects), ...
        groupOrder(1:numSubjects), ...
        numericSubjectIds(1:numSubjects), ...
        'VariableNames', ...
        {'SubjectID', 'Group', 'SourceFile', 'GroupOrder', 'NumericSubjectID'});

    subjectKeys = subjectList.Group + "_" + subjectList.SubjectID;
    if numel(unique(subjectKeys)) ~= height(subjectList)
        error( ...
            'TFA:DuplicateSubjectFiles', ...
            ['Only one baseline file is allowed for each group and ' ...
             'subject ID.']);
    end

    subjectList = sortrows( ...
        subjectList, {'GroupOrder', 'NumericSubjectID', 'SourceFile'});
    subjectList.GroupOrder = [];
    subjectList.NumericSubjectID = [];

end
