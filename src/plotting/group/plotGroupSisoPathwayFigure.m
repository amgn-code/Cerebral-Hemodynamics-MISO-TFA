function plotGroupSisoPathwayFigure( ...
    sisoResults, pathwayName, groupName, plotSettings)
% plotGroupSisoPathwayFigure Plot one group-average SISO pathway.

    pathwayResults = sisoResults.(pathwayName);
    pathwayLabel = upper(pathwayName);

    if pathwayName == "co2"
        coherenceColor = plotSettings.colors.co2Coherence;
        coherenceLabel = "CO2-CBV coherence";
        gainLabel = 'Gain (%CBV/mmHg CO2)';
    else
        coherenceColor = plotSettings.colors.mapCoherence;
        coherenceLabel = "MAP-CBV coherence";
        gainLabel = 'Gain (%CBV/mmHg)';
    end

    figureName = groupName + "_GroupSiso" + ...
        upper(extractBefore(pathwayName, 2)) + ...
        extractAfter(pathwayName, 1) + "ToCbv";
    figure('Name', figureName, 'NumberTitle', 'off')
    plotLayout = tiledlayout(2, 3);

    ax = nexttile(plotLayout);
    plotMeanAndSd( ...
        ax, sisoResults.f, pathwayResults.gain.mean, ...
        pathwayResults.gain.sd, plotSettings.colors.transferFunction, ...
        plotSettings.transferFunctionStyle, plotSettings);
    xlabel(ax, 'Frequency (Hz)')
    ylabel(ax, gainLabel)
    title(ax, 'Gain')
    xlim(ax, plotSettings.frequencyLimitsHz)
    grid(ax, 'on')

    ax = nexttile(plotLayout);
    plotMeanAndSd( ...
        ax, sisoResults.f, pathwayResults.phase.wrapped.mean, ...
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
        ax, sisoResults.f, pathwayResults.phase.unwrapped.mean, ...
        pathwayResults.phase.unwrapped.sd, ...
        plotSettings.colors.transferFunction, ...
        plotSettings.transferFunctionStyle, plotSettings);
    xlabel(ax, 'Frequency (Hz)')
    ylabel(ax, 'Unwrapped phase (rad)')
    title(ax, 'Unwrapped Phase')
    xlim(ax, plotSettings.frequencyLimitsHz)
    grid(ax, 'on')

    ax = nexttile(plotLayout);
    plotMeanAndSd( ...
        ax, sisoResults.f, pathwayResults.coherence.pairwise.mean, ...
        pathwayResults.coherence.pairwise.sd, coherenceColor, ...
        "line", plotSettings);
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

    title(plotLayout, groupName + ' Group SISO ' + pathwayLabel + ' to CBV')

end
