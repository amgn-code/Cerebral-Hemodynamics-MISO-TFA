function settings = defaultMisoRealDataSettings()
% defaultMisoRealDataSettings Return settings for a user MISO analysis.

    settings = defaultTfaAnalysisSettings("NC");
    settings.runMISO = true;
    settings.runSISO = false;
    settings.retainAnalysisInput = true;
    settings.statistics.enabled = false;
    settings.plot = defaultPlotSettings("none");

end
