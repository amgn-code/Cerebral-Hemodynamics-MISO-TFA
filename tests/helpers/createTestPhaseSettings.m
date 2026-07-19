function phaseSettings = createTestPhaseSettings(unwrapMethod)
% createTestPhaseSettings Create phase settings for pipeline tests.

phaseSettings.unwrapMethod = unwrapMethod;
phaseSettings.custom.windowSize = 11;
phaseSettings.custom.numPasses = 3;
phaseSettings.custom.useCoherenceWeights = true;
phaseSettings.custom.weightMode = "power";
phaseSettings.custom.weightPower = 4;
phaseSettings.custom.expAlpha = 4;
phaseSettings.custom.minWeight = 0.01;

end
