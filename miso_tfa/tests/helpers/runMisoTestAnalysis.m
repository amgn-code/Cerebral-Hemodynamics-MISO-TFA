function results = runMisoTestAnalysis(signalData, unwrapMethod)
% runMisoTestAnalysis Run the MISO pipeline with test settings.

phaseSettings = createTestPhaseSettings(unwrapMethod);
welchSettings = createTestWelchSettings();
spectra = estimateWelchSpectra( ...
    signalData.map, signalData.co2, signalData.cbv, signalData.fs, ...
    welchSettings);

results = runMISOTFA(spectra, phaseSettings);

end
