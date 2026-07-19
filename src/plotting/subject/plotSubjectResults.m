function figureNames = plotSubjectResults( ...
    signalData, misoResults, sisoResults, analysisSettings)
% plotSubjectResults Plot the subject figures selected in analysisSettings.

    figureNames = strings(0, 1);
    plotSettings = analysisSettings.plot;
    show = plotSettings.show;

    if show.overview
        if analysisSettings.runMISO
            overviewResults = misoResults;
        else
            overviewResults = sisoResults;
        end

        plotOverviewFigure(signalData, overviewResults, plotSettings)
        figureNames(end + 1, 1) = "Overview";
    end

    if analysisSettings.runMISO && show.miso.map
        plotMisoPathwayFigure(misoResults, "map", plotSettings)
        figureNames(end + 1, 1) = "MisoMapToCbv";
    end

    if analysisSettings.runMISO && show.miso.co2
        plotMisoPathwayFigure(misoResults, "co2", plotSettings)
        figureNames(end + 1, 1) = "MisoCo2ToCbv";
    end

    if analysisSettings.runMISO && show.misoPartitioned.map
        plotMisoPartitionedPathwayFigure( ...
            misoResults, "map", analysisSettings.frequencyBandEdgesHz, ...
            analysisSettings.frequencyBandNames, plotSettings)
        figureNames(end + 1, 1) = "PartitionedMisoMapToCbv";
    end

    if analysisSettings.runMISO && show.misoPartitioned.co2
        plotMisoPartitionedPathwayFigure( ...
            misoResults, "co2", analysisSettings.frequencyBandEdgesHz, ...
            analysisSettings.frequencyBandNames, plotSettings)
        figureNames(end + 1, 1) = "PartitionedMisoCo2ToCbv";
    end

    if analysisSettings.runSISO && show.siso.map
        plotSisoPathwayFigure(sisoResults, "map", plotSettings)
        figureNames(end + 1, 1) = "SisoMapToCbv";
    end

    if analysisSettings.runSISO && show.siso.co2
        plotSisoPathwayFigure(sisoResults, "co2", plotSettings)
        figureNames(end + 1, 1) = "SisoCo2ToCbv";
    end

    if analysisSettings.runSISO && show.sisoPartitioned.map
        plotSisoPartitionedPathwayFigure( ...
            sisoResults, "map", analysisSettings.frequencyBandEdgesHz, ...
            analysisSettings.frequencyBandNames, plotSettings)
        figureNames(end + 1, 1) = "PartitionedSisoMapToCbv";
    end

    if analysisSettings.runSISO && show.sisoPartitioned.co2
        plotSisoPartitionedPathwayFigure( ...
            sisoResults, "co2", analysisSettings.frequencyBandEdgesHz, ...
            analysisSettings.frequencyBandNames, plotSettings)
        figureNames(end + 1, 1) = "PartitionedSisoCo2ToCbv";
    end

end
