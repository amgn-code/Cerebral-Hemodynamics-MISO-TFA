function plotMISOwCoherence(f, H, multiple_coherence, partial_coherence, pathway_label, figure_name)

    figure('Name', figure_name, 'NumberTitle', 'off')

    % Gain plot
    subplot(1,2,1)

    yyaxis left
    h_tf_gain = stem(f, abs(H), 'filled');
    h_tf_gain.DisplayName = 'Transfer function';
    ylabel('Magnitude')
    xlabel('Frequency (Hz)')
    title([pathway_label ' Gain'])
    grid on
    hold on

    left_min = min(abs(H), [], 'omitnan');
    left_max = max(abs(H), [], 'omitnan');
    left_min = min(left_min, 0);
    left_max = max(left_max, 0);

    if left_min == left_max
        left_min = left_min - 1;
        left_max = left_max + 1;
    end

    yyaxis right
    h_mult_gain = plot(f, multiple_coherence, 'LineWidth', 0.7);
    hold on
    h_part_gain = plot(f, partial_coherence, 'Color', '#FFD580', 'LineWidth', 0.7);
    ylabel('Coherence')

    right_max = max([1; multiple_coherence(:); partial_coherence(:)], [], 'omitnan');
    right_max = 1.05 * right_max;

    alignRightYAxisZero(left_min, left_max, right_max)

    legend([h_tf_gain, h_mult_gain, h_part_gain], ...
        {'Transfer function', 'Multiple coherence', 'Partial coherence'}, ...
        'Location', 'best')


    % Phase plot
    subplot(1,2,2)

    yyaxis left
    h_tf_phase = stem(f, angle(H), 'filled');
    h_tf_phase.DisplayName = 'Transfer function';
    ylabel('Phase (rad)')
    xlabel('Frequency (Hz)')
    title([pathway_label ' Phase'])
    grid on
    hold on

    left_min = min(angle(H), [], 'omitnan');
    left_max = max(angle(H), [], 'omitnan');
    left_min = min(left_min, 0);
    left_max = max(left_max, 0);

    if left_min == left_max
        left_min = left_min - 1;
        left_max = left_max + 1;
    end

    yyaxis right
    h_mult_phase = plot(f, multiple_coherence, 'LineWidth', 0.7);
    hold on
    h_part_phase = plot(f, partial_coherence, 'Color', '#FFD580', 'LineWidth', 0.7);
    ylabel('Coherence')

    right_max = max([1; multiple_coherence(:); partial_coherence(:)], [], 'omitnan');
    right_max = 1.05 * right_max;

    alignRightYAxisZero(left_min, left_max, right_max)

    legend([h_tf_phase, h_mult_phase, h_part_phase], ...
        {'Transfer function', 'Multiple coherence', 'Partial coherence'}, ...
        'Location', 'best')

    sgtitle([pathway_label ' Transfer Function'])

end