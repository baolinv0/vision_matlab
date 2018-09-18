classdef BRISKPointsImpl < vision.internal.FeaturePointsImpl %#codegen
    properties(Access = protected)
        pScale       = ones(0,1,'single');
        pOrientation = ones(0,1,'single');
    end
    
    properties(Dependent = true)
        %Scale Array of point scales
        Scale        
        %Orientation Array of feature orientations
        Orientation
    end
    
    methods
        
        function this = BRISKPointsImpl(varargin)
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
            %   points = BRISKPoints(ones(50,2), 'Metric', 1:50);
            %   % keep 2 strongest features
            %   points = points.selectStrongest(2)
            strongest = selectStrongest@vision.internal.FeaturePointsImpl(this,N);
        end
        
        %-------------------------------------------------------------------
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
            %   % Detect many corners by reducing the quality threshold
            %   points1 = detectBRISKFeatures(rgb2gray(im), 'MinQuality', 0.05);
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
            %   See also detectHarrisFeatures, detectFASTFeatures, detectMinEigenFeatures
            %      matchFeatures, vision.PointTracker, estimateFundamentalMatrix
            
            that = selectUniform@vision.internal.FeaturePointsImpl(this, N, imageSize);
       end
    end
    methods(Hidden, Access = protected);
        function this = configure(this, inputs)
            this = configure@vision.internal.FeaturePointsImpl(this,inputs);
            
            n = size(this.Location,1);
            
            this.pScale       = coder.nullcopy(zeros(n,1,'single'));
            this.pOrientation = coder.nullcopy(zeros(n,1,'single'));
            
            this.pScale(:) = ...
                vision.internal.FeaturePointsImpl.assignValue(single(inputs.Scale),n);
            
            this.pOrientation(:) = ...
                vision.internal.FeaturePointsImpl.assignValue(single(inputs.Orientation),n);
            
        end
    end
    
    methods(Hidden)
        %------------------------------------------------------------------
        % Returns feature points in a struct
        %------------------------------------------------------------------
        function s = toStruct(this)
            coder.varsize('s(:).Location',    [inf 2]);
            coder.varsize('s(:).Metric',      [inf 1]);
            coder.varsize('s(:).Orientation', [inf 1]);
            coder.varsize('s(:).Scale',       [inf 1]);
            
            s.Location    = this.Location;
            s.Metric      = this.Metric;
            s.Orientation = this.Orientation;
            s.Scale       = this.Scale;
            s.Count       = this.Count;
        end
        
        %------------------------------------------------------------------
        % Set Orientation values. Used to update orientation values after
        % feature extraction.
        %------------------------------------------------------------------
        function this = setOrientation(this, orientation)   
            this.checkForResizing(orientation);
            this.checkOrientation(orientation);
            this.pOrientation(:) = single(orientation(:));
        end
    end
    
    methods(Access = protected)
        function validate(this,inputs)
            
            validate@vision.internal.FeaturePointsImpl(this,inputs);
            
            this.checkScale(inputs.Scale);
            this.checkOrientation(inputs.Orientation);
            
            numPts = size(inputs.Location,1);
            % All parameters must have the same number of elements or be a scalar
            vision.internal.FeaturePointsImpl.validateParamLength(numel(inputs.Scale), 'Scale',  numPts);
            vision.internal.FeaturePointsImpl.validateParamLength(numel(inputs.Orientation), 'Orientation', numPts);
        end
    end
    
    methods(Access=protected)
        function inputs = parseInputs(~,varargin)
            
            defaults = struct(...
                'Metric',      single(0),...
                'Scale',       single(12),...
                'Orientation', single(0));
            
            if isempty(coder.target)
                
                p = inputParser;
                p.addRequired('Location');
                
                addParameter(p,'Metric',      defaults.Metric);
                addParameter(p,'Scale',       defaults.Scale);
                addParameter(p,'Orientation', defaults.Orientation);
                
                parse(p,varargin{:});
                
                inputs = p.Results;
                
            else
               
                pvPairs = struct(...
                    'Metric',      uint32(0),...
                    'Scale',       uint32(0),...
                    'Orientation', uint32(0));
                
                properties =  struct( ...
                    'CaseSensitivity', false, ...
                    'StructExpand',    true, ...
                    'PartialMatching', false);
                
                optarg = eml_parse_parameter_inputs(pvPairs, properties, varargin{2:end});
                
                inputs.Location = single(varargin{1});
                
                inputs.Metric = eml_get_parameter_value(optarg.Metric, ...
                    defaults.Metric, varargin{2:end});
                
                inputs.Scale  = eml_get_parameter_value(optarg.Scale , ...
                    defaults.Scale, varargin{2:end});
                
                inputs.Orientation = eml_get_parameter_value(optarg.Orientation , ...
                    defaults.Orientation, varargin{2:end});
            end
        end
    end
    
    methods % set and get methods
        function this = set.Scale(this, in)
            this.checkForResizing(in);
            this.checkScale(in);
            this.pScale = single(in);
        end
        
        function out = get.Scale(this)
            out = this.pScale;
        end
        
        function this = set.Orientation(this,in)
           this = setOrientation(this, in);
        end
        
        function out = get.Orientation(this)
            out = this.pOrientation;
        end
    end
end

%  In order for method help to work properly for subclasses, this classdef
%  file cannot have a comment block at the top, so the following remark and
%  copyright/version information are provided here at the end. Please do
%  not move them.

% Copyright 2013 The MathWorks, Inc.
