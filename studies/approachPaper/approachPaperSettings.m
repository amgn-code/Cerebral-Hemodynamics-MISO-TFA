function settings = approachPaperSettings( ...
    dataFolder, outputFolder, profileName)
% approachPaperSettings Create all user-facing settings for Paper 1.
%
% Example:
%   settings = approachPaperSettings( ...
%       "/path/to/ieem_data", "/path/to/paper_results", "quick");
%   paperResults = runApproachPaper(settings);
%
% Use "quick" while checking code and figures. Use "paper" only for the
% final, larger simulation and surrogate analyses.

    if nargin < 1
        dataFolder = "";
    end
    if nargin < 2
        outputFolder = "";
    end
    if nargin < 3
        profileName = "quick";
    end
    profileName = lower(string(profileName));

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

    settings.batch.dataFolder = settings.dataFolder;
    settings.batch.groupsToRun = "NC";
    settings.batch.targetSuccessfulSubjectsPerGroup = Inf;
    settings.batch.previewOnly = false;
    settings.batch.numSubjectFiguresPerGroup = "none";

    settings.analysis.runMISO = true;
    settings.analysis.runSISO = true;
    settings.analysis.frequencyRangeHz = [0 0.35];
    settings.analysis.frequencyBandEdgesHz = ...
        [0.005; 0.024; 0.070; 0.200; 0.350];
    settings.analysis.frequencyBandNames = ...
        ["VVLF"; "VLF"; "LF"; "HF"];
    settings.analysis.fsTarget = 4;

    settings.analysis.preprocessing.normalizeCbv = true;
    settings.analysis.preprocessing.detrendEnabled = false;
    settings.analysis.preprocessing.detrendOrder = 1;
    settings.analysis.preprocessing.meanRemovalEnabled = true;

    settings.analysis.pwelch.windowLengthSeconds = 128;
    settings.analysis.pwelch.windowOverlap = 0.5;
    settings.analysis.pwelch.minimumWindows = 3;
    settings.analysis.pwelch.smoothingEnabled = true;
    settings.analysis.pwelch.smoothingKernel = [0.25 0.50 0.25];

    settings.analysis.phase.unwrapMethod = "standard";
    settings.analysis.phase.custom.windowSize = 11;
    settings.analysis.phase.custom.numPasses = 3;
    settings.analysis.phase.custom.useCoherenceWeights = true;
    settings.analysis.phase.custom.weightMode = "power";
    settings.analysis.phase.custom.weightPower = 4;
    settings.analysis.phase.custom.expAlpha = 4;
    settings.analysis.phase.custom.minWeight = 0.01;

    settings.analysis.misoSolver = defaultMisoSolverSettings();
    settings.analysis.retainAnalysisInput = true;

    %% NC-Only Statistical Plan

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

    settings.analysis.plot = defaultPlotSettings();

    %% Standard Pipeline Output

    settings.output.baseOutputFolder = settings.outputFolder;
    settings.output.saveSubjectFigures = false;
    settings.output.saveBatchFigures = false;
    settings.output.saveExcel = false;
    settings.output.excelFileName = "approach_paper_pipeline_results.xlsx";
    settings.output.excelStatistics = false;

    %% Known-Truth Simulation

    settings.simulation = ...
        defaultKnownTruthSimulationSettings(profileName);
    settings.simulation.frequencyRangeHz = ...
        settings.analysis.frequencyRangeHz;
    settings.simulation.frequencyBandEdgesHz = ...
        settings.analysis.frequencyBandEdgesHz;
    settings.simulation.frequencyBandNames = ...
        settings.analysis.frequencyBandNames;
    settings.simulation.welch = settings.analysis.pwelch;
    settings.simulation.phase = settings.analysis.phase;

    %% Empirical Robustness Checks

    settings.robustness.randomSeed = 2026;
    settings.robustness.delaysSeconds = [0 3 6];
    settings.robustness.lambdas = [0 0.0001 0.001 0.01 0.1 1];
    settings.robustness.sensitivityVariants = ...
        defaultSensitivityVariants();

    if profileName == "quick"
        settings.robustness.numSurrogates = 20;
    elseif profileName == "paper"
        settings.robustness.numSurrogates = 1000;
    else
        error( ...
            "TFA:UnknownApproachPaperProfile", ...
            "profileName must be ""quick"" or ""paper"".");
    end
    settings.robustness.minimumShiftSeconds = 30;

    %% Publication Export

    settings.export.widthInches = 7.2;
    settings.export.heightInches = 7.2;
    settings.export.pngResolution = 600;
    settings.export.savePdf = true;
    settings.export.savePng = true;
    settings.export.saveFigureSourceData = true;
    % A value of 2 displays error ratios from 0.01 to 100 on the common
    % blue-white-orange model-advantage color scale.
    settings.export.advantageColorLimit = 2;

end
