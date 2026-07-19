function saveSubjectResultsToExcel( ...
    filename, subjectInfo, runStatus, misoResults, sisoResults, ...
    outputSettings)
% saveSubjectResultsToExcel Write one subject's results workbook.

    if exist(filename, "file")
        delete(filename);
    end

    status = {
        "SubjectID", string(subjectInfo.subjectID);
        "Group", string(subjectInfo.group);
        "Session", string(subjectInfo.session);
        "SourceFile", string(subjectInfo.sourceFile);
        "AnalysisSucceeded", string(runStatus.analysisSucceeded);
        "RunStage", string(runStatus.runStage);
        "StatusMessage", string(runStatus.statusMessage);
        "SignalDurationSeconds", runStatus.signalDurationSeconds;
        "NumWelchWindows", runStatus.numWelchWindows;
        "MinimumWelchWindows", runStatus.minimumWelchWindows;
        "WindowLengthSeconds", runStatus.windowLengthSeconds;
        "WindowOverlap", runStatus.windowOverlap;
        "RunMISO", string(runStatus.runMISO);
        "RunSISO", string(runStatus.runSISO);
        "CBVBaseline_cm_per_s", runStatus.cbvBaselineCmPerSec;
        "CBVUnits", string(runStatus.cbvUnits);
        "MISO_CoherenceThreshold", runStatus.misoCoherenceThreshold;
        "SISO_CoherenceThreshold", runStatus.sisoCoherenceThreshold;
        "MISO_CoherenceThresholdSource", ...
            string(runStatus.misoCoherenceThresholdSource);
        "SISO_CoherenceThresholdSource", ...
            string(runStatus.sisoCoherenceThresholdSource)
    };

    writecell(status, filename, "Sheet", "Status", "Range", "A1");

    if ~runStatus.analysisSucceeded
        return
    end

    if outputSettings.runMISO
        writetable(misoResults.bandAverages, filename, "Sheet", "MISO_Bands");

        if outputSettings.saveFullFrequencyData
            misoFullTable = createMisoFullFrequencyTable( ...
                misoResults, ...
                outputSettings.frequencyBandEdgesHz, ...
                outputSettings.frequencyBandNames);
            writetable(misoFullTable, filename, "Sheet", "MISO_Full");
        end
    end

    if outputSettings.runSISO
        writetable(sisoResults.bandAverages, filename, "Sheet", "SISO_Bands");

        if outputSettings.saveFullFrequencyData
            sisoFullTable = createSisoFullFrequencyTable( ...
                sisoResults, ...
                outputSettings.frequencyBandEdgesHz, ...
                outputSettings.frequencyBandNames);
            writetable(sisoFullTable, filename, "Sheet", "SISO_Full");
        end
    end

    if outputSettings.runMISO && outputSettings.runSISO
        comparisonTable = createModelComparisonTable( ...
            misoResults, sisoResults);
        writetable(comparisonTable, filename, "Sheet", "MISO_vs_SISO");
    end

end
