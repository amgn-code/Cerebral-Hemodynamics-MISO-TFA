classdef estimateWelchSpectraTest < matlab.unittest.TestCase
    % estimateWelchSpectraTest Tests the shared spectral-estimation step.

    methods (TestClassSetup)
        function addProjectToPath(testCase)
            projectRoot = fileparts(fileparts(mfilename("fullpath")));
            testCase.applyFixture( ...
                matlab.unittest.fixtures.PathFixture( ...
                    projectRoot, IncludingSubfolders=true));
        end
    end

    methods (Test)
        function sisoStoresThreeWindowCarnetReference(testCase)
            signalData = createSyntheticSignal(4);
            welchSettings = createTestWelchSettings();

            spectra = estimateWelchSpectra( ...
                signalData.map, signalData.co2, signalData.cbv, ...
                signalData.fs, welchSettings);
            phaseSettings = createTestPhaseSettings("standard");
            sisoResults = runSISOTFA(spectra, phaseSettings);

            testCase.verifyEqual(spectra.welchInfo.numWindows, 3);
            testCase.verifyEqual( ...
                sisoResults.welchInfo.coherenceThreshold, 0.51, ...
                AbsTol=1e-12);
            testCase.verifyFalse( ...
                isfield(spectra.welchInfo, 'coherenceThreshold'));
        end

        function modelsUseTheStoredSpectra(testCase)
            signalData = createSyntheticSignal(4);
            welchSettings = createTestWelchSettings();
            spectra = estimateWelchSpectra( ...
                signalData.map, signalData.co2, signalData.cbv, ...
                signalData.fs, welchSettings);
            phaseSettings = createTestPhaseSettings("standard");

            misoResults = runMISOTFA(spectra, phaseSettings);
            sisoResults = runSISOTFA(spectra, phaseSettings);

            testCase.verifyEqual(misoResults.map.power, spectra.map.power);
            testCase.verifyEqual(sisoResults.map.power, spectra.map.power);
            testCase.verifyEqual(misoResults.f, sisoResults.f);
        end

        function smoothingCanBeDisabled(testCase)
            signalData = createSyntheticSignal(4);
            welchSettings = createTestWelchSettings();
            welchSettings.smoothingEnabled = false;
            [window, welchInfo] = getWelchWindowSettings( ...
                welchSettings, signalData.fs, numel(signalData.map));
            [expectedMapPower, ~] = cpsd( ...
                signalData.map, signalData.map, window, ...
                welchInfo.windowOverlapSamples, ...
                welchInfo.fftLengthSamples, signalData.fs);

            spectra = estimateWelchSpectra( ...
                signalData.map, signalData.co2, signalData.cbv, ...
                signalData.fs, welchSettings);

            testCase.verifyEqual( ...
                spectra.map.power, expectedMapPower, AbsTol=1e-12);
            testCase.verifyFalse(spectra.welchInfo.smoothingEnabled);
        end

        function usesTheConfiguredSmoothingKernel(testCase)
            signalData = createSyntheticSignal(4);
            unsmoothedSettings = createTestWelchSettings();
            unsmoothedSettings.smoothingEnabled = false;
            smoothedSettings = unsmoothedSettings;
            smoothedSettings.smoothingEnabled = true;
            smoothedSettings.smoothingKernel = [0.20 0.60 0.20];
            unsmoothedSpectra = estimateWelchSpectra( ...
                signalData.map, signalData.co2, signalData.cbv, ...
                signalData.fs, unsmoothedSettings);

            smoothedSpectra = estimateWelchSpectra( ...
                signalData.map, signalData.co2, signalData.cbv, ...
                signalData.fs, smoothedSettings);
            expectedMapPower = conv( ...
                unsmoothedSpectra.map.power, ...
                smoothedSettings.smoothingKernel, "same");

            testCase.verifyEqual( ...
                smoothedSpectra.map.power, expectedMapPower, ...
                AbsTol=1e-12);
            testCase.verifyEqual( ...
                smoothedSpectra.welchInfo.smoothingKernel, ...
                [0.20 0.60 0.20], AbsTol=1e-12);
        end
    end
end
