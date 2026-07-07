function [phaseUnwrapped, modelInfo] = unwrapPhase(values, inputType, unwrapMethod, ...
    coherenceValues, coherenceThreshold, frequencyValues, modelOptions)
% unwrapPhase Compute phase and unwrap contiguous finite segments.
%
% By default, inputs are treated as transfer-function values and converted
% with angle before unwrapping. Use inputType="phase" when values are already
% phase values in radians. NaN and Inf values are preserved, and finite
% segments separated by non-finite values are unwrapped independently.
%
% unwrapMethod controls the branch convention:
%   "standard" uses MATLAB unwrap on each finite segment.
%   "fitted" uses a dynamic-programming branch search followed by a
%   conservative endpoint trend pass. The fitted method preserves the
%   measured circular phase at every bin; the trend fit only chooses the
%   displayed 2*pi branch.
%   "coherence" uses coherence-passing bins to define the unwrap branch,
%   then assigns low-coherence bins to the nearest equivalent 2*pi branch
%   without removing them.
%   "model" fits a coherence-weighted circular delay model and assigns
%   every phase value to the nearest equivalent 2*pi branch of that model.
%   This method requires frequencyValues.
%   "localWeighted" uses a fixed, edge-pinned local window and a
%   transformed coherence-weighted line fit to choose each point's 2*pi
%   branch.
%   "wrapped" returns the measured wrapped phase in [-pi, pi].

    if nargin < 2
        inputType = "complex";
    end

    if nargin < 3
        unwrapMethod = "standard";
    end

    if nargin < 4
        coherenceValues = [];
    end

    if nargin < 5
        coherenceThreshold = 0;
    end

    if nargin < 6
        frequencyValues = [];
    end

    if nargin < 7
        modelOptions = struct();
    end

    modelInfo = emptyModelInfo(string(unwrapMethod));

    if string(inputType) == "phase"
        phase = values;
    else
        phase = angle(values);
    end

    phaseUnwrapped = phase;
    finiteMask = isfinite(phase);

    if ~any(finiteMask(:))
        return
    end

    if isvector(phase)
        [phaseUnwrapped, modelInfo] = unwrapVectorSegments( ...
            phase, finiteMask, unwrapMethod, coherenceValues, ...
            coherenceThreshold, frequencyValues, modelOptions);
    else
        modelInfo = repmat(modelInfo, 1, size(phase, 2));
        for columnIndex = 1:size(phase, 2)
            coherenceColumn = columnCoherenceValues(coherenceValues, columnIndex);
            frequencyColumn = columnFrequencyValues(frequencyValues, columnIndex);
            [phaseUnwrapped(:, columnIndex), modelInfo(columnIndex)] = unwrapVectorSegments( ...
                phase(:, columnIndex), finiteMask(:, columnIndex), ...
                unwrapMethod, coherenceColumn, coherenceThreshold, ...
                frequencyColumn, modelOptions);
        end
    end

end


function [phaseOut, modelInfo] = unwrapVectorSegments( ...
    phaseIn, finiteMask, unwrapMethod, coherenceValues, ...
    coherenceThreshold, frequencyValues, modelOptions)

    phaseOut = phaseIn;
    phaseVector = phaseIn(:);
    finiteVector = finiteMask(:);
    coherenceVector = vectorCoherenceValues(coherenceValues, numel(phaseVector));
    frequencyVector = vectorFrequencyValues(frequencyValues, numel(phaseVector));
    segmentModelInfo = emptyModelInfo(string(unwrapMethod));
    segmentStarts = find(diff([false; finiteVector]) == 1);
    segmentEnds = find(diff([finiteVector; false]) == -1);

    for segmentIndex = 1:numel(segmentStarts)
        segmentRange = segmentStarts(segmentIndex):segmentEnds(segmentIndex);
        segmentPhase = phaseVector(segmentRange);
        if string(unwrapMethod) == "wrapped"
            phaseVector(segmentRange) = angle(exp(1i * segmentPhase));
        elseif string(unwrapMethod) == "localWeighted"
            segmentCoherence = [];
            if ~isempty(coherenceVector)
                segmentCoherence = coherenceVector(segmentRange);
            end
            segmentFrequency = frequencyVector(segmentRange);
            if isempty(segmentFrequency)
                segmentFrequency = (1:numel(segmentPhase))';
            end
            phaseVector(segmentRange) = selectLocalWeightedBranches( ...
                segmentPhase, segmentCoherence, segmentFrequency, modelOptions);
        elseif string(unwrapMethod) == "model" && ~isempty(frequencyVector)
            segmentCoherence = [];
            if ~isempty(coherenceVector)
                segmentCoherence = coherenceVector(segmentRange);
            end
            [phaseVector(segmentRange), segmentModelInfo] = ...
                selectModelReferencedBranches( ...
                    segmentPhase, segmentCoherence, coherenceThreshold, ...
                    frequencyVector(segmentRange), modelOptions);
        elseif string(unwrapMethod) == "coherence" && ~isempty(coherenceVector)
            phaseVector(segmentRange) = selectCoherenceGuidedBranches( ...
                segmentPhase, coherenceVector(segmentRange), coherenceThreshold);
        elseif string(unwrapMethod) == "fitted"
            phaseVector(segmentRange) = selectSmoothPhaseBranches(segmentPhase);
        else
            phaseVector(segmentRange) = unwrap(segmentPhase);
        end
    end

    phaseOut(:) = phaseVector;
    modelInfo = segmentModelInfo;

