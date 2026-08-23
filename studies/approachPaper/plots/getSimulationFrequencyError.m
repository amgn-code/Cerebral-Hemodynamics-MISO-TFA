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
    complete = isfinite(truth) & isfinite(estimate);

    values = NaN(size(truth));
    switch errorType
        case "complex"
            numerator = abs(estimate - truth).^2;
            denominator = max(abs(truth).^2, errorFloor);
            values(complete) = ...
                numerator(complete)./denominator(complete);
        case "gain"
            gainError = abs(abs(estimate) - abs(truth));
            values(complete) = gainError(complete);
        case "phase"
            phaseDefined = complete & ...
                abs(truth) > sqrt(errorFloor);
            phaseError = abs(angle(estimate.*conj(truth)));
            values(phaseDefined) = phaseError(phaseDefined);
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
