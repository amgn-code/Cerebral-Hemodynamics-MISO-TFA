function population = calculateKnownTruthPopulationTargets( ...
    frequencyHz, truth, settings)
% calculateKnownTruthPopulationTargets Return analytic infinite-record targets.
%
% The conditional target is the filter used to generate CBFV. The SISO
% population target is the transfer function a one-input estimator converges
% to when the omitted input is correlated with the included input.

    frequencyHz = frequencyHz(:);
    scenario.targetInputCoherence = truth.targetInputCoherence;
    scenario.spectralSimilarityControl = truth.spectralSimilarityControl;
    scenario.petco2ToMapFluctuationSdRatio = ...
        truth.petco2ToMapFluctuationSdRatio;
    scenario.petco2ToMapBandGainRatio = ...
        truth.assignedPETCO2ToMAPBandGainRatio;
    scenario.co2DelaySeconds = truth.co2DelaySeconds;
    scenario.inputPhaseLagSeconds = truth.inputPhaseLagSeconds;
    scenario.mapPathwayTimeConstantSeconds = ...
        truth.mapPathwayTimeConstantSeconds;
    scenario.co2PathwayTimeConstantSeconds = ...
        truth.co2PathwayTimeConstantSeconds;

    designed = createKnownTruthInputSpectra( ...
        frequencyHz, scenario, settings);
    phaseRadians = -2*pi*frequencyHz*scenario.inputPhaseLagSeconds;
    designedCrossSpectrum = sqrt( ...
        designed.targetCoherence .* designed.mapPower .* ...
        designed.co2Power) .* exp(1i*phaseRadians);

    trueMap = freqz(truth.mapImpulseResponse, 1, ...
        frequencyHz, settings.samplingFrequencyHz);
    trueCo2 = freqz(truth.co2ImpulseResponse, 1, ...
        frequencyHz, settings.samplingFrequencyHz);
    mapPower = max(designed.mapPower, eps);
    co2Power = max(designed.co2Power, eps);

    population.frequencyHz = frequencyHz;
    population.conditional.map = trueMap(:);
    population.conditional.co2 = trueCo2(:);
    population.designed.mapPower = designed.mapPower(:);
    population.designed.co2Power = designed.co2Power(:);
    population.designed.crossMapCo2 = designedCrossSpectrum(:);
    population.siso.map = trueMap(:) + trueCo2(:) .* ...
        (designedCrossSpectrum(:)./mapPower(:));
    population.siso.co2 = trueCo2(:) + trueMap(:) .* ...
        (conj(designedCrossSpectrum(:))./co2Power(:));

end
