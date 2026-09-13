function settings = defaultTfaAnalysisSettings(groupsToCompare)
% defaultTfaAnalysisSettings Return a complete ordinary TFA configuration.
%
% This function owns the structural defaults used by main.m, tests, and
% study-specific settings. Users normally select scientific choices in
% main.m and only need to edit this file when changing a project-wide
% default.

    if nargin < 1
        groupsToCompare = ["NC"; "MCI"];
    end

    groupsToCompare = upper(string(groupsToCompare(:)));
    if isempty(groupsToCompare) || numel(groupsToCompare) > 2 || ...
            numel(unique(groupsToCompare)) ~= numel(groupsToCompare)
        error( ...
            "TFA:InvalidDefaultStatisticalGroups", ...
            ['groupsToCompare must contain one or two unique group ' ...
             'names.']);
    end

    %% Models and Frequency Range

    settings.runMISO = true;
    settings.runSISO = true;
    settings.misoSolver = defaultMisoSolverSettings();
    settings.retainAnalysisInput = false;

    settings.fsTarget = 4;
    settings.frequencyRangeHz = [0 0.35];
    settings.frequencyBandEdgesHz = ...
        [0.005; 0.024; 0.070; 0.200; 0.350];
    settings.frequencyBandNames = ["VVLF"; "VLF"; "LF"; "HF"];

    %% Preprocessing, Welch Spectra, and Phase

    settings.preprocessing.normalizeCbv = true;
    settings.preprocessing.detrendEnabled = false;
    settings.preprocessing.detrendOrder = 1;
    settings.preprocessing.meanRemovalEnabled = true;

    settings.pwelch.windowLengthSeconds = 128;
    settings.pwelch.windowOverlap = 0.5;
    settings.pwelch.minimumWindows = 3;
    settings.pwelch.smoothingEnabled = true;
    settings.pwelch.smoothingKernel = [0.25 0.50 0.25];

    settings.phase.unwrapMethod = "standard";
    settings.phase.custom.windowSize = 11;
    settings.phase.custom.numPasses = 3;
    settings.phase.custom.useCoherenceWeights = true;
    settings.phase.custom.weightMode = "power";
    settings.phase.custom.weightPower = 4;
    settings.phase.custom.expAlpha = 4;
    settings.phase.custom.minWeight = 0.01;

    %% Statistical Analysis

    settings.statistics.enabled = true;
    settings.statistics.alpha = 0.05;
    settings.statistics.numPhasePermutations = 10000;
    settings.statistics.randomSeed = 2026;
    settings.statistics.groupsToCompare = groupsToCompare;
    settings.statistics.primaryBandNames = ...
        settings.frequencyBandNames;
    settings.statistics.primaryGroups = groupsToCompare;
    settings.statistics.primaryPathways = ["MAP"; "CO2"];
    settings.statistics.secondaryPathways = strings(0, 1);
    settings.statistics.participantDataFile = "";
    settings.statistics.withinGroupModelComparison.enabled = true;
    settings.statistics.betweenGroupComparison.enabled = ...
        numel(groupsToCompare) == 2;

    settings.statistics.frequencyWise.enabled = true;
    settings.statistics.frequencyWise.groupComparison.gain = true;
    settings.statistics.frequencyWise.groupComparison.coherence = true;
    settings.statistics.frequencyWise.groupComparison.phase = true;
    settings.statistics.frequencyWise.modelComparison.gain = true;
    settings.statistics.frequencyWise.modelComparison.phase = true;

    %% Figures

    settings.plot = defaultPlotSettings("none");

end
