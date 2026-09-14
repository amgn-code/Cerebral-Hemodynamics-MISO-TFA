function diagnostics = calculateMisoCoherenceDiagnostics( ...
    spectra, multipleCoherence)
% calculateMisoCoherenceDiagnostics Calculate the coherence quantities used
% to interpret the two-input MISO result.

    mapPower = spectra.map.power;
    co2Power = spectra.co2.power;
    cbvPower = spectra.cbv.power;
    mapCo2 = spectra.cross.mapCo2;
    co2Map = spectra.cross.co2Map;
    mapCbv = spectra.cross.mapCbv;
    co2Cbv = spectra.cross.co2Cbv;

    diagnostics.mapPairwiseCoherence = abs(mapCbv).^2 ./ ...
        real(mapPower .* cbvPower);
    diagnostics.co2PairwiseCoherence = abs(co2Cbv).^2 ./ ...
        real(co2Power .* cbvPower);
    diagnostics.inputCoherence = abs(mapCo2).^2 ./ ...
        real(mapPower .* co2Power);

    % Remove the contribution of the conditioning input from the two
    % remaining signals before calculating partial coherence.
    mapCbvGivenCo2 = mapCbv - (mapCo2 .* co2Cbv) ./ co2Power;
    mapPowerGivenCo2 = mapPower - (mapCo2 .* co2Map) ./ co2Power;
    cbvPowerGivenCo2 = cbvPower - ...
        (conj(co2Cbv) .* co2Cbv) ./ co2Power;
    diagnostics.partialMapCoherence = abs(mapCbvGivenCo2).^2 ./ ...
        real(mapPowerGivenCo2 .* cbvPowerGivenCo2);

    co2CbvGivenMap = co2Cbv - (co2Map .* mapCbv) ./ mapPower;
    co2PowerGivenMap = co2Power - (co2Map .* mapCo2) ./ mapPower;
    cbvPowerGivenMap = cbvPower - ...
        (conj(mapCbv) .* mapCbv) ./ mapPower;
    diagnostics.partialCo2Coherence = abs(co2CbvGivenMap).^2 ./ ...
        real(co2PowerGivenMap .* cbvPowerGivenMap);

    % These are the two interpretable gaps to carry into the simulation
    % result. They are diagnostics, not additional assigned factors.
    diagnostics.multipleMinusMapCoherence = ...
        multipleCoherence - diagnostics.mapPairwiseCoherence;
    diagnostics.multipleMinusPartialMapCoherence = ...
        multipleCoherence - diagnostics.partialMapCoherence;

end
