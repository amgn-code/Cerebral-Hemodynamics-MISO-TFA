function conditions = createSimulationConditions(settings)
% createSimulationConditions Make explicit reference-based or factorial cases.
%
% Every row contains all generating and observation settings. A zero factor
% level is retained. The baseline is included once, with duplicates removed.

    baseline = settings.baseline;
    names = string(fieldnames(baseline)).';
    baseValues = cellfun(@(name) baseline.(name), cellstr(names));
    varied = string(settings.vary(:)).';
    rows = baseValues;
    switch settings.design
        case "oneAtATime"
            for factor = varied
                column = find(names == factor, 1);
                levels = settings.ranges.(factor);
                block = repmat(baseValues, numel(levels), 1);
                block(:, column) = levels(:);
                rows = [rows; block]; %#ok<AGROW>
            end
        case "factorial"
            rows = baseValues;
            for factor = varied
                column = find(names == factor, 1);
                levels = unique([baseline.(factor), settings.ranges.(factor)], "stable");
                previous = rows;
                rows = repmat(previous, numel(levels), 1);
                rows(:, column) = repelem(levels(:), size(previous, 1));
            end
        otherwise
            error("TFA:Design", 'Use "oneAtATime" or "factorial".');
    end
    rows = unique(rows, "rows", "stable");
    conditions = array2table(rows, VariableNames=names);
    conditions.conditionID = (1:height(conditions)).';
    conditions.isReference = all(rows == baseValues, 2);
    labels = strings(height(conditions), 1);
    for index = 1:height(conditions)
        changed = find(rows(index, :) ~= baseValues);
        if isempty(changed)
            labels(index) = "Reference";
        else
            terms = strings(numel(changed), 1);
            for term = 1:numel(changed)
                column = changed(term);
                terms(term) = names(column) + "=" + string(rows(index, column));
            end
            labels(index) = strjoin(terms, "; ");
        end
    end
    conditions.label = labels;
end
