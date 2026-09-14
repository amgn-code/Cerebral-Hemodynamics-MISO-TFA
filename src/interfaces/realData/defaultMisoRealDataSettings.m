function settings = defaultMisoRealDataSettings()
% defaultMisoRealDataSettings Return settings for a user MISO analysis.

    settings = defaultTfaNumericalSettings();
    settings.runMISO = true;
    settings.runSISO = false;
    settings.retainAnalysisInput = true;
    settings.statistics.enabled = false;

end
