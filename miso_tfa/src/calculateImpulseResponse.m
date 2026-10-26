function impulse = calculateImpulseResponse(oneSidedResponse, fs, fftLength, bandHz)
% calculateImpulseResponse Invert a complete, uniformly spaced one-sided TF.
%
% Retain bandHz, zero the other frequencies, restore negative frequencies
% by conjugate symmetry, then IFFT. Multiplication by fs gives response per
% second: sum(response)/fs equals the retained DC gain. This is a periodic,
% band-limited impulse estimate; negative lags and ringing may be present.
% It is not obtained by applying IFFT to the cropped reporting-band vector.

    arguments
        oneSidedResponse (:,1) double
        fs (1,1) double {mustBePositive}
        fftLength (1,1) double {mustBeInteger, mustBePositive}
        bandHz (1,2) double
    end
    assert(numel(oneSidedResponse) == floor(fftLength/2) + 1, ...
        "TFA:ImpulseGrid", "Pass the full DC-to-Nyquist TF and its original FFT length.");
    frequencyHz = (0:floor(fftLength/2))'*fs/fftLength;
    retained = frequencyHz >= bandHz(1) & frequencyHz <= bandHz(2);
    positive = complex(zeros(size(oneSidedResponse)));
    positive(retained) = oneSidedResponse(retained);
    % An unidentified frequency invalidates this inverse, rather than being
    % replaced by zero and presented as a fully identified response.
    if any(~isfinite(positive(retained)))
        response = NaN(fftLength, 1);
    else
        positive(1) = real(positive(1));
        if mod(fftLength, 2) == 0
            positive(end) = real(positive(end));
            twoSided = [positive; conj(positive(end - 1:-1:2))];
        else
            twoSided = [positive; conj(positive(end:-1:2))];
        end
        response = fftshift(real(ifft(twoSided)))*fs;
    end
    impulse.timeSeconds = (-floor(fftLength/2):ceil(fftLength/2) - 1)'/fs;
    impulse.response = response;
    impulse.bandHz = bandHz;
end