end


function coherenceColumn = columnCoherenceValues(coherenceValues, columnIndex)

    if isempty(coherenceValues)
        coherenceColumn = [];
    elseif isvector(coherenceValues)
        coherenceColumn = coherenceValues;
    else
        coherenceColumn = coherenceValues(:, columnIndex);
    end

end


function frequencyColumn = columnFrequencyValues(frequencyValues, columnIndex)

    if isempty(frequencyValues)
        frequencyColumn = [];
    elseif isvector(frequencyValues)
        frequencyColumn = frequencyValues;
    else
        frequencyColumn = frequencyValues(:, columnIndex);
    end

end


function coherenceVector = vectorCoherenceValues(coherenceValues, numValues)

    if isempty(coherenceValues)
        coherenceVector = [];
        return
    end

    coherenceVector = coherenceValues(:);

    if numel(coherenceVector) ~= numValues
        error('Coherence values must match the phase vector length.');
    end

end


function frequencyVector = vectorFrequencyValues(frequencyValues, numValues)

    if isempty(frequencyValues)
        frequencyVector = [];
        return
    end

    frequencyVector = frequencyValues(:);

    if numel(frequencyVector) ~= numValues
        error('Frequency values must match the phase vector length.');
    end

end


function modelInfo = emptyModelInfo(unwrapMethod)

    modelInfo = struct( ...
        'method', unwrapMethod, ...
        'success', false, ...
        'tauSeconds', NaN, ...
        'phi0Rad', NaN, ...
        'objective', NaN, ...
        'numFitPoints', 0, ...
        'fitBandHz', [NaN NaN], ...
        'coherenceThreshold', NaN);

end


function phaseSelected = selectCoherenceGuidedBranches( ...
    phaseOriginal, coherenceValues, coherenceThreshold)

    basePhase = angle(exp(1i * phaseOriginal(:)));
    coherenceValues = coherenceValues(:);
    reliableMask = isfinite(coherenceValues) & ...
        coherenceValues >= coherenceThreshold & isfinite(basePhase);

    if nnz(reliableMask) < 2
        phaseSelected = unwrap(basePhase);
        return
    end

    phaseIndex = (1:numel(basePhase))';
    reliablePhase = unwrap(basePhase(reliableMask));
    reliableIndex = phaseIndex(reliableMask);

    if numel(reliableIndex) >= 4
        interpolationMethod = "pchip";
    else
        interpolationMethod = "linear";
    end

    guidePhase = interp1( ...
        reliableIndex, reliablePhase, phaseIndex, interpolationMethod, "extrap");
    phaseSelected = alignPhaseToGuide(basePhase, guidePhase);

end


