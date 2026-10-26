function spectra = estimateWelchSpectra( ...
    map, co2, cbv, samplingFrequencyHz, welchSettings)
% estimateWelchSpectra Estimate and smooth the spectra shared by all models.

    [window, welchInfo] = getWelchWindowSettings( ...
        welchSettings, samplingFrequencyHz, length(map));

    if welchInfo.isTooShort
        error([ ...
            'Signal is shorter than the Welch window. ' ...
            'Use a longer signal or reduce windowLengthSeconds.']);
    end

    [mapPower, f] = estimateSegmentDetrendedCpsd( ...
        map, map, window, welchInfo, samplingFrequencyHz);
    co2Power = estimateSegmentDetrendedCpsd( ...
        co2, co2, window, welchInfo, samplingFrequencyHz);
    cbvPower = estimateSegmentDetrendedCpsd( ...
        cbv, cbv, window, welchInfo, samplingFrequencyHz);

    mapCo2Conjugate = estimateSegmentDetrendedCpsd( ...
        map, co2, window, welchInfo, samplingFrequencyHz);
    mapCbvConjugate = estimateSegmentDetrendedCpsd( ...
        map, cbv, window, welchInfo, samplingFrequencyHz);
    co2CbvConjugate = estimateSegmentDetrendedCpsd( ...
        co2, cbv, window, welchInfo, samplingFrequencyHz);

    % MATLAB defines CPSD as X(Y*), while the model equations use (X*)Y.
    mapCo2 = conj(mapCo2Conjugate);
    mapCbv = conj(mapCbvConjugate);
    co2Cbv = conj(co2CbvConjugate);

    if welchSettings.smoothingEnabled
        smoothingKernel = welchSettings.smoothingKernel;
    else
        smoothingKernel = 1;
    end

    spectra.f = f;
    spectra.map.power = conv(mapPower, smoothingKernel, "same");
    spectra.co2.power = conv(co2Power, smoothingKernel, "same");
    spectra.cbv.power = conv(cbvPower, smoothingKernel, "same");
    spectra.cross.mapCo2 = conv(mapCo2, smoothingKernel, "same");
    spectra.cross.co2Map = conj(spectra.cross.mapCo2);
    spectra.cross.mapCbv = conv(mapCbv, smoothingKernel, "same");
    spectra.cross.co2Cbv = conv(co2Cbv, smoothingKernel, "same");

    spectra.welchInfo = welchInfo;
    spectra.welchInfo.smoothingEnabled = ...
        welchSettings.smoothingEnabled;
    spectra.welchInfo.smoothingKernel = ...
        welchSettings.smoothingKernel;
    spectra.welchInfo.segmentDetrend = "linear";
    spectra.welchInfo.effectiveAverages = ...
        spectra.welchInfo.numWindows / ...
        sum(smoothingKernel.^2);

end

function [crossPower, frequencyHz] = estimateSegmentDetrendedCpsd( ...
    firstSignal, secondSignal, window, welchInfo, samplingFrequencyHz)
% estimateSegmentDetrendedCpsd Apply a linear detrend inside each segment.

    firstSignal = firstSignal(:);
    secondSignal = secondSignal(:);
    window = window(:);
    windowLength = welchInfo.windowLengthSamples;
    stepLength = windowLength - welchInfo.windowOverlapSamples;
    fftLength = welchInfo.fftLengthSamples;
    numWindows = welchInfo.numWindows;
    accumulated = complex(zeros(fftLength, 1));

    for windowIndex = 1:numWindows
        firstIndex = 1 + (windowIndex - 1)*stepLength;
        indices = firstIndex:(firstIndex + windowLength - 1);
        firstSegment = detrend(firstSignal(indices), "linear").*window;
        secondSegment = detrend(secondSignal(indices), "linear").*window;
        firstFft = fft(firstSegment, fftLength);
        secondFft = fft(secondSegment, fftLength);
        accumulated = accumulated + firstFft.*conj(secondFft);
    end

    crossPower = accumulated/(numWindows*samplingFrequencyHz*sum(window.^2));
    if mod(fftLength, 2) == 0
        keptBins = 1:(fftLength/2 + 1);
        doubledBins = 2:(numel(keptBins) - 1);
    else
        keptBins = 1:((fftLength + 1)/2);
        doubledBins = 2:numel(keptBins);
    end
    crossPower = crossPower(keptBins);
    crossPower(doubledBins) = 2*crossPower(doubledBins);
    frequencyHz = (keptBins(:) - 1)*samplingFrequencyHz/fftLength;

end
