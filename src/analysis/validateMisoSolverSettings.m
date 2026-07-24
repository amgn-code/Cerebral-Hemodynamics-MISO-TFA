function solverSettings = validateMisoSolverSettings(solverSettings)
% validateMisoSolverSettings Fill defaults and validate MISO solver options.

    defaultSettings = defaultMisoSolverSettings();

    if nargin < 1 || isempty(solverSettings)
        solverSettings = defaultSettings;
        return
    end

    if ~isfield(solverSettings, "regularization")
        solverSettings.regularization = ...
            defaultSettings.regularization;
    end
    if ~isfield(solverSettings.regularization, "enabled")
        solverSettings.regularization.enabled = ...
            defaultSettings.regularization.enabled;
    end
    if ~isfield(solverSettings.regularization, "lambda")
        solverSettings.regularization.lambda = ...
            defaultSettings.regularization.lambda;
    end
    if ~isfield(solverSettings, "poorConditionThreshold")
        solverSettings.poorConditionThreshold = ...
            defaultSettings.poorConditionThreshold;
    end

    enabled = solverSettings.regularization.enabled;
    if ~islogical(enabled) || ~isscalar(enabled)
        error( ...
            "TFA:InvalidRegularizationToggle", ...
            "misoSolver.regularization.enabled must be true or false.");
    end

    validateattributes( ...
        solverSettings.regularization.lambda, {'numeric'}, ...
        {'real', 'finite', 'scalar', 'nonnegative'}, ...
        mfilename, 'misoSolver.regularization.lambda');
    validateattributes( ...
        solverSettings.poorConditionThreshold, {'numeric'}, ...
        {'real', 'scalar', 'positive'}, ...
        mfilename, 'misoSolver.poorConditionThreshold');

    solverSettings.regularization.enabled = logical(enabled);
    solverSettings.regularization.lambda = ...
        double(solverSettings.regularization.lambda);
    solverSettings.poorConditionThreshold = ...
        double(solverSettings.poorConditionThreshold);

end
