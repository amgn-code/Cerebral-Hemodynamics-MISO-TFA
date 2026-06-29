%% Clean Start

clear; clc; close all;

project_root = pwd;
addpath(genpath(project_root));
rehash

%% Load Dataset

subjectNum = '547';
excel_file = "/Users/amoghn/Downloads/547_baseline_1.xlsx"; % Change to File Location
signalData = loadData(excel_file);
preprocessedsignalData = btbPreProcessing(signalData);

%% Assign Data

map = preprocessedsignalData.map;
co2 = preprocessedsignalData.co2;
cbv = preprocessedsignalData.cbv;
fs = preprocessedsignalData.fs;
t = preprocessedsignalData.t;

%% Visualize Starting Data

visualizeTimeSeries(t, map, co2, cbv)

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

tfaResults = runMISOTFA(map, co2, cbv, fs);

%% SISO Model
sisoResults = runSISOTFA(map, co2, cbv, fs);

%% Output Folder

baseOutputFolder = "/Users/amoghn/Desktop/TFA Results";
confidenceLevel = preprocessedsignalData.confidenceLevel;
outputFolder = fullfile(baseOutputFolder, confidenceLevel, subjectNum);

if ~exist(outputFolder, "dir")
    mkdir(outputFolder);
end

%% Save Data to Excel

filename = fullfile(outputFolder, "miso_tfa_results.xlsx");
sheetName = "MISO TFA Results";

saveDatatoExcel(filename, sheetName, tfaResults);

%% Save Figures

figures = findall(0, "Type", "figure");

for k = 1:numel(figures)

    fig = figures(k);
    figure(fig)

    set(fig, "WindowState", "maximized")
    pause(0.2)

    figurePath = fullfile(outputFolder, sprintf("Figure_%02d.png", k));
    exportgraphics(fig, figurePath, "Resolution", 300);

end
