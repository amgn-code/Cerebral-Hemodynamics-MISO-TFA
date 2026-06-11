function signalData = loadPublicTFAData(filename)
% loadPublicTFAData
%
% Loads public cerebrovascular/respiratory data and preprocesses it for TFA.
%
% Expected first columns:
%   1 = right_MCA_BFV
%   2 = left_MCA_BFV
%   3 = Blood_pressure
%   4 = resp_uncalibrated
%
% Notes:
%   - resp_uncalibrated is not necessarily calibrated ETCO2.
%   - Treat it as a respiratory/CO2 surrogate for testing.
%   - The raw public dataset is assumed to be sampled at 3 Hz.
%   - The output is resampled to 4 Hz to match the TFA pipeline.

%% User settings

fs_raw = 3;      % Original/public dataset sampling frequency
fs = 4;          % Target sampling frequency for TFA

analysis_start_s = 0;
analysis_end_s = 1500;   % Crop before messy artifact-heavy end section

use_artifact_rejection = true;

%% Read table

data = readtable(filename, "VariableNamingRule", "preserve");

disp("MATLAB variable names are:");
disp(data.Properties.VariableNames');

%% Extract by column position

cbf_right_raw = data{:,1};
cbf_left_raw  = data{:,2};
bp_raw        = data{:,3};
co2_raw       = data{:,4};

%% Convert to numeric if needed

cbf_right = str2double(string(cbf_right_raw));
cbf_left  = str2double(string(cbf_left_raw));
bp        = str2double(string(bp_raw));
co2       = str2double(string(co2_raw));

%% Remove nonnumeric/header rows and missing values

validRows = ~isnan(bp) & ~isnan(co2) & ~isnan(cbf_right) & ~isnan(cbf_left);

bp = bp(validRows);
co2 = co2(validRows);
cbf_right = cbf_right(validRows);
cbf_left = cbf_left(validRows);

%% Create raw time vector

N_raw = length(bp);
t_raw = (0:N_raw-1)' / fs_raw;

%% Crop to analysis segment

segment_idx = t_raw >= analysis_start_s & t_raw <= analysis_end_s;

t_raw = t_raw(segment_idx);
bp = bp(segment_idx);
co2 = co2(segment_idx);
cbf_right = cbf_right(segment_idx);
cbf_left = cbf_left(segment_idx);

%% Simple artifact rejection

if use_artifact_rejection

    % Broad sanity limits for public test data.
    % These are not final clinical preprocessing thresholds.
    validArtifactRows = ...
        bp > 20 & bp < 220 & ...
        cbf_right > 5 & cbf_right < 200 & ...
        cbf_left > 5 & cbf_left < 200;

    t_raw = t_raw(validArtifactRows);
    bp = bp(validArtifactRows);
    co2 = co2(validArtifactRows);
    cbf_right = cbf_right(validArtifactRows);
    cbf_left = cbf_left(validArtifactRows);

end

%% Reset time to start at zero

t_raw = t_raw - t_raw(1);

%% Resample/interpolate to 4 Hz

t = (0:1/fs:t_raw(end))';

bp = interp1(t_raw, bp, t, "linear", "extrap");
co2 = interp1(t_raw, co2, t, "linear", "extrap");
cbf_right = interp1(t_raw, cbf_right, t, "linear", "extrap");
cbf_left = interp1(t_raw, cbf_left, t, "linear", "extrap");

%% Convert CBFV to relative units

cbf_right_rel = (cbf_right / mean(cbf_right, "omitnan")) * 100;
cbf_left_rel  = (cbf_left  / mean(cbf_left,  "omitnan")) * 100;

%% Detrend / remove baseline

bp = detrend(bp);
co2 = detrend(co2);
cbf_right_rel = detrend(cbf_right_rel);
cbf_left_rel = detrend(cbf_left_rel);

%% Remove mean after detrending

bp = bp - mean(bp, "omitnan");
co2 = co2 - mean(co2, "omitnan");
cbf_right_rel = cbf_right_rel - mean(cbf_right_rel, "omitnan");
cbf_left_rel = cbf_left_rel - mean(cbf_left_rel, "omitnan");

%% Store output

signalData.fs = fs;
signalData.fs_raw = fs_raw;

signalData.t = t;
signalData.N = length(t);
signalData.duration_seconds = t(end) - t(1);

signalData.bp = bp;
signalData.co2 = co2;
signalData.cbf = cbf_right_rel;      % default output signal

signalData.cbf_right = cbf_right_rel;
signalData.cbf_left = cbf_left_rel;

signalData.raw.t_raw = t_raw;
signalData.raw.bp = bp_raw;
signalData.raw.co2 = co2_raw;
signalData.raw.cbf_right = cbf_right_raw;
signalData.raw.cbf_left = cbf_left_raw;

signalData.rawTable = data;

signalData.description = ...
    "Public dataset using Blood_pressure, resp_uncalibrated, and right_MCA_BFV. Cropped, artifact-filtered, interpolated to 4 Hz, converted to relative CBFV, detrended, and mean-centered.";

end