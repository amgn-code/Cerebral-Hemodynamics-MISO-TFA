%% Clean Start
clc
clearvars
close all

%% SHO's MISO Toy Signal

signalData = createShoMisoSignal();

bp = signalData.bp;
co2 = signalData.co2;
cbf = signalData.cbf;
fs = signalData.fs;
t = signalData.t;


%% Visualize Starting Data

figure()

subplot(2,1,1)
plot(t, bp)
hold on
plot(t, co2)
hold off

title('BP & CO2 Inputs vs. Time')
xlabel('Time (s)')
ylabel('Amplitude')
legend('BP', 'CO2')
grid on

subplot(2,1,2)
plot(t, cbf)

title('CBF Output vs. Time')
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

tfaResults = runTFA(bp, co2, cbf, fs);

