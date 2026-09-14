function phaseUnwrapped = customPhaseUnwrap( ...
    phaseWrapped, f, coherence, customSettings)
% customPhaseUnwrap Select phase branches using local coherence-weighted fits.

    originalSize = size(phaseWrapped);
    basePhase = angle(exp(1i*phaseWrapped(:)));
    f = f(:);
    coherence = coherence(:);
    phaseSelected = basePhase;
    numPhases = numel(basePhase);

    if numPhases < 3
        phaseUnwrapped = reshape(phaseSelected, originalSize);
        return
    end

    windowSize = round(customSettings.windowSize);
    windowSize = min(max(windowSize, 3), numPhases);
    halfWindow = floor(windowSize / 2);

    for passIndex = 1:customSettings.numPasses
        if mod(passIndex, 2) == 1
            sweepOrder = 1:numPhases;
        else
            sweepOrder = numPhases:-1:1;
        end

        for phaseIndex = sweepOrder
            if ~isfinite(basePhase(phaseIndex))
                continue
            end

            windowStart = max(1, phaseIndex - halfWindow);
            windowStart = min(windowStart, numPhases - windowSize + 1);
            neighborIndex = windowStart:(windowStart + windowSize - 1);
            neighborIndex(neighborIndex == phaseIndex) = [];
            neighborIndex = neighborIndex( ...
                isfinite(basePhase(neighborIndex)) & isfinite(f(neighborIndex)));

            if numel(neighborIndex) < 2
                continue
            end

            if customSettings.useCoherenceWeights
                weights = coherence(neighborIndex);
                weights(~isfinite(weights)) = 0;
                weights = min(max(weights, 0), 1);

                switch customSettings.weightMode
                    case "linear"
                    case "power"
                        weights = weights.^customSettings.weightPower;
                    case "exponential"
                        weights = exp( ...
                            customSettings.expAlpha*(weights - 1));
                    otherwise
                        error( ...
                            'TFA:UnknownCustomPhaseWeightMode', ...
                            ['phase.custom.weightMode must be "linear", ' ...
                             '"power", or "exponential".']);
                end

                weights = max(weights, customSettings.minWeight);
            else
                weights = ones(size(neighborIndex));
            end

            weights = weights(:) / sum(weights, 'omitnan');
            neighborPhase = basePhase(neighborIndex) + ...
                2*pi*round((phaseSelected(neighborIndex) - ...
                basePhase(neighborIndex)) / (2*pi));

            designMatrix = [f(neighborIndex), ones(numel(neighborIndex), 1)];
            weightedDesign = designMatrix .* sqrt(weights);
            weightedPhase = neighborPhase(:) .* sqrt(weights);
            coefficients = weightedDesign \ weightedPhase;
            predictedPhase = [f(phaseIndex), 1]*coefficients;

            phaseSelected(phaseIndex) = basePhase(phaseIndex) + ...
                2*pi*round((predictedPhase - basePhase(phaseIndex)) / (2*pi));
        end
    end

    phaseUnwrapped = reshape(phaseSelected, originalSize);

end
