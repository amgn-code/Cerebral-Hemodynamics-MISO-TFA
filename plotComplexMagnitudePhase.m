function plotComplexMagnitudePhase(complexData, f, plotTitle, t)

figure()

if isvector(complexData)

    %% 1D Complex Spectrum Plot

    subplot(1,2,1)
    stem(f, abs(complexData))
    title(['Magnitude: ', plotTitle])
    xlabel('Frequency (Hz)')
    ylabel('Magnitude')
    grid on

    subplot(1,2,2)
    stem(f, angle(complexData))
    title(['Phase: ', plotTitle])
    xlabel('Frequency (Hz)')
    ylabel('Phase (rad)')
    grid on

else

    %% 2D Time-Frequency Complex Plot

    if nargin < 4
        error('For matrix data, you must provide a time vector t.')
    end

    subplot(1,2,1)
    imagesc(t, f, abs(complexData))
    axis xy
    title(['Magnitude: ', plotTitle])
    xlabel('Time (s)')
    ylabel('Frequency (Hz)')
    colorbar

    subplot(1,2,2)
    imagesc(t, f, angle(complexData))
    axis xy
    title(['Phase: ', plotTitle])
    xlabel('Time (s)')
    ylabel('Frequency (Hz)')
    colorbar
    caxis([-pi pi])

end

end