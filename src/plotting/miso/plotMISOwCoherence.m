function plotMISOwCoherence( ...
    f, H, phaseData, multipleCoherence, partialCoherence, pathwayLabel, figureName)

    freqIndex = f >= 0 & f <= 0.5;
    f = f(freqIndex);
    H = H(freqIndex);
    phaseWrapped = phaseData.wrapped(freqIndex);
    phaseUnwrapped = phaseData.display(freqIndex);
    multipleCoherence = multipleCoherence(freqIndex);
    partialCoherence = partialCoherence(freqIndex);
    freqLimits = [0 0.5];

    figure('Name', figureName, 'NumberTitle', 'off')

    % Gain plot
    subplot(1,3,1)

    yyaxis left
    hTfGain = stem(f, abs(H), 'filled');
    hTfGain.DisplayName = 'Transfer function';
    ylabel('Gain (%CBV/mmHg)')
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


    % Wrapped phase plot
    subplot(1,3,2)

    yyaxis left
    hTfPhase = stem(f, phaseWrapped, 'filled');
    hTfPhase.DisplayName = 'Transfer function';
    ylabel('Wrapped phase (rad)')
    xlabel('Frequency (Hz)')
    title([pathwayLabel ' Wrapped Phase'])
    grid on
    hold on
    xlim(freqLimits)
    ylim([-pi pi])

    yyaxis right
    hMultPhase = plot(f, multipleCoherence, 'LineWidth', 0.7);
    hold on
    hPartPhase = plot(f, partialCoherence, 'Color', '#FFD580', 'LineWidth', 0.7);
    ylabel('Coherence')
    xlim(freqLimits)

    rightMax = max([1; multipleCoherence(:); partialCoherence(:)], [], 'omitnan');
    rightMax = 1.05 * rightMax;

    alignRightYAxisZero(-pi, pi, rightMax)

    legend([hTfPhase, hMultPhase, hPartPhase], ...
        {'Transfer function', 'Multiple coherence', 'Partial coherence'}, ...
        'Location', 'best')

    % Unwrapped phase plot
    subplot(1,3,3)

    yyaxis left
    hTfPhase = stem(f, phaseUnwrapped, 'filled');
    hTfPhase.DisplayName = 'Transfer function';
    ylabel('Unwrapped phase (rad)')
    xlabel('Frequency (Hz)')
    title([pathwayLabel ' Unwrapped Phase'])
    grid on
    hold on
    xlim(freqLimits)

    leftMin = min(phaseUnwrapped, [], 'omitnan');
    leftMax = max(phaseUnwrapped, [], 'omitnan');
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