function phaseSelected = selectLocalWeightedBranches( ...
    phaseOriginal, coherenceValues, frequencyValues, localOptions)

    basePhase = angle(exp(1i * phaseOriginal(:)));
    numPhases = numel(basePhase);
    phaseSelected = basePhase;

    if numPhases < 3
        return
    end

    if isempty(coherenceValues)
        coherenceValues = ones(numPhases, 1);
    else
        coherenceValues = coherenceValues(:);
    end

    frequencyValues = frequencyValues(:);

    windowSize = localWindowSize(localOptions, numPhases);
    numPasses = localOptionValue(localOptions, 'numPasses', 3);
    useCoherenceWeights = localOptionValue(localOptions, 'useCoherenceWeights', true);
    weightMode = string(localOptionValue(localOptions, 'weightMode', "power"));
    weightPower = localOptionValue(localOptions, 'weightPower', 4);
    expAlpha = localOptionValue(localOptions, 'expAlpha', 4);
    minWeight = localOptionValue(localOptions, 'minWeight', 0.01);

    for passIndex = 1:numPasses
        sweepOrder = localSweepOrder(passIndex, numPhases);

        for phaseIndex = sweepOrder
            if ~isfinite(basePhase(phaseIndex))
                continue
            end

            neighborRange = localWindowIndices(phaseIndex, numPhases, windowSize);
            neighborRange(neighborRange == phaseIndex) = [];
            neighborMask = isfinite(basePhase(neighborRange)) & ...
                isfinite(frequencyValues(neighborRange));
            neighborIndex = neighborRange(neighborMask);

            if numel(neighborIndex) < 2
                continue
            end

            if useCoherenceWeights
                localWeights = localCoherenceWeights( ...
                    coherenceValues(neighborIndex), weightMode, ...
                    weightPower, expAlpha, minWeight);
            else
                localWeights = ones(size(neighborIndex(:)));
                localWeights = localWeights ./ sum(localWeights);
            end

            localPhase = basePhase(neighborIndex) + ...
                2*pi*round((phaseSelected(neighborIndex) - ...
                basePhase(neighborIndex)) / (2*pi));

            predictedPhase = weightedLinearPrediction( ...
                frequencyValues(neighborIndex), localPhase, localWeights, ...
                frequencyValues(phaseIndex));
            phaseSelected(phaseIndex) = basePhase(phaseIndex) + ...
                2*pi*round((predictedPhase - basePhase(phaseIndex)) / (2*pi));
        end
    end

end


function sweepOrder = localSweepOrder(passIndex, numPhases)

    if mod(passIndex, 2) == 1
        sweepOrder = 1:numPhases;
    else
        sweepOrder = numPhases:-1:1;
    end

end


function windowSize = localWindowSize(localOptions, numPhases)

    if isstruct(localOptions) && isfield(localOptions, 'windowSize')
        windowSize = localOptions.windowSize;
    else
        windowRadius = localOptionValue(localOptions, 'windowRadius', 5);
        windowSize = 2*windowRadius + 1;
    end

    windowSize = round(windowSize);
    windowSize = max(3, windowSize);
    windowSize = min(windowSize, numPhases);

end


function windowIndex = localWindowIndices(phaseIndex, numPhases, windowSize)

    halfWindow = floor(windowSize / 2);
    startIndex = phaseIndex - halfWindow;
    startIndex = max(startIndex, 1);
    startIndex = min(startIndex, numPhases - windowSize + 1);
    endIndex = startIndex + windowSize - 1;
    windowIndex = startIndex:endIndex;

end


function weights = localCoherenceWeights( ...
    coherenceValues, weightMode, weightPower, expAlpha, minWeight)

    coherenceValues = coherenceValues(:);
    coherenceValues(~isfinite(coherenceValues)) = 0;
    coherenceValues = min(max(coherenceValues, 0), 1);

    switch weightMode
        case "linear"
            weights = coherenceValues;
        case "power"
            weights = coherenceValues .^ weightPower;
        case "exponential"
            weights = exp(expAlpha .* (coherenceValues - 1));
        otherwise
            error('Unknown localWeighted weightMode: %s', weightMode);
    end

    weights = max(weights, minWeight);
    weightSum = sum(weights, 'omitnan');

    if weightSum > 0
        weights = weights ./ weightSum;
    else
        weights = ones(size(weights)) ./ numel(weights);
    end

end


function value = localOptionValue(localOptions, fieldName, defaultValue)

    if isstruct(localOptions) && isfield(localOptions, fieldName)
        value = localOptions.(fieldName);
    else
        value = defaultValue;
    end

end


function predictedPhase = weightedLinearPrediction( ...
    frequencyValues, phaseValues, weights, targetFrequency)

    frequencyValues = frequencyValues(:);
    phaseValues = phaseValues(:);
    weights = weights(:);

    positiveWeights = weights(isfinite(weights) & weights > 0);

    if isempty(positiveWeights)
        weights = ones(size(frequencyValues));
    else
        weights(~isfinite(weights) | weights <= 0) = min(positiveWeights);
    end

    designMatrix = [frequencyValues, ones(size(frequencyValues))];
    weightedDesign = designMatrix .* sqrt(weights);
    weightedPhase = phaseValues .* sqrt(weights);
    coefficients = weightedDesign \ weightedPhase;
    predictedPhase = [targetFrequency, 1] * coefficients;

