function results = runMisoSisoRealData( ...
    dataOrFile, interfaceSettings)
% runMisoSisoRealData Run separate MISO and SISO interfaces on one file.
%
% The recording is connected once. The two model interfaces retain separate
% settings and return their own run status and analysis inputs.

    if nargin < 1 || isempty(dataOrFile)
        error( ...
            "TFA:MissingInputFile", ...
            "Provide a file path or the output of connectTfaData.");
    end
    if nargin < 2 || isempty(interfaceSettings)
        interfaceSettings = defaultRealDataInterfaceSettings();
    end
    validateRealDataInterfaceSettings(interfaceSettings);

    if isstruct(dataOrFile) && isfield(dataOrFile, "signalData")
        connectedData = dataOrFile;
    else
        connectedData = connectTfaData(dataOrFile);
    end

    misoRun = runMisoRealData( ...
        connectedData, interfaceSettings.miso);
    sisoRun = runSisoRealData( ...
        connectedData, interfaceSettings.siso);

    results.subjectInfo = connectedData.subjectInfo;
    results.userInputFile = connectedData.filePath;
    results.rawSignalData = connectedData.signalData;
    results.misoResults = misoRun.misoResults;
    results.sisoResults = sisoRun.sisoResults;
    results.misoRunStatus = misoRun.runStatus;
    results.sisoRunStatus = sisoRun.runStatus;
    results.misoSettings = misoRun.analysisSettings;
    results.sisoSettings = sisoRun.analysisSettings;
    results.analysisInput.miso = misoRun.analysisInput;
    results.analysisInput.siso = sisoRun.analysisInput;
    results.physiology = misoRun.physiology;
    results.co2Startup = misoRun.co2Startup;
    results.outputFolder = "";
    results.runStatus = combineRunStatus( ...
        misoRun.runStatus, sisoRun.runStatus);

end

function validateRealDataInterfaceSettings(interfaceSettings)
% validateRealDataInterfaceSettings Check the public nested settings.

    if ~isstruct(interfaceSettings) || ...
            ~isfield(interfaceSettings, "miso") || ...
            ~isfield(interfaceSettings, "siso")
        error( ...
            "TFA:InvalidRealDataInterfaceSettings", ...
            "Settings must contain separate miso and siso fields.");
    end

end

function runStatus = combineRunStatus(misoStatus, sisoStatus)
% combineRunStatus Summarize the two independent model runs.

    runStatus = misoStatus;
    runStatus.analysisSucceeded = ...
        misoStatus.analysisSucceeded && sisoStatus.analysisSucceeded;
    runStatus.statusMessage = ...
        "MISO: " + string(misoStatus.statusMessage) + ...
        "; SISO: " + string(sisoStatus.statusMessage);
    runStatus.subjectFiguresSaved = ...
        misoStatus.subjectFiguresSaved || sisoStatus.subjectFiguresSaved;

end
