function results = runRealDataModel( ...
    connectedData, analysisSettings, modelName)
% runRealDataModel Run one model interface on connected user data.

    modelName = upper(string(modelName));
    if ~ismember(modelName, ["MISO" "SISO"])
        error( ...
            "TFA:UnknownRealDataModel", ...
            'modelName must be "MISO" or "SISO".');
    end

    if nargin < 2 || isempty(analysisSettings)
        if modelName == "MISO"
            analysisSettings = defaultMisoRealDataSettings();
        else
            analysisSettings = defaultSisoRealDataSettings();
        end
    end

    if ~isstruct(connectedData) || ...
            ~isfield(connectedData, "signalData") || ...
            ~isfield(connectedData, "subjectInfo")
        connectedData = connectTfaData(connectedData);
    end

    % The model-specific interface owns model selection. A caller can still
    % edit the shared frequency, Welch, preprocessing, and phase settings.
    analysisSettings.runMISO = modelName == "MISO";
    analysisSettings.runSISO = modelName == "SISO";
    analysisSettings.retainAnalysisInput = true;
    if ~isfield(analysisSettings, "statistics")
        analysisSettings.statistics = struct();
    end
    analysisSettings.statistics.enabled = false;
    analysisSettings.plot = defaultPlotSettings("none");
    analysisSettings = validateTfaSettings(analysisSettings);

    outputSettings = defaultTfaOutputSettings("", "none");
    outputSettings.saveSubjectFigures = false;
    outputSettings.saveBatchFigures = false;
    outputSettings.saveExcel = false;

    results = analyzeSubjectTFA( ...
        connectedData.signalData, connectedData.subjectInfo, ...
        analysisSettings, outputSettings);

    results.interfaceModel = modelName;
    results.analysisSettings = analysisSettings;
    results.userInputFile = connectedData.filePath;
    results.rawSignalData = connectedData.signalData;
    results.outputFolder = "";

end
