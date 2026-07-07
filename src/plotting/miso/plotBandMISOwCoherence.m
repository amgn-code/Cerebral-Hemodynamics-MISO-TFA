function plotBandMISOwCoherence( ...
    fBand, HBand, phaseWrappedBand, phaseUnwrappedBand, ...
    multipleCoherenceBand, partialCoherenceBand, pathwayLabel, bandLabel, rowIndex)

subplot(4,3,3 * (rowIndex - 1) + 1)
plotBandPanel( ...
    fBand, abs(HBand), multipleCoherenceBand, partialCoherenceBand, ...
    [bandLabel ' ' pathwayLabel ' Gain'], 'Gain (%CBV/mmHg)', [])

subplot(4,3,3 * (rowIndex - 1) + 2)
plotBandPanel( ...
    fBand, phaseWrappedBand, multipleCoherenceBand, partialCoherenceBand, ...
    [bandLabel ' ' pathwayLabel ' Wrapped Phase'], 'Wrapped phase (rad)', [-pi pi])

subplot(4,3,3 * (rowIndex - 1) + 3)
plotBandPanel( ...
    fBand, phaseUnwrappedBand, multipleCoherenceBand, partialCoherenceBand, ...
    [bandLabel ' ' pathwayLabel ' Unwrapped Phase'], 'Unwrapped phase (rad)', [])

end


function plotBandPanel( ...
    fBand, transferBand, multipleCoherenceBand, partialCoherenceBand, ...
    panelTitle, yLabelText, leftLimits)

yyaxis left
hTf = stem(fBand, transferBand, 'filled');
hTf.DisplayName = 'Transfer function';
ylabel(yLabelText)
xlabel('Frequency (Hz)')
title(panelTitle)
grid on
hold on

leftMin = min(transferBand, [], 'omitnan');
leftMax = max(transferBand, [], 'omitnan');
leftMin = min(leftMin, 0);
leftMax = max(leftMax, 0);

if leftMin == leftMax
    leftMin = leftMin - 1;
    leftMax = leftMax + 1;
end

if ~isempty(leftLimits)
    ylim(leftLimits)
    leftMin = leftLimits(1);
    leftMax = leftLimits(2);
end

yyaxis right
hMult = plot(fBand, multipleCoherenceBand, 'LineWidth', 0.7);
hold on
hPart = plot(fBand, partialCoherenceBand, 'Color', '#FFD580', 'LineWidth', 0.7);
ylabel('Coherence')

rightMax = max([1; multipleCoherenceBand(:); partialCoherenceBand(:)], [], 'omitnan');
rightMax = 1.05 * rightMax;

alignRightYAxisZero(leftMin, leftMax, rightMax)

legend([hTf, hMult, hPart], ...
    {'Transfer function', 'Multiple coherence', 'Partial coherence'}, ...
    'Location', 'best')

end
