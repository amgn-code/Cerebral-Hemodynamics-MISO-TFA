function connectedData = connectTfaData(filePath)
% connectTfaData Load and identify one user-supplied TFA recording.
%
% This is the data connection interface. It owns the file path and column
% loading step; model interfaces receive the returned structure instead of
% repeating file handling.

    if nargin < 1 || isempty(filePath)
        error( ...
            "TFA:MissingInputFile", ...
            "Provide the path to one Excel recording.");
    end

    filePath = string(filePath);
    if ~isscalar(filePath) || strlength(filePath) == 0
        error( ...
            "TFA:MissingInputFile", ...
            "filePath must contain one nonempty Excel file path.");
    end

    if ~isfile(filePath)
        error( ...
            "TFA:MissingInputFile", ...
            "The input file does not exist: %s", filePath);
    end

    signalData = loadSubjectData(filePath);
    [~, subjectID, ~] = fileparts(filePath);

    connectedData.filePath = filePath;
    connectedData.signalData = signalData;
    connectedData.subjectInfo.subjectID = string(subjectID);
    connectedData.subjectInfo.group = "UserData";
    connectedData.subjectInfo.sourceFile = filePath;

end
