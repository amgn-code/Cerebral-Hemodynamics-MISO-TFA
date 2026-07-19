function plotGroupOverviewFigure(groupResults, groupName, plotSettings)
% plotGroupOverviewFigure Plot group spectral means and standard deviations.

    f = groupResults.f;
    figureName = groupName + "_GroupOverview";
    figure('Name', figureName, 'NumberTitle', 'off')
    plotLayout = tiledlayout(2, 2);

    ax = nexttile(plotLayout);
    mapHandle = plotMeanAndSd( ...
        ax, f, groupResults.map.power.meanDb, ...
        groupResults.map.power.sdDb, plotSettings.colors.map, ...
        "line", plotSettings);
    co2Handle = plotMeanAndSd( ...
        ax, f, groupResults.co2.power.meanDb, ...
        groupResults.co2.power.sdDb, plotSettings.colors.co2, ...
        "line", plotSettings);
    xlabel(ax, 'Frequency (Hz)')
    ylabel(ax, 'Power (dB)')
    title(ax, 'Processed Input Power Spectra')
    legend(ax, [mapHandle co2Handle], {'MAP', 'CO2'}, 'Location', 'best')
    xlim(ax, plotSettings.frequencyLimitsHz)
    grid(ax, 'on')

    ax = nexttile(plotLayout);
    plotMeanAndSd( ...
        ax, f, groupResults.cbv.power.meanDb, ...
        groupResults.cbv.power.sdDb, plotSettings.colors.cbv, ...
        "line", plotSettings);
    xlabel(ax, 'Frequency (Hz)')
    ylabel(ax, 'CBV power (dB)')
    title(ax, 'Processed CBV Power Spectrum')
    xlim(ax, plotSettings.frequencyLimitsHz)
    grid(ax, 'on')

    ax = nexttile(plotLayout);
    plotMeanAndSd( ...
        ax, f, groupResults.inputRelationship.coherence.mean, ...
        groupResults.inputRelationship.coherence.sd, ...
        plotSettings.colors.inputCoherence, "line", plotSettings);
    xlabel(ax, 'Frequency (Hz)')
    ylabel(ax, 'Coherence')
    title(ax, 'MAP-CO2 Coherence')
    xlim(ax, plotSettings.frequencyLimitsHz)
    ylim(ax, [0 1])
    grid(ax, 'on')

    ax = nexttile(plotLayout);
    plotMeanAndSd( ...
        ax, f, groupResults.inputRelationship.phase.wrapped.mean, ...
        groupResults.inputRelationship.phase.wrapped.sd, ...
        plotSettings.colors.inputCoherence, "line", plotSettings);
    xlabel(ax, 'Frequency (Hz)')
    ylabel(ax, 'Phase difference (rad)')
    title(ax, 'MAP-CO2 Phase Difference')
    xlim(ax, plotSettings.frequencyLimitsHz)
    ylim(ax, [-pi pi])
    grid(ax, 'on')

    title(plotLayout, groupName + ' Group Overview')

end
