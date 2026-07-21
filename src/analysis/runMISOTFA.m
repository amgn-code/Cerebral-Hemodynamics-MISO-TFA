function misoResults = runMISOTFA(spectra, phaseSettings)
% runMISOTFA Calculate two-input, one-output transfer-function results.

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
    multipleCoherence = NaN(size(f));
    conditionNumber = NaN(size(f));

    for frequencyIndex = 1:length(f)
        S_xx = [mapPower(frequencyIndex), mapCo2(frequencyIndex);
                co2Map(frequencyIndex), co2Power(frequencyIndex)];

        S_xy = [mapCbv(frequencyIndex);
                co2Cbv(frequencyIndex)];

        H = S_xx \ S_xy;

        H_mapcbv(frequencyIndex) = H(1);
        H_co2cbv(frequencyIndex) = H(2);

        conditionNumber(frequencyIndex) = cond(S_xx);
        cbvPowerAtFrequency = real(cbvPower(frequencyIndex));
        multipleCoherence(frequencyIndex) = ...
            real(S_xy' * H) / cbvPowerAtFrequency;
    end

    unexplainedFraction = 1 - multipleCoherence;
    residualPower = real(cbvPower) .* unexplainedFraction;

    %% Partial Coherence

    cbvCo2 = conj(co2Cbv);

    mapCbvGivenCo2 = mapCbv - (mapCo2 .* co2Cbv) ./ co2Power;
    mapPowerGivenCo2 = mapPower - (mapCo2 .* co2Map) ./ co2Power;
    cbvPowerGivenCo2 = cbvPower - (cbvCo2 .* co2Cbv) ./ co2Power;

    partialCohMapCbvGivenCo2 = abs(mapCbvGivenCo2).^2 ./ ...
        real(mapPowerGivenCo2 .* cbvPowerGivenCo2);

    cbvMap = conj(mapCbv);

    co2CbvGivenMap = co2Cbv - (co2Map .* mapCbv) ./ mapPower;
    co2PowerGivenMap = co2Power - (co2Map .* mapCo2) ./ mapPower;
    cbvPowerGivenMap = cbvPower - (cbvMap .* mapCbv) ./ mapPower;

    partialCohCo2CbvGivenMap = abs(co2CbvGivenMap).^2 ./ ...
        real(co2PowerGivenMap .* cbvPowerGivenMap);

    %% Input-Input Coherence

    inputInputCoherence = abs(mapCo2).^2 ./ ...
        real(mapPower .* co2Power);

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
    misoResults.map.gain = abs(H_mapcbv);
    misoResults.map.phase.wrapped = mapPhaseWrapped;
    misoResults.map.phase.unwrapped = mapPhaseUnwrapped;
    misoResults.map.coherence.partial = partialCohMapCbvGivenCo2;

    misoResults.co2.power = co2Power;
    misoResults.co2.transferFunction = H_co2cbv;
    misoResults.co2.gain = abs(H_co2cbv);
    misoResults.co2.phase.wrapped = co2PhaseWrapped;
    misoResults.co2.phase.unwrapped = co2PhaseUnwrapped;
    misoResults.co2.coherence.partial = partialCohCo2CbvGivenMap;

    misoResults.cbv.power = cbvPower;

    misoResults.system.multipleCoherence = multipleCoherence;
    misoResults.system.unexplainedFraction = unexplainedFraction;
    misoResults.system.residualPower = residualPower;

    misoResults.inputRelationship.coherence = inputInputCoherence;
    misoResults.inputRelationship.phase.wrapped = inputPhaseWrapped;
    misoResults.inputRelationship.phase.unwrapped = inputPhaseUnwrapped;

    misoResults.diagnostics.conditionNumber = conditionNumber;

    misoResults.phaseUnwrapMethod = string(phaseSettings.unwrapMethod);
    misoResults.welchInfo = spectra.welchInfo;

end
