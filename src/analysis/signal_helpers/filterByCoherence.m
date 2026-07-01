function H_filtered = filterByCoherence(H, coherence, threshold)

    H_filtered = H;
    H_filtered(coherence < threshold) = NaN;

end