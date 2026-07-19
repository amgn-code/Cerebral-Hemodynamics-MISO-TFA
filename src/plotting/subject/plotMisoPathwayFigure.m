function plotMisoPathwayFigure(misoResults, pathwayName, plotSettings)
% plotMisoPathwayFigure Plot one MISO MAP-to-CBV or CO2-to-CBV figure.

    pathwayResults = misoResults.(pathwayName);
    pathwayLabel = upper(pathwayName);
    if pathwayName == "co2"
        coherenceColor = plotSettings.colors.co2Coherence;
        coherenceLabel = "CO2 partial coherence | MAP";
    else
        coherenceColor = plotSettings.colors.mapCoherence;
        coherenceLabel = "MAP partial coherence | CO2";
    end

    figureName = "Miso" + upper(extractBefore(pathwayName, 2)) + ...
        extractAfter(pathwayName, 1) + "ToCbv";
    figure('Name', figureName, 'NumberTitle', 'off')
    plotLayout = tiledlayout(2, 3);

    ax = nexttile(plotLayout);
    if plotSettings.transferFunctionStyle == "line"
        plot(ax, misoResults.f, pathwayResults.gain, '-o', ...
            'Color', plotSettings.colors.transferFunction, ...
            'MarkerSize', plotSettings.markerSize, ...
            'LineWidth', plotSettings.lineWidth.transferFunction)
    else
        stem(ax, misoResults.f, pathwayResults.gain, 'filled', ...
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
        plot(ax, misoResults.f, pathwayResults.phase.wrapped, '-o', ...
            'Color', plotSettings.colors.transferFunction, ...
            'MarkerSize', plotSettings.markerSize, ...
            'LineWidth', plotSettings.lineWidth.transferFunction)
    else
        stem(ax, misoResults.f, pathwayResults.phase.wrapped, 'filled', ...
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
        plot(ax, misoResults.f, pathwayResults.phase.unwrapped, '-o', ...
            'Color', plotSettings.colors.transferFunction, ...
            'MarkerSize', plotSettings.markerSize, ...
            'LineWidth', plotSettings.lineWidth.transferFunction)
    else
        stem(ax, misoResults.f, pathwayResults.phase.unwrapped, 'filled', ...
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
    plot(ax, misoResults.f, pathwayResults.coherence.partial, ...
        'Color', coherenceColor, ...
        'LineWidth', plotSettings.lineWidth.coherence)
    hold(ax, 'on')
    plot(ax, misoResults.f, misoResults.system.multipleCoherence, ...
        'Color', plotSettings.colors.multipleCoherence, ...
        'LineWidth', plotSettings.lineWidth.coherence)
    xlabel(ax, 'Frequency (Hz)')
    ylabel(ax, 'Coherence')
    title(ax, 'MISO Coherence')
    legend(ax, coherenceLabel, 'Multiple coherence', 'Location', 'best')
    xlim(ax, plotSettings.frequencyLimitsHz)
    ylim(ax, [0 1])
    grid(ax, 'on')

    ax = nexttile(plotLayout);
    semilogy(ax, misoResults.f, misoResults.diagnostics.conditionNumber, ...
        'Color', plotSettings.colors.conditionNumber, ...
        'LineWidth', plotSettings.lineWidth.coherence)
    xlabel(ax, 'Frequency (Hz)')
    ylabel(ax, 'Condition number')
    title(ax, 'MISO Condition Number')
    xlim(ax, plotSettings.frequencyLimitsHz)
    grid(ax, 'on')

    ax = nexttile(plotLayout);
    axis(ax, 'off')

    title(plotLayout, 'MISO ' + pathwayLabel + ' to CBV')

end
