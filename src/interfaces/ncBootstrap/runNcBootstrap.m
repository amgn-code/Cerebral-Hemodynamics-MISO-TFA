function results = runNcBootstrap(dataFolder, settings)
% runNcBootstrap Run the NC subject bootstrap and blocked validation.

    if nargin < 1 || isempty(dataFolder)
        error( ...
            "TFA:MissingNCDataFolder", ...
            "Provide the folder that contains the NC subfolder.");
    end
    if nargin < 2 || isempty(settings)
        settings = defaultNcBootstrapSettings();
    else
        settings = completeNcBootstrapSettings(settings);
    end

    dataFolder = string(dataFolder);
    if ~isscalar(dataFolder) || strlength(dataFolder) == 0 || ...
            ~isfolder(dataFolder)
        error( ...
            "TFA:MissingNCDataFolder", ...
            "The NC data folder does not exist: %s", dataFolder);
    end

    subjectList = findIEEMSubjects(dataFolder, settings.group);
    numSubjects = height(subjectList);
    subjectResults = repmat( ...
        createEmptySubjectResultForBatch(subjectList(1,:)), ...
        numSubjects, 1);

    frequencyHz = [];
    sisoErrorCells = cell(numSubjects, 1);
    misoErrorCells = cell(numSubjects, 1);

    for subjectIndex = 1:numSubjects
        subjectInfo = subjectList(subjectIndex, :);
        try
            subjectResults(subjectIndex) = ...
                runNcSubjectBlockedValidation(subjectInfo, settings);
        catch errorInfo
            if settings.execution.stopOnSubjectError
                rethrow(errorInfo)
            end

            subjectResults(subjectIndex) = ...
                createFailedSubjectResult(subjectInfo, errorInfo);
        end

        currentResult = subjectResults(subjectIndex);
        if currentResult.status ~= "Completed"
            continue
        end

        if isempty(frequencyHz)
            frequencyHz = currentResult.frequencyHz(:);
        end

        if numel(currentResult.frequencyHz) ~= numel(frequencyHz) || ...
                any(currentResult.frequencyHz(:) ~= frequencyHz)
            subjectResults(subjectIndex).status = "FrequencyMismatch";
            subjectResults(subjectIndex).statusMessage = ...
                "Subject frequency grid does not match the first completed subject.";
            continue
        end

        sisoErrorCells{subjectIndex} = currentResult.sisoError(:).';
        misoErrorCells{subjectIndex} = currentResult.misoError(:).';
    end

    if isempty(frequencyHz)
        error( ...
            "TFA:NoCompletedNCSubjects", ...
            "No NC subject completed the blocked validation protocol.");
    end

    sisoErrors = NaN(numSubjects, numel(frequencyHz));
    misoErrors = NaN(numSubjects, numel(frequencyHz));
    for subjectIndex = 1:numSubjects
        if isempty(sisoErrorCells{subjectIndex})
            continue
        end
        sisoErrors(subjectIndex, :) = sisoErrorCells{subjectIndex};
        misoErrors(subjectIndex, :) = misoErrorCells{subjectIndex};
    end

    summary = summarizeNcBootstrap( ...
        frequencyHz, sisoErrors, misoErrors, settings);
    frequencyTable = createNcFrequencyTable(summary);

    results.dataFolder = dataFolder;
    results.group = string(settings.group);
    results.settings = settings;
    results.subjectList = subjectList;
    results.subjectResults = subjectResults;
    results.statusTable = createNcStatusTable(subjectResults);
    results.frequencyHz = summary.frequencyHz;
    results.subjectSisoError = sisoErrors;
    results.subjectMisoError = misoErrors;
    results.summary = summary;
    results.frequencyTable = frequencyTable;
    results.figureHandle = [];

end

function settings = completeNcBootstrapSettings(settings)
% completeNcBootstrapSettings Fill omitted public settings from defaults.

    defaults = defaultNcBootstrapSettings();
    settingFields = fieldnames(defaults);
    for fieldIndex = 1:numel(settingFields)
        fieldName = settingFields{fieldIndex};
        if ~isfield(settings, fieldName)
            settings.(fieldName) = defaults.(fieldName);
        end
    end

    analysisFields = fieldnames(defaults.analysis);
    for fieldIndex = 1:numel(analysisFields)
        fieldName = analysisFields{fieldIndex};
        if ~isfield(settings.analysis, fieldName)
            settings.analysis.(fieldName) = defaults.analysis.(fieldName);
        end
    end

    validationFields = fieldnames(defaults.validation);
    for fieldIndex = 1:numel(validationFields)
        fieldName = validationFields{fieldIndex};
        if ~isfield(settings.validation, fieldName)
            settings.validation.(fieldName) = ...
                defaults.validation.(fieldName);
        end
    end

    bootstrapFields = fieldnames(defaults.bootstrap);
    for fieldIndex = 1:numel(bootstrapFields)
        fieldName = bootstrapFields{fieldIndex};
        if ~isfield(settings.bootstrap, fieldName)
            settings.bootstrap.(fieldName) = ...
                defaults.bootstrap.(fieldName);
        end
    end

    plotFields = fieldnames(defaults.plot);
    for fieldIndex = 1:numel(plotFields)
        fieldName = plotFields{fieldIndex};
        if ~isfield(settings.plot, fieldName)
            settings.plot.(fieldName) = defaults.plot.(fieldName);
        end
    end

    validateNcBootstrapSettings(settings);

