function plotMISOwCoherence(f, H, multipleCoherence, partialCoherence, pathwayLabel, figureName)

    freqIndex = f >= 0 & f <= 0.5;
    f = f(freqIndex);
    H = H(freqIndex);
    multipleCoherence = multipleCoherence(freqIndex);
    partialCoherence = partialCoherence(freqIndex);
    freqLimits = [0 0.5];

    figure('Name', figureName, 'NumberTitle', 'off')

    % Gain plot
    subplot(1,2,1)

    yyaxis left
    hTfGain = stem(f, abs(H), 'filled');
    hTfGain.DisplayName = 'Transfer function';
    ylabel('Magnitude')
    xlabel('Frequency (Hz)')
    title([pathwayLabel ' Gain'])
    grid on
    hold on
    xlim(freqLimits)

    leftMin = min(abs(H), [], 'omitnan');
    leftMax = max(abs(H), [], 'omitnan');
    leftMin = min(leftMin, 0);
    leftMax = max(leftMax, 0);

    if leftMin == leftMax
        leftMin = leftMin - 1;
        leftMax = leftMax + 1;
    end

    yyaxis right
    hMultGain = plot(f, multipleCoherence, 'LineWidth', 0.7);
    hold on
    hPartGain = plot(f, partialCoherence, 'Color', '#FFD580', 'LineWidth', 0.7);
    ylabel('Coherence')
    xlim(freqLimits)

    rightMax = max([1; multipleCoherence(:); partialCoherence(:)], [], 'omitnan');
    rightMax = 1.05 * rightMax;

    alignRightYAxisZero(leftMin, leftMax, rightMax)

    legend([hTfGain, hMultGain, hPartGain], ...
        {'Transfer function', 'Multiple coherence', 'Partial coherence'}, ...
        'Location', 'best')


    % Phase plot
    subplot(1,2,2)

    yyaxis left
    hTfPhase = stem(f, angle(H), 'filled');
    hTfPhase.DisplayName = 'Transfer function';
    ylabel('Phase (rad)')
    xlabel('Frequency (Hz)')
    title([pathwayLabel ' Phase'])
    grid on
    hold on
    xlim(freqLimits)

    leftMin = min(angle(H), [], 'omitnan');
    leftMax = max(angle(H), [], 'omitnan');
    leftMin = min(leftMin, 0);
    leftMax = max(leftMax, 0);

    if leftMin == leftMax
        leftMin = leftMin - 1;
        leftMax = leftMax + 1;
    end

    yyaxis right
    hMultPhase = plot(f, multipleCoherence, 'LineWidth', 0.7);
    hold on
    hPartPhase = plot(f, partialCoherence, 'Color', '#FFD580', 'LineWidth', 0.7);
    ylabel('Coherence')
    xlim(freqLimits)

    rightMax = max([1; multipleCoherence(:); partialCoherence(:)], [], 'omitnan');
    rightMax = 1.05 * rightMax;

    alignRightYAxisZero(leftMin, leftMax, rightMax)

    legend([hTfPhase, hMultPhase, hPartPhase], ...
        {'Transfer function', 'Multiple coherence', 'Partial coherence'}, ...
        'Location', 'best')

    sgtitle([pathwayLabel ' Transfer Function'])

end
