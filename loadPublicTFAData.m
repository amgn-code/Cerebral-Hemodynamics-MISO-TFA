function signalData = loadPublicTFAData(filename)
% loadPublicTFAData
%
% Loads public cerebrovascular/respiratory data.
%
% Expected first columns:
%   1 = right_MCA_BFV
%   2 = left_MCA_BFV
%   3 = Blood_pressure
%   4 = resp_uncalibrated
%
% Note:
%   resp_uncalibrated is not necessarily calibrated ETCO2.
%   Treat it as a respiratory/capnography-related signal for testing.

%% Read table

data = readtable(filename, "VariableNamingRule", "preserve");

% Show actual MATLAB variable names for debugging
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

%% Sampling frequency and time vector

fs = 3;  % Hz

N = length(bp);
t = (0:N-1)' / fs;  % seconds

%% Store output

signalData.fs = fs;
signalData.t = t;
signalData.N = N;
signalData.duration_seconds = t(end);

signalData.bp = bp;
signalData.co2 = co2;
signalData.cbf = cbf_right;      % default CBF signal

signalData.cbf_right = cbf_right;
signalData.cbf_left = cbf_left;

signalData.rawTable = data;

signalData.description = ...
    "Public dataset using Blood_pressure, resp_uncalibrated, and right_MCA_BFV.";

end