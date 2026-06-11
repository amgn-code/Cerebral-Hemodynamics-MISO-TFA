function signalData = createShoMisoSignal()
% createShoMisoSignal
%
% Creates a Sho-inspired MISO test signal:
%
%   BP + CO2 -> CBF
%
% BP and CO2 are built from different sinusoidal components so the MISO
% algorithm can separate their contributions more easily.

    %% Sampling setup
    fs = 4;
    Ts = 1/fs;
    t = (0:Ts:300)';

    %% Frequencies by band
    % VLF: 0.02 - 0.07 Hz
    % LF:  0.07 - 0.20 Hz
    % HF:  0.20 - 0.50 Hz
    
    f_BP_VLF  = 0.03;
    f_BP_LF   = 0.10;   % intentionally overlaps with CO2
    f_BP_HF   = 0.30;
    
    f_CO2_VLF = 0.05;
    f_CO2_LF  = 0.11;   % overlap frequency
    f_CO2_HF  = 0.40;
    
    shared_lf = sin(2*pi*0.08*t);

    BP_clean = ...
        sin(2*pi*0.03*t) + ...
        sin(2*pi*0.10*t) + ...
        sin(2*pi*0.30*t) + ...
        0.4*shared_lf;
    
    CO2_clean = ...
        sin(2*pi*0.05*t) + ...
        sin(2*pi*0.11*t) + ...
        sin(2*pi*0.40*t) + ...
        0.4*shared_lf;
    
    %% Add noise to inputs
    BP  = awgn(BP_clean, 30);
    CO2 = awgn(CO2_clean, 30);
    
    %% CBF output created from both BP and CO2 components
    CBF_clean = ...
        0.7*sin(2*pi*0.03*t - pi/3) + ...     % MAP VLF
        1.0*sin(2*pi*0.10*t - pi/6) + ...     % MAP LF
        0.5*sin(2*pi*0.30*t - 3*pi/4) + ...   % MAP HF
        1.2*sin(2*pi*0.05*t + pi/4) + ...     % CO2 VLF
        0.6*sin(2*pi*0.11*t + pi/2) + ...     % CO2 LF
        0.4*sin(2*pi*0.40*t - pi/8) + ...     % CO2 HF
        0.8*shared_lf;                        % shared-frequency output contribution
    
    %% Add output noise
    CBF = awgn(CBF_clean, 30);

    %% Not sure what detrending does
    p = polyfit(t,BP,2);
    BP_detrend = BP - polyval(p,t);

    p = polyfit(t,CO2,2);
    CO2_detrend = CO2 - polyval(p,t);

    p = polyfit(t,CBF,2);
    CBF_detrend = CBF - polyval(p,t);

    clear p

    %% Store results
    signalData.fs = fs;
    signalData.t = t;

    signalData.bp = BP;
    signalData.co2 = CO2;
    signalData.cbf = CBF;

    signalData.bp_clean = BP_clean;
    signalData.co2_clean = CO2_clean;
    signalData.cbf_clean = CBF_clean;

    signalData.bp_detrend = BP_detrend;
    signalData.co2_detrend = CO2_detrend;
    signalData.cbf_detrend = CBF_detrend;

    signalData.BP_testFrequencies_Hz = [1/3; 1/10; 1/48];
    signalData.CO2_testFrequencies_Hz = [1/6; 1/20; 1/80];

    signalData.BP_trueGain = [0.5; 1.0; 1.5];
    signalData.BP_truePhase_rad = [-3*pi/4; 0; pi/2];
    signalData.BP_truePhase_deg = rad2deg(signalData.BP_truePhase_rad);

    signalData.CO2_trueGain = [0.8; 1.2; 0.6];
    signalData.CO2_truePhase_rad = [-pi/4; pi/3; 0];
    signalData.CO2_truePhase_deg = rad2deg(signalData.CO2_truePhase_rad);

    signalData.description = "Sho-inspired MISO sinusoid test signal";

end