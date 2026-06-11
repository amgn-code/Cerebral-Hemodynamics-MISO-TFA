function [window, window_overlap_n, fft_length_n, num_windows] = ...
    windowSettings(window_length_s, window_overlap, fs, signal_length)

    window_length_n = round(window_length_s * fs);

    window = hann(window_length_n);

    window_overlap_n = round(window_length_n * window_overlap);

    fft_length_n = window_length_n;

    window_step_n = window_length_n - window_overlap_n;

    num_windows = floor((signal_length - window_length_n) / window_step_n) + 1;

end