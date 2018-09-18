classdef KAZEPointsImpl < vision.internal.FeaturePointsImpl
  
    properties (Dependent = true)
        %Scale Array of point scales
        Scale;
        %Orientation Array of feature orientations
        Orientation;
    end
    
    % Internal properties that are accessible only indirectly through
    % dependent properties
    properties (Access = protected)
        pDiffusion      = 'region';
        pNumOctaves     = uint8(1);
        pNumScaleLevels = uint8(3);
        pScale          = ones(0,1,'single');
        pOrientation    = ones(0,1,'single');
        pLayerID        = ones(0,1,'int32');
    end
    
    methods % Accessors for Dependent properties
        
        function this = KAZEPointsImpl(varargin)
            if nargin > 0
                inputs = parseInputs(this, varargin{:});
                validate(this, inputs);
                this = configure(this, inputs);
            end
        end
        
        function strongest = selectStrongest(this, N)
            %selectStrongest Return N points with strongest metrics           
            %            
            %   strongest = selectStrongest(points, N) keeps N
            %   points with strongest metrics.
            %
            %   Example
            %   -------
            %   % create object holding 50 points
            %   points = KAZEPoints(ones(50,2), 'Metric', 1:50);
            %   % keep 2 strongest features
            %   points = selectStrongest(points, 2)
            
            strongest = selectStrongest@vision.internal.FeaturePointsImpl(this,N);
        end
        
        %------------------------------------------------------------------
        function that = selectUniform(this, N, imageSize)
            % selectUniform Return a uniformly distributed subset of feature points
            %   pointsOut = selectUniform(pointsIn, N, imageSize) keeps N
            %   points with the strongest metrics approximately uniformly
            %   distributed throughout the image. imageSize is a 2-element
            %   or 3-element vector containing the size of the image.
            %
            %   Example - Select a uniformly distributed subset of features
            %   -----------------------------------------------------------
            %   % Read in the image
            %   im = imread('yellowstone_left.png');
            %
            %   % Detect and display KAZE features 
            %   points1 = detectKAZEFeatures(rgb2gray(im));
            %   subplot(1, 2, 1);
            %   imshow(im);
            %   hold on
            %   plot(points1);
            %   hold off
            %   title('Original points');
            %
            %   % Select a uniformly distributed subset of points
            %   numPoints = 100;
            %   points2 = selectUniform(points1, numPoints, size(im));
            %   subplot(1, 2, 2);
            %   imshow(im);
            %   hold on
            %   plot(points2);
            %   hold off
            %   title('Uniformly distributed points');
            %
            %   See also detectKAZEFeatures, matchFeatures, vision.PointTracker, 
            %       estimateFundamentalMatrix
            
            that = selectUniform@vision.internal.FeaturePointsImpl(this, N, imageSize);
        end
        
        function this = set.Scale(this, in)
            this.checkForResizing(in);
            this.checkScale(in);
            this.pScale = single(in);
        end
        
        function out = get.Scale(this)
            out = this.pScale;
        end
        
        function this = set.Orientation(this, in)
            this = setOrientation(this,in);
        end
        
        function out = get.Orientation(this)
            out = this.pOrientation;
        end
      
    end
    
    methods (Access = protected)
        function inputs = parseInputs(~, varargin)
            defaults = struct(...
                'Metric',         single(0),...
                'Scale',          single(1.6),...
                'Orientation',    single(0), ...
                'LayerID',        int32(1), ...
                'Diffusion',      'region', ...
                'NumOctaves',     uint8(1), ...
                'NumScaleLevels', uint8(3));
            
            % Parse the PV pairs
            parser = inputParser;

            parser.addRequired('Location');
            parser.addParameter('Metric',         defaults.Metric);
            parser.addParameter('Scale',          defaults.Scale);
            parser.addParameter('Orientation',    defaults.Orientation);
            parser.addParameter('LayerID',        defaults.LayerID);            
            parser.addParameter('Diffusion',      defaults.Diffusion);
            parser.addParameter('NumOctaves',     defaults.NumOctaves);
            parser.addParameter('NumScaleLevels', defaults.NumScaleLevels);

            % Parse input
            parser.parse(varargin{:});
            inputs = parser.Results;
        end
        
        function this = configure(this, inputs)
            this = configure@vision.internal.FeaturePointsImpl(this,inputs);
            
            n = size(this.Location,1);
            
            this.pScale           = coder.nullcopy(zeros(n,1,'single'));
            this.pOrientation     = coder.nullcopy(zeros(n,1,'single'));
            this.pScale(:) = ...
                vision.internal.FeaturePointsImpl.assignValue(single(inputs.Scale),n);
            this.pOrientation(:) = ...
                vision.internal.FeaturePointsImpl.assignValue(single(inputs.Orientation),n);
            
            
            % initiate layer IDs so the numbers of octaves and scale levels
            % can be set. Once actual layer IDs are assigned, the numbers
            % of octaves and scale levels cannot be changed.
            this.pLayerID         = coder.nullcopy(zeros(n,1,'int32'));
            
            % checking and validation done within each of the following
            this = this.setDiffusion(inputs.Diffusion);
            this = this.setNumOctaves(inputs.NumOctaves);
            this = this.setNumScaleLevels(inputs.NumScaleLevels);
            this = this.setLayerID(inputs.LayerID);
        end
        
        function validate(this, inputs)
            validate@vision.internal.FeaturePointsImpl(this,inputs);
            
            this.checkScale(inputs.Scale);
            this.checkOrientation(inputs.Orientation);
            numPts = size(inputs.Location,1);
            
            % All parameters must have the same number of elements or be a scalar
            vision.internal.FeaturePointsImpl.validateParamLength(numel(inputs.Scale), 'Scale', numPts);
            vision.internal.FeaturePointsImpl.validateParamLength(numel(inputs.Orientation), 'Orientation', numPts);            
        end
        %--------------------------------------------------------------------------
        function checkScale(this, scale)
            validateattributes(scale, {'numeric'},...
                {'nonnan', 'finite', 'nonsparse','real','vector','>=',1.6},...
                class(this),'Scale');
        end
        
        function checkOrientation(this, orientation)
            validateattributes(orientation, {'numeric'},...
                {'nonnan', 'finite', 'nonsparse','real','vector'},...
                class(this),'Orientation');
        end        
        
        function checkLayerID(this, layerIndex)
            nO = this.pNumOctaves;
            nS = this.pNumScaleLevels;
            nL = nO*nS;
            validateattributes(layerIndex, {'numeric'},...
                {'nonnan', 'finite', 'nonsparse','nonnegative', ...
                 'integer','vector','>=',1,'<=',nL-2},...
                class(this),'LayerID');
        end           
        
        function validString = checkDiffusion(this, in)
            validStrings = {'region', 'sharpedge', 'edge'};
            validString = validatestring(in, validStrings, class(this), 'Diffusion');
        end
        
        function checkNumOctaves(this, in)
            vision.internal.errorIfNotFixedSize(in, 'NumOctaves');
            validateattributes(in, {'numeric'},...
                               {'scalar','>=', 1, 'real','nonsparse','integer'},...
                               class(this), 'NumOctaves');
        end
        
        function checkNumScaleLevels(this, in)
            vision.internal.errorIfNotFixedSize(in, 'NumScaleLevels');
            validateattributes(in, {'numeric'},...
                               {'scalar','>=', 3, 'real','nonsparse','integer'},...
                               class(this), 'NumScaleLevels');
        end
    end
    
    methods(Hidden)
        %------------------------------------------------------------------
        % Set Orientation values. Used to update orientation values after
        % feature extraction.
        %------------------------------------------------------------------
        function this = setOrientation(this, orientation)
            this.checkForResizing(orientation);
            this.checkOrientation(orientation);
            this.pOrientation = single(orientation);
        end
  
        function this = setupLayerID(this, layerIndex)
            n = size(this.Location, 1);
            this.checkLayerID(layerIndex);
            vision.internal.FeaturePointsImpl.validateParamLength(numel(layerIndex), 'LayerID', n);
            this.pLayerID = coder.nullcopy(zeros(n,1,'int32'));
            this.pLayerID(:) = ...
                vision.internal.FeaturePointsImpl.assignValue(int32(layerIndex),n);
        end
				        
        function this = setDiffusion(this, in)
            in = this.checkDiffusion(in);
            this.pDiffusion = in;
        end
        
        function out = getDiffusion(this)
            out = this.pDiffusion;
        end
        
        function this = setNumOctaves(this, in)
            if all(this.pLayerID == 0)
                this.checkNumOctaves(in);
                this.pNumOctaves = uint8(in);
            else
                error(message('vision:KAZEPoints:cannotChangeOctaves'));
            end
        end
        
        function out = getNumOctaves(this)
            out = uint8(this.pNumOctaves);
        end
        
        function this = setNumScaleLevels(this, in)
            if all(this.pLayerID == 0)
                this.checkNumScaleLevels(in);
                this.pNumScaleLevels = uint8(in);
            else
                error(message('vision:KAZEPoints:cannotChangeScaleLevels'));
            end
        end
        
        function out = getNumScaleLevels(this)
            out = uint8(this.pNumScaleLevels);
        end
        
        function this = setLayerID(this, in)
            this = setupLayerID(this,in);
        end
        
        function out = getLayerID(this)
            out = this.pLayerID;
        end  
    end
end

%  In order for method help to work properly for subclasses, this classdef
%  file cannot have a comment block at the top, so the following remark and
%  copyright/version information are provided here at the end. Please do
%  not move them.

% Copyright 2017 The MathWorks, Inc.
