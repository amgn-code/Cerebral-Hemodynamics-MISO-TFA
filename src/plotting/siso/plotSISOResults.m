function plotSISOResults( ...
    f, ...
    H_mapcbv, ...
    H_co2cbv, ...
    mapCbvPhaseData, ...
    co2CbvPhaseData, ...
    mapCbvCoherence, ...
    co2CbvCoherence, ...
    coherenceThreshold, ...
    frequencyBandEdgesHz, ...
    frequencyBandNames, ...
    figureMode)

if nargin < 11
    figureMode = "all";
end

%% H MAP -> CBV with standard coherence overlay

plotSISOTransferFunctionWithCoherence( ...
    f, H_mapcbv, mapCbvPhaseData, mapCbvCoherence, ...
    'MAP to CBV', ...
    'SisoMapToCbvTransferFunction');

%% H CO2 -> CBV with standard coherence overlay

plotSISOTransferFunctionWithCoherence( ...
    f, H_co2cbv, co2CbvPhaseData, co2CbvCoherence, ...
    'CO2 to CBV', ...
    'SisoCo2ToCbvTransferFunction');

if figureMode == "summary"
    return
end

%% VLF, LF, HF partitioned

bands = getFrequencyBands(f, frequencyBandEdgesHz, frequencyBandNames);

plotPartitionedSISOWithCoherence( ...
    bands, H_mapcbv, mapCbvPhaseData, mapCbvCoherence, ...
    'MAP to CBV', ...
    'PartitionedSisoMapToCbvTransferFunction');

plotPartitionedSISOWithCoherence( ...
    bands, H_co2cbv, co2CbvPhaseData, co2CbvCoherence, ...
    'CO2 to CBV', ...
    'PartitionedSisoCo2ToCbvTransferFunction');

%% Coherence-filtered H MAP -> CBV

H_mapcbvCohFiltered = filterByCoherence( ...
    H_mapcbv, mapCbvCoherence, coherenceThreshold);

plotFilteredSISO( ...
    f, H_mapcbvCohFiltered, ...
    'MAP to CBV', ...
    'CohFilteredSisoMapToCbvTransferFunction', ...
    frequencyBandEdgesHz, frequencyBandNames);

%% Coherence-filtered H CO2 -> CBV

H_co2cbvCohFiltered = filterByCoherence( ...
    H_co2cbv, co2CbvCoherence, coherenceThreshold);

plotFilteredSISO( ...
    f, H_co2cbvCohFiltered, ...
    'CO2 to CBV', ...
    'CohFilteredSisoCo2ToCbvTransferFunction', ...
    frequencyBandEdgesHz, frequencyBandNames);

end


function plotSISOTransferFunctionWithCoherence( ...
    f, H, phaseData, coherence, pathwayLabel, figureName)

    freqIndex = f >= 0 & f <= 0.5;
    f = f(freqIndex);
    H = H(freqIndex);
    phaseWrapped = phaseData.wrapped(freqIndex);
    phaseUnwrapped = phaseData.display(freqIndex);
    coherence = coherence(freqIndex);
    freqLimits = [0 0.5];

    figure('Name', figureName, 'NumberTitle', 'off')

    subplot(1,3,1)
    yyaxis left
    hTfGain = stem(f, abs(H), 'filled');
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
    hCohGain = plot(f, coherence, 'LineWidth', 0.7);
    ylabel('Coherence')
    xlim(freqLimits)

    rightMax = max([1; coherence(:)], [], 'omitnan');
    rightMax = 1.05 * rightMax;

    alignRightYAxisZero(leftMin, leftMax, rightMax)

    legend([hTfGain, hCohGain], ...
        {'Transfer function', 'Coherence'}, ...
        'Location', 'best')

    subplot(1,3,2)
    yyaxis left
    hTfPhase = stem(f, phaseWrapped, 'filled');
    ylabel('Wrapped phase (rad)')
    xlabel('Frequency (Hz)')
    title([pathwayLabel ' Wrapped Phase'])
    grid on
    hold on
    xlim(freqLimits)
    ylim([-pi pi])

    yyaxis right
    hCohPhase = plot(f, coherence, 'LineWidth', 0.7);
    ylabel('Coherence')
    xlim(freqLimits)

    rightMax = max([1; coherence(:)], [], 'omitnan');
    rightMax = 1.05 * rightMax;

    alignRightYAxisZero(-pi, pi, rightMax)

    legend([hTfPhase, hCohPhase], ...
        {'Transfer function', 'Coherence'}, ...
        'Location', 'best')

    subplot(1,3,3)
    yyaxis left
    hTfPhase = stem(f, phaseUnwrapped, 'filled');
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
    hCohPhase = plot(f, coherence, 'LineWidth', 0.7);
    ylabel('Coherence')
    xlim(freqLimits)

    rightMax = max([1; coherence(:)], [], 'omitnan');
    rightMax = 1.05 * rightMax;

    alignRightYAxisZero(leftMin, leftMax, rightMax)

    legend([hTfPhase, hCohPhase], ...
        {'Transfer function', 'Coherence'}, ...
        'Location', 'best')

    sgtitle([pathwayLabel ' Transfer Function'])

