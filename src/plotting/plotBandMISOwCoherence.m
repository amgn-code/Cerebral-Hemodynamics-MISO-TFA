function plotBandMISOwCoherence(f_band, H_band, multiple_coherence_band, partial_coherence_band, pathway_label, band_label, subplot_start)

    % Gain plot
    subplot(4,2,subplot_start)

    yyaxis left
    h_tf_gain = stem(f_band, abs(H_band), 'filled');
    h_tf_gain.DisplayName = 'Transfer function';
    ylabel('Magnitude')
    xlabel('Frequency (Hz)')
    title([band_label ' ' pathway_label ' Gain'])
    grid on
    hold on

    left_min = min(abs(H_band), [], 'omitnan');
    left_max = max(abs(H_band), [], 'omitnan');
    left_min = min(left_min, 0);
    left_max = max(left_max, 0);

    if left_min == left_max
        left_min = left_min - 1;
        left_max = left_max + 1;
    end

    yyaxis right
    h_mult_gain = plot(f_band, multiple_coherence_band, 'LineWidth', 0.7);
    hold on
    h_part_gain = plot(f_band, partial_coherence_band, 'Color', '#FFD580', 'LineWidth', 0.7);
    ylabel('Coherence')

    right_max = max([1; multiple_coherence_band(:); partial_coherence_band(:)], [], 'omitnan');
    right_max = 1.05 * right_max;

    alignRightYAxisZero(left_min, left_max, right_max)

    legend([h_tf_gain, h_mult_gain, h_part_gain], ...
        {'Transfer function', 'Multiple coherence', 'Partial coherence'}, ...
        'Location', 'best')


    % Phase plot
    subplot(4,2,subplot_start + 1)

    yyaxis left
    h_tf_phase = stem(f_band, angle(H_band), 'filled');
    h_tf_phase.DisplayName = 'Transfer function';
    ylabel('Phase (rad)')
    xlabel('Frequency (Hz)')
    title([band_label ' ' pathway_label ' Phase'])
    grid on
    hold on

    left_min = min(angle(H_band), [], 'omitnan');
    left_max = max(angle(H_band), [], 'omitnan');
    left_min = min(left_min, 0);
    left_max = max(left_max, 0);

    if left_min == left_max
        left_min = left_min - 1;
        left_max = left_max + 1;
    end

    yyaxis right
    h_mult_phase = plot(f_band, multiple_coherence_band, 'LineWidth', 0.7);
    hold on
    h_part_phase = plot(f_band, partial_coherence_band, 'Color', '#FFD580', 'LineWidth', 0.7);
    ylabel('Coherence')

    right_max = max([1; multiple_coherence_band(:); partial_coherence_band(:)], [], 'omitnan');
    right_max = 1.05 * right_max;

    alignRightYAxisZero(left_min, left_max, right_max)

    legend([h_tf_phase, h_mult_phase, h_part_phase], ...
        {'Transfer function', 'Multiple coherence', 'Partial coherence'}, ...
        'Location', 'best')

end
