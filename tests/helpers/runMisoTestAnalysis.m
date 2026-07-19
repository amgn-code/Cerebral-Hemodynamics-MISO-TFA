function results = runMisoTestAnalysis(signalData, unwrapMethod)
% runMisoTestAnalysis Run the MISO pipeline with test settings.

phaseSettings = createTestPhaseSettings(unwrapMethod);

results = runMISOTFA( ...
    signalData.map, signalData.co2, signalData.cbv, signalData.fs, ...
    128, 0.5, phaseSettings);

end
