function plotFilteredMISO(f, H_filtered, pathway_label, filter_label, figure_name)

    freq_xlim = [0.005 0.50];

    figure('Name', figure_name, 'NumberTitle', 'off')

    subplot(1,2,1)
    stem(f, abs(H_filtered), 'filled')
    title([pathway_label ' Gain'])
    xlabel('Frequency (Hz)')
    ylabel('Magnitude')
    xlim(freq_xlim)
    grid on
    hold on
    addFrequencyBandLines()

    subplot(1,2,2)
    stem(f, angle(H_filtered), 'filled')
    title([pathway_label ' Phase'])
    xlabel('Frequency (Hz)')
    ylabel('Phase (rad)')
    xlim(freq_xlim)
    grid on
    hold on
    addFrequencyBandLines()

    sgtitle([filter_label ' ' pathway_label ' Transfer Function'])

end
