function saveSubjectRunStatusToExcel(filename, sheetName, subjectInfo, runStatus)

metadata = {
    "SubjectID", string(subjectInfo.subjectID);
    "Group", string(subjectInfo.group);
    "Session", string(subjectInfo.session);
    "SourceFile", string(subjectInfo.sourceFile);
    "AnalysisSucceeded", string(runStatus.analysisSucceeded);
    "RunStage", string(runStatus.runStage);
    "StatusMessage", string(runStatus.statusMessage);
    "IsTooShortForWelch", string(runStatus.isTooShortForWelch);
    "NumWelchWindows", runStatus.numWelchWindows;
    "SignalDurationSeconds", runStatus.signalDurationSeconds;
    "WindowLengthSeconds", runStatus.windowLengthSeconds;
    "WindowOverlap", runStatus.windowOverlap;
    "RunSISO", string(runStatus.runSISO);
    "MISO_UsedDefaultCoherenceThreshold", statusValueToString(runStatus.misoUsedDefaultCoherenceThreshold);
    "SISO_UsedDefaultCoherenceThreshold", statusValueToString(runStatus.sisoUsedDefaultCoherenceThreshold);
    "MISO_CoherenceThreshold", runStatus.misoCoherenceThreshold;
    "SISO_CoherenceThreshold", runStatus.sisoCoherenceThreshold
};

writecell(metadata, filename, ...
    "Sheet", sheetName, ...
    "Range", "A1");

end


function valueString = statusValueToString(value)

    if islogical(value)
        valueString = string(value);
    elseif isnumeric(value) && isnan(value)
        valueString = "";
    else
        valueString = string(value);
    end

end
