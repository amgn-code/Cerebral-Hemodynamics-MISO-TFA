function subjectResults = runSelectedWorkflow( ...
    outputFolder, runMISO, runSISO)
% runSelectedWorkflow Run the subject workflow with selected test models.

    [analysisSettings, outputSettings] = createWorkflowTestSettings( ...
        outputFolder, runMISO, runSISO);
    signalData = createTestSignal(analysisSettings.fsTarget);

    subjectInfo.subjectID = "test";
    subjectInfo.group = "LC";
    subjectInfo.session = "simulation";
    subjectInfo.sourceFile = "Generated test signal";

    subjectResults = runSubjectTFA( ...
        signalData, subjectInfo, analysisSettings, outputSettings);

end
