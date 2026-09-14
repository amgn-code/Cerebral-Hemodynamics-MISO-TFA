function results = runSisoRealData(dataOrFile, analysisSettings)
% runSisoRealData Run the SISO models on one user recording.

    if nargin < 1 || isempty(dataOrFile)
        error( ...
            "TFA:MissingInputFile", ...
            "Provide a file path or the output of connectTfaData.");
    end
    if nargin < 2
        analysisSettings = defaultSisoRealDataSettings();
    end

    results = runRealDataModel( ...
        dataOrFile, analysisSettings, "SISO");

end
