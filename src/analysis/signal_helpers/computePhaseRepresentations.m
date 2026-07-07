function phaseData = computePhaseRepresentations( ...
    transferValues, f, coherence, coherenceThreshold, phaseSettings, pathwayName)
% computePhaseRepresentations Compute wrapped, unwrapped, and anchored phase.

phaseSettings = normalizePhaseSettings(phaseSettings);
unwrapMethod = phaseSettings.unwrapMethod;

phaseWrapped = unwrapPhase(transferValues, "complex", "wrapped");
phaseUnwrapped = unwrapPhase( ...
    transferValues, "complex", unwrapMethod, coherence, coherenceThreshold, ...
    f, phaseSettings.localWeighted);
[phaseAnchored, anchorInfo] = anchorPhaseCurve( ...
    phaseUnwrapped, f, coherence, phaseSettings, pathwayName);

if phaseSettings.anchor.enabled && anchorInfo.applied
    phaseDisplay = phaseAnchored;
else
    phaseDisplay = phaseUnwrapped;
end

phaseData = struct();
phaseData.wrapped = phaseWrapped;
phaseData.unwrapped = phaseUnwrapped;
phaseData.anchored = phaseAnchored;
phaseData.display = phaseDisplay;
phaseData.anchorInfo = anchorInfo;

end
