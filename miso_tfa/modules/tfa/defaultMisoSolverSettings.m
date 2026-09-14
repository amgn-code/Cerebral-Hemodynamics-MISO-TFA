function solverSettings = defaultMisoSolverSettings()
% defaultMisoSolverSettings Return readable defaults for the MISO solve.
%
% The ordinary, unregularized MISO solution remains the default. Ridge
% regularization is available as an explicit sensitivity analysis.

    solverSettings.regularization.enabled = false;
    solverSettings.regularization.lambda = 0;

    % This threshold only creates a diagnostic flag. It does not change
    % the estimated transfer functions or exclude frequency bins.
    solverSettings.poorConditionThreshold = 100;

end
