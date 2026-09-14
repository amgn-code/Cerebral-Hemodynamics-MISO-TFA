function results = runSisoTestAnalysis(signalData, unwrapMethod)
% runSisoTestAnalysis Run the SISO pipeline with test settings.

phaseSettings = createTestPhaseSettings(unwrapMethod);
welchSettings = createTestWelchSettings();
spectra = estimateWelchSpectra( ...
    signalData.map, signalData.co2, signalData.cbv, signalData.fs, ...
    welchSettings);

results = runSISOTFA(spectra, phaseSettings);

end
