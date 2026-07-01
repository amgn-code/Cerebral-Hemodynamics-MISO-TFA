function signalData = createMisoValidationSignal(addNoise)
% createMisoValidationSignal
%
% Creates simulated MAP, CO2, and CBV signals for testing a MISO TFA pipeline.
%
% This signal is designed to test:
%   1. Whether MAP-driven CBV components are recovered.
%   2. Whether CO2-driven CBV components are recovered.
%   3. Whether the MISO method handles a frequency where MAP and CO2 both
%      have power.
%   4. Whether reliability masks remove unsupported frequency regions.
%
% Output model:
%
%   CBV(f) = H_MAP(f)*MAP(f) + H_CO2(f)*CO2(f)
%
% The generated signals represent already preprocessed / resampled
% beat-to-beat-style data, not raw pulsatile waveforms.

if nargin < 1
    addNoise = false;
end

%% Basic settings

fs = 4;             % Hz, like resampled beat-to-beat data
T_total = 300;      % seconds
t = (0:1/fs:T_total-1/fs)';

rng(2);

%% Define MAP components

% MAP frequencies
f_map1 = 0.03;
f_map2 = 0.10;
f_map3 = 0.32;

% MAP amplitudes
A_map1 = 1.0;
A_map2 = 0.8;
A_map3 = 0.6;

% MAP input signal components
map1 = A_map1 * sin(2*pi*f_map1*t);
map2 = A_map2 * sin(2*pi*f_map2*t);
map3 = A_map3 * sin(2*pi*f_map3*t);

%% Define CO2 components

% CO2 frequencies
f_co21 = 0.05;
f_co22 = 0.16;
f_co23 = 0.23;

% CO2 amplitudes
A_co21 = 0.9;
A_co22 = 0.7;
A_co23 = 0.5;

% CO2 input signal components
co21 = A_co21 * sin(2*pi*f_co21*t);
co22 = A_co22 * sin(2*pi*f_co22*t);
co23 = A_co23 * sin(2*pi*f_co23*t);

%% Shared/coupled MAP and CO2 component

% This frequency is intentionally present in both MAP and CO2.
% It tests whether the MISO model can handle input-input coupling.
f_shared = 0.12;

map_shared_amp = 0.5;
co2_shared_amp = 0.5;

map_shared  = map_shared_amp  * sin(2*pi*f_shared*t);
co2_shared = co2_shared_amp * sin(2*pi*f_shared*t + pi/6);

%% Build total MAP and CO2 inputs

mapClean = map1 + map2 + map3 + map_shared;
co2Clean = co21 + co22 + co23 + co2_shared;

%% Define known MAP-to-CBV transfer behavior

% MAP-driven gains
gain_map1 = 1.4;
gain_map2 = 0.9;
gain_map3 = 0.5;

% MAP-driven phases
phase_map1 = -pi/3;
phase_map2 = 0;
phase_map3 = pi/2;

% MAP contribution to CBV
cbv_map1 = gain_map1 * A_map1 * sin(2*pi*f_map1*t + phase_map1);
cbv_map2 = gain_map2 * A_map2 * sin(2*pi*f_map2*t + phase_map2);
cbv_map3 = gain_map3 * A_map3 * sin(2*pi*f_map3*t + phase_map3);

%% Define known CO2-to-CBV transfer behavior

% CO2-driven gains
gain_co21 = 0.7;
gain_co22 = 1.1;
gain_co23 = 0.6;

% CO2-driven phases
phase_co21 = pi/4;
phase_co22 = -pi/5;
phase_co23 = 0;

% CO2 contribution to CBV
cbv_co21 = gain_co21 * A_co21 * sin(2*pi*f_co21*t + phase_co21);
cbv_co22 = gain_co22 * A_co22 * sin(2*pi*f_co22*t + phase_co22);
cbv_co23 = gain_co23 * A_co23 * sin(2*pi*f_co23*t + phase_co23);

%% Shared-frequency CBV contribution

% At this shared frequency, both MAP and CO2 contribute to CBV.
% This is intentionally more challenging than the isolated frequencies.
gain_map_shared = 0.8;
phase_map_shared = -pi/6;

gain_co2_shared = 1.0;
phase_co2_shared = pi/3;

cbv_map_shared = gain_map_shared * map_shared_amp * ...
    sin(2*pi*f_shared*t + phase_map_shared);

cbv_co2_shared = gain_co2_shared * co2_shared_amp * ...
    sin(2*pi*f_shared*t + pi/6 + phase_co2_shared);

%% Total clean CBV output

cbvClean = ...
    cbv_map1 + cbv_map2 + cbv_map3 + ...
    cbv_co21 + cbv_co22 + cbv_co23 + ...
    cbv_map_shared + cbv_co2_shared;

%% Optional measurement noise

if addNoise
    map_noise_level = 0.05 * std(mapClean);
    co2_noise_level = 0.05 * std(co2Clean);
    cbv_noise_level = 0.05 * std(cbvClean);

    map = mapClean + map_noise_level * randn(size(mapClean));
    co2 = co2Clean + co2_noise_level * randn(size(co2Clean));
    cbv = cbvClean + cbv_noise_level * randn(size(cbvClean));
else
    map = mapClean;
    co2 = co2Clean;
    cbv = cbvClean;
end

%% Store true values for validation

trueMAP = table( ...
    [f_map1; f_map2; f_map3; f_shared], ...
    [gain_map1; gain_map2; gain_map3; gain_map_shared], ...
    [phase_map1; phase_map2; phase_map3; phase_map_shared], ...
    ["MAP isolated"; "MAP isolated"; "MAP isolated"; "MAP shared with CO2"], ...
    'VariableNames', {'Frequency_Hz','TrueGain','TruePhase_rad','Type'} );

trueCO2 = table( ...
    [f_co21; f_co22; f_co23; f_shared], ...
    [gain_co21; gain_co22; gain_co23; gain_co2_shared], ...
    [phase_co21; phase_co22; phase_co23; phase_co2_shared], ...
    ["CO2 isolated"; "CO2 isolated"; "CO2 isolated"; "CO2 shared with MAP"], ...
    'VariableNames', {'Frequency_Hz','TrueGain','TruePhase_rad','Type'} );

%% Store output struct

signalData.fs = fs;
signalData.t = t;

signalData.map = map;
signalData.co2 = co2;
signalData.cbv = cbv;

signalData.mapClean = mapClean;
signalData.co2Clean = co2Clean;
signalData.cbvClean = cbvClean;

signalData.trueMAP = trueMAP;
signalData.trueCO2 = trueCO2;

signalData.description = ...
    "MISO validation signal with MAP-only, CO2-only, and shared MAP/CO2 frequency components.";

end