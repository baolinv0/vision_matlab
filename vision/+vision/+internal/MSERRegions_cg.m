%MSERRegions_cg Object used during codegen instead of MSERRegions
%
%   MSERRegions_cg replaces MSERRegions during codegen.

%   Outputs and inputs are different for MSERRegions and MSERRegions_cg
%
%   REGIONS = MSERRegions(PIXELLIST) (simulation path)
%   --------------------------------
%   PIXELLIST is an M-by-1 cell array representing M regions. Each region
%   contains L-by-2 array of [x y] coordinates. L is not same for each
%   region.
%   REGIONS is an object with following public properties
%           Count: M scalar double (M >= 0)
%        Location: [Mx2 single]
%            Axes: [Mx2 single]
%     Orientation: [Mx1 single]
%       PixelList: {Mx1 cell}; each cell [Li-by-2 int32] i=1,2,...,M
%                  PixelList = {L1 x 2, L2 x 2, L3 x 2, ....LM x 2}'
%
%   REGIONS = MSERRegions(PIXELLIST, LENGTHS) (uses MSERRegions_cg in codegen)
%   -----------------------------------------
%   PIXELLIST is an M*N-by-2 array representing M regions. Each region
%   contains P-by-2 array of [x y] coordinates. P is not same for each
%   region. Here N = P1+P2+....+PM, Pi is the number of pixels in i-th
%   region
%   REGIONS is an object with following public properties
%           Count: M scalar double (M >= 0)
%        Location: [Mx2 single]
%            Axes: [Mx2 single]
%     Orientation: [Mx1 single]
%       PixelList: [M*LL-by-2 int32]; each "region" [Li-by-2 int32] i=1,2,...,M
%                                     And LL = L1+L2+...+LM
%                  PixelList = [L1 x 2; L2 x 2; L3 x 2; ....LM x 2]
%         Lengths: [Mx1 int32]-each value represents number of pixels in each region
%                  Lengths = [L1 L2 L3 ... LM]'

% Copyright 2012 The MathWorks, Inc.

%#codegen
%#ok<*EMCA>

classdef MSERRegions_cg
    
    properties (SetAccess='private', GetAccess='public')
        %Count Number of stored regions
        Count = 0;
        %Location Array of [x y] center coordinates of ellipses
        Location    = ones(0,2,'single');
    end
    
    properties (SetAccess='private', GetAccess='public', Hidden=true)
        %Centroid Array of [x y] center coordinates of ellipses
        Centroid    = ones(0,2,'single');
    end
    
    properties (SetAccess='private', GetAccess='public')
        %Axes Array of [majorAxis minorAxis] of ellipses
        Axes        = ones(0,2,'single');
        %Orientation Orientation of the ellipses
        Orientation = ones(0,1,'single');
    end
    
    properties (Access='public')
%   PixelList: [M*LL-by-2 int32]; each "region" [Li-by-2 int32] i=1,2,...,M
%                                 And LL = L1+L2+...+LM
%              PixelList = [L1 x 2; L2 x 2; L3 x 2; ....LM x 2]
%     Lengths: [Mx1 int32]-each value represents number of pixels in each region
%              Lengths = [L1 L2 L3 ... LM]'

        PixelList = ones(0,2,'int32');
        Lengths = ones(0,1,'int32');;
    end
    
%     % Internal properties that are accessible only indirectly through
%     % dependent properties
%     properties (Access='private')
%         pPixelList     = zeros(0,2,'int32');
%         pLengths       = zeros(0,1,'int32');
%     end
    
    methods % Accessors for Dependent properties

    end
   
    %-----------------------------------------------------------------------
    methods (Access='public')
        function this = MSERRegions_cg(varargin)
            %MSERRegions_cg constructor
            if nargin >= 1
                if isstruct(varargin{1})
                    inputs = varargin{1};
                    
                    checkPixelList(inputs.PixelList);
                    checkLengths(inputs.Lengths);
                    crossCheckPixelListAndLengths(inputs.PixelList, inputs.Lengths);
                    
                    this.Lengths     = inputs.Lengths;
                    this.PixelList   = inputs.PixelList;                    
                    this.Count       = inputs.Count;
                    this.Centroid    = inputs.Centroid;
                    this.Location    = inputs.Location;
                    this.Axes        = inputs.Axes;
                    this.Orientation = inputs.Orientation;
                else
                    inputs = parseInputs(varargin{:});
                    
                    % Value classes with set.prop method are not supported for
                    % code generation; so set/get methods are removed
                    this.Lengths   = inputs.Lengths;
                    this.PixelList = inputs.PixelList;
                    
                    % pixelListLen is the number of regions
                    pixelListLen     = length(this.Lengths);%size(this.pPixelList,1);
                    
                    this.Count = size(this.Lengths,1);
                    this.Centroid    = single(zeros(pixelListLen,2));
                    this.Location    = this.Centroid;
                    this.Axes        = single(zeros(pixelListLen,2));
                    this.Orientation = single(zeros(pixelListLen,1));
                    
                    startIdx = int32(1);
                    for idx = 1:pixelListLen
                        len = int32(this.Lengths(idx));
                        endIdx = startIdx + len - int32(1);
                        thisRegion = this.PixelList(startIdx:endIdx,:);
                        ellipseStruct           = computeEllipseProps(thisRegion);
                        this.Centroid(idx,:)    = single(ellipseStruct.Centroid);
                        this.Axes(idx,:)        = single(ellipseStruct.Axes);
                        this.Orientation(idx,1) = single(ellipseStruct.Orientation);
                        startIdx = startIdx + len;
                    end
                    this.Location    = this.Centroid;
                end
            end
        end
    end
    methods(Hidden)
        %-------------------------------------------------------------------
        % Returns feature points at specified indices
        %-------------------------------------------------------------------
        function obj = getIndexedObj(this, idx)
            
            validateattributes(idx, {'numeric'}, {'vector', 'integer'}, ...
                'MSERRegions');
                        
            % unpack MSER region data and copy into OBJ. This avoids
            % recomputing the ellipse data for an index operation.
            
            % index to the start of each region in PixelList
            cs = cumsum(this.Lengths);            
            thisStartIdx = [0; cs(:)] + 1; 
            
            len1 = this.Lengths(idx);
            r.Lengths   = this.Lengths(idx);
            r.PixelList = coder.nullcopy(zeros(sum(len1),2,'int32'));                
            
            cs2 = cumsum(len1);
            objStartIdx = [0; cs2(:)] + 1; 
            
            % copy pixel data for indexed region
            for k = 1:numel(idx)
                i   = thisStartIdx(idx(k));
                len = this.Lengths(idx(k));
                j   = objStartIdx(k);
                r.PixelList(j:j+len-1,:) = this.PixelList(i:i+len-1,:);                
            end
            
            r.Count       = size(idx,1);            
            r.Centroid    = this.Centroid(idx,:);
            r.Location    = this.Location(idx,:);
            r.Axes        = this.Axes(idx,:);
            r.Orientation = this.Orientation(idx);
            
            obj = vision.internal.MSERRegions_cg(r);
        end
                
    end  
