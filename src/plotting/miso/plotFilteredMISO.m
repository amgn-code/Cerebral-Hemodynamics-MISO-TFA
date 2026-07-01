function plotFilteredMISO(f, H_filtered, pathwayLabel, filterLabel, figureName, frequencyBandEdgesHz, frequencyBandNames)

    freqIndex = f >= 0 & f <= 0.5;
    f = f(freqIndex);
    H_filtered = H_filtered(freqIndex);
    freqLimits = [0 0.5];

    figure('Name', figureName, 'NumberTitle', 'off')

    subplot(1,2,1)
    stem(f, abs(H_filtered), 'filled')
    title([pathwayLabel ' Gain'])
    xlabel('Frequency (Hz)')
    ylabel('Magnitude')
    xlim(freqLimits)
    grid on
    hold on
    addFrequencyBandLines(frequencyBandEdgesHz, frequencyBandNames)

    subplot(1,2,2)
    stem(f, angle(H_filtered), 'filled')
    title([pathwayLabel ' Phase'])
    xlabel('Frequency (Hz)')
    ylabel('Phase (rad)')
    xlim(freqLimits)
    grid on
    hold on
    addFrequencyBandLines(frequencyBandEdgesHz, frequencyBandNames)

    sgtitle([filterLabel ' ' pathwayLabel ' Transfer Function'])

end
