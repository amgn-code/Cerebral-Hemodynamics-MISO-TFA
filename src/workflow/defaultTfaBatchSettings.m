function settings = defaultTfaBatchSettings(dataFolder, groupsToRun)
% defaultTfaBatchSettings Return batch discovery and execution defaults.

    if nargin < 1
        dataFolder = "";
    end
    if nargin < 2
        groupsToRun = ["NC"; "MCI"];
    end

    settings.dataFolder = string(dataFolder);
    settings.groupsToRun = upper(string(groupsToRun(:)));
    settings.targetSuccessfulSubjectsPerGroup = Inf;
    settings.previewOnly = false;
    settings.numSubjectFiguresPerGroup = 1;

end