end

%--------------------------------------------------------------------------
% Main parser for the class
%--------------------------------------------------------------------------
function inputs = parseInputs(varargin)

if nargin<2
    % output object is empty
    inputs.PixelList = zeros(0,2,'int32');
    inputs.Lengths   = zeros(0,1,'int32');
else
    inputs.PixelList = varargin{1};
    inputs.Lengths = varargin{2};
    checkPixelList(inputs.PixelList);
    checkLengths(inputs.Lengths);
    crossCheckPixelListAndLengths(inputs.PixelList, inputs.Lengths);
end

end

%--------------------------------------------------------------------------
function tf = checkPixelList(in)

validateattributes(in,{'int32'}, {'nonnan', 'finite', ...
    'nonsparse', 'finite', 'nonsparse', 'real', 'size',[NaN,2]}, ...
    mfilename);

tf = true;
end

%--------------------------------------------------------------------------
function tf = checkLengths(in)

validateattributes(in, {'int32'}, {'nonnan', 'finite', 'nonsparse',...
            'real', 'vector'}, mfilename);

tf = true;
end

%--------------------------------------------------------------------------
function tf = crossCheckPixelListAndLengths(PixelList, Lengths)
sz1 = sum(Lengths(:));
sz2 = size(PixelList,1);
coder.internal.errorIf(sz1 ~= sz2, ...
    'Coder:builtins:SizeMismatch',sz1,sz2);

tf = true;
end

%==========================================================================
% Calculate Ellipse parameters
%==========================================================================
function EllipseStruct = computeEllipseProps(region)
%computeEllipseProps  Calculate ellipse properties 
%
%   Find the ellipse that has the same normalized second central moments as 
%   the region. Compute the axes lengths and orientation of the ellipse. 

%   Reference:
%       Haralick and Shapiro, Computer and Robot Vision vol I, 
%       Addison-Wesley 1992, Appendix A.

EllipseStruct.Centroid = mean(region, 1);
EllipseStruct.Axes = [0 0]; %[majorAxis minorAxis]
EllipseStruct.Orientation = 0;

% Assign X and Y variables so that we're measuring orientation
% counterclockwise from the horizontal axis.

xbar = EllipseStruct.Centroid(1);
ybar = EllipseStruct.Centroid(2);

x =   region(:,1) - xbar;
y = -(region(:,2) - ybar); % This is negative for the
% orientation calculation (measured in the
% counter-clockwise direction).

N = length(x);

% Calculate normalized second central moments for the region. 1/12 is
% the normalized second central moment of a pixel with unit length.
uxx = sum(x.^2)/N + 1/12;
uyy = sum(y.^2)/N + 1/12;
uxy = sum(x.*y)/N;

% Calculate major axis length, minor axis length.
common = sqrt((uxx - uyy)^2 + 4*uxy^2);
EllipseStruct.Axes(1) = 2*sqrt(2)*sqrt(uxx + uyy + common);
EllipseStruct.Axes(2) = 2*sqrt(2)*sqrt(uxx + uyy - common);

% Calculate orientation.
if (uyy > uxx)
    num = uyy - uxx + sqrt((uyy - uxx)^2 + 4*uxy^2);
    den = 2*uxy;
else
    num = 2*uxy;
    den = uxx - uyy + sqrt((uxx - uyy)^2 + 4*uxy^2);
end

if (num == 0) && (den == 0)
    EllipseStruct.Orientation = 0;
else
    EllipseStruct.Orientation = atan(num/den);
end

end
% LocalWords:  OpenCV


