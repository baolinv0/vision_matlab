%integralKernel Define filter for use with integral images.
%   integralKernel object describes filters for use with integral images.
%
%   H = integralKernel(bbox, weights) defines an upright box filter using
%   an M-by-4 matrix of bounding boxes, bbox, and a length M vector of
%   corresponding weights, weights. Each row of bbox contains the upper
%   left corner location (x,y) and the size of a region (width, height)
%   in the form [x y width height]. Sums are computed over regions defined
%   by bbox. The bounding boxes can overlap.
%
%   H = integralKernel(bbox, weights, orientation) returns a filter H
%   with specified orientation. Orientation can be either 'upright'
%   or 'rotated'. When orientation is 'rotated', the (x,y) components of
%   the bbox refer to the location of the top corner and the
%   (width, height) are along 45 degree lines from the top corner.
%
%   integralKernel methods:
%      transpose - Transpose filter
%      rot45     - Rotate upright kernel clockwise by 45 degrees
%
%   integralKernel public properties (read-only):
%      BoundingBoxes - Bounding boxes which define the filter
%      Weights       - Vector containing a weight per bounding box
%      Coefficients  - Conventional filter coefficients
%      Center        - Filter center
%      Size          - Filter size
%      Orientation   - Filter orientation ('upright' or 'rotated')
%
%   Example 1
%   ---------
%   % Define an 11-by-11 average filter
%   avgH = integralKernel([1 1 11 11], 1/11^2);
%
%   Example 2
%   ---------
%   % Define a filter to approximate a Gaussian second order partial
%   % derivative in Y direction.
%   ydH = integralKernel([1,1,5,9;1,4,5,3], [1, -3]);
%
%   % Note that this same filter could have been defined as:
%   %   integralKernel([1,1,5,3;1,4,5,3;1,7,5,3], [1, -2, 1]);
%   % but it would be less efficient since it requires 3 bounding boxes.
%   ydH.Coefficients % visualize the filter
%
%   Example 3
%   ---------
%   % Create a Haar-like wavelet to detect 45 degree edges
%   K = integralKernel([3,1,3,3;6 4 3 3], [1 -1], 'rotated');
%
%   % visualize the filter
%   imshow(K.Coefficients, [], 'InitialMagnification', 'fit');
%   hold on;
%   plot(K.Center(2),K.Center(1), 'r*'); % Mark filter center
%   impixelregion;
%
%   See also integralImage, integralFilter

%   Copyright 2011 The MathWorks, Inc.

%   References;
%      Rainer Lienhart and Jochen Maydt. An Extended Set of Haar-like
%      Features for Rapid Object Detection.
%      In International Conference on Image Processing, pages I-900-913, 2002


