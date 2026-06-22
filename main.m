%% Clean Start

clear; clc; close all;

project_root = pwd;
addpath(genpath(project_root));
rehash

%% Signal Generation

%excel_file = ;
%signalData = loadExcelTFAData(excel_file);
%signalData = createShoMisoSignal();
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

%% Save Figures to Project

% 1. Create the output folder if it doesn't exist
outputFolder = 'exported_figures';
if ~exist(outputFolder, 'dir')
    mkdir(outputFolder);
end

allFigs = findall(0, 'Type', 'figure');

for i = 1:numel(allFigs)
    figHandle = allFigs(i);
    
    % --- NEW SIZE ADJUSTMENT CODE ---
    % 1. Store the original size so we don't break your current screen view
    origUnits = figHandle.Units;
    origPos = figHandle.Position;
    
    % 2. Set units to pixels and define a large, spacious canvas size
    % [Left, Bottom, Width, Height] -> 1600x900 is a standard clear widescreen
    figHandle.Units = 'pixels';
    figHandle.Position = [100, 100, 1600, 900]; 
    
    % 3. Force MATLAB to redraw the text/axes with the new spacious dimensions
    drawnow;
    % --------------------------------
    
    % Dynamic name cleaning
    customName = figHandle.Name; 
    if isempty(customName)
        customName = sprintf('Figure_%d', figHandle.Number);
    else
        customName = regexprep(customName, '[\s\./\\:\*,?"<>|]', '_');
    end
    
    fileName = fullfile(outputFolder, [customName '.png']);
    
    % Export with high resolution
    exportgraphics(figHandle, fileName, 'Resolution', 300);
    
    % 4. Restore the figure back to its original screen layout size
    figHandle.Units = origUnits;
    figHandle.Position = origPos;
end