function groupResults = createGroupResults( ...
    subjectResults, groupNames, runMiso, runSiso, phaseSettings)
% createGroupResults Organize subject arrays and group summaries.

    groupResults = struct();
    groupNames = upper(string(groupNames));
    groupNames = groupNames(:);

    for groupIndex = 1:numel(groupNames)
        groupName = groupNames(groupIndex);
        groupField = char(groupName);

        if runMiso
            misoResults = createGroupModelResults( ...
                subjectResults, groupName, "miso", phaseSettings);

            if ~isempty(misoResults)
                groupResults.(groupField).miso = misoResults;
            end
        end

        if runSiso
            sisoResults = createGroupModelResults( ...
                subjectResults, groupName, "siso", phaseSettings);

            if ~isempty(sisoResults)
                groupResults.(groupField).siso = sisoResults;
            end
        end

        if isfield(groupResults, groupField) && ...
                isempty(fieldnames(groupResults.(groupField)))
            groupResults = rmfield(groupResults, groupField);
        end
    end

end