classdef integralKernel
    
    properties (SetAccess='private', GetAccess='public', Dependent = true)
        % Bounding boxes defining the filter [x y width height]
        BoundingBoxes;
        % Filter weights
        Weights;
        % Filter Coefficients
        Coefficients;
        % Filter Center
        Center;
        % Overall filter size
        Size;
        % Filter Orientation
        Orientation;
    end
    
    % Internal properties that are accessible only indirectly through
    % dependent properties
    properties (Access='private')
        pBoundingBoxes = ones(0,4);
        pWeights       = ones(1,0);
        pOrientation   = 'upright';
    end
    
    methods % Accessors for Dependent properties
        function out = get.BoundingBoxes(this)
            out = this.pBoundingBoxes;
        end
        %-----------------------------------------------
        function out = get.Weights(this)
            out = this.pWeights;
        end
        %-----------------------------------------------
        function out = get.Orientation(this)
            out = this.pOrientation;
        end
        %-----------------------------------------------
        function out = get.Center(this)
            if isempty(this.pBoundingBoxes)
                out = [];
                return;
            end
            
            out = ceil(this.Size/2);
        end
        %-----------------------------------------------
        function out = get.Coefficients(this)
            % The coefficients are provided mainly for visualization.
            % Cast bounding boxes and weights to double in order to
            % prevent overflows if they are specified as integer types.
            % This will result in Coefficients being expressed in doubles.
            hBBox = this.BoundingBoxes;
            weights = this.Weights;
            inSize = this.Size;
            
            if(isempty(hBBox))
                out = [];
                return;
            end
            
            if(strcmp(this.Orientation,'upright'))
                out = getUprightCoefficients(hBBox, weights, inSize);
                
            else
                out = getRotatedCoefficients(hBBox, weights, inSize);
                
            end
        end
        %-----------------------------------------------
        function out = get.Size(this)
            hBBox = this.BoundingBoxes;
            if(isempty(hBBox))
               out = [];
               return;
            end
            
            if(strcmp(this.Orientation,  'upright'))   % Size of an upright kernel
                out = getUprightSize(hBBox);
            else % Size of a rotated kernel
                out = getRotatedSize(hBBox);
            end
        end
    end
    
    methods (Access='public')
        %-----------------------------------------------
        function this = integralKernel(bbox, weights, varargin)
            % permit empty constructor
            if nargin > 0
                nVarargs = length(varargin);
                if(nVarargs == 1)
                    orientation = varargin{1};
                else
                    orientation = 'upright';
                end
                inputs = parseInputs(bbox, weights, orientation);
                this.pBoundingBoxes = inputs.BoundingBoxes;
                this.pWeights       = inputs.Weights;
                this.pOrientation   = inputs.Orientation;
            end
        end
        
        %-----------------------------------------------
        function this = transpose(this)
            %transpose Transposes the kernel
            %
            %   intKernel = intKernel.transpose transposes the kernel. This
            %   operation is particularly useful for changing the direction
            %   of an oriented filter.
            %
            %   Example
            %   -------
            %   % Construct Haar-like wavelet filters
            %   horiH = integralKernel([1 1 4 3; 1 4 4 3], [-1, 1]); % horizontal filter
            %   vertH = horiH.'; % vertical filter; note use of the dot before '
            bbox = this.pBoundingBoxes;
            if(strcmp(this.pOrientation,'upright'))    % transpose an upright filter
                
                % transpose the filter
                this.pBoundingBoxes = [fliplr(bbox(:,1:2)), fliplr(bbox(:,3:4))];
            else % transpose a rotated filter
                boxSize= this.Size;
                newBBox = zeros(size(bbox));
               
                for k = 1:size(bbox,1)
                    newBBox(k,1) = boxSize(2) - bbox(k,1) + 1;
                    newBBox(k,2) = bbox(k,2);
                    newBBox(k,3:4) = fliplr(bbox(k,3:4));
                end
                
                this.pBoundingBoxes = newBBox;
                
            end
        end
        %-----------------------------------------------
        function this = rot45(this)
            %rot45 rotates the upright kernel clockwise by 45 degrees
            %
            %   rotKernel = rot45(uprKernel) rotates the kernel.
            %
            %   Example
            %   -------
            %   % Construct Haar-like wavelet filters
            %   H = integralKernel([1 1 4 3; 1 4 4 3], [-1, 1]); % horizontal filter
            %   rotH = H.rot45(); % rotated version of the same filter
            
            % rotation not supported for already rotated kernels
            if(strcmp(this.pOrientation, 'rotated'))
                error(message('vision:integralKernel:alreadyRotated'));
            end
            
            % rotation of empty upright kernels should return empty rotated
            % kernels
            if(isempty(this.pBoundingBoxes))
                this = integralKernel(this.pBoundingBoxes, this.pWeights, 'rotated');
                return;
            end
            
            inBBox = this.pBoundingBoxes;
            % sort bounding boxes according to x coordinate of top corner.
            % this is done because the input bounding boxes can be in any
            % order.
            [inBBox, sortIndex] = sortrows(inBBox);
            inWeights = this.pWeights;
            
            % reorder weights to match bounding boxes
            outWeights = inWeights(sortIndex); 
            
            inSize = this.Size;
            hWhole = inSize(1);
            
            outBBox = zeros(size(inBBox));
            
            % The x-coordinate of the top corner in the rotated domain is the Manhattan
            % distance between the corresponding top corner in the upright domain
            % and the bottom left corner of the entire upright filter.
            % The y-coordinate of the top corner in the rotated domain is the
            % Manhattan distance between the corresponding top corner in the
            % upright domain and the top left corner of the upright filter.
            
            for i = 1:size(inBBox,1)
                
                currX = inBBox(i,1);
                currY = inBBox(i,2);
                currW = inBBox(i,3);
                currH = inBBox(i,4);
                
                
                newTopX = currX + (hWhole - currY);
                newTopY = currX + currY  - 1;
                outBBox(i,:) = [newTopX newTopY currW currH];
            end
            
            this = integralKernel(outBBox, outWeights, 'rotated');
        end 
    end
end

%--------------------------------------------------------------------------
function h = parseInputs(varargin)

parser = inputParser;
parser.CaseSensitive = false;

parser.addRequired('bbox',    @checkBoundingBoxeses);
parser.addRequired('weights', @checkWeights);
parser.addOptional('orientation', 'upright',@checkOrientation);
parser.parse(varargin{:});

h.BoundingBoxes = parser.Results.bbox;
h.Weights       = parser.Results.weights;
h.Orientation   = parser.Results.orientation;

if numel(h.Weights) ~= size(h.BoundingBoxes,1)
    error(message('vision:integralKernel:weightsBBoxMismatch'));
