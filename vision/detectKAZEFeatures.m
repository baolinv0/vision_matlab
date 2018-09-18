function points = detectKAZEFeatures(I, varargin) 
% detectKAZEFeatures detects KAZE features
%   points = detectKAZEFeatures(I) returns a KAZEPoints object containing
%   information about KAZE keypoints detected in a 2-D grayscale image I.
%   detectKAZEFeatures uses a non-linear diffusion process to construct a
%   scale space for the given image and detect multi-scale corner features
%   from the scale space.
%
%   points = detectKAZEFeatures(I, Name, Value) specifies additional
%   name-value pair arguments described below:
%
%   'Diffusion'         A string or character array specifying
%                       the method to be used for computing the
%                       conductivity based on first order derivatives of a
%                       layer in scale space. Possible values are:
%
%                        'region'      - This option promotes wider 
%                                        regions over smaller ones.
%                        'sharpedge'   - This option promotes 
%                                        high-contrast edges.
%                        'edge'        - This option promotes 
%                                        smoothing on both sides of 
%                                        an edge stronger than 
%                                        smoothing across it.
%
%                       Default: 'region'
%
%   'Threshold'         Double scalar, Threshold >= 0. Increase this value
%                       to exclude less significant local extrema.
%
%                       Default: 0.0001
%
%   'NumOctaves'        Integer scalar, NumOctaves >= 1. Increase this
%                       value to detect larger features. Recommended values
%                       are between 1 and 4. Setting NumOctaves to zero
%                       disables multi-scale detection and performs the
%                       detection at the scale of input image I.
%
%                       Default: 3
%
%   'NumScaleLevels'    Integer scalar, NumScaleLevels >= 3 and <= 10.
%                       Increase this value to achieve smoother scale
%                       changes, along with getting more intermediate
%                       scales between octaves. Recommended values are
%                       between 1 and 4.
%
%                       Default: 4
%
%   'ROI'               A vector of the format [X Y WIDTH HEIGHT],
%                       specifying a rectangular region in which corners
%                       will be detected. [X Y] is the upper left corner of
%                       the region.
%
%                       Default: [1 1 size(I,2) size(I,1)]
%
% Class Support
% -------------
% The input image I can be logical, uint8, int16, uint16, single, 
% or double, and it must be real and nonsparse.
%
% Notes
% -----
% 'region' method uses Perona and Malik conductivity coefficient
% 1/(1 + dL^2/k^2). 'sharpedge' method uses Perona and Malik
% conductivity coefficient exp(-|dL|^2/k^2). 'edge' method uses
% for Weickert conductivity coefficient.
%
% Example
% -------
% % Detect KAZE feature points in cameraman.tif
% I = imread('cameraman.tif');
% points = detectKAZEFeatures(I);
%
% % Plot the 20 strongest points
% imshow(I);
% hold on;
% plot(selectStrongest(points, 20));
% hold off;
%
% See also detectBRISKFeatures, detectHarrisFeatures, detectFASTFeatures,
%          detectMinEigenFeatures, detectSURFFeatures, detectMSERFeatures,
%          KAZEPoints, extractFeatures, matchFeatures

% Copyright 2017 The MathWorks, Inc.

% References
% ----------
% P. F. Alcantarilla, A. Bartoli, and A. J. Davison, KAZE Features, ECCV 2012,
% Part VI, LNCS 7577, pp. 214-227, 2012.

    params = parseInputs(I, varargin{:});
    points = detectKAZE(I, params);
end

% -------------------------------------------------------------------------
% Process image and detect KAZE features
% -------------------------------------------------------------------------
function points = detectKAZE(I, params)

    img  = vision.internal.detector.cropImageIfRequested(I, params.ROI, params.UsingROI);
    Iu8  = im2uint8(img);
    
    threshold = single(params.Threshold);
    numOctaves = uint8(adjustNumOctaves(size(Iu8),params.NumOctaves));
    numScaleLevels = uint8(params.NumScaleLevels);
    diffusivity = vision.internal.detector.convertKAZEDiffusionToOCVCode(params.Diffusion);
    
    % the following two parameters do not affect the detection process.
    extended = true; 
    upright = true;
    
    if any(size(Iu8) == 1)
        % row/column image or single pixel.
        points = KAZEPoints();
    else   
        rawPts = ocvDetectKAZE(Iu8, extended, upright, ...
                               threshold, numOctaves, ...
                               numScaleLevels, diffusivity);

        rawPts.Location = vision.internal.detector.addOffsetForROI( ...
                          rawPts.Location, params.ROI, params.UsingROI);

        points = KAZEPoints(rawPts.Location, 'Diffusion', params.Diffusion, ...
                            'NumOctaves', numOctaves, 'NumScaleLevels', numScaleLevels, ...
                            'Scale', rawPts.Scale/2, ... % diameter to radius
                            'Metric', rawPts.Metric, ...
                            'Orientation', rawPts.Orientation, 'LayerID', rawPts.Misc);
    end
