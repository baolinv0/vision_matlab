function filters = channelCorrelation(chns, wFilter, nFilter)
% Compute filters capturing local correlations for each channel.
%
% This code is a modified version of that found in:
%
% Piotr's Computer Vision Matlab Toolbox      Version 3.23
% Copyright 2014 Piotr Dollar & Ron Appel.  [pdollar-at-gmail.com]
% Licensed under the Simplified BSD License [see pdollar_toolbox.rights]

[~, ~, m, n] = size(chns); 
w = wFilter; 
wp = w * 2 - 1;
filters = zeros(w, w, m, nFilter, 'single');
for i = 1 : m  
    % compute local auto-decorrelation using Wiener-Khinchin theorem
    mus = squeeze(mean(mean(chns(:,:,i,:)))); 
    sig = cell(1, n);
    for j = 1 : n
        T = fftshift(ifft2(abs(fft2(chns(:,:,i,j)-mean(mus))).^2));
        sig{j} = T(floor(end/2)+1-w+(1:wp),floor(end/2)+1-w+(1:wp));
    end
    
    sig = double(mean(cat(4, sig{mus > 1/50}), 4));
    sig = reshape(full(convmtx2(sig, w, w)), wp+w-1, wp+w-1, []);
    sig = reshape(sig(w:wp, w:wp, :), w^2, w^2); 
    sig = (sig + sig') / 2;
    % compute filters for each channel from sig (sorted by eigenvalue)
    [fs, D] = eig(sig); 
    fs = reshape(fs, w, w, []);
    [~,ord] = sort(diag(D), 'descend');
    fs = flipdim(flipdim(fs, 1), 2); %#ok<DFLIPDIM>
    filters(:, :, i, :) = fs(:, :, ord(1 : nFilter));
end