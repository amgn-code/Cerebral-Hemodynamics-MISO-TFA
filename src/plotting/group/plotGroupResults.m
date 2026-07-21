function figureNames = plotGroupResults( ...
    groupResults, groupName, analysisSettings)
% plotGroupResults Plot the selected group-average figures.

    figureNames = strings(0, 1);
    plotSettings = analysisSettings.plot;
    show = plotSettings.show;
    groupName = upper(string(groupName));

    if show.overview
        if isfield(groupResults, 'miso')
            overviewResults = groupResults.miso;
        else
            overviewResults = groupResults.siso;
        end

        plotGroupOverviewFigure(overviewResults, groupName, plotSettings)
        figureNames(end + 1, 1) = groupName + "_GroupOverview";
    end

    if isfield(groupResults, 'miso') && show.miso.map
        plotGroupMisoPathwayFigure( ...
            groupResults.miso, "map", groupName, plotSettings)
        figureNames(end + 1, 1) = groupName + "_GroupMisoMapToCbv";
    end

    if isfield(groupResults, 'miso') && show.miso.co2
        plotGroupMisoPathwayFigure( ...
            groupResults.miso, "co2", groupName, plotSettings)
        figureNames(end + 1, 1) = groupName + "_GroupMisoCo2ToCbv";
    end

    if isfield(groupResults, 'miso') && show.misoPartitioned.map
        plotGroupMisoPartitionedPathwayFigure( ...
            groupResults.miso, "map", groupName, ...
            analysisSettings.frequencyBandEdgesHz, ...
            analysisSettings.frequencyBandNames, plotSettings)
        figureNames(end + 1, 1) = ...
            groupName + "_GroupPartitionedMisoMapToCbv";
    end

    if isfield(groupResults, 'miso') && show.misoPartitioned.co2
        plotGroupMisoPartitionedPathwayFigure( ...
            groupResults.miso, "co2", groupName, ...
            analysisSettings.frequencyBandEdgesHz, ...
            analysisSettings.frequencyBandNames, plotSettings)
        figureNames(end + 1, 1) = ...
            groupName + "_GroupPartitionedMisoCo2ToCbv";
    end

    if isfield(groupResults, 'siso') && show.siso.map
        plotGroupSisoPathwayFigure( ...
            groupResults.siso, "map", groupName, plotSettings)
        figureNames(end + 1, 1) = groupName + "_GroupSisoMapToCbv";
    end

    if isfield(groupResults, 'siso') && show.siso.co2
        plotGroupSisoPathwayFigure( ...
            groupResults.siso, "co2", groupName, plotSettings)
        figureNames(end + 1, 1) = groupName + "_GroupSisoCo2ToCbv";
    end

    if isfield(groupResults, 'siso') && show.sisoPartitioned.map
        plotGroupSisoPartitionedPathwayFigure( ...
            groupResults.siso, "map", groupName, ...
            analysisSettings.frequencyBandEdgesHz, ...
            analysisSettings.frequencyBandNames, plotSettings)
        figureNames(end + 1, 1) = ...
            groupName + "_GroupPartitionedSisoMapToCbv";
    end

    if isfield(groupResults, 'siso') && show.sisoPartitioned.co2
        plotGroupSisoPartitionedPathwayFigure( ...
            groupResults.siso, "co2", groupName, ...
            analysisSettings.frequencyBandEdgesHz, ...
            analysisSettings.frequencyBandNames, plotSettings)
        figureNames(end + 1, 1) = ...
            groupName + "_GroupPartitionedSisoCo2ToCbv";
    end

end
