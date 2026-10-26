function summary = summarizeAdvantage(sisoError, misoError, bootstrapSamples, confidence, seed)
% summarizeAdvantage Ratio of mean paired errors, with Monte Carlo uncertainty.
%
% A = log10(mean(SISO error)/mean(MISO error)); positive favors MISO.
% A gain error is absolute gain difference. A phase error is the absolute
% shortest angular difference. The optional complex error is band-normalized
% squared complex difference. We never average individual error ratios.
% Invalid estimates are counted and excluded using one shared paired mask.

    count = size(sisoError, 1);
    summary.advantage = NaN(count, 1);
    summary.sisoMeanError = NaN(count, 1);
    summary.misoMeanError = NaN(count, 1);
    summary.validPairs = zeros(count, 1);
    summary.sisoInvalid = sum(~isfinite(sisoError), 2);
    summary.misoInvalid = sum(~isfinite(misoError), 2);
    summary.monteCarloSE = NaN(count, 1);
    summary.ciLower = NaN(count, 1);
    summary.ciUpper = NaN(count, 1);
    summary.bootstrapFiniteFraction = NaN(count, 1);
    previousState = rng;
    restoreState = onCleanup(@() rng(previousState));
    rng(seed, "twister");
    for frequency = 1:count
        valid = isfinite(sisoError(frequency, :)) & isfinite(misoError(frequency, :));
        siso = sisoError(frequency, valid);
        miso = misoError(frequency, valid);
        n = numel(siso);
        summary.validPairs(frequency) = n;
        if n == 0
            continue
        end
        summary.sisoMeanError(frequency) = mean(siso);
        summary.misoMeanError(frequency) = mean(miso);
        summary.advantage(frequency) = errorRatio(mean(siso), mean(miso));
        if bootstrapSamples > 0 && n >= 2
            indices = randi(n, n, bootstrapSamples);
            bootstrap = errorRatio(mean(siso(indices), 1), mean(miso(indices), 1));
            finite = bootstrap(isfinite(bootstrap));
            summary.bootstrapFiniteFraction(frequency) = numel(finite)/bootstrapSamples;
            % Do not censor infinite resamples and report a spuriously
            % narrow interval. A degenerate log ratio has undefined SE/CI.
            if numel(finite) == bootstrapSamples
                summary.monteCarloSE(frequency) = std(finite);
                limits = prctile(finite, 100*[(1 - confidence)/2, (1 + confidence)/2]);
                summary.ciLower(frequency) = limits(1);
                summary.ciUpper(frequency) = limits(2);
            end
        end
    end
    clear restoreState
end

function advantage = errorRatio(siso, miso)
    advantage = log10(siso./miso);
    advantage(siso == 0 & miso == 0) = 0;
end
