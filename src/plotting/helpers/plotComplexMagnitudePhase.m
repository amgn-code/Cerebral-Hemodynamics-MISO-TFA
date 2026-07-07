function plotComplexMagnitudePhase(complexData, f, plotTitle, t)



if isvector(complexData)

    %% 1D Complex Spectrum Plot

    freqIndex = f >= 0 & f <= 0.5;
    f = f(freqIndex);
    complexData = complexData(freqIndex);
    phaseData = unwrapPhase(complexData);
    freqLimits = [0 0.5];

    subplot(1,2,1)
    stem(f, abs(complexData))
    title(['Magnitude: ', plotTitle])
    xlabel('Frequency (Hz)')
    ylabel('Magnitude')
    xlim(freqLimits)
    grid on

    subplot(1,2,2)
    stem(f, phaseData)
    title(['Phase: ', plotTitle])
    xlabel('Frequency (Hz)')
    ylabel('Phase (rad)')
    xlim(freqLimits)
    grid on

else

    %% 2D Time-Frequency Complex Plot

    if nargin < 4
        error('For matrix data, you must provide a time vector t.')
    end

    phaseData = unwrapPhase(complexData);

    subplot(1,2,1)
    imagesc(t, f, abs(complexData))
    axis xy
    title(['Magnitude: ', plotTitle])
    xlabel('Time (s)')
    ylabel('Frequency (Hz)')
    colorbar

    subplot(1,2,2)
    imagesc(t, f, phaseData)
    axis xy
    title(['Phase: ', plotTitle])
    xlabel('Time (s)')
    ylabel('Frequency (Hz)')
    colorbar

end

end