end


function [phaseSelected, modelInfo] = selectModelReferencedBranches( ...
    phaseOriginal, coherenceValues, coherenceThreshold, frequencyValues, modelOptions)

    modelInfo = emptyModelInfo("model");
    basePhase = angle(exp(1i * phaseOriginal(:)));
    frequencyValues = frequencyValues(:);

    if isempty(coherenceValues)
        coherenceValues = ones(size(basePhase));
    else
        coherenceValues = coherenceValues(:);
    end

    if numel(coherenceValues) ~= numel(basePhase)
        error('Coherence values must match the phase vector length.');
    end

    fitBandHz = modelOptionValue(modelOptions, 'fitBandHz', [0.02 0.20]);
    tauBoundsSeconds = modelOptionValue(modelOptions, 'tauBoundsSeconds', [0 60]);
    minFitPoints = modelOptionValue(modelOptions, 'minFitPoints', 3);

    fitMask = isfinite(basePhase) & isfinite(frequencyValues) & ...
        isfinite(coherenceValues) & coherenceValues >= coherenceThreshold & ...
        frequencyValues >= fitBandHz(1) & frequencyValues <= fitBandHz(2);

    modelInfo.fitBandHz = fitBandHz;
    modelInfo.coherenceThreshold = coherenceThreshold;
    modelInfo.numFitPoints = nnz(fitMask);

    if modelInfo.numFitPoints < minFitPoints
        phaseSelected = unwrap(basePhase);
        return
    end

    fitFrequency = frequencyValues(fitMask);
    fitPhase = basePhase(fitMask);
    fitCoherence = coherenceValues(fitMask);
    weights = max(0, fitCoherence - coherenceThreshold);

    if sum(weights, 'omitnan') <= 0
        weights = fitCoherence;
    end

    weights = weights ./ sum(weights, 'omitnan');

    [phi0Rad, tauSeconds, objectiveValue] = fitCircularDelayModel( ...
        fitFrequency, fitPhase, weights, tauBoundsSeconds);

    phaseModel = phi0Rad - 2*pi*frequencyValues*tauSeconds;
    phaseSelected = alignPhaseToGuide(basePhase, phaseModel);

    modelInfo.success = true;
    modelInfo.tauSeconds = tauSeconds;
    modelInfo.phi0Rad = wrapPhase(phi0Rad);
    modelInfo.objective = objectiveValue;

end


function value = modelOptionValue(modelOptions, fieldName, defaultValue)

    if isstruct(modelOptions) && isfield(modelOptions, fieldName)
        value = modelOptions.(fieldName);
    else
        value = defaultValue;
    end

end


function [phi0Rad, tauSeconds, objectiveValue] = fitCircularDelayModel( ...
    frequencyValues, phaseValues, weights, tauBoundsSeconds)

    objective = @(parameters) circularDelayObjective( ...
        parameters, frequencyValues, phaseValues, weights, tauBoundsSeconds);
    optimizerOptions = optimset('Display', 'off');
    initialPhi0Values = [-pi, -pi/2, 0, pi/2, pi];
    initialTauValues = [0, 2, 5, 10, 20];
    bestParameters = [0 5];
    objectiveValue = Inf;

    for phi0Initial = initialPhi0Values
        for tauInitial = initialTauValues
            [candidateParameters, candidateObjective] = fminsearch( ...
                objective, [phi0Initial tauInitial], optimizerOptions);

            if candidateObjective < objectiveValue
                objectiveValue = candidateObjective;
                bestParameters = candidateParameters;
            end
        end
    end

    phi0Rad = bestParameters(1);
    tauSeconds = min(max(bestParameters(2), tauBoundsSeconds(1)), tauBoundsSeconds(2));

end


function objectiveValue = circularDelayObjective( ...
    parameters, frequencyValues, phaseValues, weights, tauBoundsSeconds)

    tauSeconds = parameters(2);

    if tauSeconds < tauBoundsSeconds(1) || tauSeconds > tauBoundsSeconds(2)
        objectiveValue = Inf;
        return
    end

    phaseModel = parameters(1) - 2*pi*frequencyValues*tauSeconds;
    circularResidual = wrapPhase(phaseValues - phaseModel);
    objectiveValue = sum(weights .* circularResidual.^2, 'omitnan');

