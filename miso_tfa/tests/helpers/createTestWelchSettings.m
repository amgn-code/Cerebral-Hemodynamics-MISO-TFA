function welchSettings = createTestWelchSettings()
% createTestWelchSettings Create the standard Welch settings used in tests.

    welchSettings.windowLengthSeconds = 128;
    welchSettings.windowOverlap = 0.5;
    welchSettings.minimumWindows = 3;
    welchSettings.smoothingEnabled = true;
    welchSettings.smoothingKernel = [0.25 0.50 0.25];

end