end


function plotPartitionedSISOWithCoherence(bands, H, phaseData, coherence, pathwayLabel, figureName)

    figure('Name', figureName, 'NumberTitle', 'off')

    bandNames = {'vlf', 'lf', 'hf'};
    bandLabels = {'VLF', 'LF', 'HF'};

    for b = 1:numel(bandNames)

        bandName = bandNames{b};
        bandLabel = bandLabels{b};
        bandIndex = bands.(bandName).idx;
        fBand = bands.(bandName).f;
        HBand = H(bandIndex);
        phaseWrappedBand = phaseData.wrapped(bandIndex);
        phaseUnwrappedBand = phaseData.display(bandIndex);
        coherenceBand = coherence(bandIndex);

        subplotStart = 3*b - 2;

        subplot(3,3,subplotStart)
        yyaxis left
        hTf = stem(fBand, abs(HBand), 'filled');
        ylabel('Gain (%CBV/mmHg)')
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
        hCoh = plot(fBand, coherenceBand, 'LineWidth', 0.7);
        ylabel('Coherence')
        rightMax = 1.05 * max([1; coherenceBand(:)], [], 'omitnan');
        alignRightYAxisZero(leftMin, leftMax, rightMax)
        legend([hTf, hCoh], {'Transfer function', 'Coherence'}, 'Location', 'best')

        subplot(3,3,subplotStart + 1)
        yyaxis left
        hTf = stem(fBand, phaseWrappedBand, 'filled');
        ylabel('Wrapped phase (rad)')
        xlabel('Frequency (Hz)')
        title([bandLabel ' ' pathwayLabel ' Wrapped Phase'])
        grid on
        hold on
        ylim([-pi pi])

        yyaxis right
        hCoh = plot(fBand, coherenceBand, 'LineWidth', 0.7);
        ylabel('Coherence')
        rightMax = 1.05 * max([1; coherenceBand(:)], [], 'omitnan');
        alignRightYAxisZero(-pi, pi, rightMax)
        legend([hTf, hCoh], {'Transfer function', 'Coherence'}, 'Location', 'best')

        subplot(3,3,subplotStart + 2)
        yyaxis left
        hTf = stem(fBand, phaseUnwrappedBand, 'filled');
        ylabel('Unwrapped phase (rad)')
        xlabel('Frequency (Hz)')
        title([bandLabel ' ' pathwayLabel ' Unwrapped Phase'])
        grid on
        hold on

        leftMin = min(phaseUnwrappedBand, [], 'omitnan');
        leftMax = max(phaseUnwrappedBand, [], 'omitnan');
        leftMin = min(leftMin, 0);
        leftMax = max(leftMax, 0);
        if leftMin == leftMax
            leftMin = leftMin - 1;
            leftMax = leftMax + 1;
        end

        yyaxis right
        hCoh = plot(fBand, coherenceBand, 'LineWidth', 0.7);
        ylabel('Coherence')
        rightMax = 1.05 * max([1; coherenceBand(:)], [], 'omitnan');
        alignRightYAxisZero(leftMin, leftMax, rightMax)
        legend([hTf, hCoh], {'Transfer function', 'Coherence'}, 'Location', 'best')

    end

    sgtitle(['Partitioned ' pathwayLabel ' Transfer Function'])

end


function plotFilteredSISO(f, H_filtered, pathwayLabel, figureName, frequencyBandEdgesHz, frequencyBandNames)

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

    sgtitle(['Coherence Filtered ' pathwayLabel ' Transfer Function'])

end
