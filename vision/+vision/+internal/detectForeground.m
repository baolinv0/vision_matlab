function [fgMask, W, M, V] = detectForeground(I, learningRate, ...
                                              W, M, V, varargin)  %#codegen                                          
% detectForeground Detect foreground using Gaussian Mixture Models
%    
%   References:
% [1]  P. Kaewtrakulpong, R. Bowden, "An Improved Adaptive Background 
%      Mixture Model for Realtime Tracking with Shadow Detection". In Proc. 
%      2nd European Workshop on Advanced Video Based Surveillance Systems, 
%      AVBS01, VIDEO BASED SURVEILLANCE SYSTEMS: Computer Vision and 
%      Distributed Processing (September 2001)
%
% [2]  Stauffer, C. and Grimson, W.E.L, "Adaptive Background Mixture Models 
%      for Real-Time Tracking". Computer Vision and Pattern Recognition, 
%      IEEE Computer Society Conference on, Vol. 2 (06 August 1999), 
%      pp. 2246-252 Vol. 2.

% Copyright 2009 The MathWorks, Inc.

[classToUse, paramStruct] = parseInputs(varargin{:});

[fgMask, W, M, V] = detectForegroundAlgorithm(I, learningRate, W, M, V, ...
                                             classToUse, paramStruct);


function [fgMask, Weights, Means, Variances] = detectForegroundAlgorithm...
    (I, learningRate, Weights, Means, Variances, ...
    classToUse, p) 

% numChannels and frameSize of image I with singleton extensions
iSize = size(I);
if length(iSize) > 2
    numChannels = iSize(3);
else
    numChannels = 1;
end
if length(iSize) > 1
    frameSize = iSize(1:2);
else
    frameSize = [iSize(1), 1];
end

% allocate per pixel buffers
states.w = coder.nullcopy(zeros(1, p.numGaussians, classToUse));
states.m = coder.nullcopy(zeros(numChannels, p.numGaussians, classToUse));
states.v = coder.nullcopy(zeros(numChannels, p.numGaussians, classToUse));

% allocate output fgMask
fgMask = coder.nullcopy(false(frameSize));

% allocate buffer for pixel data
x = coder.nullcopy(ones([numChannels 1], classToUse));

% pre-compute offset into I
numPixels = iSize(1)*iSize(2);
offset = (0:numChannels)*numPixels;


% for each pixel
% The loop below could have been written as two nested loops thus avoiding 
% computation of col and row per each pixel.  Instead, it was reduced to
% a single loop because MATLAB Coder is able to better optimize the loop.
for pixel = 1:numPixels
   
    % extract pixel data
    for c = 1:numChannels        
        x(c) = I(pixel + offset(c));
    end
    
    % get per pixel parameters from parameter buffers    
    states.w(:)    = Weights(:, pixel);
    states.m(:, :) = Means(:, :, pixel);
    states.v(:, :) = Variances(:, :, pixel);
           
    % initialize model update mechanism
    match = false;
    kCurr = p.numGaussians;
    kHit = cast(1, classToUse);
        
    % for each Gaussian mode
    for k = 1:p.numGaussians
        kCurr = k;
        if (states.w(k) <= 0) % this mode needs to be initialized
            break;
        end

        % compute distance of pixel from gaussian mean
        d = x(:) - states.m(:,k);
        dd = d.*d;
        normD = sum(dd);
        
        % compute if the pixel belongs to kth mode
        match = normD<(p.varianceThreshold * sum(states.v(:,k)));
                
        if match
                        
            % update model parameters if match occured            
            states = updateModelParameters(states, k, learningRate, ...
                d, dd);                           
                
            % sort model parameters based on updated rank
            [states, kHit] = sortModelParameters(states, k, ...
                classToUse, p.numGaussians);            
            
            break; % winner takes all
        end
        
    end
        
    if (~match)
        kHit = kCurr;                   
        % reinitialize lowest ranked gaussian mode
        states = initializeModelParameters(states, kHit, p, x);    
    end    
        
    % normalize weights
    wSum = sum(states.w);
    wScale = 1/wSum;
    states.w = states.w .* wScale;        
    
    % compute background model
    % the first kBackground modes in the sorted model make up the
    % background model
    [states, kBackground] = getBackgroundModel(states, p, ...
        classToUse);
        
    % compute fgMask
    % a pixel is a foreground pixel if it does not belong to the
    % background model computed above
    fgMask(pixel) = (kHit>kBackground);
       
    % put the per pixel model parameters back into parameter buffers
    Weights(:, pixel)      = states.w;
    Means(:, :, pixel)     = states.m;
    Variances(:, :, pixel) = states.v;

