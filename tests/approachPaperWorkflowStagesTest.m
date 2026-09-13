classdef approachPaperWorkflowStagesTest < matlab.unittest.TestCase
    % approachPaperWorkflowStagesTest Verify reusable workflow stages.

    methods (TestClassSetup)
        function addProjectFolders(testCase)
            projectRoot = fileparts(fileparts(mfilename("fullpath")));
            testCase.applyFixture( ...
                matlab.unittest.fixtures.PathFixture( ...
                    projectRoot, IncludingSubfolders=true));
        end
    end

    methods (Test)
        function wrapperSavesAnalysisBeforeOutputs(testCase)
            outputFolder = createTemporaryFolder(testCase);
            settings = makeNoAnalysisSettings(outputFolder);

            paperResults = runApproachPaper(settings);
            savedAnalysis = load( ...
                paperResults.analysisResultFile, "paperResults");
            savedFinal = load(paperResults.resultFile, "paperResults");

            testCase.verifyTrue(isfile( ...
                fullfile(outputFolder, ...
                    "approach_paper_analysis_results.mat")));
            testCase.verifyTrue(isfile( ...
                fullfile(outputFolder, "approach_paper_results.mat")));
            testCase.verifyTrue(isfile( ...
                fullfile(outputFolder, ...
                    "reproducibility_manifest.csv")));
            testCase.verifyEqual( ...
                savedAnalysis.paperResults.analysisResultFile, ...
                paperResults.analysisResultFile);
            testCase.verifyEqual( ...
                savedFinal.paperResults.resultFile, ...
                paperResults.resultFile);
        end

        function regenerationUsesSavedAnalyses(testCase)
            analysisFolder = createTemporaryFolder(testCase);
            renderFolder = createTemporaryFolder(testCase);
            settings = makeNoAnalysisSettings(analysisFolder);
            sourceResults = runApproachPaper(settings);
            sourceAnalysis = load( ...
                sourceResults.analysisResultFile, "paperResults");
            overrides = struct( ...
                "outputFolder", string(renderFolder), ...
                "createTables", false, ...
                "createFigures", false);

            regenerated = regenerateApproachPaperOutputs( ...
                sourceResults.analysisResultFile, overrides);

            testCase.verifyEqual( ...
                regenerated.empirical, ...
                sourceAnalysis.paperResults.empirical);
            testCase.verifyEqual( ...
                regenerated.simulation, ...
                sourceAnalysis.paperResults.simulation);
            testCase.verifyEqual( ...
                regenerated.robustness, ...
                sourceAnalysis.paperResults.robustness);
            testCase.verifyEqual( ...
                regenerated.settings.outputFolder, ...
                string(analysisFolder));
            testCase.verifyEqual( ...
                regenerated.outputSettings.outputFolder, ...
                string(renderFolder));
            testCase.verifyEqual( ...
                regenerated.sourceAnalysisResultFile, ...
                sourceResults.analysisResultFile);
            testCase.verifyTrue(isfile(regenerated.resultFile));
        end

        function regenerationRejectsNumericalOverrides(testCase)
            outputFolder = createTemporaryFolder(testCase);
            settings = makeNoAnalysisSettings(outputFolder);
            sourceResults = runApproachPaper(settings);
            overrides.analysis = struct("fsTarget", 8);

            testCase.verifyError( ...
                @() regenerateApproachPaperOutputs( ...
                    sourceResults.analysisResultFile, overrides), ...
                "TFA:InvalidRenderOverride");
        end

        function regenerationRendersSavedResults(testCase)
            analysisFolder = createTemporaryFolder(testCase);
            renderFolder = createTemporaryFolder(testCase);
            settings = makeNoAnalysisSettings(analysisFolder);
            sourceResults = runApproachPaper(settings);
            exportOverrides = struct( ...
                "widthInches", 4, ...
                "heightInches", 3, ...
                "pngResolution", 72, ...
                "savePdf", false, ...
                "savePng", true, ...
                "saveFigureSourceData", false);
            overrides = struct( ...
                "outputFolder", string(renderFolder), ...
                "createTables", false, ...
                "createFigures", true, ...
                "export", exportOverrides);

            regenerated = regenerateApproachPaperOutputs( ...
                sourceResults.analysisResultFile, overrides);

            testCase.verifyGreaterThan( ...
                numel(regenerated.figureFiles), 0);
            testCase.verifyTrue(all(isfile(regenerated.figureFiles)));
            testCase.verifyTrue(isfile( ...
                regenerated.plotResults.manifestFile));
            testCase.verifyTrue(isfile( ...
                regenerated.plotResults.captionCatalogFile));
            testCase.verifyTrue(all(isfile( ...
                regenerated.plotResults.manifest.CaptionFile)));
        end

        function regenerationRequiresPaperResultsVariable(testCase)
            outputFolder = createTemporaryFolder(testCase);
            invalidFile = fullfile(outputFolder, "invalid_results.mat");
            unrelatedValue = 1;
            save(invalidFile, "unrelatedValue");

            testCase.verifyError( ...
                @() regenerateApproachPaperOutputs(invalidFile), ...
                "TFA:MissingApproachPaperResults");
        end

        function tinySimulationStageReturnsRawResults(testCase)
            outputFolder = createTemporaryFolder(testCase);
            settings = makeTinySimulationSettings(outputFolder);

            paperResults = runApproachPaper(settings);

            testCase.verifyEqual( ...
                height(paperResults.simulation.familyDesign), 1);
            testCase.verifyEqual( ...
                height(paperResults.simulation.observations), 1);
            testCase.verifyGreaterThan( ...
                numel(paperResults.tables.savedFiles), 0);
            testCase.verifyTrue(all(isfile( ...
                paperResults.tables.savedFiles)));
            testCase.verifyTrue(isfield( ...
                paperResults, "simulationAudit"));
            testCase.verifyTrue(isfile( ...
                paperResults.simulationAudit.reportFile));
            testCase.verifyTrue(ismember( ...
                "simulationAuditOverview", ...
                string(fieldnames(paperResults.tables))));
            testCase.verifyTrue(isfile(paperResults.analysisResultFile));
            testCase.verifyTrue(isfile(paperResults.resultFile));
        end
    end
