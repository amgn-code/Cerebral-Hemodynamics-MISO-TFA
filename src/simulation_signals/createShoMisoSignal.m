function signalData = createShoMisoSignal()
% createShoMisoSignal
%
% Creates a Sho-inspired MISO test signal:
%
%   MAP + CO2 -> CBV
%
% MAP and CO2 are built from different sinusoidal components so the MISO
% algorithm can separate their contributions more easily.

    %% Sampling setup
    fs = 4;
    Ts = 1/fs;
    t = (0:Ts:300)';

    %% Frequencies by band
    % VLF: 0.02 - 0.07 Hz
    % LF:  0.07 - 0.20 Hz
    % HF:  0.20 - 0.50 Hz
    
    fMapVLF  = 0.03;
    fMapLF   = 0.10;   % intentionally overlaps with CO2
    fMapHF   = 0.30;
    
    fCO2VLF = 0.05;
    fCO2LF  = 0.11;   % overlap frequency
    fCO2HF  = 0.40;
    
    sharedLf = sin(2*pi*0.08*t);

    mapClean = ...
        sin(2*pi*fMapVLF*t) + ...
        sin(2*pi*fMapLF*t) + ...
        sin(2*pi*fMapHF*t) + ...
        0.4*sharedLf;
    
    co2Clean = ...
        sin(2*pi*fCO2VLF*t) + ...
        sin(2*pi*fCO2LF*t) + ...
        sin(2*pi*fCO2HF*t) + ...
        0.4*sharedLf;
    
    %% Add noise to inputs
    map  = awgn(mapClean, 30);
    co2 = awgn(co2Clean, 30);
    
    %% CBV output created from both MAP and CO2 components
    cbvClean = ...
        0.7*sin(2*pi*fMapVLF*t - pi/3) + ...     % MAP VLF
        1.0*sin(2*pi*fMapLF*t - pi/6) + ...      % MAP LF
        0.5*sin(2*pi*fMapHF*t - 3*pi/4) + ...    % MAP HF
        1.2*sin(2*pi*fCO2VLF*t + pi/4) + ...     % CO2 VLF
        0.6*sin(2*pi*fCO2LF*t + pi/2) + ...      % CO2 LF
        0.4*sin(2*pi*fCO2HF*t - pi/8) + ...      % CO2 HF
        0.8*sharedLf;                            % shared-frequency output contribution
    
    %% Add output noise
    cbv = awgn(cbvClean, 30);

    %% Not sure what detrending does
    p = polyfit(t,map,2);
    mapDetrend = map - polyval(p,t);

    p = polyfit(t,co2,2);
    co2Detrend = co2 - polyval(p,t);

    p = polyfit(t,cbv,2);
    cbvDetrend = cbv - polyval(p,t);

    clear p

    %% Store results
    signalData.fs = fs;
    signalData.t = t;

    signalData.map = map;
    signalData.co2 = co2;
    signalData.cbv = cbv;

    signalData.mapClean = mapClean;
    signalData.co2Clean = co2Clean;
    signalData.cbvClean = cbvClean;

    signalData.mapDetrend = mapDetrend;
    signalData.co2Detrend = co2Detrend;
    signalData.cbvDetrend = cbvDetrend;

    signalData.mapTestFrequenciesHz = [1/3; 1/10; 1/48];
    signalData.co2TestFrequenciesHz = [1/6; 1/20; 1/80];

    signalData.mapTrueGain = [0.5; 1.0; 1.5];
    signalData.mapTruePhaseRad = [-3*pi/4; 0; pi/2];
    signalData.mapTruePhaseDeg = rad2deg(signalData.mapTruePhaseRad);

    signalData.co2TrueGain = [0.8; 1.2; 0.6];
    signalData.co2TruePhaseRad = [-pi/4; pi/3; 0];
    signalData.co2TruePhaseDeg = rad2deg(signalData.co2TruePhaseRad);

    signalData.description = "Sho-inspired MISO sinusoid test signal";

end
