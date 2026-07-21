function [window, welchInfo] = ...
    getWelchWindowSettings(welchSettings, samplingFrequencyHz, signalLength)
% getWelchWindowSettings Calculate the window and recording readiness.

    windowLengthSamples = round( ...
        welchSettings.windowLengthSeconds * samplingFrequencyHz);
    windowOverlapSamples = round( ...
        windowLengthSamples * welchSettings.windowOverlap);
    windowStepSamples = windowLengthSamples - windowOverlapSamples;

    window = hann(windowLengthSamples);

    numWindows = floor( ...
        (signalLength - windowLengthSamples) / windowStepSamples) + 1;
    numWindows = max(numWindows, 0);

    welchInfo.windowLengthSeconds = welchSettings.windowLengthSeconds;
    welchInfo.windowOverlap = welchSettings.windowOverlap;
    welchInfo.windowLengthSamples = windowLengthSamples;
    welchInfo.windowOverlapSamples = windowOverlapSamples;
    welchInfo.fftLengthSamples = windowLengthSamples;
    welchInfo.numWindows = numWindows;
    welchInfo.minimumWindows = welchSettings.minimumWindows;
    welchInfo.signalLengthSamples = signalLength;
    welchInfo.signalDurationSeconds = signalLength / samplingFrequencyHz;
    welchInfo.isTooShort = signalLength < windowLengthSamples;
    welchInfo.isReadyForTFA = ...
        ~welchInfo.isTooShort && numWindows >= welchSettings.minimumWindows;

end
