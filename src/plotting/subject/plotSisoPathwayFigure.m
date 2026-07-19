function plotSisoPathwayFigure(sisoResults, pathwayName, plotSettings)
% plotSisoPathwayFigure Plot one SISO MAP-to-CBV or CO2-to-CBV figure.

    pathwayResults = sisoResults.(pathwayName);
    pathwayLabel = upper(pathwayName);
    if pathwayName == "co2"
        coherenceColor = plotSettings.colors.co2Coherence;
        coherenceLabel = "CO2-CBV coherence";
    else
        coherenceColor = plotSettings.colors.mapCoherence;
        coherenceLabel = "MAP-CBV coherence";
    end

    figureName = "Siso" + upper(extractBefore(pathwayName, 2)) + ...
        extractAfter(pathwayName, 1) + "ToCbv";
    figure('Name', figureName, 'NumberTitle', 'off')
    plotLayout = tiledlayout(2, 3);

    ax = nexttile(plotLayout);
    if plotSettings.transferFunctionStyle == "line"
        plot(ax, sisoResults.f, pathwayResults.gain, '-o', ...
            'Color', plotSettings.colors.transferFunction, ...
            'MarkerSize', plotSettings.markerSize, ...
            'LineWidth', plotSettings.lineWidth.transferFunction)
    else
        stem(ax, sisoResults.f, pathwayResults.gain, 'filled', ...
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
    title(ax, 'Gain')
    xlim(ax, plotSettings.frequencyLimitsHz)
    grid(ax, 'on')

    ax = nexttile(plotLayout);
    if plotSettings.transferFunctionStyle == "line"
        plot(ax, sisoResults.f, pathwayResults.phase.wrapped, '-o', ...
            'Color', plotSettings.colors.transferFunction, ...
            'MarkerSize', plotSettings.markerSize, ...
            'LineWidth', plotSettings.lineWidth.transferFunction)
    else
        stem(ax, sisoResults.f, pathwayResults.phase.wrapped, 'filled', ...
            'Color', plotSettings.colors.transferFunction, ...
            'MarkerSize', plotSettings.markerSize, ...
            'LineWidth', plotSettings.lineWidth.transferFunction)
    end
    xlabel(ax, 'Frequency (Hz)')
    ylabel(ax, 'Wrapped phase (rad)')
    title(ax, 'Wrapped Phase')
    xlim(ax, plotSettings.frequencyLimitsHz)
    ylim(ax, [-pi pi])
    grid(ax, 'on')

    ax = nexttile(plotLayout);
    if plotSettings.transferFunctionStyle == "line"
        plot(ax, sisoResults.f, pathwayResults.phase.unwrapped, '-o', ...
            'Color', plotSettings.colors.transferFunction, ...
            'MarkerSize', plotSettings.markerSize, ...
            'LineWidth', plotSettings.lineWidth.transferFunction)
    else
        stem(ax, sisoResults.f, pathwayResults.phase.unwrapped, 'filled', ...
            'Color', plotSettings.colors.transferFunction, ...
            'MarkerSize', plotSettings.markerSize, ...
            'LineWidth', plotSettings.lineWidth.transferFunction)
    end
    xlabel(ax, 'Frequency (Hz)')
    ylabel(ax, 'Unwrapped phase (rad)')
    title(ax, 'Unwrapped Phase')
    xlim(ax, plotSettings.frequencyLimitsHz)
    grid(ax, 'on')

    ax = nexttile(plotLayout);
    plot(ax, sisoResults.f, pathwayResults.coherence.pairwise, ...
        'Color', coherenceColor, ...
        'LineWidth', plotSettings.lineWidth.coherence)
    xlabel(ax, 'Frequency (Hz)')
    ylabel(ax, 'Coherence')
    title(ax, coherenceLabel)
    xlim(ax, plotSettings.frequencyLimitsHz)
    ylim(ax, [0 1])
    grid(ax, 'on')

    ax = nexttile(plotLayout);
    axis(ax, 'off')

    ax = nexttile(plotLayout);
    axis(ax, 'off')

    title(plotLayout, 'SISO ' + pathwayLabel + ' to CBV')

end
