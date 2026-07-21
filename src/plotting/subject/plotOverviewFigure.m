function plotOverviewFigure(signalData, analysisResults, plotSettings)
% plotOverviewFigure Plot raw signals and processed spectral relationships.

    f = analysisResults.f;

    mapPower = real(analysisResults.map.power);
    co2Power = real(analysisResults.co2.power);
    cbvPower = real(analysisResults.cbv.power);
    mapPower(mapPower <= 0) = NaN;
    co2Power(co2Power <= 0) = NaN;
    cbvPower(cbvPower <= 0) = NaN;

    figure('Name', 'Overview', 'NumberTitle', 'off')
    plotLayout = tiledlayout(3, 2);

    ax = nexttile(plotLayout);
    yyaxis(ax, 'left')
    plot(ax, signalData.t, signalData.map, 'Color', plotSettings.colors.map)
    ylabel(ax, 'MAP (mmHg)')
    grid(ax, 'on')
    yyaxis(ax, 'right')
    plot(ax, signalData.t, signalData.co2, 'Color', plotSettings.colors.co2)
    ylabel(ax, 'CO2 (mmHg)')
    xlabel(ax, 'Time (s)')
    title(ax, 'Raw MAP and CO2')
    legend(ax, 'MAP', 'CO2', 'Location', 'best')

    ax = nexttile(plotLayout);
    plot(ax, signalData.t, signalData.cbv, 'Color', plotSettings.colors.cbv)
    xlabel(ax, 'Time (s)')
    ylabel(ax, 'CBV (cm/s)')
    title(ax, 'Raw CBV')
    grid(ax, 'on')

    ax = nexttile(plotLayout);
    plot(ax, f, 10 * log10(mapPower), ...
        'Color', plotSettings.colors.map, ...
        'LineWidth', plotSettings.lineWidth.coherence)
    hold(ax, 'on')
    plot(ax, f, 10 * log10(co2Power), ...
        'Color', plotSettings.colors.co2, ...
        'LineWidth', plotSettings.lineWidth.coherence)
    xlabel(ax, 'Frequency (Hz)')
    ylabel(ax, 'PSD (dB)')
    title(ax, 'Processed Input Power Spectral Density')
    legend(ax, 'MAP', 'CO2', 'Location', 'best')
    xlim(ax, plotSettings.frequencyLimitsHz)
    grid(ax, 'on')

    ax = nexttile(plotLayout);
    plot(ax, f, 10 * log10(cbvPower), ...
        'Color', plotSettings.colors.cbv, ...
        'LineWidth', plotSettings.lineWidth.coherence)
    xlabel(ax, 'Frequency (Hz)')
    ylabel(ax, 'CBV PSD (dB)')
    title(ax, 'Processed CBV Power Spectral Density (' + ...
        string(analysisResults.welchInfo.cbvUnits) + ')')
    xlim(ax, plotSettings.frequencyLimitsHz)
    grid(ax, 'on')

    ax = nexttile(plotLayout);
    plot(ax, f, analysisResults.inputRelationship.coherence, ...
        'Color', plotSettings.colors.inputCoherence, ...
        'LineWidth', plotSettings.lineWidth.coherence)
    xlabel(ax, 'Frequency (Hz)')
    ylabel(ax, 'Coherence')
    title(ax, 'MAP-CO2 Coherence')
    xlim(ax, plotSettings.frequencyLimitsHz)
    ylim(ax, [0 1])
    grid(ax, 'on')

    ax = nexttile(plotLayout);
    plot(ax, f, analysisResults.inputRelationship.phase.wrapped, ...
        'Color', plotSettings.colors.inputCoherence, ...
        'LineWidth', plotSettings.lineWidth.coherence)
    xlabel(ax, 'Frequency (Hz)')
    ylabel(ax, 'Phase difference (rad)')
    title(ax, 'MAP-CO2 Phase Difference')
    xlim(ax, plotSettings.frequencyLimitsHz)
    ylim(ax, [-pi pi])
    grid(ax, 'on')

    title(plotLayout, 'Subject Overview')

end
