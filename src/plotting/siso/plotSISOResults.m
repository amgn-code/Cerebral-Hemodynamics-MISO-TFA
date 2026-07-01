function plotSISOResults( ...
    f, ...
    H_mapcbv, ...
    H_co2cbv, ...
    mapCbvCoherence, ...
    co2CbvCoherence, ...
    coherenceThreshold, ...
    frequencyBandEdgesHz, ...
    frequencyBandNames, ...
    figureMode)

if nargin < 9
    figureMode = "all";
end

%% H MAP -> CBV with standard coherence overlay

plotSISOTransferFunctionWithCoherence( ...
    f, H_mapcbv, mapCbvCoherence, ...
    'MAP to CBV', ...
    'SisoMapToCbvTransferFunction');

%% H CO2 -> CBV with standard coherence overlay

plotSISOTransferFunctionWithCoherence( ...
    f, H_co2cbv, co2CbvCoherence, ...
    'CO2 to CBV', ...
    'SisoCo2ToCbvTransferFunction');

if figureMode == "summary"
    return
end

%% VLF, LF, HF partitioned

bands = getFrequencyBands(f, frequencyBandEdgesHz, frequencyBandNames);

plotPartitionedSISOWithCoherence( ...
    bands, H_mapcbv, mapCbvCoherence, ...
    'MAP to CBV', ...
    'PartitionedSisoMapToCbvTransferFunction');

plotPartitionedSISOWithCoherence( ...
    bands, H_co2cbv, co2CbvCoherence, ...
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


function plotSISOTransferFunctionWithCoherence(f, H, coherence, pathwayLabel, figureName)

    freqIndex = f >= 0 & f <= 0.5;
    f = f(freqIndex);
    H = H(freqIndex);
    coherence = coherence(freqIndex);
    freqLimits = [0 0.5];

    figure('Name', figureName, 'NumberTitle', 'off')

    subplot(1,2,1)
    yyaxis left
    hTfGain = stem(f, abs(H), 'filled');
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
    hCohGain = plot(f, coherence, 'LineWidth', 0.7);
    ylabel('Coherence')
    xlim(freqLimits)

    rightMax = max([1; coherence(:)], [], 'omitnan');
    rightMax = 1.05 * rightMax;

    alignRightYAxisZero(leftMin, leftMax, rightMax)

    legend([hTfGain, hCohGain], ...
        {'Transfer function', 'Coherence'}, ...
        'Location', 'best')

    subplot(1,2,2)
    yyaxis left
    hTfPhase = stem(f, angle(H), 'filled');
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


function plotPartitionedSISOWithCoherence(bands, H, coherence, pathwayLabel, figureName)

    figure('Name', figureName, 'NumberTitle', 'off')

    bandNames = {'vlf', 'lf', 'hf'};
    bandLabels = {'VLF', 'LF', 'HF'};

    for b = 1:numel(bandNames)

        bandName = bandNames{b};
        bandLabel = bandLabels{b};
        bandIndex = bands.(bandName).idx;
        fBand = bands.(bandName).f;
        HBand = H(bandIndex);
        coherenceBand = coherence(bandIndex);

        subplotStart = 2*b - 1;

        subplot(3,2,subplotStart)
        yyaxis left
        hTf = stem(fBand, abs(HBand), 'filled');
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
        hCoh = plot(fBand, coherenceBand, 'LineWidth', 0.7);
        ylabel('Coherence')
        rightMax = 1.05 * max([1; coherenceBand(:)], [], 'omitnan');
        alignRightYAxisZero(leftMin, leftMax, rightMax)
        legend([hTf, hCoh], {'Transfer function', 'Coherence'}, 'Location', 'best')

        subplot(3,2,subplotStart + 1)
        yyaxis left
        hTf = stem(fBand, angle(HBand), 'filled');
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
    freqLimits = [0 0.5];

    figure('Name', figureName, 'NumberTitle', 'off')

    subplot(1,2,1)
    stem(f, abs(H_filtered), 'filled')
    title([pathwayLabel ' Gain'])
    xlabel('Frequency (Hz)')
    ylabel('Magnitude')
    xlim(freqLimits)
    grid on
    hold on
    addFrequencyBandLines(frequencyBandEdgesHz, frequencyBandNames)

    subplot(1,2,2)
    stem(f, angle(H_filtered), 'filled')
    title([pathwayLabel ' Phase'])
    xlabel('Frequency (Hz)')
    ylabel('Phase (rad)')
    xlim(freqLimits)
    grid on
    hold on
    addFrequencyBandLines(frequencyBandEdgesHz, frequencyBandNames)

    sgtitle(['Coherence Filtered ' pathwayLabel ' Transfer Function'])

end
