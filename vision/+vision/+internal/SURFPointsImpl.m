classdef SURFPointsImpl < vision.internal.FeaturePointsImpl %#codegen  
  
    properties (Dependent = true)
        %Scale Array of point scales
        Scale;
        %SignOfLaplacian Sign of Laplacian
        SignOfLaplacian;
        %Orientation Array of feature orientations
        Orientation;
    end
    
    % Internal properties that are accessible only indirectly through
    % dependent properties
    properties (Access = protected)
        pScale           = ones(0,1,'single');
        pSignOfLaplacian = ones(0,1,'int8'  );
        pOrientation     = ones(0,1,'single');
    end
    
    methods % Accessors for Dependent properties
        
        function this = SURFPointsImpl(varargin)
            if nargin > 0
                inputs = parseInputs(this, varargin{:});
                validate(this,inputs);
                this = configure(this,inputs);
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
            %   points = SURFPoints(ones(50,2), 'Metric', 1:50);
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
            %   % Detect and display SURF features 
            %   points1 = detectSURFFeatures(rgb2gray(im));
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
            %   See also detectSURFFeatures, matchFeatures, vision.PointTracker, 
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
        
        function this = set.SignOfLaplacian(this, in)
            this.checkForResizing(in);
            this.checkSignOfLaplacian(in);
            this.pSignOfLaplacian = int8(in);
        end
        
        function out = get.SignOfLaplacian(this)
            out = this.pSignOfLaplacian;
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
                'Metric',          single(0),...
                'Scale',           single(1.6),...
                'SignOfLaplacian', single(0),...
                'Orientation',     single(0));
            
            if isempty(coder.target)
                % Parse the PV pairs
                parser = inputParser;
                
                parser.addRequired('Location');
                
                parser.addParameter('Scale',           defaults.Scale);
                parser.addParameter('Metric',          defaults.Metric);
                parser.addParameter('SignOfLaplacian', defaults.SignOfLaplacian);
                parser.addParameter('Orientation',     defaults.Orientation);
                
                % Parse input
                parser.parse(varargin{:});
                
                inputs = parser.Results;
                
            else % codegen
                
                pvPairs = struct(...
                    'Location',        uint32(0),...
                    'Metric',          uint32(0),...
                    'Scale',           uint32(0),...
                    'SignOfLaplacian', uint32(0),...
                    'Orientation',     uint32(0));
                
                properties =  struct( ...
                    'CaseSensitivity', false, ...
                    'StructExpand',    true, ...
                    'PartialMatching', false);
                
                inputs.Location = single(varargin{1});
                
                optarg = eml_parse_parameter_inputs(pvPairs, properties, varargin{2:end});
                
                inputs.Metric = eml_get_parameter_value(optarg.Metric, ...
                    defaults.Metric, varargin{2:end});
                
                inputs.Scale  = eml_get_parameter_value(optarg.Scale , ...
                    defaults.Scale, varargin{2:end});
                
                inputs.SignOfLaplacian = eml_get_parameter_value(optarg.SignOfLaplacian, ...
                    defaults.SignOfLaplacian, varargin{2:end});
                
                inputs.Orientation = eml_get_parameter_value(optarg.Orientation , ...
                    defaults.Orientation, varargin{2:end});
                
                
                
            end
        end
        
        function this = configure(this, inputs)
            
            this = configure@vision.internal.FeaturePointsImpl(this,inputs);
            
            n = size(this.Location,1);
            
            this.pScale           = coder.nullcopy(zeros(n,1,'single'));
            this.pOrientation     = coder.nullcopy(zeros(n,1,'single'));
            this.pSignOfLaplacian = coder.nullcopy(zeros(n,1,'int8'));
            
            this.pScale(:) = ...
                vision.internal.FeaturePointsImpl.assignValue(single(inputs.Scale),n);
            
            this.pOrientation(:) = ...
                vision.internal.FeaturePointsImpl.assignValue(single(inputs.Orientation),n);
            
            this.pSignOfLaplacian(:) = ...
                vision.internal.FeaturePointsImpl.assignValue(single(inputs.SignOfLaplacian),n);
                        
        end
        
        function validate(this, inputs)
            
            validate@vision.internal.FeaturePointsImpl(this,inputs);
            
            this.checkScale(inputs.Scale);
            this.checkOrientation(inputs.Orientation);
            this.checkSignOfLaplacian(inputs.SignOfLaplacian);
            
            numPts = size(inputs.Location,1);
            
            % All parameters must have the same number of elements or be a scalar
            vision.internal.FeaturePointsImpl.validateParamLength(numel(inputs.Scale), 'Scale', numPts);
            vision.internal.FeaturePointsImpl.validateParamLength(numel(inputs.SignOfLaplacian), 'SignOfLaplacian',...
                numPts);
            vision.internal.FeaturePointsImpl.validateParamLength(numel(inputs.Orientation), 'Orientation', numPts);
            
            
        end
        %--------------------------------------------------------------------------
        function checkSignOfLaplacian(this,in)
            validateattributes(in, {'numeric'},...
                {'integer', 'real', 'vector','real','nonsparse','finite'}, ...
                class(this),'SignOfLaplacian'); %#ok<*EMCA>
            
            coder.internal.errorIf( ~(all(in >= -1) && all( in <= 1)),...
                'vision:SURFPoints:invalidSignOfLaplacian');
        end
        
        function checkScale(this, scale)
            validateattributes(scale, {'numeric'},...
                {'nonnan', 'finite', 'nonsparse','real','vector','>=',1.6},...
                class(this),'Scale');
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
    end
end

%  In order for method help to work properly for subclasses, this classdef
%  file cannot have a comment block at the top, so the following remark and
%  copyright/version information are provided here at the end. Please do
%  not move them.

% Copyright 2013 The MathWorks, Inc.
