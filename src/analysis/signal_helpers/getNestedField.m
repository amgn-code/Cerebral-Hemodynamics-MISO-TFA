function [value, fieldExists] = getNestedField(data, fieldPath)
% getNestedField Read a value using a dot-separated structure field path.

    fieldNames = split(string(fieldPath), ".");
    value = data;
    fieldExists = true;

    for k = 1:numel(fieldNames)
        fieldName = char(fieldNames(k));

        if ~isstruct(value) || ~isfield(value, fieldName)
            value = [];
            fieldExists = false;
            return
        end

        value = value.(fieldName);
    end

end
