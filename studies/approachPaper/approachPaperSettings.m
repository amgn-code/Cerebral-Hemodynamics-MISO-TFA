function settings = approachPaperSettings( ...
    dataFolder, outputFolder, profileName, baseAnalysisSettings)
% approachPaperSettings Create all user-facing settings for Paper 1.
%
% Example:
%   settings = approachPaperSettings( ...
%       "/path/to/ieem_data", "/path/to/paper_results", "quick");
%   paperResults = runApproachPaper(settings);
%
% Use "quick" for unit checks, "designSmoke" for one balanced block,
% "proof250" for the presentation proof of concept, and "paper1000" for
% the likely final-paper analysis. Historical "paper" remains an alias for
% "paper1000".

    if nargin < 1
        dataFolder = "";
    end
    if nargin < 2
        outputFolder = "";
    end
    if nargin < 3
        profileName = "quick";
    end
    if nargin < 4
        baseAnalysisSettings = defaultTfaAnalysisSettings("NC");
    end
    simulationDefaults = ...
        defaultKnownTruthSimulationSettings(profileName);
    profileName = simulationDefaults.profileName;

    settings.profileName = profileName;
    settings.dataFolder = string(dataFolder);
    settings.outputFolder = string(outputFolder);

    %% Select Which Parts to Run

    settings.steps.runEmpiricalAnalysis = true;
    settings.steps.runKnownTruthSimulation = true;
    settings.steps.runRobustnessAnalysis = true;
    settings.steps.createTables = true;
    settings.steps.createFigures = true;

    %% NC Batch Analysis

    settings.batch = defaultTfaBatchSettings(settings.dataFolder, "NC");
    settings.batch.numSubjectFiguresPerGroup = "none";

    settings.analysis = baseAnalysisSettings;
    settings.analysis.runMISO = true;
    settings.analysis.runSISO = true;
    settings.analysis.retainAnalysisInput = true;

    %% NC-Only Statistical Plan

    settings.analysis.statistics = struct();
    settings.analysis.statistics.enabled = true;
    settings.analysis.statistics.alpha = 0.05;
    settings.analysis.statistics.numPhasePermutations = 10000;
    settings.analysis.statistics.randomSeed = 2026;
    settings.analysis.statistics.groupsToCompare = "NC";
    settings.analysis.statistics.primaryBandNames = ...
        settings.analysis.frequencyBandNames;
    settings.analysis.statistics.primaryGroups = "NC";
    settings.analysis.statistics.primaryPathways = "MAP";
    settings.analysis.statistics.secondaryPathways = "CO2";
    settings.analysis.statistics.participantDataFile = "";
    settings.analysis.statistics.withinGroupModelComparison.enabled = true;
    settings.analysis.statistics.betweenGroupComparison.enabled = false;

    settings.analysis.statistics.frequencyWise.enabled = true;
    settings.analysis.statistics.frequencyWise.groupComparison.gain = false;
    settings.analysis.statistics.frequencyWise.groupComparison.coherence = ...
        false;
    settings.analysis.statistics.frequencyWise.groupComparison.phase = false;
    settings.analysis.statistics.frequencyWise.modelComparison.gain = true;
    % Phase uses paired circular tests on wrapped MISO-minus-SISO angles.
    % The output also reports the principal equivalent delay difference.
    settings.analysis.statistics.frequencyWise.modelComparison.phase = true;

    settings.analysis.plot = defaultPlotSettings("none");

    %% Standard Pipeline Output

    settings.output = defaultTfaOutputSettings( ...
        settings.outputFolder, "none");
    settings.output.saveSubjectFigures = false;
    settings.output.saveBatchFigures = false;
    settings.output.saveExcel = false;
    settings.output.excelFileName = "approach_paper_pipeline_results.xlsx";
    settings.output.excelStatistics = false;

    %% Known-Truth Simulation

    settings.simulation = applyTfaAnalysisSettingsToSimulation( ...
        simulationDefaults, ...
        settings.analysis);

    %% Empirical Robustness Checks

    settings.robustness.randomSeed = 2026;
    settings.robustness.delaysSeconds = [0 3 6];
    settings.robustness.lambdas = [0 0.0001 0.001 0.01 0.1 1];
    settings.robustness.sensitivityVariants = ...
        defaultSensitivityVariants();

    switch profileName
        case {"quick", "designsmoke"}
            settings.robustness.numSurrogates = 20;
        case "proof250"
            settings.robustness.numSurrogates = 250;
        case "paper1000"
            settings.robustness.numSurrogates = 1000;
    end
    settings.robustness.minimumShiftSeconds = 30;

    %% Publication Export

    settings.export.widthInches = 7.2;
    settings.export.heightInches = 7.2;
    settings.export.pngResolution = 600;
    settings.export.savePdf = true;
    settings.export.savePng = true;
    settings.export.saveFigureSourceData = true;
    settings.export.saveCaptionFiles = true;
    settings.export.saveCaptionCatalog = true;
    % A value of 2 displays error ratios from 0.01 to 100 on the common
    % blue-white-orange model-advantage color scale.
    settings.export.advantageColorLimit = 2;

end
