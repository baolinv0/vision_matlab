function [Is, IsOrig] = sampleWindows(imds, bboxes, params, positive, detector, printer)
% Sample windows for training detector.
%
% imds     : an ImageDatastore object
% bboxes   : a cell array of bounding boxes
% params   : struct of parameters
% positive : true if we want to sample positive examples, false for
%            negative examples
% 
% Is       : 4-dimension array (h x w x channel x k), each (h x w x channel)
%            block is a cropped/resized/jittered image
% IsOrig   : 4-dimension array, each block is an image without jittering

% This code is a modified version of that found in:
%
% Piotr's Computer Vision Matlab Toolbox      Version 3.23
% Copyright 2014 Piotr Dollar & Ron Appel.  [pdollar-at-gmail.com]
% Licensed under the Simplified BSD License [see pdollar_toolbox.rights]

narginchk(5, 6);
verbose = (nargin == 6);

numImages   = length(imds.Files);
shrink      = params.Shrink;
modelDs     = params.ModelSize;
modelDsPad  = params.ModelSizePadded;
modelDsBig  = max(8 * shrink, modelDsPad) + max(2, ceil(64 / shrink)) * shrink;
ratio       = modelDsBig ./ modelDs; 
if params.UseParallel
    pool = gcp('nocreate');
    if isempty(pool)
        tryToCreateLocalPool();
    end
    modelDsBigConst = parallel.pool.Constant(modelDsBig);
    ratioConst = parallel.pool.Constant(ratio);
end    

Is = cell(numImages*max(100,params.NumNegativePerImage), 1);
k = 0; 
i = 0; 
batchSize = 16;
if positive
    n = params.NumPositiveSamples;
    if verbose
        printer.printMessageNoReturn('vision:acfObjectDetector:trainSamplePositive');
    end
else
    % It might not be able to retrieve n negative examples, either because
    % the number of negative examples per image is too few, or the detector
    % is too good to return any false alarms, or there are not enough
    % images.
    n = params.NumNegativeSamples;
    if verbose
        printer.printMessageNoReturn('vision:acfObjectDetector:trainSampleNegative');
    end
end

if verbose
    msg = [sprintf('(~%d%', 0),'%% Completed)'];
    printer.printDoNotEscapePercent(msg);
end

while (i < numImages && k < n)
    batchSize = min(batchSize, numImages-i); 
    Is1 = cell(1, batchSize);
    bboxes1 = bboxes(i+1:i+batchSize);
    
    if params.UseParallel
        parfor j = 1 : batchSize 
            I = readimage(imds, i+j);
            if ismatrix(I)
                I = cat(3, I, I, I);
            end
            bbs = bboxes1{j};
            if ~positive
                bbs = sampleWins(I, bbs, detector, params);
            end
            bbs = vision.internal.acf.resizeBboxes(bbs, ratioConst.Value(1), ratioConst.Value(2));
            Is1{j} = vision.internal.acf.cropBboxes(I, bbs, 'replicate', modelDsBigConst.Value([2 1]));
        end
    else
        for j = 1 : batchSize 
            I = readimage(imds, i+j);
            if ismatrix(I)
                I = cat(3, I, I, I);
            end
            bbs = bboxes1{j};
            if ~positive
                bbs = sampleWins(I, bbs, detector, params);
            end
            bbs = vision.internal.acf.resizeBboxes(bbs, ratio(1), ratio(2));
            Is1{j} = vision.internal.acf.cropBboxes(I, bbs, 'replicate', modelDsBig([2 1]));
        end
    end
    Is1 = [Is1{:}]; 
    k1 = length(Is1); 
    Is(k + 1:k + k1) = Is1; 
    k = k + k1;
    if k > n
        Is = Is(vision.internal.samplingWithoutReplacement(k, n)); 
        k = n; 
    end
    i = i + batchSize;

    if verbose
        nextMessage = [sprintf('(~%d%', round(100*k/n)),'%% Completed)'];
        msg = updateMessage(printer, numel(msg)-1, nextMessage);
    end
