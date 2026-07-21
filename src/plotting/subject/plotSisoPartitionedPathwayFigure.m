function plotSisoPartitionedPathwayFigure( ...
    sisoResults, pathwayName, frequencyBandEdgesHz, frequencyBandNames, ...
    plotSettings)
% plotSisoPartitionedPathwayFigure Plot SISO results within each frequency band.

    pathwayResults = sisoResults.(pathwayName);
    pathwayLabel = upper(pathwayName);
    if pathwayName == "co2"
        coherenceColor = plotSettings.colors.co2Coherence;
    else
        coherenceColor = plotSettings.colors.mapCoherence;
    end

    figureName = "PartitionedSiso" + upper(extractBefore(pathwayName, 2)) + ...
        extractAfter(pathwayName, 1) + "ToCbv";
    figure('Name', figureName, 'NumberTitle', 'off')
    plotLayout = tiledlayout(numel(frequencyBandNames), 3);

    for bandIndex = 1:numel(frequencyBandNames)
        lowerHz = frequencyBandEdgesHz(bandIndex);
        upperHz = frequencyBandEdgesHz(bandIndex + 1);

        if bandIndex == numel(frequencyBandNames)
            frequencyIndex = sisoResults.f >= lowerHz & sisoResults.f <= upperHz;
        else
            frequencyIndex = sisoResults.f >= lowerHz & sisoResults.f < upperHz;
        end

        ax = nexttile(plotLayout);
        if plotSettings.transferFunctionStyle == "line"
            plot(ax, sisoResults.f(frequencyIndex), ...
                pathwayResults.gain(frequencyIndex), '-o', ...
                'Color', plotSettings.colors.transferFunction, ...
                'MarkerSize', plotSettings.markerSize, ...
                'LineWidth', plotSettings.lineWidth.transferFunction)
        else
            stem(ax, sisoResults.f(frequencyIndex), ...
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
        title(ax, frequencyBandNames(bandIndex) + ' Gain')
        xlim(ax, [lowerHz upperHz])
        grid(ax, 'on')

        ax = nexttile(plotLayout);
        if plotSettings.transferFunctionStyle == "line"
            plot(ax, sisoResults.f(frequencyIndex), ...
                pathwayResults.phase.unwrapped(frequencyIndex), '-o', ...
                'Color', plotSettings.colors.transferFunction, ...
                'MarkerSize', plotSettings.markerSize, ...
                'LineWidth', plotSettings.lineWidth.transferFunction)
        else
            stem(ax, sisoResults.f(frequencyIndex), ...
                pathwayResults.phase.unwrapped(frequencyIndex), 'filled', ...
                'Color', plotSettings.colors.transferFunction, ...
                'MarkerSize', plotSettings.markerSize, ...
                'LineWidth', plotSettings.lineWidth.transferFunction)
        end
        xlabel(ax, 'Frequency (Hz)')
        ylabel(ax, 'Unwrapped phase (rad)')
        title(ax, frequencyBandNames(bandIndex) + ' Unwrapped Phase')
        xlim(ax, [lowerHz upperHz])
        grid(ax, 'on')

        ax = nexttile(plotLayout);
        plot(ax, sisoResults.f(frequencyIndex), ...
            pathwayResults.coherence.pairwise(frequencyIndex), ...
            'Color', coherenceColor, ...
            'LineWidth', plotSettings.lineWidth.coherence)
        if plotSettings.showSisoCoherenceReference
            yline(ax, sisoResults.welchInfo.coherenceThreshold, "--", ...
                'Color', plotSettings.colors.coherenceReference, ...
                'LineWidth', plotSettings.lineWidth.coherenceReference);
        end
        xlabel(ax, 'Frequency (Hz)')
        ylabel(ax, 'Coherence')
        title(ax, frequencyBandNames(bandIndex) + ' Coherence')
        xlim(ax, [lowerHz upperHz])
        ylim(ax, [0 1])
        grid(ax, 'on')
    end

    title(plotLayout, 'SISO ' + pathwayLabel + ' to CBV by Frequency Band')

end
