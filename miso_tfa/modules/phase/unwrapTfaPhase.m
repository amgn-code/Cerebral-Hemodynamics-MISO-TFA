function phaseUnwrapped = unwrapTfaPhase( ...
    phaseWrapped, f, coherence, phaseSettings)
% unwrapTfaPhase Unwrap TFA phase using the selected analysis method.

    unwrapMethod = string(phaseSettings.unwrapMethod);

    if unwrapMethod == "standard"
        phaseUnwrapped = unwrap(phaseWrapped);
    elseif unwrapMethod == "custom"
        phaseUnwrapped = customPhaseUnwrap( ...
            phaseWrapped, f, coherence, phaseSettings.custom);
    else
        error( ...
            'TFA:UnknownPhaseUnwrapMethod', ...
            'phase.unwrapMethod must be "standard" or "custom".');
    end

end
