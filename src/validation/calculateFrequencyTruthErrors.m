function errors = calculateFrequencyTruthErrors( ...
    estimate, truth, errorFloor, phaseMinimumGainFraction)
% calculateFrequencyTruthErrors Calculate frequency-resolved truth errors.
%
% Complex error is normalized by one RMS truth gain for the full analysis
% band. A weak individual frequency bin therefore cannot make the error
% explode. Phase is omitted where the true gain is too small to define it
% reliably.

    if nargin < 4
        phaseMinimumGainFraction = 0.05;
    end

    estimate = estimate(:);
    truth = truth(:);
    complete = isfinite(estimate) & isfinite(truth);

    errors.gain = NaN(size(truth));
    errors.phase = NaN(size(truth));
    errors.complex = NaN(size(truth));

    truthGain = abs(truth);
    estimatedGain = abs(estimate);
    errors.gain(complete) = abs( ...
        estimatedGain(complete) - truthGain(complete));
    truthBandRmsGain = sqrt(mean(truthGain(complete).^2, "omitnan"));
    normalizationPower = max(truthBandRmsGain^2, errorFloor);
    errors.complex(complete) = ...
        abs(estimate(complete) - truth(complete)).^2/ ...
        normalizationPower;

    phaseThreshold = max( ...
        phaseMinimumGainFraction*truthBandRmsGain, sqrt(errorFloor));
    phaseDefined = complete & truthGain >= phaseThreshold;
    errors.phase(phaseDefined) = abs(angle( ...
        estimate(phaseDefined).*conj(truth(phaseDefined))));
    errors.phaseValid = phaseDefined;
    errors.truthBandRmsGain = truthBandRmsGain;
    errors.phaseGainThreshold = phaseThreshold;

end
