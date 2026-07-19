function subjectResults = runSingleSubjectTFA( ...
    subjectInfo, analysisSettings, outputSettings)
% runSingleSubjectTFA Load and analyze one subject dataset.

    try
        signalData = loadData(subjectInfo.sourceFile);
    catch errorInfo
        error('TFA:LoadDataFailed', ...
            'LoadDataFailed: %s', errorInfo.message);
    end

    subjectResults = runSubjectTFA( ...
        signalData, subjectInfo, analysisSettings, outputSettings);

end
