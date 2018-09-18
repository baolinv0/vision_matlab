function IJ = jitterImage(I, varargin)
%jitterImage Creates multiple, slightly jittered versions of an image.
%   IJ = jitterImage(I) returns jittered versions of image(s) I. I can be a
%   single image or a stack of multiple images. If the input image is 
%   actually an MxNxK stack of K images then applies op to each image. IJ
%   is M-by-N-by-K-by-R or M-by-N-by-C-by-K-by-R set of images, R is the
%   total number of jitter operations.
%
%   [...] = jitterImage(...,Name, Value) specifies additional
%   name-value pairs described below:
%
%   'MaxJitters'        A nonnegative integer to specify the maximum number 
%                       of jittered images to return.
%
%                       Default: 1000
%
%   'NumSteps'          A nonnegative integer to specify the number of 
%                       translations along each axis. 
%                           
%                       Default: 0
%
%   'Bound'             A nonnegative integer to specify the range of
%                       translations. The actual operations is defined by 
%                       linspace(-Bound, Bound, NumSteps).
%
%                       Default: 0
%
%   'Flip'              A boolean scalar to specify the mirror operation
%                       that flips from the left to right.
%
%                       Default: False
%
%   'OutSize'           A 2-element vector to specify the output size of
%                       jittered image. If the size is bigger than the
%                       original image, padding is added.
%
%                       Default: [size(I, 1), size(I, 2)] 
%
%   'HasChn'            A boolean scalar to indicate the input image has
%                       multiple channels.
%
%                       Default: False
%
%   Note:
%   -----
%   For simplicity, the translation has to be an integer shift.
%
%   Example: 
%   --------------------------------
%   load trees; 
%   I = imresize(ind2gray(X, map), [41 41]); 
%   clear X caption map
%   % creates 10 (of 7^2*2) images of slight translations
%   IJ = vision.internal.acf.jitterImage(I, ...
%                    'MaxJitters', 10, ...
%                    'NumSteps', 7, ...
%                    'Bound', 3); 
%   images = zeros(size(IJ,1),size(IJ, 2), 1, size(IJ, 3));
%   images(:,:,1,:) = IJ;
%   montage(images);
 
% Copyright 2016 The MathWorks, Inc.

% get additional parameters
[maxJitters, numSteps, bound, flip, outSize, hasChn] = validateAndParseOptInputs(I, varargin{:});

% I must be big enough to support given ops so grow I if necessary
siz = size(I);
trn = linspace(-bound, bound, numSteps); 
[dX, dY] = meshgrid(trn, trn);
dY = dY(:)'; 
dX = dX(:)'; 
siz1 = outSize + 2 * max(dX); 
pad = (siz1 - siz(1 : 2)) / 2; 
pad = max([ceil(pad) 0], 0);
if any(pad > 0)
    I = padarray(I, pad, 'replicate', 'both'); 
end

% jitter each image
nOps = min(maxJitters, length(dX)); 
if flip
    nOps = nOps * 2; 
end

if hasChn
    nd = 3; 
    outSize = [outSize siz(3)]; 
else
    nd = 2; 
end

numImages = size(I, nd + 1); 
IJ = zeros([outSize nOps numImages], class(I));
is = repmat({':'}, 1, nd); 
for i = 1 : numImages
    IJ(is{:}, :, i) = jitterImageHelper(I(is{:}, i), maxJitters, outSize,...
                        dX, dY, flip); 
end

end

function IJ = jitterImageHelper(I, maxJitters, outSize, dX, dY, flip)
    % generate list of transformations (HS)
    nOps = length(dX); 
    HS = zeros(3, 3, nOps); 
    for k = 1 : nOps
        HS(:,:,k) = [eye(2) [dX(k); dY(k)]; 0 0 1]; 
    end
    % apply each transformation HS(:,:,i) to image I
    if nOps > maxJitters
        HS = HS(:, :, vision.internal.samplingWithoutReplacement(nOps, maxJitters)); 
        nOps = maxJitters; 
    end
    siz = size(I); 
    nd = ndims(I); 
    I1 = I; 
    p = (siz-outSize)/2; 
    IJ = zeros([outSize nOps], class(I));
    for i = 1 : nOps
        H = HS(:, :, i); 
        d = H(1 : 2, 3)';

        if all(mod(d, 1)==0)
            % handle transformation that's just an integer translation
            s = max(1-d, 1); 
            e = min(siz(1:2)-d, siz(1:2)); 
            s1 = 2 - min(1-d,1); 
            e1 = e - s + s1;
            I1(s1(1):e1(1), s1(2):e1(2), :) = I(s(1):e(1), s(2):e(2), :);
        else % handle general transformations
            error('do not handle non-integer translation');
        end
        % crop and store result
        I2 = I1(p(1)+1:end-p(1), p(2)+1:end-p(2), :);
        if nd == 2
            IJ(:, :, i) = I2; 
        else
            IJ(:, :, :, i) = I2;  
        end
    end
    % finally flip each resulting image
    if flip
        IJ = cat(nd+1, IJ, IJ(:,end:-1:1,:,:)); 
    end
end

function [maxJitters, numSteps, bound, flip, outSize, hasChn] = ...
    validateAndParseOptInputs(I, varargin)

    validateattributes(I, {'numeric'}, {'real'}, mfilename, 'I');
    siz = size(I);

    % Set input parser
    defaults = struct(...
        'MaxJitters', 1000, ...
        'NumSteps',  0, ...
        'Bound', 0,...
        'Flip', false,...
        'OutSize', siz(1:2),...
        'HasChn', false);

    parser = inputParser;
    parser.CaseSensitive = false;
    parser.addParameter('MaxJitters', defaults.MaxJitters, ...    
                @(x)validateattributes(x, {'double'}, {'real','scalar','nonnegative','integer'}));
    parser.addParameter('NumSteps', defaults.NumSteps, ...
                @(x)validateattributes(x, {'double'}, {'real','scalar','nonnegative','integer'}));
    parser.addParameter('Bound', defaults.Bound, ...
                @(x)validateattributes(x, {'double'}, {'real','nonempty','scalar','nonnegative','integer'}));
    parser.addParameter('Flip', defaults.Flip, ...
                @(x)validateattributes(x,{'logical'}, {'scalar','nonempty'}));
    parser.addParameter('OutSize', defaults.OutSize, ...
                @(x)validateattributes(x,{'double'}, {'real','nonempty','integer','numel', 2}));
    parser.addParameter('HasChn', defaults.HasChn, ...
                @(x)validateattributes(x,{'logical'}, {'scalar','nonempty'}));

    parser.parse(varargin{:});

    maxJitters  = parser.Results.MaxJitters;
    numSteps    = parser.Results.NumSteps;
    bound       = parser.Results.Bound;
    flip        = parser.Results.Flip;
    outSize     = parser.Results.OutSize;
    hasChn      = parser.Results.HasChn;

    if numSteps < 1
        bound = 0; 
        numSteps = 1; 
    end
end