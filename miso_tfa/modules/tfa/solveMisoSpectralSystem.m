function solution = solveMisoSpectralSystem( ...
    inputSpectralMatrix, inputOutputSpectrum, solverSettings)
% solveMisoSpectralSystem Solve one two-input spectral system.
%
% inputSpectralMatrix is the 2-by-2 spectral matrix of MAP and CO2.
% inputOutputSpectrum is the 2-by-1 cross-spectrum with CBFV.
%
% The function reports both raw and scale-normalized conditioning. Ridge
% regularization is performed after scaling each input to unit spectral
% power. This makes one lambda value comparable when MAP and CO2 have
% different units or spectral power.

    if nargin < 3
        solverSettings = defaultMisoSolverSettings();
    else
        solverSettings = validateMisoSolverSettings(solverSettings);
    end

    validateattributes( ...
        inputSpectralMatrix, {'numeric'}, {'size', [2 2]}, ...
        mfilename, 'inputSpectralMatrix');
    validateattributes( ...
        inputOutputSpectrum, {'numeric'}, {'size', [2 1]}, ...
        mfilename, 'inputOutputSpectrum');

    nanCoefficients = complex(NaN(2, 1));
    solution.unregularizedCoefficients = nanCoefficients;
    solution.ridgeCoefficients = nanCoefficients;
    solution.selectedCoefficients = nanCoefficients;
    solution.inputScale = NaN(2, 1);
    solution.rawConditionNumber = NaN;
    solution.normalizedConditionNumber = NaN;
    solution.normalizedDeterminant = NaN;
    solution.minimumNormalizedEigenvalue = NaN;
    solution.reciprocalConditionEstimate = NaN;
    solution.isFiniteSystem = false;
    solution.isPoorlyConditioned = true;
    solution.usedRegularization = ...
        solverSettings.regularization.enabled;
    solution.lambda = solverSettings.regularization.lambda;
    solution.status = "Invalid input spectral matrix";

    if any(~isfinite(inputSpectralMatrix), "all") || ...
            any(~isfinite(inputOutputSpectrum), "all")
        return
    end

    % Small imaginary diagonal values can arise from finite precision.
    % Symmetrizing keeps the matrix consistent with a spectral matrix.
    inputSpectralMatrix = ...
        (inputSpectralMatrix + inputSpectralMatrix') / 2;
    inputPowers = real(diag(inputSpectralMatrix));

    if any(inputPowers <= 0)
        solution.status = "Input power must be positive";
        return
    end

    inputScale = sqrt(inputPowers);
    scaleMatrix = diag(inputScale);
    normalizedMatrix = ...
        scaleMatrix \ inputSpectralMatrix / scaleMatrix;
    normalizedCrossSpectrum = ...
        scaleMatrix \ inputOutputSpectrum;

    solution.inputScale = inputScale;
    solution.rawConditionNumber = cond(inputSpectralMatrix);
    solution.normalizedConditionNumber = cond(normalizedMatrix);
    solution.normalizedDeterminant = real(det(normalizedMatrix));
    normalizedEigenvalues = real(eig(normalizedMatrix));
    solution.minimumNormalizedEigenvalue = ...
        min(normalizedEigenvalues);
    solution.reciprocalConditionEstimate = rcond(normalizedMatrix);
    solution.isFiniteSystem = ...
        all(isfinite(normalizedMatrix), "all") && ...
        all(isfinite(normalizedCrossSpectrum), "all");
    solution.isPoorlyConditioned = ...
        ~isfinite(solution.normalizedConditionNumber) || ...
        solution.normalizedConditionNumber >= ...
        solverSettings.poorConditionThreshold;

    directCoefficients = ...
        inputSpectralMatrix \ inputOutputSpectrum;
    solution.unregularizedCoefficients = directCoefficients;

    lambda = solverSettings.regularization.lambda;
    ridgeCoefficientsNormalized = ...
        (normalizedMatrix + lambda*eye(2)) \ ...
        normalizedCrossSpectrum;
    ridgeCoefficients = ...
        scaleMatrix \ ridgeCoefficientsNormalized;
    solution.ridgeCoefficients = ridgeCoefficients;

    if solverSettings.regularization.enabled
        solution.selectedCoefficients = ridgeCoefficients;
        solution.status = "Solved with standardized ridge";
    else
        solution.selectedCoefficients = directCoefficients;
        solution.status = "Solved without regularization";
    end

end
