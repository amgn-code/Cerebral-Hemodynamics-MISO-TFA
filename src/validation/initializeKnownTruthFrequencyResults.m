function results = initializeKnownTruthFrequencyResults( ...
    frequencyHz, numObservations)
% initializeKnownTruthFrequencyResults Preallocate frequency result arrays.

    numFrequencies = numel(frequencyHz);
    realArray = NaN(numFrequencies, numObservations);
    complexArray = complex(realArray, realArray);

    results.frequencyHz = frequencyHz(:);
    results.observationId = NaN(1, numObservations);
    results.inputCoherence = realArray;
    results.normalizedConditionNumber = realArray;
    results.normalizedDeterminant = realArray;

    results.map.truth = complexArray;
    results.map.sisoEstimate = complexArray;
    results.map.misoEstimate = complexArray;
    results.map.sisoComplexError = realArray;
    results.map.misoComplexError = realArray;
    results.map.sisoGainError = realArray;
    results.map.misoGainError = realArray;
    results.map.sisoPhaseErrorRadians = realArray;
    results.map.misoPhaseErrorRadians = realArray;
    results.map.complexAdvantage = realArray;
    results.map.gainAdvantage = realArray;
    results.map.phaseAdvantage = realArray;

    results.co2.truth = complexArray;
    results.co2.sisoEstimate = complexArray;
    results.co2.misoEstimate = complexArray;
    results.co2.sisoComplexError = realArray;
    results.co2.misoComplexError = realArray;
    results.co2.sisoGainError = realArray;
    results.co2.misoGainError = realArray;
    results.co2.sisoPhaseErrorRadians = realArray;
    results.co2.misoPhaseErrorRadians = realArray;
    results.co2.complexAdvantage = realArray;
    results.co2.gainAdvantage = realArray;
    results.co2.phaseAdvantage = realArray;

end
