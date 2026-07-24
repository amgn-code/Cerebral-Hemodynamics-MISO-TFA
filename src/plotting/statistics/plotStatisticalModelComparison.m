function figureHandle = plotStatisticalModelComparison( ...
    statisticalResults, analysisSettings)
% plotStatisticalModelComparison Plot paired SISO and MISO gain values.

    values = statisticalResults.modelComparisonValues;
    comparisons = statisticalResults.modelComparisons;
    groupNames = analysisSettings.statistics.groupsToCompare(:);
    bandNames = analysisSettings.statistics.primaryBandNames(:);
    pathways = ["MAP"; "CO2"];
    colors = analysisSettings.plot.colors.groupComparison;

    figureHandle = figure( ...
        "Name", "Statistical_Model_Comparison", ...
        "NumberTitle", "off");
    plotLayout = tiledlayout(numel(pathways), numel(bandNames));

    for pathwayIndex = 1:numel(pathways)
        for bandIndex = 1:numel(bandNames)
            pathway = pathways(pathwayIndex);
            bandName = bandNames(bandIndex);
            ax = nexttile(plotLayout);
            hold(ax, "on")
            annotationLines = strings(0, 1);
            legendHandles = gobjects(0, 1);

            for groupIndex = 1:numel(groupNames)
                groupName = groupNames(groupIndex);
                rowMask = values.Group == groupName & ...
                    values.Pathway == pathway & ...
                    values.Metric == "Gain" & ...
                    values.Band == bandName;
                groupValues = values(rowMask, :);

                for subjectIndex = 1:height(groupValues)
                    plot(ax, [1 2], [ ...
                        groupValues.SISOValue(subjectIndex), ...
                        groupValues.MISOValue(subjectIndex)], ...
                        "-o", "Color", colors(groupIndex,:), ...
                        "LineWidth", 0.8, "MarkerSize", 4);
                end

                legendHandles(end + 1,1) = scatter( ...
                    ax, NaN, NaN, 24, colors(groupIndex,:), "filled");

                summaryMask = comparisons.Group == groupName & ...
                    comparisons.Pathway == pathway & ...
                    comparisons.Metric == "Gain" & ...
                    comparisons.Band == bandName;
                if any(summaryMask)
                    summaryRow = comparisons(find(summaryMask, 1), :);
                    annotationLines(end + 1,1) = sprintf( ...
                        "%s: n=%d, difference=%.3g, raw P=%.3g, BH P=%.3g", ...
                        groupName, summaryRow.N, ...
                        summaryRow.MISOminusSISO, summaryRow.RawP, ...
                        summaryRow.BHAdjustedP);
                end
            end

            xlim(ax, [0.7 2.3])
            xticks(ax, [1 2])
            xticklabels(ax, ["SISO", "MISO"])
            ylabel(ax, pathway + " gain")
            title(ax, pathway + " - " + bandName)
            grid(ax, "on")
            text(ax, 0.03, 0.97, join(annotationLines, newline), ...
                "Units", "normalized", "VerticalAlignment", "top", ...
                "FontSize", 8);

            if pathwayIndex == 1 && bandIndex == 1
                legend(ax, legendHandles, groupNames, ...
                    "Location", "best");
            end
        end
    end

    title(plotLayout, ...
        "Paired subject-level SISO and MISO gain comparisons")

end
