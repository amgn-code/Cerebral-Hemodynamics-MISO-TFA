function values = getSimulationFrequencyError( ...
    frequency, pathway, modelName, errorType, errorFloor)
% getSimulationFrequencyError Return one stored or reconstructed error.

    pathway = lower(string(pathway));
    modelName = lower(string(modelName));
    errorType = lower(string(errorType));

    storedField = getStoredFieldName(modelName, errorType);
    pathwayResults = frequency.(pathway);
    if isfield(pathwayResults, storedField)
        values = pathwayResults.(storedField);
        return
    end

    truth = pathwayResults.truth;
    estimate = pathwayResults.(modelName + "Estimate");

    % Reconstruct old result files with the same definitions used by the
    % current truth-error calculation. In particular, the complex-error
    % denominator must depend on truth, not on which estimate is finite.
    errors = calculateFrequencyTruthErrors( ...
        estimate, truth, errorFloor);
    switch errorType
        case "complex"
            values = errors.complex;
        case "gain"
            values = errors.gain;
        case "phase"
            values = errors.phase;
        otherwise
            error( ...
                "TFA:UnknownFrequencyErrorType", ...
                "errorType must be complex, gain, or phase.");
    end

end

function fieldName = getStoredFieldName(modelName, errorType)
% getStoredFieldName Map readable inputs to the saved result schema.

    switch errorType
        case "complex"
            suffix = "ComplexError";
        case "gain"
            suffix = "GainError";
        case "phase"
            suffix = "PhaseErrorRadians";
        otherwise
            suffix = "";
    end
    fieldName = modelName + suffix;

end
