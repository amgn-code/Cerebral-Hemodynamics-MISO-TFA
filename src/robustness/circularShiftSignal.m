function shiftedSignal = circularShiftSignal(signal, shiftSamples)
% circularShiftSignal Shift a vector without changing its stored values.

    validateattributes( ...
        shiftSamples, {'numeric'}, ...
        {'real', 'finite', 'scalar', 'integer'}, ...
        mfilename, 'shiftSamples');

    wasRow = isrow(signal);
    shiftedSignal = circshift(signal(:), shiftSamples);
    if wasRow
        shiftedSignal = shiftedSignal.';
    end

end
