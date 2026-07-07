function phaseSettings = normalizePhaseSettings(phaseSettingsInput)
% normalizePhaseSettings Merge user phase settings with defaults.

defaults = defaultPhaseSettings();

if nargin < 1 || isempty(phaseSettingsInput)
    phaseSettings = defaults;
    return
end

if isstruct(phaseSettingsInput)
    phaseSettings = mergeStructDefaults(phaseSettingsInput, defaults);
else
    phaseSettings = defaults;
    phaseSettings.unwrapMethod = string(phaseSettingsInput);
end

if isfield(phaseSettings, 'phaseUnwrapMethod')
    phaseSettings.unwrapMethod = string(phaseSettings.phaseUnwrapMethod);
end

if isfield(phaseSettings, 'unwrapMethod')
    phaseSettings.unwrapMethod = string(phaseSettings.unwrapMethod);
end

end


function merged = mergeStructDefaults(userStruct, defaultStruct)

merged = defaultStruct;
userFields = fieldnames(userStruct);

for k = 1:numel(userFields)
    fieldName = userFields{k};

    if isfield(defaultStruct, fieldName) && ...
            isstruct(defaultStruct.(fieldName)) && ...
            isstruct(userStruct.(fieldName))
        merged.(fieldName) = mergeStructDefaults( ...
            userStruct.(fieldName), defaultStruct.(fieldName));
    else
        merged.(fieldName) = userStruct.(fieldName);
    end
end

end
