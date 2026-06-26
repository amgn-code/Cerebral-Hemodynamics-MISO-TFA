function [window, window_overlap_n, fft_length_n, num_windows] = ...
    windowSettings(window_length_s, window_overlap, fs, signal_length)

    % Window length in samples
    window_length_n = round(window_length_s * fs);

    % Hann window
    window = hann(window_length_n);

    % Overlap in samples
    window_overlap_n = round(window_length_n * window_overlap);

    % Step size between windows
    window_step_n = window_length_n - window_overlap_n;

    % Number of Welch windows
    num_windows = floor((signal_length - window_length_n) / window_step_n) + 1;

    % Zero-padded FFT length
    target_df = 0.001;  % desired displayed frequency spacing in Hz

    %{

    fft_length_n = 2^nextpow2(fs / target_df);

    % Make sure FFT length is at least as long as the window
    fft_length_n = max(fft_length_n, window_length_n);

    %}
    fft_length_n = window_length_n;

end