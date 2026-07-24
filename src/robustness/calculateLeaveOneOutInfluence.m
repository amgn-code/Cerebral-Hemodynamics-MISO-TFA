function influenceTable = calculateLeaveOneOutInfluence( ...
    modelComparisonValues)
% calculateLeaveOneOutInfluence Quantify each subject's effect on the mean.

    if isempty(modelComparisonValues)
        influenceTable = table();
        return
    end

    familyVariables = ["Group"; "Pathway"; "Metric"; "Band"];
    families = unique( ...
        modelComparisonValues(:, familyVariables), "rows", "stable");
    influenceTable = table();

    for familyIndex = 1:height(families)
        rowMask = true(height(modelComparisonValues), 1);
        for variableIndex = 1:numel(familyVariables)
            variableName = familyVariables(variableIndex);
            rowMask = rowMask & ...
                modelComparisonValues.(variableName) == ...
                families.(variableName)(familyIndex);
        end

        values = modelComparisonValues(rowMask, :);
        completeMask = isfinite(values.MISOminusSISO);
        values = values(completeMask, :);
        if height(values) < 2
            continue
        end

        fullMean = mean(values.MISOminusSISO);
        leaveOneOutMean = NaN(height(values), 1);
        for subjectIndex = 1:height(values)
            keptMask = true(height(values), 1);
            keptMask(subjectIndex) = false;
            leaveOneOutMean(subjectIndex) = ...
                mean(values.MISOminusSISO(keptMask));
        end

        influence = fullMean - leaveOneOutMean;
        currentRows = values(:, [ ...
            "SubjectID", "Group", "Pathway", "Metric", "Band"]);
        currentRows.FullMeanDifference = repmat( ...
            fullMean, height(values), 1);
        currentRows.LeaveOneOutMeanDifference = leaveOneOutMean;
        currentRows.Influence = influence;
        currentRows.AbsoluteInfluence = abs(influence);
        [~, order] = sort(currentRows.AbsoluteInfluence, "descend");
        rank = NaN(height(values), 1);
        rank(order) = (1:height(values))';
        currentRows.InfluenceRank = rank;
        influenceTable = [influenceTable; currentRows];
    end

end