end


function phaseWrapped = wrapPhase(phaseValues)

    phaseWrapped = angle(exp(1i * phaseValues));

end


function phaseAligned = alignPhaseToGuide(basePhase, guidePhase)

    twoPi = 2*pi;
    phaseAligned = NaN(size(basePhase));

    for phaseIndex = 1:numel(basePhase)
        centerBranch = round((guidePhase(phaseIndex) - basePhase(phaseIndex)) / twoPi);
        candidateBranches = centerBranch + (-2:2);
        candidates = basePhase(phaseIndex) + candidateBranches*twoPi;
        [~, bestIndex] = min(abs(candidates - guidePhase(phaseIndex)));
        phaseAligned(phaseIndex) = candidates(bestIndex);
    end

end


function phaseSelected = selectSmoothPhaseBranches(phaseOriginal)

    basePhase = angle(exp(1i * phaseOriginal(:)));
    standardUnwrapped = unwrap(basePhase);
    numPhases = numel(basePhase);

    if numPhases < 3
        phaseSelected = standardUnwrapped;
        return
    end

    twoPi = 2*pi;
    branchSearchRadius = 4;
    branchOffsets = -branchSearchRadius:branchSearchRadius;
    numBranches = numel(branchOffsets);
    centerBranches = round((standardUnwrapped - basePhase) / twoPi);
    candidatePhases = NaN(numPhases, numBranches);

    for phaseIndex = 1:numPhases
        candidateBranches = centerBranches(phaseIndex) + branchOffsets;
        candidatePhases(phaseIndex,:) = ...
            basePhase(phaseIndex) + candidateBranches*twoPi;
    end

    adjacentWeight = 1.0;
    curvatureWeight = 0.75;
    standardTieBreakWeight = 1e-4;
    discontinuityWeight = 1e6;

    pairCosts = Inf(numBranches, numBranches);

    for firstBranch = 1:numBranches
        for secondBranch = 1:numBranches
            firstCandidate = candidatePhases(1, firstBranch);
            secondCandidate = candidatePhases(2, secondBranch);
            pairCosts(firstBranch, secondBranch) = ...
                adjacentCost( ...
                    firstCandidate, secondCandidate, ...
                    adjacentWeight, discontinuityWeight) + ...
                standardTieBreakWeight*( ...
                    abs(firstCandidate - standardUnwrapped(1)) + ...
                    abs(secondCandidate - standardUnwrapped(2)));
        end
    end

    previousBranchIndex = zeros(numPhases, numBranches, numBranches);

    for phaseIndex = 3:numPhases
        nextPairCosts = Inf(numBranches, numBranches);

        for previousBranch = 1:numBranches
            previousCandidate = candidatePhases(phaseIndex - 1, previousBranch);

            for currentBranch = 1:numBranches
                currentCandidate = candidatePhases(phaseIndex, currentBranch);
                transitionCosts = Inf(numBranches, 1);

                for earlierBranch = 1:numBranches
                    earlierCandidate = ...
                        candidatePhases(phaseIndex - 2, earlierBranch);
                    transitionCosts(earlierBranch) = ...
                        pairCosts(earlierBranch, previousBranch) + ...
                        adjacentCost( ...
                            previousCandidate, currentCandidate, ...
                            adjacentWeight, discontinuityWeight) + ...
                        curvatureWeight*abs( ...
                            earlierCandidate - 2*previousCandidate + currentCandidate) + ...
                        standardTieBreakWeight*abs( ...
                            currentCandidate - standardUnwrapped(phaseIndex));
                end

                [nextPairCosts(previousBranch, currentBranch), bestEarlierBranch] = ...
                    min(transitionCosts);
                previousBranchIndex(phaseIndex, previousBranch, currentBranch) = ...
                    bestEarlierBranch;
            end
        end

        pairCosts = nextPairCosts;
    end

    branchPath = recoverBestBranchPath(pairCosts, previousBranchIndex);
    phaseSelected = NaN(numPhases, 1);

    for phaseIndex = 1:numPhases
        phaseSelected(phaseIndex) = candidatePhases(phaseIndex, branchPath(phaseIndex));
    end

    phaseSelected = correctBranchesWithLocalTrend(phaseSelected);