end
Is = Is(1 : k); 

if verbose
    if k ~= n 
        nextMessage = [sprintf('(~%d%', 100),'%% Completed)'];
        updateMessage(printer, numel(msg)-1, nextMessage);
    end
    printer.linebreak;
end

if length(Is) < 2 % make sure this returns a 4-D array
    Is = [];
    if nargout > 1
        IsOrig = Is;
    end
    return
end

nd = ndims(Is{1}) + 1; 
Is = cat(nd, Is{:});

if nargout > 1
    IsOrig = Is;
end

% optionally jitter positive windows
if params.MaxJitters > 0  
    Is = vision.internal.acf.jitterImage(Is, ...
        'MaxJitters', params.MaxJitters, ...
        'NumSteps', params.NumSteps, ...
        'Bound', params.Bound, ...
        'Flip', params.Flip, ...
        'HasChn', (nd==4));
    ds = size(Is); 
    ds(nd) = ds(nd) * ds(nd+1); 
    Is = reshape(Is, ds(1:nd));
end

% make sure dims are divisible by shrink and not smaller than modelDsPad
ds = size(Is); 
cr = rem(ds(1:2), shrink); 
s = floor(cr / 2) + 1;
e = ceil(cr / 2); 
Is = Is(s(1):end-e(1), s(2):end-e(2), :, :); 
ds = size(Is);
if any(ds(1:2) < modelDsPad)
    error(message('vision:acfObjectDetector:trainSampleWindowTooSmall')); 
end

%--------------------------------------------------------------------------
function bboxes = sampleWins(I, gt, detector, params)
% Sample windows from I given its ground truth gt.
if isempty(detector)
    % generate candidate bounding boxes in a grid
    [h, w, ~] = size(I); 
    h1 = params.ModelSize(1); 
    w1 = params.ModelSize(2);
    n = params.NumNegativePerImage; 
    ny = sqrt(n*h/w); 
    nx = n/ny; 
    ny = ceil(ny); 
    nx = ceil(nx);
    [xs, ys] = meshgrid(linspace(1,w-w1,nx),linspace(1,h-h1,ny));
    bboxes = [xs(:) ys(:)]; 
    bboxes(:,3) = w1; 
    bboxes(:,4) = h1; 
    bboxes = bboxes(1:min(n, size(bboxes, 1)), :);
else
    % run detector to generate candidate bounding boxes
    P = vision.internal.acf.computePyramid(I, params);
    [bboxes, scores] = vision.internal.acf.detect(P, detector, params);
    [~, ord] = sort(scores, 'descend');
    bboxes = bboxes(ord(1:min(length(ord), params.NumNegativePerImage)), :);
end

if (~isempty(gt))
    % discard any candidate negative bb that matches the gt
    n = size(bboxes, 1); 
    keep = false(1, n);
    for i = 1 : n
        o = bboxOverlapRatio(bboxes(i,:), gt);
        keep(i) = all(o < 0.1); 
    end
    bboxes = bboxes(keep, :);
end

%--------------------------------------------------------------------------
function nextMessage = updateMessage(printer, prevMessageSize, nextMessage)
backspace = sprintf(repmat('\b',1,prevMessageSize)); % figure how much to delete
printer.printDoNotEscapePercent([backspace nextMessage]);

%--------------------------------------------------------------------------
function pool = tryToCreateLocalPool()
defaultProfile = ...
    parallel.internal.settings.ProfileExpander.getClusterType(parallel.defaultClusterProfile());

if(defaultProfile == parallel.internal.types.SchedulerType.Local)
    % Create the default pool (ensured local)
    pool = parpool;
else
    % Default profile not local   
    error(message('vision:vision_utils:noLocalPool', parallel.defaultClusterProfile()));    
end
