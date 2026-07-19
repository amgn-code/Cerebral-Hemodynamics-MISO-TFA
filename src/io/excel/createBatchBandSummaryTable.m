function bandSummaryTable = createBatchBandSummaryTable(subjectResults)
% createBatchBandSummaryTable Combine subject MISO/SISO band summaries.

    subjectTables = cell(numel(subjectResults), 1);
    numSubjectTables = 0;

    for k = 1:numel(subjectResults)
        if isempty(subjectResults{k}) || ...
                ~subjectResults{k}.runStatus.analysisSucceeded
            continue
        end

        subjectResult = subjectResults{k};
        comparisonTable = createModelComparisonTable( ...
            subjectResult.tfaResults, subjectResult.sisoResults);
        numRows = height(comparisonTable);

        comparisonTable = addvars( ...
            comparisonTable, ...
            repmat(string(subjectResult.subjectInfo.subjectID), numRows, 1), ...
            repmat(string(subjectResult.subjectInfo.group), numRows, 1), ...
            repmat(string(subjectResult.subjectInfo.session), numRows, 1), ...
            'Before', 'Band', ...
            'NewVariableNames', {'SubjectID', 'Group', 'Session'});

        numSubjectTables = numSubjectTables + 1;
        subjectTables{numSubjectTables} = comparisonTable;
    end

    if numSubjectTables == 0
        bandSummaryTable = table();
    else
        bandSummaryTable = vertcat(subjectTables{1:numSubjectTables});
    end

end
