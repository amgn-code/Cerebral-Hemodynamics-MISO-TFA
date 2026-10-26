function results = runMisoRealData(dataOrFile, analysisSettings)
% runMisoRealData Run the MISO model on one user recording.

    if nargin < 1 || isempty(dataOrFile)
        error( ...
            "TFA:MissingInputFile", ...
            "Provide a file path or the output of connectTfaData.");
    end
    if nargin < 2
        analysisSettings = defaultMisoRealDataSettings();
    end

    results = runRealDataModel( ...
        dataOrFile, analysisSettings, "MISO");

end