end

function outputFolder = createTemporaryFolder(testCase)
% createTemporaryFolder Register removal of a test output folder.

    outputFolder = string(tempname());
    mkdir(outputFolder);
    testCase.addTeardown(@() rmdir(outputFolder, "s"));

end

function settings = makeNoAnalysisSettings(outputFolder)
% makeNoAnalysisSettings Build a fast workflow-only test configuration.

    settings = approachPaperSettings("", outputFolder, "quick");
    settings.steps.runEmpiricalAnalysis = false;
    settings.steps.runKnownTruthSimulation = false;
    settings.steps.runRobustnessAnalysis = false;
    settings.steps.createTables = false;
    settings.steps.createFigures = false;

end

function settings = makeTinySimulationSettings(outputFolder)
% makeTinySimulationSettings Run one family under one observation setting.

    settings = makeNoAnalysisSettings(outputFolder);
    settings.steps.runKnownTruthSimulation = true;
    settings.steps.createTables = true;
    settings.simulation.families.numFamilies = 1;
    settings.simulation.families.progressEvery = 1;
    settings.simulation.observations.durationSeconds = 300;
    settings.simulation.observations.referenceDurationSeconds = 300;
    settings.simulation.observations.outputSnrDb = Inf;
    settings.simulation.observations.referenceOutputSnrDb = Inf;
    settings.simulation.observations.runInputNoiseExperiment = false;
    settings.simulation.observations.runAlignmentExperiment = false;
    settings.simulation.estimatorSensitivity.enabled = false;
    settings.simulation.estimators.ridgeLambdas = [];
    settings.simulation.storage.retainFrequencyResults = false;
    settings.simulation.storage.retainExampleFamily = false;

end
