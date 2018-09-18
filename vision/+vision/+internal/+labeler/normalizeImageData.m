function im = normalizeImageData(im)
%normalizeImageData
% normalizeImageData casts the input image IM to data type single. If the
% input image IM is single or double, this function will replace NaN, Inf,
% and -Inf with 0, 1, and 0, respectively, and scale any data outside the
% range [0 1] to be within the range [0 1]. Grayscale images are converted
% to RGB for display purposes.

% Copyright 2017 The MathWorks, Inc.

isFloat = isa(im,'single') || isa(im,'double');

if isFloat
    
    % Check if image has NaN, Inf or -Inf valued pixels.
    finiteIdx       = isfinite(im(:));
    hasNansInfs     = ~all(finiteIdx);
    
    % Check if image pixels are outside [0,1].
    isOutsideRange  = any(im(finiteIdx)>1) || any(im(finiteIdx)<0);
    
    % First clean-up data by removing NaN's and Inf's.
    if hasNansInfs
        % Replace nan pixels with 0.
        im(isnan(im)) = 0;
        % Replace inf pixels with 1.
        im(im == Inf) = 1;
        % Replace -inf pixels with 0.
        im(im == -Inf) = 0;
    end
    
    % Normalize data in [0,1] if outside range.
    if isOutsideRange
        imMax = max(im(:));
        imMin = min(im(:));
        if isequal(imMax,imMin)
            % If imMin equals imMax, the scaling will return
            % an image of all NaNs. Replace with zeros;
            im = 0*im;
        else
            if hasNansInfs
                % Only normalize the pixels that were finite.
                im(finiteIdx) = (im(finiteIdx) - imMin) ./ (imMax - imMin);
            else
                im = (im-imMin) ./ (imMax - imMin);
            end
        end
    end
end
% Cast to single precision
im = im2single(im);

% Convert grayscale images into RGB
if size(im,3) == 1
    im = repmat(im,[1 1 3]);
end

end