end

function validateNcBootstrapSettings(settings)
% validateNcBootstrapSettings Validate choices that define the protocol.

    if ~isstruct(settings.analysis) || ...
            ~isstruct(settings.validation) || ...
            ~isstruct(settings.bootstrap)
        error( ...
            "TFA:InvalidNCBootstrapSettings", ...
            "NC bootstrap settings contain invalid nested fields.");
    end

    if settings.validation.numFolds ~= 3
        error( ...
            "TFA:InvalidNCFoldCount", ...
            "The current NC protocol requires exactly three folds.");
    end
    if settings.validation.blockLengthSeconds <= 0 || ...
            settings.analysis.pwelch.windowLengthSeconds ~= ...
            settings.validation.blockLengthSeconds || ...
            settings.analysis.pwelch.windowOverlap ~= 0
        error( ...
            "TFA:InvalidNCBlockProtocol", ...
            "Block length must equal the Welch window and use zero overlap.");
    end
    if settings.bootstrap.numSamples < 2 || ...
            settings.bootstrap.randomSeed < 0 || ...
            settings.bootstrap.confidenceLevel <= 0 || ...
            settings.bootstrap.confidenceLevel >= 1
        error( ...
            "TFA:InvalidNCBootstrapOptions", ...
            "Bootstrap samples, seed, and confidence level are invalid.");
    end

end

function result = createEmptySubjectResultForBatch(subjectInfo)
    result.subjectID = string(subjectInfo.SubjectID);
    result.group = string(subjectInfo.Group);
    result.sourceFile = string(subjectInfo.SourceFile);
    result.status = "NotStarted";
    result.statusMessage = "";
    result.numFoldsCompleted = 0;
    result.numValidFrequencyBins = 0;
    result.recordingDurationSeconds = NaN;
    result.co2StartupRemovedSeconds = NaN;
    result.welchWindowLengthSeconds = NaN;
    result.welchWindowCountForTraining = NaN;
    result.frequencyHz = [];
    result.foldSisoError = [];
    result.foldMisoError = [];
    result.sisoError = [];
    result.misoError = [];
    result.advantage = [];
end

function result = createFailedSubjectResult(subjectInfo, errorInfo)
    result = createEmptySubjectResultForBatch(subjectInfo);
    result.status = "Failed";
    result.statusMessage = string(errorInfo.message);
end

function statusTable = createNcStatusTable(subjectResults)
    statusTable = table( ...
        string({subjectResults.subjectID}).', ...
        string({subjectResults.status}).', ...
        string({subjectResults.statusMessage}).', ...
        [subjectResults.numFoldsCompleted].', ...
        [subjectResults.numValidFrequencyBins].', ...
        [subjectResults.recordingDurationSeconds].', ...
        [subjectResults.co2StartupRemovedSeconds].', ...
        'VariableNames', { ...
            'SubjectID', 'Status', 'StatusMessage', ...
            'NumFoldsCompleted', 'NumValidFrequencyBins', ...
            'RecordingDurationSeconds', 'Co2StartupRemovedSeconds'});
end

function frequencyTable = createNcFrequencyTable(summary)
    frequencyTable = table( ...
        summary.frequencyHz, ...
        summary.sisoMean, ...
        summary.misoMean, ...
        summary.advantage, ...
        summary.sisoSD, ...
        summary.misoSD, ...
        summary.bootstrapSD, ...
        summary.ciLower, ...
        summary.ciUpper, ...
        summary.validSubjectN, ...
        'VariableNames', { ...
            'FrequencyHz', 'SISOErrorMean', 'MISOErrorMean', ...
            'Advantage', 'SISOErrorSD', 'MISOErrorSD', ...
            'BootstrapSD', 'CILower', 'CIUpper', ...
            'ValidSubjectN'});
end
