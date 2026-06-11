function signalData = createMisoValidationSignal(addNoise)
% createMisoValidationSignal
%
% Creates simulated BP, CO2, and CBF signals for testing a MISO TFA pipeline.
%
% This signal is designed to test:
%   1. Whether BP-driven CBF components are recovered.
%   2. Whether CO2-driven CBF components are recovered.
%   3. Whether the MISO method handles a frequency where BP and CO2 both
%      have power.
%   4. Whether reliability masks remove unsupported frequency regions.
%
% Output model:
%
%   CBF(f) = H_BP(f)*BP(f) + H_CO2(f)*CO2(f)
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

%% Define BP components

% BP frequencies
f_bp1 = 0.03;
f_bp2 = 0.10;
f_bp3 = 0.32;

% BP amplitudes
A_bp1 = 1.0;
A_bp2 = 0.8;
A_bp3 = 0.6;

% BP input signal components
bp1 = A_bp1 * sin(2*pi*f_bp1*t);
bp2 = A_bp2 * sin(2*pi*f_bp2*t);
bp3 = A_bp3 * sin(2*pi*f_bp3*t);

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

%% Shared/coupled BP and CO2 component

% This frequency is intentionally present in both BP and CO2.
% It tests whether the MISO model can handle input-input coupling.
f_shared = 0.12;

bp_shared_amp = 0.5;
co2_shared_amp = 0.5;

bp_shared  = bp_shared_amp  * sin(2*pi*f_shared*t);
co2_shared = co2_shared_amp * sin(2*pi*f_shared*t + pi/6);

%% Build total BP and CO2 inputs

bp_clean = bp1 + bp2 + bp3 + bp_shared;
co2_clean = co21 + co22 + co23 + co2_shared;

%% Define known BP-to-CBF transfer behavior

% BP-driven gains
gain_bp1 = 1.4;
gain_bp2 = 0.9;
gain_bp3 = 0.5;

% BP-driven phases
phase_bp1 = -pi/3;
phase_bp2 = 0;
phase_bp3 = pi/2;

% BP contribution to CBF
cbf_bp1 = gain_bp1 * A_bp1 * sin(2*pi*f_bp1*t + phase_bp1);
cbf_bp2 = gain_bp2 * A_bp2 * sin(2*pi*f_bp2*t + phase_bp2);
cbf_bp3 = gain_bp3 * A_bp3 * sin(2*pi*f_bp3*t + phase_bp3);

%% Define known CO2-to-CBF transfer behavior

% CO2-driven gains
gain_co21 = 0.7;
gain_co22 = 1.1;
gain_co23 = 0.6;

% CO2-driven phases
phase_co21 = pi/4;
phase_co22 = -pi/5;
phase_co23 = 0;

% CO2 contribution to CBF
cbf_co21 = gain_co21 * A_co21 * sin(2*pi*f_co21*t + phase_co21);
cbf_co22 = gain_co22 * A_co22 * sin(2*pi*f_co22*t + phase_co22);
cbf_co23 = gain_co23 * A_co23 * sin(2*pi*f_co23*t + phase_co23);

%% Shared-frequency CBF contribution

% At this shared frequency, both BP and CO2 contribute to CBF.
% This is intentionally more challenging than the isolated frequencies.
gain_bp_shared = 0.8;
phase_bp_shared = -pi/6;

gain_co2_shared = 1.0;
phase_co2_shared = pi/3;

cbf_bp_shared = gain_bp_shared * bp_shared_amp * ...
    sin(2*pi*f_shared*t + phase_bp_shared);

cbf_co2_shared = gain_co2_shared * co2_shared_amp * ...
    sin(2*pi*f_shared*t + pi/6 + phase_co2_shared);

%% Total clean CBF output

cbf_clean = ...
    cbf_bp1 + cbf_bp2 + cbf_bp3 + ...
    cbf_co21 + cbf_co22 + cbf_co23 + ...
    cbf_bp_shared + cbf_co2_shared;

%% Optional measurement noise

if addNoise
    bp_noise_level = 0.05 * std(bp_clean);
    co2_noise_level = 0.05 * std(co2_clean);
    cbf_noise_level = 0.05 * std(cbf_clean);

    bp = bp_clean + bp_noise_level * randn(size(bp_clean));
    co2 = co2_clean + co2_noise_level * randn(size(co2_clean));
    cbf = cbf_clean + cbf_noise_level * randn(size(cbf_clean));
else
    bp = bp_clean;
    co2 = co2_clean;
    cbf = cbf_clean;
end

%% Store true values for validation

trueBP = table( ...
    [f_bp1; f_bp2; f_bp3; f_shared], ...
    [gain_bp1; gain_bp2; gain_bp3; gain_bp_shared], ...
    [phase_bp1; phase_bp2; phase_bp3; phase_bp_shared], ...
    ["BP isolated"; "BP isolated"; "BP isolated"; "BP shared with CO2"], ...
    'VariableNames', {'Frequency_Hz','TrueGain','TruePhase_rad','Type'} );

trueCO2 = table( ...
    [f_co21; f_co22; f_co23; f_shared], ...
    [gain_co21; gain_co22; gain_co23; gain_co2_shared], ...
    [phase_co21; phase_co22; phase_co23; phase_co2_shared], ...
    ["CO2 isolated"; "CO2 isolated"; "CO2 isolated"; "CO2 shared with BP"], ...
    'VariableNames', {'Frequency_Hz','TrueGain','TruePhase_rad','Type'} );

%% Store output struct

signalData.fs = fs;
signalData.t = t;

signalData.bp = bp;
signalData.co2 = co2;
signalData.cbf = cbf;

signalData.bp_clean = bp_clean;
signalData.co2_clean = co2_clean;
signalData.cbf_clean = cbf_clean;

signalData.trueBP = trueBP;
signalData.trueCO2 = trueCO2;

signalData.description = ...
    "MISO validation signal with BP-only, CO2-only, and shared BP/CO2 frequency components.";

end