function phaseSettings = defaultPhaseSettings()
% defaultPhaseSettings Default phase display and anchoring settings.

phaseSettings.unwrapMethod = "standard";    % "standard" or "localWeighted"

phaseSettings.localWeighted.windowSize = 11;
phaseSettings.localWeighted.numPasses = 3;
phaseSettings.localWeighted.useCoherenceWeights = true;
phaseSettings.localWeighted.weightMode = "power";
phaseSettings.localWeighted.weightPower = 4;
phaseSettings.localWeighted.expAlpha = 4;
phaseSettings.localWeighted.minWeight = 0.01;

phaseSettings.anchor.enabled = false;

phaseSettings.anchor.map.bandHz = [0.05 0.10];
phaseSettings.anchor.map.targetRangeRad = [0 pi/2];

phaseSettings.anchor.co2.bandHz = [0.01 0.05];
phaseSettings.anchor.co2.targetRangeRad = [-pi/2 0];

end
