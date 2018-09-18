function channels = computeSingleScaleChannels( Is, params )
% Compute single scale feature channels
%
% This code is a modified version of that found in:
%
% Piotr's Computer Vision Matlab Toolbox      Version 3.23
% Copyright 2014 Piotr Dollar & Ron Appel.  [pdollar-at-gmail.com]
% Licensed under the Simplified BSD License [see pdollar_toolbox.rights]

if isempty(Is)
    channels = []; 
    return; 
end

ds = size(Is); 
ds(1:end-1) = 1;
siz = size(Is);
nd = ndims(Is);
bounds = cell(1, nd);
for d = 1 : nd
    bounds{d} = repmat( siz(d)/ds(d), [1 ds(d)] ); 
end
Is = squeeze(mat2cell(Is, bounds{:})); 
channels = cell(1, length(Is));

if params.UseParallel
    parfor i = 1 : length(Is)
        channels{i} = computeFeatureChannels(Is{i}, params);
    end
else
    for i = 1 : length(Is)
        channels{i} = computeFeatureChannels(Is{i}, params);
    end
end 
channels = cat(4, channels{:});
end

function C = computeFeatureChannels(I, params)
    if isfloat(I)       
        I = single(mat2gray(I)); % scales floating point values between [0 1].       
    else
        I = im2single(I);
    end

    I = vision.internal.acf.rgb2luv(I,true);
    data = vision.internal.acf.computeChannels(I, params);
    C = vision.internal.acf.convTri(data, params.SmoothChannels);
  
    fs = params.Filters;
    if ~isempty(fs)
        C = repmat(C, [1 1 size(fs,4)]);
        for j = 1 : size(C,3) 
            C(:,:,j) = conv2(C(:,:,j),fs(:,:,j),'same'); 
        end
    end
    
    if ~isempty(fs)
        m1 = round(size(C, 1)*0.5); 
        n1 = round(size(C, 2)*0.5);
        C = visionACFResize(C, m1, n1, 1);
        shr = 2; 
    else
        shr = 1; 
    end
    
    dsTar = params.ModelSizePadded / params.Shrink; 
    ds = size(C);
    cr = ds(1:2)-dsTar/shr; 
    s = floor(cr/2)+1; 
    e = ceil(cr/2);
    C = C(s(1):end-e(1),s(2):end-e(2),:); 
end