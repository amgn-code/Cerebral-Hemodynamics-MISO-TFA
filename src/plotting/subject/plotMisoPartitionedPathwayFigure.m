function plotMisoPartitionedPathwayFigure( ...
    misoResults, pathwayName, frequencyBandEdgesHz, frequencyBandNames, ...
    plotSettings)
% plotMisoPartitionedPathwayFigure Plot MISO results within each frequency band.

    pathwayResults = misoResults.(pathwayName);
    pathwayLabel = upper(pathwayName);
    if pathwayName == "co2"
        coherenceColor = plotSettings.colors.co2Coherence;
        coherenceLabel = "CO2 partial coherence | MAP";
    else
        coherenceColor = plotSettings.colors.mapCoherence;
        coherenceLabel = "MAP partial coherence | CO2";
    end

    figureName = "PartitionedMiso" + upper(extractBefore(pathwayName, 2)) + ...
        extractAfter(pathwayName, 1) + "ToCbv";
    figure('Name', figureName, 'NumberTitle', 'off')
    plotLayout = tiledlayout(numel(frequencyBandNames), 3);

    for k = 1:numel(frequencyBandNames)
        lowerHz = frequencyBandEdgesHz(k);
        upperHz = frequencyBandEdgesHz(k + 1);

        if k == numel(frequencyBandNames)
            frequencyIndex = misoResults.f >= lowerHz & misoResults.f <= upperHz;
        else
            frequencyIndex = misoResults.f >= lowerHz & misoResults.f < upperHz;
        end

        ax = nexttile(plotLayout);
        if plotSettings.transferFunctionStyle == "line"
            plot(ax, misoResults.f(frequencyIndex), ...
                pathwayResults.gain(frequencyIndex), '-o', ...
                'Color', plotSettings.colors.transferFunction, ...
                'MarkerSize', plotSettings.markerSize, ...
                'LineWidth', plotSettings.lineWidth.transferFunction)
        else
            stem(ax, misoResults.f(frequencyIndex), ...
                pathwayResults.gain(frequencyIndex), 'filled', ...
                'Color', plotSettings.colors.transferFunction, ...
                'MarkerSize', plotSettings.markerSize, ...
                'LineWidth', plotSettings.lineWidth.transferFunction)
        end
        xlabel(ax, 'Frequency (Hz)')
        if pathwayName == "co2"
            ylabel(ax, 'Gain (%CBV/mmHg CO2)')
        else
            ylabel(ax, 'Gain (%CBV/mmHg)')
        end
        title(ax, frequencyBandNames(k) + ' Gain')
        xlim(ax, [lowerHz upperHz])
        grid(ax, 'on')

        ax = nexttile(plotLayout);
        if plotSettings.transferFunctionStyle == "line"
            plot(ax, misoResults.f(frequencyIndex), ...
                pathwayResults.phase.unwrapped(frequencyIndex), '-o', ...
                'Color', plotSettings.colors.transferFunction, ...
                'MarkerSize', plotSettings.markerSize, ...
                'LineWidth', plotSettings.lineWidth.transferFunction)
        else
            stem(ax, misoResults.f(frequencyIndex), ...
                pathwayResults.phase.unwrapped(frequencyIndex), 'filled', ...
                'Color', plotSettings.colors.transferFunction, ...
                'MarkerSize', plotSettings.markerSize, ...
                'LineWidth', plotSettings.lineWidth.transferFunction)
        end
        xlabel(ax, 'Frequency (Hz)')
        ylabel(ax, 'Unwrapped phase (rad)')
        title(ax, frequencyBandNames(k) + ' Unwrapped Phase')
        xlim(ax, [lowerHz upperHz])
        grid(ax, 'on')

        ax = nexttile(plotLayout);
        plot(ax, misoResults.f(frequencyIndex), ...
            pathwayResults.coherence.partial(frequencyIndex), ...
            'Color', coherenceColor, ...
            'LineWidth', plotSettings.lineWidth.coherence)
        hold(ax, 'on')
        plot(ax, misoResults.f(frequencyIndex), ...
            misoResults.system.multipleCoherence(frequencyIndex), ...
            'Color', plotSettings.colors.multipleCoherence, ...
            'LineWidth', plotSettings.lineWidth.coherence)
        xlabel(ax, 'Frequency (Hz)')
        ylabel(ax, 'Coherence')
        title(ax, frequencyBandNames(k) + ' Coherence')
        legend(ax, coherenceLabel, 'Multiple coherence', 'Location', 'best')
        xlim(ax, [lowerHz upperHz])
        ylim(ax, [0 1])
        grid(ax, 'on')
    end

    title(plotLayout, 'MISO ' + pathwayLabel + ' to CBV by Frequency Band')

end
