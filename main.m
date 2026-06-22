%% Clean Start

clear; clc; close all;

project_root = pwd;
addpath(genpath(project_root));
rehash

%% Signal Generation

%excel_file = ;
signalData = loadExcelTFAData(excel_file);
%signalData = createMisoValidationSignal(false);  % false = no added noise

%public_data_file = fullfile(project_root, "data", "public_data", "subj01.csv");
%signalData = loadPublicTFAData(public_data_file);

bp = signalData.bp;
co2 = signalData.co2;
cbf = signalData.cbf;
fs = signalData.fs;
t = signalData.t;




%% Visualize Starting Data

figure()

subplot(2,1,1)

yyaxis left
plot(t, bp)
ylabel('MAP')
grid on
hold on

left_min = min(bp, [], 'omitnan');
left_max = max(bp, [], 'omitnan');
left_min = min(left_min, 0);
left_max = max(left_max, 0);

if left_min == left_max
    left_min = left_min - 1;
    left_max = left_max + 1;
end

yyaxis right
plot(t, co2)
ylabel('CO2')

right_max = max(abs(co2), [], 'omitnan');
right_max = max(right_max, 1);
right_max = 1.05 * right_max;

alignRightYAxisZero(left_min, left_max, right_max)

title('MAP and CO2 Inputs vs. Time')
xlabel('Time (s)')
legend('MAP', 'CO2', 'Location', 'best')
grid on

subplot(2,1,2)
plot(t, cbf)

title('CBV Output vs. Time')
xlabel('Time (s)')
ylabel('Amplitude')
grid on

%% PSD / Cross-Spectral Transfer Function
%
% Goal:
%   Use Welch PSD and cross spectral density:
%
%       H(f) = Sxy(f) / Sxx(f)
%
% Benefit:
%   More stable than direct FFT division.
%
% Limitation:
%   Gives one average transfer function over the full recording.
%   Does not tell us when the BP-CBF or CO2-CBF relationship changes.

tfaResults = runMISOTFA(bp, co2, cbf, fs);


%% SISO Model
sisoResults = runSISO2(bp, co2, cbf, fs);




%% Save Data to Excel

filename = "miso_tfa_results.xlsx";
sheetName = "MISO TFA Results";

saveDatatoExcel(filename, sheetName, tfaResults);