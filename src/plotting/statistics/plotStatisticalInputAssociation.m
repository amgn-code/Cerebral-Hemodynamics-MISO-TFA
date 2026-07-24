function figureHandle = plotStatisticalInputAssociation( ...
    statisticalResults, analysisSettings)
% plotStatisticalInputAssociation Plot input coherence and gain changes.

    values = statisticalResults.inputAssociationValues;
    associations = statisticalResults.inputAssociations;
    groupNames = analysisSettings.statistics.groupsToCompare(:);
    bandNames = analysisSettings.statistics.primaryBandNames(:);
    pathways = ["MAP"; "CO2"];
    colors = analysisSettings.plot.colors.groupComparison;

    figureHandle = figure( ...
        "Name", "Statistical_Input_Association", ...
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
                    values.Band == bandName;
                scatter(ax, values.InputCoherence(rowMask), ...
                    values.AbsoluteGainChange(rowMask), 28, ...
                    colors(groupIndex,:), "filled", ...
                    "MarkerFaceAlpha", 0.75);
                legendHandles(end + 1,1) = scatter( ...
                    ax, NaN, NaN, 24, colors(groupIndex,:), "filled");

                summaryMask = associations.Group == groupName & ...
                    associations.Pathway == pathway & ...
                    associations.Band == bandName;
                if any(summaryMask)
                    summaryRow = associations(find(summaryMask, 1), :);
                    annotationLines(end + 1,1) = sprintf( ...
                        "%s: n=%d, rho=%.2f, raw P=%.3g, BH P=%.3g", ...
                        groupName, summaryRow.N, summaryRow.Rho, ...
                        summaryRow.RawP, ...
                        summaryRow.BHAdjustedP);
                end
            end

            xlabel(ax, "MAP-CO2 input coherence")
            ylabel(ax, "Absolute MISO-SISO gain change")
            title(ax, pathway + " - " + bandName)
            xlim(ax, [0 1])
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
        ['Input coherence and model-related gain changes ' ...
         '(exploratory)'])

end