end


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% HELPER METHODS
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%--------------------------------------------------------------------------
function states = updateModelParameters(states, k, learningRate, ...
    d, dd) 
% - updates model parameters for each of the kth gaussian mode
% - implements update equations derived from [2]

for c = 1:size(states.m, 1)
    % mean
    states.m(c,k) = states.m(c,k) + learningRate * d(c);
    % variance
    states.v(c,k) = states.v(c,k) + learningRate * (dd(c) - states.v(c,k));    
end
% weight
states.w(k)    = states.w(k) + learningRate * (1 - states.w(k));

%--------------------------------------------------------------------------
function [states, kHit] = sortModelParameters(states, k, ...
                                              classToUse, numGaussians)
% - sorts model parameters based on rank

kHit = cast(1, classToUse); % return early if k == kHit
if (k == kHit)
    return;
end

gaussianRank = coder.nullcopy(zeros(1, numGaussians, classToUse));

% Compute the rank of each model
for i = 1:k
    gaussianRank(i) = states.w(i) / sqrt(sum(states.v(:,i)));
end    

% sort by rank
for ki = k:-1:2
    kHit = ki;               
    if gaussianRank(ki-1) >= gaussianRank(ki) % ordered correctly
        break;                                % no need to swap
    end
    % swap model parameters if rank ordering is wrong
    states = swapModelParameters(states, ki-1, ki);
    kHit = ki-1; % kHit changes after the swap
end

%--------------------------------------------------------------------------
function states = initializeModelParameters(states, k, p, x)
states.w(k) = p.initialWeight;
for c=1:size(states.m, 1)
    states.m(c,k) = x(c); % mean at current pixel
    states.v(c,k) = p.initialVariance;
end

%--------------------------------------------------------------------------
function [states, kBackground] = getBackgroundModel(states, p, ...
    classToUse)
% - getBackgoroundModel computes the number of
%   gaussians in the sorted mixture that make the background model
kBackground = cast(-1, classToUse); % set to invalid value
wSum = cast(0, classToUse);
for k=1:p.numGaussians    
    wSum = wSum + states.w(k); % accumulate weights of all modes
    if ((p.minimumBackgroundRatio - wSum) <= eps(classToUse)) 
        kBackground = k;
        return;
    end
end

%--------------------------------------------------------------------------
function  states = swapModelParameters(states, idx1, idx2)
% swap w, m and v
states.w  = swap(states.w, 1, idx1, idx2);
for c = 1:size(states.m, 1)
    states.m = swap(states.m, c, idx1, idx2);
    states.v = swap(states.v, c, idx1, idx2);
end

%--------------------------------------------------------------------------
function x = swap(x,c,idx1,idx2)
% swap element at (c,idx1) of 2D array x with element at (c,idx2)
temp = x(c,idx1);
x(c,idx1) = x(c,idx2);
x(c,idx2) = temp;

%--------------------------------------------------------------------------
function [classToUse, paramStruct] = parseInputs(varargin)
classToUse = varargin{1};
paramStruct.numGaussians           = cast(varargin{2}, classToUse);
paramStruct.varianceThreshold      = cast(varargin{3}, classToUse);
paramStruct.minimumBackgroundRatio = cast(varargin{4}, classToUse);
paramStruct.initialWeight          = cast(varargin{5}, classToUse);
paramStruct.initialVariance        = cast(varargin{6}, classToUse);
