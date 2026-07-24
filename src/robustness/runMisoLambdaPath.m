function lambdaResults = runMisoLambdaPath( ...
    analysisInput, analysisSettings, lambdas)
% runMisoLambdaPath Refit standardized ridge over selected lambda values.

    if nargin < 3
        lambdas = [0 0.0001 0.001 0.01 0.1 1];
    end

    spectra = estimateWelchSpectra( ...
        analysisInput.map, analysisInput.co2, analysisInput.cbv, ...
        analysisInput.fs, analysisSettings.pwelch);
    siso = runSISOTFA(spectra, analysisSettings.phase);
    siso = limitResultsToFrequencyRange( ...
        siso, "siso", analysisSettings.frequencyRangeHz);

    allRows = table();
    for lambdaIndex = 1:numel(lambdas)
        solverSettings = defaultMisoSolverSettings();
        solverSettings.regularization.enabled = lambdas(lambdaIndex) > 0;
        solverSettings.regularization.lambda = lambdas(lambdaIndex);
        miso = runMISOTFA( ...
            spectra, analysisSettings.phase, solverSettings);
        miso = limitResultsToFrequencyRange( ...
            miso, "miso", analysisSettings.frequencyRangeHz);

        comparison.miso = miso;
        comparison.siso = siso;
        currentRows = summarizeGainModelComparisonByBand( ...
            comparison, analysisSettings);
        currentRows.Lambda = repmat( ...
            lambdas(lambdaIndex), height(currentRows), 1);
        allRows = [allRows; currentRows];
    end

    lambdaResults.summary = allRows;
    lambdaResults.lambdas = lambdas(:);

end
