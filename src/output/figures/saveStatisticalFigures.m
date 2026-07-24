function savedFigureFiles = saveStatisticalFigures( ...
    statisticalResults, outputFolder, analysisSettings)
% saveStatisticalFigures Create and save the selected comparison figures.

    show = analysisSettings.plot.show.statistics;
    figureHandles = gobjects(0, 1);
    figureNames = strings(0, 1);

    if show.modelComparison && ...
            ~isempty(statisticalResults.modelComparisonValues)
        figureHandles(end + 1,1) = plotStatisticalModelComparison( ...
            statisticalResults, analysisSettings);
        figureNames(end + 1,1) = "Statistical_Model_Comparison";
    end

    if show.groupComparison && ...
            ~isempty(statisticalResults.groupComparisonValues)
        figureHandles(end + 1,1) = plotStatisticalGroupComparison( ...
            statisticalResults, analysisSettings);
        figureNames(end + 1,1) = "Statistical_Group_Comparison";
    end

    hasPathwayBalance = ...
        ~isempty(statisticalResults.groupComparisons) && ...
        any(statisticalResults.groupComparisons.Metric == ...
            "Pathway balance");

    if show.pathwayBalance && hasPathwayBalance
        figureHandles(end + 1,1) = plotStatisticalPathwayBalance( ...
            statisticalResults, analysisSettings);
        figureNames(end + 1,1) = "Statistical_Pathway_Balance";
    end

    if show.inputAssociation && ...
            ~isempty(statisticalResults.inputAssociationValues)
        figureHandles(end + 1,1) = plotStatisticalInputAssociation( ...
            statisticalResults, analysisSettings);
        figureNames(end + 1,1) = "Statistical_Input_Association";
    end

    if show.frequencyWiseComparison
        groupFrequencyResults = ...
            statisticalResults.frequencyGroupComparisons;
        if ~isempty(groupFrequencyResults)
            groupMetrics = unique( ...
                groupFrequencyResults.Metric, "stable");

            for metricIndex = 1:numel(groupMetrics)
                metric = groupMetrics(metricIndex);
                selectedRows = groupFrequencyResults( ...
                    groupFrequencyResults.Metric == metric, :);
                figureHandles(end + 1,1) = ...
                    plotFrequencyWiseComparison( ...
                        selectedRows, "group", metric, ...
                        analysisSettings);
                figureNames(end + 1,1) = ...
                    "Statistical_Frequency_Group_" + metric;
            end
        end

        modelFrequencyResults = ...
            statisticalResults.frequencyModelComparisons;
        if ~isempty(modelFrequencyResults)
            groupNames = unique( ...
                modelFrequencyResults.Group, "stable");
            modelMetrics = unique( ...
                modelFrequencyResults.Metric, "stable");

            for groupIndex = 1:numel(groupNames)
                for metricIndex = 1:numel(modelMetrics)
                    groupName = groupNames(groupIndex);
                    metric = modelMetrics(metricIndex);
                    selectedRows = modelFrequencyResults( ...
                        modelFrequencyResults.Group == groupName & ...
                        modelFrequencyResults.Metric == metric, :);

                    if isempty(selectedRows)
                        continue
                    end

                    figureHandles(end + 1,1) = ...
                        plotFrequencyWiseComparison( ...
                            selectedRows, "model", metric, ...
                            analysisSettings);
                    figureNames(end + 1,1) = ...
                        "Statistical_Frequency_Model_" + ...
                        groupName + "_" + metric;
                end
            end
        end
    end

    figureOutputFolder = fullfile(outputFolder, "Batch_Figures");
    if ~exist(figureOutputFolder, "dir")
        mkdir(figureOutputFolder);
    end

    savedFigureFiles = strings(numel(figureHandles), 1);

    for figureIndex = 1:numel(figureHandles)
        figurePath = fullfile( ...
            figureOutputFolder, ...
            lower(figureNames(figureIndex)) + ".png");
        drawnow
        exportgraphics( ...
            figureHandles(figureIndex), figurePath, "Resolution", 150);
        close(figureHandles(figureIndex))
        savedFigureFiles(figureIndex) = string(figurePath);
    end

end