end


function cost = adjacentCost(previousCandidate, currentCandidate, ...
    adjacentWeight, discontinuityWeight)

    phaseJump = abs(currentCandidate - previousCandidate);
    cost = adjacentWeight*phaseJump;

    if phaseJump > pi
        cost = cost + discontinuityWeight*(phaseJump - pi);
    end

end


function branchPath = recoverBestBranchPath(pairCosts, previousBranchIndex)

    numPhases = size(previousBranchIndex, 1);
    branchPath = zeros(numPhases, 1);

    [~, linearIndex] = min(pairCosts(:));
    [branchPath(numPhases - 1), branchPath(numPhases)] = ...
        ind2sub(size(pairCosts), linearIndex);

    for phaseIndex = numPhases:-1:3
        branchPath(phaseIndex - 2) = previousBranchIndex( ...
            phaseIndex, branchPath(phaseIndex - 1), branchPath(phaseIndex));
    end

end


function phaseCorrected = correctBranchesWithLocalTrend(phaseIn)

    phaseCorrected = phaseIn(:);
    numPhases = numel(phaseCorrected);

    if numPhases < 6
        return
    end

    twoPi = 2*pi;
    maxIterations = 3;
    maxBlockLength = min(8, max(1, floor(numPhases / 2)));
    contextRadius = min(12, max(4, numPhases - 1));
    branchShifts = [-2 -1 1 2];
    minimumContextPoints = 3;
    minimumAbsoluteImprovement = 0.50;
    minimumRelativeImprovement = 0.15;

    for iteration = 1:maxIterations
        bestChange = makeEmptyBranchChange();

        for blockLength = 1:maxBlockLength
            bestChange = evaluateEndpointBlock( ...
                phaseCorrected, 1:blockLength, ...
                (blockLength + 1):min(numPhases, blockLength + contextRadius), ...
                branchShifts, twoPi, minimumContextPoints, ...
                minimumAbsoluteImprovement, minimumRelativeImprovement, bestChange);

            suffixStart = numPhases - blockLength + 1;
            bestChange = evaluateEndpointBlock( ...
                phaseCorrected, suffixStart:numPhases, ...
                max(1, suffixStart - contextRadius):(suffixStart - 1), ...
                branchShifts, twoPi, minimumContextPoints, ...
                minimumAbsoluteImprovement, minimumRelativeImprovement, bestChange);
        end

        if isempty(bestChange.blockIndex)
            break
        end

        phaseCorrected(bestChange.blockIndex) = ...
            phaseCorrected(bestChange.blockIndex) + bestChange.shift;
    end

end


function branchChange = makeEmptyBranchChange()

    branchChange.blockIndex = [];
    branchChange.shift = 0;
    branchChange.improvement = 0;

end


function bestChange = evaluateEndpointBlock( ...
    phaseValues, blockIndex, contextIndex, branchShifts, twoPi, ...
    minimumContextPoints, minimumAbsoluteImprovement, ...
    minimumRelativeImprovement, bestChange)

    if numel(contextIndex) < minimumContextPoints
        return
    end

    predictedPhase = predictEndpointTrend( ...
        contextIndex, phaseValues(contextIndex), blockIndex);
    currentScore = mean(abs(phaseValues(blockIndex) - predictedPhase));

    for shiftMultiplier = branchShifts
        shiftedPhase = phaseValues(blockIndex) + shiftMultiplier*twoPi;
        shiftedScore = mean(abs(shiftedPhase - predictedPhase));
        absoluteImprovement = currentScore - shiftedScore;
        relativeImprovement = absoluteImprovement / max(currentScore, eps);

        if absoluteImprovement > minimumAbsoluteImprovement && ...
                relativeImprovement > minimumRelativeImprovement && ...
                absoluteImprovement > bestChange.improvement
            bestChange.blockIndex = blockIndex;
            bestChange.shift = shiftMultiplier*twoPi;
            bestChange.improvement = absoluteImprovement;
        end
    end

end


function predictedPhase = predictEndpointTrend(contextIndex, contextPhase, blockIndex)

    contextIndex = contextIndex(:);
    contextPhase = contextPhase(:);
    blockIndex = blockIndex(:);

    polynomialCoefficients = polyfit(contextIndex, contextPhase, 1);
    predictedPhase = polyval(polynomialCoefficients, blockIndex);

end
