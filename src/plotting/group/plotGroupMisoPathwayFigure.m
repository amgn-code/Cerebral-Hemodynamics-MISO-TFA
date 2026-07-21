function plotGroupMisoPathwayFigure( ...
    misoResults, pathwayName, groupName, plotSettings)
% plotGroupMisoPathwayFigure Plot one group-average MISO pathway.

    pathwayResults = misoResults.(pathwayName);
    pathwayLabel = upper(pathwayName);

    if pathwayName == "co2"
        coherenceColor = plotSettings.colors.co2Coherence;
        coherenceLabel = "CO2 partial coherence | MAP";
        gainLabel = 'Gain (%CBV/mmHg CO2)';
    else
        coherenceColor = plotSettings.colors.mapCoherence;
        coherenceLabel = "MAP partial coherence | CO2";
        gainLabel = 'Gain (%CBV/mmHg)';
    end

    figureName = groupName + "_GroupMiso" + ...
        upper(extractBefore(pathwayName, 2)) + ...
        extractAfter(pathwayName, 1) + "ToCbv";
    figure('Name', figureName, 'NumberTitle', 'off')
    plotLayout = tiledlayout(2, 3);

    ax = nexttile(plotLayout);
    plotMeanAndSd( ...
        ax, misoResults.f, pathwayResults.gain.mean, ...
        pathwayResults.gain.sd, plotSettings.colors.transferFunction, ...
        plotSettings.transferFunctionStyle, plotSettings);
    xlabel(ax, 'Frequency (Hz)')
    ylabel(ax, gainLabel)
    title(ax, 'Gain')
    xlim(ax, plotSettings.frequencyLimitsHz)
    grid(ax, 'on')

    ax = nexttile(plotLayout);
    plotMeanAndSd( ...
        ax, misoResults.f, pathwayResults.phase.wrapped.mean, ...
        pathwayResults.phase.wrapped.sd, ...
        plotSettings.colors.transferFunction, ...
        plotSettings.transferFunctionStyle, plotSettings);
    xlabel(ax, 'Frequency (Hz)')
    ylabel(ax, 'Wrapped phase (rad)')
    title(ax, 'Wrapped Phase')
    xlim(ax, plotSettings.frequencyLimitsHz)
    ylim(ax, [-pi pi])
    grid(ax, 'on')

    ax = nexttile(plotLayout);
    plotMeanAndSd( ...
        ax, misoResults.f, pathwayResults.phase.unwrapped.mean, ...
        pathwayResults.phase.unwrapped.sd, ...
        plotSettings.colors.transferFunction, ...
        plotSettings.transferFunctionStyle, plotSettings);
    xlabel(ax, 'Frequency (Hz)')
    ylabel(ax, 'Unwrapped phase (rad)')
    title(ax, 'Unwrapped Phase')
    xlim(ax, plotSettings.frequencyLimitsHz)
    grid(ax, 'on')

    ax = nexttile(plotLayout);
    partialHandle = plotMeanAndSd( ...
        ax, misoResults.f, pathwayResults.coherence.partial.mean, ...
        pathwayResults.coherence.partial.sd, coherenceColor, ...
        "line", plotSettings);
    multipleHandle = plotMeanAndSd( ...
        ax, misoResults.f, misoResults.system.multipleCoherence.mean, ...
        misoResults.system.multipleCoherence.sd, ...
        plotSettings.colors.multipleCoherence, "line", plotSettings);
    xlabel(ax, 'Frequency (Hz)')
    ylabel(ax, 'Coherence')
    title(ax, 'MISO Coherence')
    legend(ax, [partialHandle multipleHandle], ...
        {char(coherenceLabel), 'Multiple coherence'}, 'Location', 'best')
    xlim(ax, plotSettings.frequencyLimitsHz)
    ylim(ax, [0 1])
    grid(ax, 'on')

    ax = nexttile(plotLayout);
    conditionMean = misoResults.diagnostics.conditionNumber.mean(:);
    conditionSd = misoResults.diagnostics.conditionNumber.sd(:);
    conditionSd(~isfinite(conditionSd)) = 0;
    lowerCondition = max(conditionMean - conditionSd, eps);
    upperCondition = conditionMean + conditionSd;
    validCondition = isfinite(misoResults.f(:)) & isfinite(conditionMean);
    set(ax, 'YScale', 'log')
    hold(ax, 'on')
    fill(ax, ...
        [misoResults.f(validCondition); flipud(misoResults.f(validCondition))], ...
        [lowerCondition(validCondition); flipud(upperCondition(validCondition))], ...
        plotSettings.colors.conditionNumber, ...
        'FaceAlpha', 0.15, ...
        'EdgeColor', 'none', ...
        'HandleVisibility', 'off');
    plot(ax, misoResults.f, conditionMean, ...
        'Color', plotSettings.colors.conditionNumber, ...
        'LineWidth', plotSettings.lineWidth.coherence)
    xlabel(ax, 'Frequency (Hz)')
    ylabel(ax, 'Condition number')
    title(ax, 'MISO Condition Number')
    xlim(ax, plotSettings.frequencyLimitsHz)
    grid(ax, 'on')

    ax = nexttile(plotLayout);
    axis(ax, 'off')

    title(plotLayout, groupName + ' Group MISO ' + pathwayLabel + ' to CBV')

end
