function settings = defaultTfaAnalysisSettings(groupsToCompare)
% defaultTfaAnalysisSettings Return a complete ordinary TFA configuration.
%
% This function owns the structural defaults used by the independent
% project. Public interfaces apply the scientific choices for each workflow.

    if nargin < 1
        groupsToCompare = ["NC"; "MCI"];
    end

    settings = defaultTfaNumericalSettings();

    groupsToCompare = upper(string(groupsToCompare(:)));
    if isempty(groupsToCompare) || numel(groupsToCompare) > 2 || ...
            numel(unique(groupsToCompare)) ~= numel(groupsToCompare)
        error( ...
            "TFA:InvalidDefaultStatisticalGroups", ...
            ['groupsToCompare must contain one or two unique group ' ...
             'names.']);
    end

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
