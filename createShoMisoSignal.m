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
    t = (0:Ts:1000)';

    %% BP-like clean input
    BP_clean = sin(t*2*pi*1/3) + ...
               sin(t*2*pi*1/10) + ...
               sin(t*2*pi*1/48);

    %% CO2-like clean input
    CO2_clean = sin(t*2*pi*1/6) + ...
                sin(t*2*pi*1/20) + ...
                sin(t*2*pi*1/80);

    %% Add noise to inputs
    BP = awgn(BP_clean,30);
    CO2 = awgn(CO2_clean,30);

    %% CBF output created from both BP and CO2 components
    CBF_clean = ...
        0.5*sin(t*2*pi*1/3 - 3*pi/4) + ...   % BP contribution
        1.0*sin(t*2*pi*1/10) + ...           % BP contribution
        1.5*cos(t*2*pi*1/48) + ...           % BP contribution
        0.8*sin(t*2*pi*1/6 - pi/4) + ...     % CO2 contribution
        1.2*sin(t*2*pi*1/20 + pi/3) + ...    % CO2 contribution
        0.6*sin(t*2*pi*1/80);                % CO2 contribution

    CBF = awgn(CBF_clean,30);

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