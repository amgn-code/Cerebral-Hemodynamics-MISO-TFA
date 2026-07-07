function plotFilteredMISO(f, H_filtered, pathwayLabel, filterLabel, figureName, frequencyBandEdgesHz, frequencyBandNames)

    freqIndex = f >= 0 & f <= 0.5;
    f = f(freqIndex);
    H_filtered = H_filtered(freqIndex);
    phaseWrapped = unwrapPhase(H_filtered, "complex", "wrapped");
    phaseUnwrapped = unwrapPhase(H_filtered, "complex", "standard");
    freqLimits = [0 0.5];

    figure('Name', figureName, 'NumberTitle', 'off')

    subplot(1,3,1)
    stem(f, abs(H_filtered), 'filled')
    title([pathwayLabel ' Gain'])
    xlabel('Frequency (Hz)')
    ylabel('Gain (%CBV/mmHg)')
    xlim(freqLimits)
    grid on
    hold on
    addFrequencyBandLines(frequencyBandEdgesHz, frequencyBandNames)

    subplot(1,3,2)
    stem(f, phaseWrapped, 'filled')
    title([pathwayLabel ' Wrapped Phase'])
    xlabel('Frequency (Hz)')
    ylabel('Wrapped phase (rad)')
    ylim([-pi pi])
    xlim(freqLimits)
    grid on
    hold on
    addFrequencyBandLines(frequencyBandEdgesHz, frequencyBandNames)

    subplot(1,3,3)
    stem(f, phaseUnwrapped, 'filled')
    title([pathwayLabel ' Unwrapped Phase'])
    xlabel('Frequency (Hz)')
    ylabel('Unwrapped phase (rad)')
    xlim(freqLimits)
    grid on
    hold on
    addFrequencyBandLines(frequencyBandEdgesHz, frequencyBandNames)

    sgtitle([filterLabel ' ' pathwayLabel ' Transfer Function'])

end