end

[~, h.Orientation] = checkOrientation(h.Orientation);

end

%--------------------------------------------------------------------------
function [tf,orientation] = checkOrientation(orientation)

orientation = validatestring(orientation,{'upright', 'rotated'});
tf = true;
end
%--------------------------------------------------------------------------
function checkBoundingBoxeses(bbox)

validateattributes(bbox, {'numeric'}, {'nonsparse','integer', ...
    'size',[NaN 4],'positive', 'finite'});

%tf = true;

end

%--------------------------------------------------------------------------
function checkWeights(weights)

validateattributes(weights, {'numeric'}, {'vector','real',...
    'finite','nonsparse'});

end

%--------------------------------------------------------------------------
% subfunction to compute coefficients for an upright kernel
function uprightCoeffs = getUprightCoefficients(bbox, weights, inSize)

uprightCoeffs = zeros(inSize);
for i=1:size(bbox, 1)
    currBbox = double(bbox(i,:));
    sR = currBbox(1,2);
    sC = currBbox(1,1);
    eR = sR + currBbox(1,4) - 1;
    eC = sC + currBbox(1,3) - 1;
    
    uprightCoeffs(sR:eR,sC:eC) = uprightCoeffs(sR:eR,sC:eC) + ...
        double(weights(i));
end

end

%--------------------------------------------------------------------------
% subfunction to compute coefficients for a rotated kernel
function rotatedCoeffs = getRotatedCoefficients(bbox, weights, inSize)

rotatedCoeffs = zeros(inSize);

for i = 1:size(bbox,1)
    
    x = bbox(i,1);
    y = bbox(i,2);
    w = bbox(i,3);
    h = bbox(i,4);
    
    % mark the positions of the coefficients
    position = [x y x+w-1 y+w-1 x+w-1 y+w  ...
        x+w-h y+w+h-1 x-h+1 y+h x-h+1 y+h-1];
    
    % insert the coefficients in the correct pixels
    tempCoeffs = insertShape(zeros(inSize), ...
        'FilledPolygon', position, ...
        'Color', [double(weights(i)) 0 0], ...
        'SmoothEdges', false, 'opacity',1);
    
    
    rotatedCoeffs = rotatedCoeffs + tempCoeffs(:,:,1);
end

end

%--------------------------------------------------------------------------
% function to compute size of an upright kernel
function uprightSize = getUprightSize(bbox)

% We need to determine the lower right corner of the filter, which
% essentially defines its size
uprightSize = [0 0];
    
for k = 1:size(bbox,1)
    hSize = fliplr(bbox(k,3:4));
    ulCorner = fliplr(bbox(k,1:2));
    lrCorner = ulCorner + hSize - 1;
    
    uprightSize(1) = max(uprightSize(1), lrCorner(1));
    uprightSize(2) = max(uprightSize(2), lrCorner(2));
end

end

%--------------------------------------------------------------------------
% function to compute size of a rotated kernel
function rotatedSize =  getRotatedSize(bbox)
% We need to compute the size of the box that bounds
% the rotated kernel.

% size should be double
bbox = double(bbox);
% Sort bounding boxes in ascending order of y coordinates
hBBox = sortrows(bbox,2);

% Assume no overlap with filter kernels
isOverlapping = false;
isOverlappingAlongWidth = false;
isOverlappingAlongHeight = false;

% Now detect if there is overlap
allWidths  = hBBox(:,3);
allHeights = hBBox(:,4);

if(~all(allWidths == allWidths(1)))
    isOverlapping = true;
    isOverlappingAlongWidth = true;
elseif(~all(allHeights == allHeights(1)))
    isOverlapping = true;
    isOverlappingAlongHeight = true;
end

if(~isOverlapping) % if non overlapping
    % The size of the filter is determined by the bottom corner
    % of the lowest bbox in the y-direction.
    lowestY = hBBox(end,2);
    lowestW = hBBox(end,3);
    lowestH = hBBox(end,4);
    
    numRows = lowestY + lowestW + lowestH - 1;
    
else % if overlapping, find out which dimension overlaps and obtain size
   
    if(isOverlappingAlongWidth)
        % find the bigger width
        [maxW, maxWInd] = max(allWidths);
        y = hBBox(maxWInd,2);
        h = hBBox(maxWInd,4);
        
        numRows = y + maxW + h - 1;
    elseif(isOverlappingAlongHeight)
        % find the bigger height
        [maxH, maxHInd] = max(allHeights);
        y = hBBox(maxHInd,2);
        w = hBBox(maxHInd,3);
        
        numRows = y + w + maxH - 1;
        
    end
end
numCols = numRows - 1;
rotatedSize = [numRows numCols];

end
