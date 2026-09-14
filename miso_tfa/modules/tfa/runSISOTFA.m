function sisoResults = runSISOTFA(spectra, phaseSettings)
% runSISOTFA Calculate independent MAP-to-CBV and CO2-to-CBV results.

    f = spectra.f;
    mapPower = spectra.map.power;
    co2Power = spectra.co2.power;
    cbvPower = spectra.cbv.power;
    mapCo2 = spectra.cross.mapCo2;
    mapCbv = spectra.cross.mapCbv;
    co2Cbv = spectra.cross.co2Cbv;

    %% Solve Independent SISO Transfer Functions

    H_mapcbv = mapCbv ./ mapPower;
    H_co2cbv = co2Cbv ./ co2Power;

    %% Coherence and Residual Quantities

    mapCbvCoherence = abs(mapCbv).^2 ./ real(mapPower .* cbvPower);
    co2CbvCoherence = abs(co2Cbv).^2 ./ real(co2Power .* cbvPower);
    inputInputCoherence = abs(mapCo2).^2 ./ real(mapPower .* co2Power);

    mapCbvCoherence = real(mapCbvCoherence);
    co2CbvCoherence = real(co2CbvCoherence);
    inputInputCoherence = real(inputInputCoherence);

    mapUnexplainedFraction = 1 - mapCbvCoherence;
    co2UnexplainedFraction = 1 - co2CbvCoherence;
    mapResidualPower = real(cbvPower) .* mapUnexplainedFraction;
    co2ResidualPower = real(cbvPower) .* co2UnexplainedFraction;

    %% Phase

    mapPhaseWrapped = angle(H_mapcbv);
    mapPhaseUnwrapped = unwrapTfaPhase( ...
        mapPhaseWrapped, f, mapCbvCoherence, phaseSettings);

    co2PhaseWrapped = angle(H_co2cbv);
    co2PhaseUnwrapped = unwrapTfaPhase( ...
        co2PhaseWrapped, f, co2CbvCoherence, phaseSettings);

    inputPhaseWrapped = angle(mapCo2);
    inputPhaseUnwrapped = unwrapTfaPhase( ...
        inputPhaseWrapped, f, inputInputCoherence, phaseSettings);

    %% Store Results

    sisoResults.f = f;

    sisoResults.map.power = mapPower;
    sisoResults.map.transferFunction = H_mapcbv;
    sisoResults.map.gain = abs(H_mapcbv);
    sisoResults.map.phase.wrapped = mapPhaseWrapped;
    sisoResults.map.phase.unwrapped = mapPhaseUnwrapped;
    sisoResults.map.coherence.pairwise = mapCbvCoherence;
    sisoResults.map.unexplainedFraction = mapUnexplainedFraction;
    sisoResults.map.residualPower = mapResidualPower;

    sisoResults.co2.power = co2Power;
    sisoResults.co2.transferFunction = H_co2cbv;
    sisoResults.co2.gain = abs(H_co2cbv);
    sisoResults.co2.phase.wrapped = co2PhaseWrapped;
    sisoResults.co2.phase.unwrapped = co2PhaseUnwrapped;
    sisoResults.co2.coherence.pairwise = co2CbvCoherence;
    sisoResults.co2.unexplainedFraction = co2UnexplainedFraction;
    sisoResults.co2.residualPower = co2ResidualPower;

    sisoResults.cbv.power = cbvPower;

    sisoResults.inputRelationship.coherence = inputInputCoherence;
    sisoResults.inputRelationship.phase.wrapped = inputPhaseWrapped;
    sisoResults.inputRelationship.phase.unwrapped = inputPhaseUnwrapped;

    sisoResults.phaseUnwrapMethod = string(phaseSettings.unwrapMethod);
    sisoResults.welchInfo = spectra.welchInfo;
    [sisoResults.welchInfo.coherenceThreshold, ...
        sisoResults.welchInfo.coherenceThresholdSource] = ...
        ordinaryCoherenceThresholdFromCarnet( ...
            spectra.welchInfo.numWindows);

end
