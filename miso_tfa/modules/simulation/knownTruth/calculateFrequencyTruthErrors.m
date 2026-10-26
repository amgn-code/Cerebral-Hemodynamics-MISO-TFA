function errors = calculateFrequencyTruthErrors( ...
    estimate, truth, errorFloor, phaseMinimumGainFraction)
% calculateFrequencyTruthErrors Calculate frequency-resolved truth errors.
%
% Complex error is normalized by one RMS truth gain for the full analysis
% band. A weak individual frequency bin therefore cannot make the error
% explode. Phase is omitted where the true gain is too small to define it
% reliably.

    if nargin < 3
        errorFloor = eps;
    end
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

    % Calculate the normalization from truth only. The set of finite
    % estimates can differ between SISO and MISO, so using the complete
    % mask here would give the two methods different denominators.
    finiteTruth = isfinite(truth);
    truthBandRmsGain = sqrt(mean(truthGain(finiteTruth).^2, "omitnan"));

    if truthBandRmsGain^2 > errorFloor
        normalizationPower = truthBandRmsGain^2;
        errors.complex(complete) = ...
            abs(estimate(complete) - truth(complete)).^2/ ...
            normalizationPower;
        errors.complexNormalization = "truth-band-rms";
    else
        % A zero pathway has no meaningful normalized denominator. Keep
        % its squared complex error on an absolute scale instead.
        normalizationPower = 1;
        errors.complex(complete) = ...
            abs(estimate(complete) - truth(complete)).^2;
        errors.complexNormalization = "absolute";
    end

    phaseThreshold = max( ...
        phaseMinimumGainFraction*truthBandRmsGain, sqrt(errorFloor));
    phaseDefined = complete & truthGain >= phaseThreshold;
    errors.phase(phaseDefined) = abs(angle( ...
        estimate(phaseDefined).*conj(truth(phaseDefined))));
    errors.phaseValid = phaseDefined;
    errors.truthBandRmsGain = truthBandRmsGain;
    errors.phaseGainThreshold = phaseThreshold;
    errors.complexNormalizationPower = normalizationPower;

end
