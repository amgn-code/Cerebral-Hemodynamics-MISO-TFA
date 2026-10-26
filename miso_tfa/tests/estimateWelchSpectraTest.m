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
        function independentBlockAverageUpdatesEffectiveAverages(testCase)
            signal = createSyntheticSignal(4);
            settings = createTestWelchSettings();
            settings.windowLengthSeconds = 50;
            first = estimateWelchSpectra( ...
                signal.map(1:600), signal.co2(1:600), ...
                signal.cbv(1:600), 4, settings);
            second = estimateWelchSpectra( ...
                signal.map(601:1200), signal.co2(601:1200), ...
                signal.cbv(601:1200), 4, settings);

            averaged = averageWelchSpectra({first; second});

            expectedEffective = 4/( ...
                1/first.welchInfo.effectiveAverages + ...
                1/second.welchInfo.effectiveAverages);
            testCase.verifyEqual( ...
                averaged.welchInfo.effectiveAverages, ...
                expectedEffective, AbsTol=1e-12);
            testCase.verifyEqual(averaged.welchInfo.numWindows, ...
                first.welchInfo.numWindows + second.welchInfo.numWindows);
        end

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

            spectra = estimateWelchSpectra( ...
                signalData.map, signalData.co2, signalData.cbv, ...
                signalData.fs, welchSettings);

            testCase.verifyFalse(spectra.welchInfo.smoothingEnabled);
            testCase.verifyEqual(spectra.welchInfo.segmentDetrend, "linear");
        end

        function linearTrendDoesNotChangeSegmentSpectra(testCase)
            signalData = createSyntheticSignal(4);
            welchSettings = createTestWelchSettings();
            welchSettings.smoothingEnabled = false;
            baseline = estimateWelchSpectra( ...
                signalData.map, signalData.co2, signalData.cbv, ...
                signalData.fs, welchSettings);
            map = signalData.map(:);
            co2 = signalData.co2(:);
            cbv = signalData.cbv(:);
            sampleIndex = (0:(numel(map) - 1))';
            trended = estimateWelchSpectra( ...
                map + 0.01*sampleIndex, ...
                co2 - 0.02*sampleIndex, ...
                cbv + 0.03*sampleIndex, ...
                signalData.fs, welchSettings);

            testCase.verifyEqual( ...
                trended.map.power, baseline.map.power, RelTol=1e-10);
            testCase.verifyEqual( ...
                trended.cross.mapCo2, baseline.cross.mapCo2, RelTol=1e-10);
            testCase.verifyEqual( ...
                trended.cross.mapCbv, baseline.cross.mapCbv, RelTol=1e-10);
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
