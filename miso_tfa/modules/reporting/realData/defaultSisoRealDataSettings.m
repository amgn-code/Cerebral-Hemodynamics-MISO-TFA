function settings = defaultSisoRealDataSettings()
% defaultSisoRealDataSettings Return settings for a user SISO analysis.

    settings = defaultTfaNumericalSettings();
    settings.runMISO = false;
    settings.runSISO = true;
    settings.retainAnalysisInput = true;
    settings.statistics.enabled = false;

end
