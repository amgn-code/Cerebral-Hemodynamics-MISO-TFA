function groupResults = createGroupResults( ...
    subjectResults, groupNames, runMISO, runSISO, phaseSettings)
% createGroupResults Organize subject arrays and group summaries.

    groupResults = struct();
    groupNames = upper(string(groupNames));
    groupNames = unique(groupNames(:), "stable");

    for groupIndex = 1:numel(groupNames)
        groupName = groupNames(groupIndex);
        groupField = char(groupName);

        if runMISO
            misoResults = createGroupModelResults( ...
                subjectResults, groupName, "miso", phaseSettings);

            if ~isempty(misoResults)
                groupResults.(groupField).miso = misoResults;
            end
        end

        if runSISO
            sisoResults = createGroupModelResults( ...
                subjectResults, groupName, "siso", phaseSettings);

            if ~isempty(sisoResults)
                groupResults.(groupField).siso = sisoResults;
            end
        end
    end

end
