function misoResults = runMISOTFA( ...
    spectra, phaseSettings, solverSettings)
% runMISOTFA Calculate two-input, one-output transfer-function results.

    if nargin < 3
        solverSettings = defaultMisoSolverSettings();
    else
        solverSettings = validateMisoSolverSettings(solverSettings);
    end

    f = spectra.f;
    mapPower = spectra.map.power;
    co2Power = spectra.co2.power;
    cbvPower = spectra.cbv.power;
    mapCo2 = spectra.cross.mapCo2;
    co2Map = spectra.cross.co2Map;
    mapCbv = spectra.cross.mapCbv;
    co2Cbv = spectra.cross.co2Cbv;

    %% Solve MISO System at Each Frequency

    H_mapcbv = complex(NaN(size(f)));
    H_co2cbv = complex(NaN(size(f)));
    H_mapcbvUnregularized = complex(NaN(size(f)));
    H_co2cbvUnregularized = complex(NaN(size(f)));
    H_mapcbvRidge = complex(NaN(size(f)));
    H_co2cbvRidge = complex(NaN(size(f)));
    multipleCoherence = NaN(size(f));
    conditionNumber = NaN(size(f));
    normalizedConditionNumber = NaN(size(f));
    normalizedDeterminant = NaN(size(f));
    minimumNormalizedEigenvalue = NaN(size(f));
    reciprocalConditionEstimate = NaN(size(f));
    isFiniteSystem = false(size(f));
    isPoorlyConditioned = false(size(f));

    for frequencyIndex = 1:length(f)
        S_xx = [mapPower(frequencyIndex), mapCo2(frequencyIndex);
                co2Map(frequencyIndex), co2Power(frequencyIndex)];

        S_xy = [mapCbv(frequencyIndex);
                co2Cbv(frequencyIndex)];

        solution = solveMisoSpectralSystem( ...
            S_xx, S_xy, solverSettings);
        H = solution.selectedCoefficients;

        H_mapcbv(frequencyIndex) = H(1);
        H_co2cbv(frequencyIndex) = H(2);
        H_mapcbvUnregularized(frequencyIndex) = ...
            solution.unregularizedCoefficients(1);
        H_co2cbvUnregularized(frequencyIndex) = ...
            solution.unregularizedCoefficients(2);
        H_mapcbvRidge(frequencyIndex) = ...
            solution.ridgeCoefficients(1);
        H_co2cbvRidge(frequencyIndex) = ...
            solution.ridgeCoefficients(2);

        conditionNumber(frequencyIndex) = ...
            solution.rawConditionNumber;
        normalizedConditionNumber(frequencyIndex) = ...
            solution.normalizedConditionNumber;
        normalizedDeterminant(frequencyIndex) = ...
            solution.normalizedDeterminant;
        minimumNormalizedEigenvalue(frequencyIndex) = ...
            solution.minimumNormalizedEigenvalue;
        reciprocalConditionEstimate(frequencyIndex) = ...
            solution.reciprocalConditionEstimate;
        isFiniteSystem(frequencyIndex) = ...
            solution.isFiniteSystem;
        isPoorlyConditioned(frequencyIndex) = ...
            solution.isPoorlyConditioned;

        cbvPowerAtFrequency = real(cbvPower(frequencyIndex));
        if cbvPowerAtFrequency > 0 && all(isfinite(H))
            multipleCoherence(frequencyIndex) = ...
                real(S_xy' * H) / cbvPowerAtFrequency;
        end
    end

    unexplainedFraction = 1 - multipleCoherence;
    residualPower = real(cbvPower) .* unexplainedFraction;

    coherence = calculateMisoCoherenceDiagnostics( ...
        spectra, multipleCoherence);
    partialCohMapCbvGivenCo2 = coherence.partialMapCoherence;
    partialCohCo2CbvGivenMap = coherence.partialCo2Coherence;
    inputInputCoherence = coherence.inputCoherence;

    %% Phase

    mapPhaseWrapped = angle(H_mapcbv);
    mapPhaseUnwrapped = unwrapTfaPhase( ...
        mapPhaseWrapped, f, partialCohMapCbvGivenCo2, phaseSettings);

    co2PhaseWrapped = angle(H_co2cbv);
    co2PhaseUnwrapped = unwrapTfaPhase( ...
        co2PhaseWrapped, f, partialCohCo2CbvGivenMap, phaseSettings);

    inputPhaseWrapped = angle(mapCo2);
    inputPhaseUnwrapped = unwrapTfaPhase( ...
        inputPhaseWrapped, f, inputInputCoherence, phaseSettings);

    %% Store Results

    misoResults.f = f;

    misoResults.map.power = mapPower;
    misoResults.map.transferFunction = H_mapcbv;
    misoResults.map.transferFunctionUnregularized = ...
        H_mapcbvUnregularized;
    misoResults.map.transferFunctionRidge = H_mapcbvRidge;
    misoResults.map.gain = abs(H_mapcbv);
    misoResults.map.phase.wrapped = mapPhaseWrapped;
    misoResults.map.phase.unwrapped = mapPhaseUnwrapped;
    misoResults.map.coherence.partial = partialCohMapCbvGivenCo2;

    misoResults.co2.power = co2Power;
    misoResults.co2.transferFunction = H_co2cbv;
    misoResults.co2.transferFunctionUnregularized = ...
        H_co2cbvUnregularized;
    misoResults.co2.transferFunctionRidge = H_co2cbvRidge;
    misoResults.co2.gain = abs(H_co2cbv);
    misoResults.co2.phase.wrapped = co2PhaseWrapped;
    misoResults.co2.phase.unwrapped = co2PhaseUnwrapped;
    misoResults.co2.coherence.partial = partialCohCo2CbvGivenMap;

    misoResults.cbv.power = cbvPower;

    misoResults.system.multipleCoherence = multipleCoherence;
    effectiveAverages = spectra.welchInfo.effectiveAverages;
    misoResults.system.nullMultipleCoherence = min( ...
        1, 2/effectiveAverages);
    misoResults.system.multipleCoherenceAboveNull = ...
        multipleCoherence - misoResults.system.nullMultipleCoherence;
    misoResults.system.unexplainedFraction = unexplainedFraction;
    misoResults.system.residualPower = residualPower;

    misoResults.inputRelationship.coherence = inputInputCoherence;
    misoResults.inputRelationship.phase.wrapped = inputPhaseWrapped;
    misoResults.inputRelationship.phase.unwrapped = inputPhaseUnwrapped;

    misoResults.diagnostics.conditionNumber = conditionNumber;
    misoResults.diagnostics.normalizedConditionNumber = ...
        normalizedConditionNumber;
    misoResults.diagnostics.normalizedDeterminant = ...
        normalizedDeterminant;
    misoResults.diagnostics.minimumNormalizedEigenvalue = ...
        minimumNormalizedEigenvalue;
    misoResults.diagnostics.reciprocalConditionEstimate = ...
        reciprocalConditionEstimate;
    misoResults.diagnostics.isFiniteSystem = isFiniteSystem;
    misoResults.diagnostics.isPoorlyConditioned = ...
        isPoorlyConditioned;
    misoResults.diagnostics.mapPairwiseCoherence = ...
        coherence.mapPairwiseCoherence;
    misoResults.diagnostics.co2PairwiseCoherence = ...
        coherence.co2PairwiseCoherence;
    misoResults.diagnostics.multipleMinusMapCoherence = ...
        coherence.multipleMinusMapCoherence;
    misoResults.diagnostics.multipleMinusPartialMapCoherence = ...
        coherence.multipleMinusPartialMapCoherence;

    misoResults.regularization.enabled = ...
        solverSettings.regularization.enabled;
    misoResults.regularization.lambda = ...
        solverSettings.regularization.lambda;
    if solverSettings.regularization.enabled
        misoResults.regularization.selectedMethod = ...
            "Standardized ridge";
    else
        misoResults.regularization.selectedMethod = ...
            "Unregularized";
    end
    misoResults.regularization.poorConditionThreshold = ...
        solverSettings.poorConditionThreshold;

    misoResults.phaseUnwrapMethod = string(phaseSettings.unwrapMethod);
    misoResults.welchInfo = spectra.welchInfo;

end
