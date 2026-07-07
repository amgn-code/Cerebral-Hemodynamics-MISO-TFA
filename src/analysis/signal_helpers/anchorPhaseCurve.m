function [phaseAnchored, anchorInfo] = anchorPhaseCurve( ...
    phaseUnwrapped, f, coherence, phaseSettings, pathwayName)
% anchorPhaseCurve Shift an unwrapped phase curve by a global 2*pi multiple.

phaseSettings = normalizePhaseSettings(phaseSettings);
phaseAnchored = phaseUnwrapped;
pathwayName = lower(string(pathwayName));
anchorInfo = makeAnchorInfo(pathwayName);

if ~phaseSettings.anchor.enabled
    return
end

[bandHz, targetRangeRad, hasAnchorConfig] = anchorConfigForPathway( ...
    phaseSettings, pathwayName);

if ~hasAnchorConfig
    return
end

f = f(:);
phaseVector = phaseUnwrapped(:);

if isempty(coherence)
    coherence = ones(size(phaseVector));
else
    coherence = coherence(:);
end

anchorMask = isfinite(phaseVector) & isfinite(f) & isfinite(coherence) & ...
    f >= bandHz(1) & f <= bandHz(2);

if ~any(anchorMask)
    return
end

weights = coherence(anchorMask);
weightSum = sum(weights, 'omitnan');

if weightSum <= 0
    weights = ones(size(weights)) ./ numel(weights);
else
    weights = weights ./ weightSum;
end

anchorBefore = sum(weights .* phaseVector(anchorMask), 'omitnan');
targetCenter = mean(targetRangeRad);
candidateShifts = (-10:10)' * 2*pi;
candidateAnchors = anchorBefore + candidateShifts;
insideTarget = candidateAnchors >= targetRangeRad(1) & ...
    candidateAnchors <= targetRangeRad(2);

if any(insideTarget)
    insideShifts = candidateShifts(insideTarget);
    [~, bestIndex] = min(abs(insideShifts));
    bestShift = insideShifts(bestIndex);
else
    [~, bestIndex] = min(abs(candidateAnchors - targetCenter));
    bestShift = candidateShifts(bestIndex);
end

phaseAnchored = phaseUnwrapped + bestShift;

anchorInfo.enabled = true;
anchorInfo.applied = true;
anchorInfo.bandHz = bandHz;
anchorInfo.targetRangeRad = targetRangeRad;
anchorInfo.shiftRad = bestShift;
anchorInfo.anchorValueBefore = anchorBefore;
anchorInfo.anchorValueAfter = anchorBefore + bestShift;
anchorInfo.numAnchorPoints = nnz(anchorMask);

end


function anchorInfo = makeAnchorInfo(pathwayName)

anchorInfo = struct( ...
    'enabled', false, ...
    'applied', false, ...
    'pathwayName', pathwayName, ...
    'bandHz', [NaN NaN], ...
    'targetRangeRad', [NaN NaN], ...
    'shiftRad', 0, ...
    'anchorValueBefore', NaN, ...
    'anchorValueAfter', NaN, ...
    'numAnchorPoints', 0);

end


function [bandHz, targetRangeRad, hasAnchorConfig] = anchorConfigForPathway( ...
    phaseSettings, pathwayName)

hasAnchorConfig = true;

if pathwayName == "map" && isfield(phaseSettings.anchor, 'map')
    anchorConfig = phaseSettings.anchor.map;
elseif pathwayName == "co2" && isfield(phaseSettings.anchor, 'co2')
    anchorConfig = phaseSettings.anchor.co2;
else
    hasAnchorConfig = false;
    bandHz = [NaN NaN];
    targetRangeRad = [NaN NaN];
    return
end

bandHz = anchorConfig.bandHz;
targetRangeRad = anchorConfig.targetRangeRad;

end
