function settings = defaultSisoRealDataSettings()
% defaultSisoRealDataSettings Return settings for a user SISO analysis.

    settings = defaultTfaAnalysisSettings("NC");
    settings.runMISO = false;
    settings.runSISO = true;
    settings.retainAnalysisInput = true;
    settings.statistics.enabled = false;
    settings.plot = defaultPlotSettings("none");

end
