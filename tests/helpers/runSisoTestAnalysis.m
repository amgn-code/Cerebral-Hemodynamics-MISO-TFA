function results = runSisoTestAnalysis(signalData, unwrapMethod)
% runSisoTestAnalysis Run the SISO pipeline with test settings.

phaseSettings = createTestPhaseSettings(unwrapMethod);

results = runSISOTFA( ...
    signalData.map, signalData.co2, signalData.cbv, signalData.fs, ...
    128, 0.5, phaseSettings);

end
