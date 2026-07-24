function figureHandle = plotFrequencyWiseComparison( ...
    comparisonRows, comparisonType, metric, analysisSettings)
% plotFrequencyWiseComparison Show curves, differences, and adjusted P.

% The first row shows the two estimates and their subject SD. The second
% row shows their difference. The third row shows the BH-adjusted P value
% at each frequency.

    comparisonType = lower(string(comparisonType));
    metric = string(metric);
    pathways = ["MAP"; "CO2"];
    colors = analysisSettings.plot.colors.groupComparison;
    alpha = analysisSettings.statistics.alpha;

    if comparisonType == "group"
        firstLabel = comparisonRows.FirstGroup(1);
        secondLabel = comparisonRows.SecondGroup(1);
        comparisonLabel = firstLabel + " versus " + secondLabel;
    elseif comparisonType == "model"
        firstLabel = "MISO";
        secondLabel = "SISO";
        comparisonLabel = comparisonRows.Group(1) + ...
            ": MISO versus SISO";
    else
        error( ...
            'TFA:UnknownFrequencyComparisonType', ...
            'comparisonType must be "group" or "model".');
    end

    if metric == "Gain"
        metricLabel = "gain";
    elseif metric == "Coherence"
        metricLabel = "partial coherence";
    else
        metricLabel = "wrapped phase (rad)";
    end

    figureHandle = figure( ...
        "Name", "Frequency_Wise_" + comparisonType + "_" + metric, ...
        "NumberTitle", "off");
    plotLayout = tiledlayout(3, numel(pathways));

    for pathwayIndex = 1:numel(pathways)
        pathway = pathways(pathwayIndex);
        pathwayRows = comparisonRows( ...
            comparisonRows.Pathway == pathway, :);
        pathwayRows = sortrows(pathwayRows, "FrequencyHz");

        frequencyHz = pathwayRows.FrequencyHz;
        if comparisonType == "group"
            firstMean = pathwayRows.FirstMean;
            secondMean = pathwayRows.SecondMean;
            firstSd = pathwayRows.FirstSD;
            secondSd = pathwayRows.SecondSD;
            difference = pathwayRows.FirstMinusSecond;
        else
            firstMean = pathwayRows.MISOMean;
            secondMean = pathwayRows.SISOMean;
            firstSd = pathwayRows.MISOSD;
            secondSd = pathwayRows.SISOSD;
            difference = pathwayRows.MISOminusSISO;
        end

        %% Data Curves

        dataAxes = nexttile(plotLayout, pathwayIndex);
        hold(dataAxes, "on")
        firstHandle = plotMeanAndSd( ...
            dataAxes, frequencyHz, firstMean, firstSd, ...
            colors(1,:), "line", analysisSettings.plot);
        secondHandle = plotMeanAndSd( ...
            dataAxes, frequencyHz, secondMean, secondSd, ...
            colors(2,:), "line", analysisSettings.plot);
        ylabel(dataAxes, pathway + " " + metricLabel)
        title(dataAxes, pathway)
        grid(dataAxes, "on")
        xlim(dataAxes, analysisSettings.frequencyRangeHz)

        if metric == "Coherence"
            ylim(dataAxes, [0 1])
        end

        if pathwayIndex == 1
            legend(dataAxes, [firstHandle secondHandle], ...
                [firstLabel secondLabel], "Location", "best");
        end

        %% Difference Curve

        differenceAxes = nexttile( ...
            plotLayout, numel(pathways) + pathwayIndex);
        hold(differenceAxes, "on")

        finiteConfidenceInterval = ...
            isfinite(pathwayRows.CILower) & ...
            isfinite(pathwayRows.CIUpper);
        confidenceFrequencies = frequencyHz(finiteConfidenceInterval);
        if ~isempty(confidenceFrequencies)
            fill(differenceAxes, ...
                [confidenceFrequencies; flipud(confidenceFrequencies)], ...
                [pathwayRows.CILower(finiteConfidenceInterval); ...
                 flipud(pathwayRows.CIUpper(finiteConfidenceInterval))], ...
                [0.35 0.35 0.35], ...
                "FaceAlpha", 0.15, "EdgeColor", "none");
        end

        plot(differenceAxes, frequencyHz, difference, ...
            "k-", "LineWidth", 1.2);
        yline(differenceAxes, 0, "--", "No difference");
        ylabel(differenceAxes, firstLabel + " - " + secondLabel)
        grid(differenceAxes, "on")
        xlim(differenceAxes, analysisSettings.frequencyRangeHz)

        %% Adjusted P-Value Curve

        pValueAxes = nexttile( ...
            plotLayout, 2*numel(pathways) + pathwayIndex);
        hold(pValueAxes, "on")
        plot(pValueAxes, frequencyHz, ...
            pathwayRows.BHAdjustedP, "k-o", ...
            "LineWidth", 1.0, "MarkerSize", 3);
        yline(pValueAxes, alpha, "r--", ...
            sprintf("Adjusted P = %.2g", alpha));

        significantMask = pathwayRows.IsSignificant;
        scatter(pValueAxes, frequencyHz(significantMask), ...
            pathwayRows.BHAdjustedP(significantMask), ...
            24, [0.80 0 0], "filled");
        xlabel(pValueAxes, "Frequency (Hz)")
        ylabel(pValueAxes, "BH-adjusted P")
        ylim(pValueAxes, [0 1])
        grid(pValueAxes, "on")
        xlim(pValueAxes, analysisSettings.frequencyRangeHz)

        %% Show the Configured Band Boundaries

        if analysisSettings.plot.showFrequencyBandLines
            bandEdges = analysisSettings.frequencyBandEdgesHz(:);
            for edgeIndex = 1:numel(bandEdges)
                xline(dataAxes, bandEdges(edgeIndex), ":", ...
                    "HandleVisibility", "off");
                xline(differenceAxes, bandEdges(edgeIndex), ":", ...
                    "HandleVisibility", "off");
                xline(pValueAxes, bandEdges(edgeIndex), ":", ...
                    "HandleVisibility", "off");
            end
        end
    end

    title(plotLayout, comparisonLabel + ": frequency-wise " + ...
        lower(metric) + " comparison (exploratory)")

end
