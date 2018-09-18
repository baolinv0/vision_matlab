function info = imageInformation(groundTruth, networkInputSize, useParallel)
% Returns various image related details that requires reading the image.

imds = imageDatastore(groundTruth{:,1});
numImages = numel(imds.Files);

sz = zeros(numImages, 2);
accum = zeros(1,1,networkInputSize(3));
if useParallel 
       
    parfor i = 1:numImages
       
        I = readimage(imds, i);
        
        % Return size information for each image.
        [M, N, ~] = size(I);        
        sz(i,:) = [M N];
        
        % Compute average image. Because each image can have varying size,
        % we compute the per-channel mean instead.
        accum = accum + iPerChannelMean(I, networkInputSize);
        
    end    
    
    info.sizes = sz;
    info.avg = (accum / numImages);
  
else        
    
    if height(groundTruth) > 1
        imds.ReadSize = min(10, numImages);
    end      
    
    % figure out scaling for each image
    k = 1;
    
    while hasdata(imds)
        batch = read(imds);
        if ~iscell(batch)
            batch = {batch};
        end
        for i = 1:numel(batch)
            I = batch{i};
            
            % Return size information for each image.            
            [M, N, ~] = size(I);        
            sz(k,:) = [M N];
            
            % Compute per channel mean            
            accum = accum + iPerChannelMean(I, networkInputSize);
            
            k = k + 1;
            
        end
    end
    
    
    
    info.sizes = sz;
    info.avg = single(accum ./ numImages);
     
end

%--------------------------------------------------------------------------
function avg = iPerChannelMean(I, networkInputSize)

avg = mean(mean(I));

netInputIsRGB = networkInputSize(3) > 1;

if netInputIsRGB    
    if isscalar(avg)
        % I is grayscale, duplicate to form RGB channel mean.
        avg = repelem(avg, 1,1,3);
    end
else
    % net input is grayscale, I is RGB. Use RGB2GRAY to convert.
    if ~isscalar(avg)
        avg = rgb2gray(avg);
    end
end
    


