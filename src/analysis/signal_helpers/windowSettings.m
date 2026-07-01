function [window, welchInfo] = ...
    windowSettings(windowLengthSeconds, windowOverlap, fs, signalLength)

    % Window length in samples
    windowLengthSamples = round(windowLengthSeconds * fs);

    % Hann window
    window = hann(windowLengthSamples);

    % Overlap in samples
    windowOverlapSamples = round(windowLengthSamples * windowOverlap);

    % Step size between windows
    windowStepSamples = windowLengthSamples - windowOverlapSamples;

    % Number of Welch windows
    numWindows = floor((signalLength - windowLengthSamples) / windowStepSamples) + 1;
    numWindows = max(numWindows, 0);

    % FFT length
    fftLengthSamples = windowLengthSamples;

    welchInfo.windowLengthSeconds = windowLengthSeconds;
    welchInfo.windowOverlap = windowOverlap;
    welchInfo.windowLengthSamples = windowLengthSamples;
    welchInfo.windowOverlapSamples = windowOverlapSamples;
    welchInfo.fftLengthSamples = fftLengthSamples;
    welchInfo.numWindows = numWindows;
    welchInfo.signalLengthSamples = signalLength;
    welchInfo.signalDurationSeconds = signalLength / fs;
    welchInfo.isTooShort = signalLength < windowLengthSamples;
    welchInfo.usesDefaultCoherenceThreshold = false;
    welchInfo.coherenceThreshold = NaN;

end