end

% -------------------------------------------------------------------------
% Limit number of octaves based on image size.
% -------------------------------------------------------------------------
function numOctaves = adjustNumOctaves(sz, n)
    coder.internal.prefer_const(sz);
    coder.internal.prefer_const(n);

    maxNumOctaves = uint8(floor(log2(min(sz))));
    coder.internal.prefer_const(maxNumOctaves);

    if n > maxNumOctaves
        numOctaves = maxNumOctaves;
    else
        numOctaves = n;
    end
    coder.internal.prefer_const(numOctaves);
end

% -------------------------------------------------------------------------
% Default parameter values
% -------------------------------------------------------------------------
function defaults = getDefaultParameters(imgSize)

    defaults = struct('Diffusion'      , 'region', ...
                      'Threshold'      , single(0.0001), ...                 
                      'NumOctaves'     , uint8(3), ...
                      'NumScaleLevels' , uint8(4), ...
                      'ROI'            , int32([1 1 imgSize([2 1])]));
end
% -------------------------------------------------------------------------
% Parse inputs
% -------------------------------------------------------------------------
function params = parseInputs(I,varargin)
    
    defaults = getDefaultParameters(size(I));
    parser = inputParser;
    addParameter(parser, 'Diffusion',      defaults.Diffusion);
    addParameter(parser, 'Threshold',      defaults.Threshold);
    addParameter(parser, 'NumOctaves',     defaults.NumOctaves);
    addParameter(parser, 'NumScaleLevels', defaults.NumScaleLevels);
    addParameter(parser, 'ROI',            defaults.ROI);

    parse(parser,varargin{:});
    userInput = parser.Results;  
    userInput.UsingROI = isempty(regexp([parser.UsingDefaults{:} ''],...
        'ROI','once'));

    validate(I,userInput);
    userInput.Diffusion = checkDiffusionMethod(userInput.Diffusion);    
    params = setParams(userInput);
end
 
% -------------------------------------------------------------------------
% Set parameters based on user input
% -------------------------------------------------------------------------
function params = setParams(userInput)
    
    params.Diffusion      = userInput.Diffusion;
    params.Threshold      = single(userInput.Threshold);
    params.NumOctaves     = uint8(userInput.NumOctaves);
    params.NumScaleLevels = uint8(userInput.NumScaleLevels);
    params.UsingROI       = logical(userInput.UsingROI);
    params.ROI            = userInput.ROI;
end
% -------------------------------------------------------------------------
% Validate user input
% -------------------------------------------------------------------------
function validate(I, userInput)

    vision.internal.inputValidation.validateImage(I, 'I', 'grayscale');

    if userInput.UsingROI
        vision.internal.detector.checkROI(userInput.ROI,size(I));
    end

    checkThreshold(userInput.Threshold);
    checkNumOctaves(userInput.NumOctaves);
    checkNumScaleLevels(userInput.NumScaleLevels);
end
% -------------------------------------------------------------------------
% Check Diffusion method
% -------------------------------------------------------------------------
function method = checkDiffusionMethod(method)
    
    validStrings = {'region', 'sharpedge', 'edge'};
    method = validatestring(method, validStrings, mfilename, 'Diffusion');
end
% -------------------------------------------------------------------------
% Check threshold value
% -------------------------------------------------------------------------
function checkThreshold(n)

    vision.internal.errorIfNotFixedSize(n,'Threshold');
    validateattributes(n,{'numeric'},...
        {'scalar','>=', 0, 'real','nonsparse'},...
        mfilename, 'Threshold');
end
% -------------------------------------------------------------------------
% Check number of octaves
% -------------------------------------------------------------------------
function checkNumOctaves(n)

    vision.internal.errorIfNotFixedSize(n,'NumOctaves');
    validateattributes(n,{'numeric'},...
        {'scalar','>=', 1, 'real','nonsparse','integer'},...
        mfilename, 'NumOctaves');
end
% -------------------------------------------------------------------------
% Check number of scale levels
% -------------------------------------------------------------------------
function checkNumScaleLevels(n)

    vision.internal.errorIfNotFixedSize(n,'NumScaleLevels');
    validateattributes(n,{'numeric'},...
        {'scalar','>=', 3, '<=', 10, 'real','nonsparse','integer'},...
        mfilename, 'NumScaleLevels');
end