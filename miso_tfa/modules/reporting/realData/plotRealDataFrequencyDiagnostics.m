function [figureHandle, sourceData] = ...
    plotRealDataFrequencyDiagnostics(results)
% plotRealDataFrequencyDiagnostics Plot descriptive real-data diagnostics.

    sourceData = createRealDataFrequencyTable(results);
    frequencyHz = sourceData.FrequencyHz;

    figureHandle = figure( ...
        'Name', 'Real Data Frequency Diagnostics', ...
        'Color', 'w', ...
        'Visible', 'off');
    tiledlayout(2, 2, 'TileSpacing', 'compact', 'Padding', 'compact');

    nexttile;
    plot(frequencyHz, sourceData.MISOMapGain, ...
        'LineWidth', 1.2, 'Color', [0.10 0.35 0.65]);
    hold on;
    plot(frequencyHz, sourceData.SISOMapGain, '--', ...
        'LineWidth', 1.1, 'Color', [0.75 0.30 0.10]);
    hold off;
    title('MAP-to-CBV gain');
    xlabel('Frequency (Hz)');
    ylabel('Gain');
    legend('MISO', 'SISO', 'Location', 'best');
    grid on;

    nexttile;
    plot(frequencyHz, sourceData.MISOCO2Gain, ...
        'LineWidth', 1.2, 'Color', [0.10 0.35 0.65]);
    hold on;
    plot(frequencyHz, sourceData.SISOCO2Gain, '--', ...
        'LineWidth', 1.1, 'Color', [0.75 0.30 0.10]);
    hold off;
    title('CO2-to-CBV gain');
    xlabel('Frequency (Hz)');
    ylabel('Gain');
    legend('MISO', 'SISO', 'Location', 'best');
    grid on;

    nexttile;
    plot(frequencyHz, sourceData.MISOMultipleCoherence, ...
        'LineWidth', 1.2, 'Color', [0.10 0.35 0.65]);
    hold on;
    plot(frequencyHz, sourceData.SISOMapCoherence, '--', ...
        'LineWidth', 1.1, 'Color', [0.75 0.30 0.10]);
    plot(frequencyHz, sourceData.SISOCO2Coherence, ':', ...
        'LineWidth', 1.1, 'Color', [0.20 0.55 0.25]);
    hold off;
    title('Output coherence');
    xlabel('Frequency (Hz)');
    ylabel('Coherence');
    legend('MISO multiple', 'SISO MAP', 'SISO CO2', ...
        'Location', 'best');
    ylim([0 1]);
    grid on;

    nexttile;
    plot(frequencyHz, sourceData.MISOMinusMapCoherence, ...
        'LineWidth', 1.2, 'Color', [0.45 0.20 0.65]);
    hold on;
    plot(frequencyHz, sourceData.MISOMinusPartialMapCoherence, '--', ...
        'LineWidth', 1.1, 'Color', [0.75 0.30 0.10]);
    yline(0, 'k-');
    hold off;
    title('MISO coherence diagnostics');
    xlabel('Frequency (Hz)');
    ylabel('MISO minus MAP coherence');
    legend('MISO minus MAP pairwise', ...
        'MISO minus MAP partial', 'Location', 'best');
    grid on;

end
