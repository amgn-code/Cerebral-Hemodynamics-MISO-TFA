function plotBandMISOwCoherence(fBand, HBand, multipleCoherenceBand, partialCoherenceBand, pathwayLabel, bandLabel, subplotStart)

    % Gain plot
    subplot(4,2,subplotStart)

    yyaxis left
    hTfGain = stem(fBand, abs(HBand), 'filled');
    hTfGain.DisplayName = 'Transfer function';
    ylabel('Magnitude')
    xlabel('Frequency (Hz)')
    title([bandLabel ' ' pathwayLabel ' Gain'])
    grid on
    hold on

    leftMin = min(abs(HBand), [], 'omitnan');
    leftMax = max(abs(HBand), [], 'omitnan');
    leftMin = min(leftMin, 0);
    leftMax = max(leftMax, 0);

    if leftMin == leftMax
        leftMin = leftMin - 1;
        leftMax = leftMax + 1;
    end

    yyaxis right
    hMultGain = plot(fBand, multipleCoherenceBand, 'LineWidth', 0.7);
    hold on
    hPartGain = plot(fBand, partialCoherenceBand, 'Color', '#FFD580', 'LineWidth', 0.7);
    ylabel('Coherence')

    rightMax = max([1; multipleCoherenceBand(:); partialCoherenceBand(:)], [], 'omitnan');
    rightMax = 1.05 * rightMax;

    alignRightYAxisZero(leftMin, leftMax, rightMax)

    legend([hTfGain, hMultGain, hPartGain], ...
        {'Transfer function', 'Multiple coherence', 'Partial coherence'}, ...
        'Location', 'best')


    % Phase plot
    subplot(4,2,subplotStart + 1)

    yyaxis left
    hTfPhase = stem(fBand, angle(HBand), 'filled');
    hTfPhase.DisplayName = 'Transfer function';
    ylabel('Phase (rad)')
    xlabel('Frequency (Hz)')
    title([bandLabel ' ' pathwayLabel ' Phase'])
    grid on
    hold on

    leftMin = min(angle(HBand), [], 'omitnan');
    leftMax = max(angle(HBand), [], 'omitnan');
    leftMin = min(leftMin, 0);
    leftMax = max(leftMax, 0);

    if leftMin == leftMax
        leftMin = leftMin - 1;
        leftMax = leftMax + 1;
    end

    yyaxis right
    hMultPhase = plot(fBand, multipleCoherenceBand, 'LineWidth', 0.7);
    hold on
    hPartPhase = plot(fBand, partialCoherenceBand, 'Color', '#FFD580', 'LineWidth', 0.7);
    ylabel('Coherence')

    rightMax = max([1; multipleCoherenceBand(:); partialCoherenceBand(:)], [], 'omitnan');
    rightMax = 1.05 * rightMax;

    alignRightYAxisZero(leftMin, leftMax, rightMax)

    legend([hTfPhase, hMultPhase, hPartPhase], ...
        {'Transfer function', 'Multiple coherence', 'Partial coherence'}, ...
        'Location', 'best')

end
