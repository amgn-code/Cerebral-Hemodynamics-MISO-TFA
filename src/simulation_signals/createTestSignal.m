function signalData = createTestSignal(fs)
% createTestSignal Create a deterministic Sho-style MISO test signal.

    durationSeconds = 300;
    t = 0:(1/fs):(durationSeconds - 1/fs);

    previousRandomState = rng;
    restoreRandomState = onCleanup(@() rng(previousRandomState));
    rng(1);

    %% MAP and CO2 Inputs

    mapFrequenciesHz = [0.03, 0.10, 0.30];
    co2FrequenciesHz = [0.05, 0.11, 0.40];
    sharedFrequencyHz = 0.08;

    sharedInput = sin(2*pi*sharedFrequencyHz*t);

    mapClean = ...
        sin(2*pi*mapFrequenciesHz(1)*t) + ...
        sin(2*pi*mapFrequenciesHz(2)*t) + ...
        sin(2*pi*mapFrequenciesHz(3)*t) + ...
        0.4*sharedInput;

    co2Clean = ...
        sin(2*pi*co2FrequenciesHz(1)*t) + ...
        sin(2*pi*co2FrequenciesHz(2)*t) + ...
        sin(2*pi*co2FrequenciesHz(3)*t) + ...
        0.4*sharedInput;

    %% Known CBV Response

    mapTrueGain = [0.7, 1.0, 0.5];
    mapTruePhaseRad = [-pi/3, -pi/6, -3*pi/4];

    co2TrueGain = [1.2, 0.6, 0.4];
    co2TruePhaseRad = [pi/4, pi/2, -pi/8];

    cbvClean = ...
        mapTrueGain(1)*sin( ...
        2*pi*mapFrequenciesHz(1)*t + mapTruePhaseRad(1)) + ...
        mapTrueGain(2)*sin( ...
        2*pi*mapFrequenciesHz(2)*t + mapTruePhaseRad(2)) + ...
        mapTrueGain(3)*sin( ...
        2*pi*mapFrequenciesHz(3)*t + mapTruePhaseRad(3)) + ...
        co2TrueGain(1)*sin( ...
        2*pi*co2FrequenciesHz(1)*t + co2TruePhaseRad(1)) + ...
        co2TrueGain(2)*sin( ...
        2*pi*co2FrequenciesHz(2)*t + co2TruePhaseRad(2)) + ...
        co2TrueGain(3)*sin( ...
        2*pi*co2FrequenciesHz(3)*t + co2TruePhaseRad(3)) + ...
        0.8*sharedInput;

    %% Deterministic 30 dB Measurement Noise

    snrDb = 30;
    noiseScale = 10^(-snrDb/20);

    mapNoiseStd = noiseScale*sqrt(mean(mapClean.^2));
    co2NoiseStd = noiseScale*sqrt(mean(co2Clean.^2));
    cbvNoiseStd = noiseScale*sqrt(mean(cbvClean.^2));

    map = 90 + mapClean + mapNoiseStd*randn(size(t));
    co2 = 40 + co2Clean + co2NoiseStd*randn(size(t));
    cbvBaselineCmPerSec = 50;
    cbv = cbvBaselineCmPerSec + ...
        (cbvBaselineCmPerSec/100)*( ...
        cbvClean + cbvNoiseStd*randn(size(t)));

    %% Store Signal and Known Values

    signalData.fs = fs;
    signalData.t = t;
    signalData.map = map;
    signalData.co2 = co2;
    signalData.cbv = cbv;
    signalData.mapClean = mapClean;
    signalData.co2Clean = co2Clean;
    signalData.cbvClean = cbvClean;

    signalData.mapTestFrequenciesHz = mapFrequenciesHz;
    signalData.mapTrueGain = mapTrueGain;
    signalData.mapTruePhaseRad = mapTruePhaseRad;

    signalData.co2TestFrequenciesHz = co2FrequenciesHz;
    signalData.co2TrueGain = co2TrueGain;
    signalData.co2TruePhaseRad = co2TruePhaseRad;

    signalData.sharedFrequencyHz = sharedFrequencyHz;
    signalData.cbvBaselineCmPerSec = cbvBaselineCmPerSec;
    signalData.description = ...
        "Sho-style MISO test signal with known MAP and CO2 responses";

    clear restoreRandomState

end
