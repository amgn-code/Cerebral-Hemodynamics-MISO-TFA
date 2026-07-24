function figureHandle = plotStatisticalPathwayBalance( ...
    statisticalResults, analysisSettings)
% plotStatisticalPathwayBalance Plot the tested pathway-balance score.

    bandData = statisticalResults.bandData;
    comparisons = statisticalResults.groupComparisons;
    groupNames = analysisSettings.statistics.groupsToCompare(:);
    bandNames = analysisSettings.statistics.primaryBandNames(:);
    allBandNames = analysisSettings.frequencyBandNames(:);
    colors = analysisSettings.plot.colors.groupComparison;

    figureHandle = figure( ...
        "Name", "Statistical_Pathway_Balance", ...
        "NumberTitle", "off");
    plotLayout = tiledlayout(1, numel(bandNames));

    for bandIndex = 1:numel(bandNames)
        bandName = bandNames(bandIndex);
        selectedBandIndex = find(allBandNames == bandName, 1);
        ax = nexttile(plotLayout);
        hold(ax, "on")

        for groupIndex = 1:numel(groupNames)
            groupName = groupNames(groupIndex);
            groupField = char(groupName);
            if isfield(bandData, groupField) && ...
                    isfield(bandData.(groupField), "miso")
                miso = bandData.(groupField).miso;
                mapValues = miso.map.coherence(selectedBandIndex,:);
                co2Values = miso.co2.coherence(selectedBandIndex,:);
                balanceValues = mapValues(:) - co2Values(:);
                balanceValues = balanceValues(isfinite(balanceValues));
                jitter = linspace( ...
                    -0.08, 0.08, numel(balanceValues))';

                scatter(ax, groupIndex + jitter, balanceValues, 28, ...
                    colors(groupIndex,:), "filled", ...
                    "MarkerFaceAlpha", 0.75);

                if ~isempty(balanceValues)
                    groupMean = mean(balanceValues);
                    plot(ax, groupIndex + [-0.14 0.14], ...
                        [groupMean groupMean], "k-", "LineWidth", 1.5);
                end
            end
        end

        summaryMask = comparisons.Metric == "Pathway balance" & ...
            comparisons.Band == bandName;
        if any(summaryMask)
            summaryRow = comparisons(find(summaryMask, 1), :);
            annotation = sprintf( ...
                "%s vs %s: raw P=%.3g, BH P=%.3g\n" + ...
                "difference=%.3g, n=%d/%d", ...
                summaryRow.FirstGroup, summaryRow.SecondGroup, ...
                summaryRow.RawP, summaryRow.BHAdjustedP, ...
                summaryRow.FirstMinusSecond, ...
                summaryRow.NFirst, summaryRow.NSecond);
            text(ax, 0.03, 0.97, annotation, ...
                "Units", "normalized", ...
                "VerticalAlignment", "top", "FontSize", 8);
        end

        yline(ax, 0, "--", "Equal MAP and CO2")
        xlim(ax, [0.5 numel(groupNames) + 0.5])
        xticks(ax, 1:numel(groupNames))
        xticklabels(ax, groupNames)
        ylabel(ax, "MAP partial coherence - CO2 partial coherence")
        title(ax, bandName)
        grid(ax, "on")
    end

    title(plotLayout, ...
        "MISO pathway-balance values used in the group test")

end
