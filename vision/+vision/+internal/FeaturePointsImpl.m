classdef FeaturePointsImpl %#codegen

    properties (Access='public', Dependent = true)
        %Location Array of [x y] point coordinates
        Location;
        %Metric Value indicating feature's strength
        Metric;
    end
    
    properties (SetAccess='private', GetAccess='public', Dependent = true)
        %Count Number of stored interest points
        Count;
    end
        
    properties (Access='protected')
        pLocation = ones(0,2,'single');
        pMetric   = ones(0,1,'single');
    end
    
    
    methods 
        %------------------------------------------------------------------
        function this = FeaturePointsImpl(varargin)
            if nargin > 0
                inputs = parseInputs(this, varargin{:});
                validate(this,inputs);
                this = configure(this,inputs);
            end
        end
                
        %------------------------------------------------------------------
        function strongest = selectStrongest(this, N)
            % selectStrongest Return N points with strongest metrics
            %
            %   strongestPoints = selectStrongest(points, N) keeps N points
            %   with strongest metrics.
                       
            validateattributes(N, {'numeric'}, {'scalar', 'integer', ...
                'positive'}, class(this));
            
            coder.varsize('idx', [inf, 1]);
            idx = coder.nullcopy(zeros(size(this.pMetric), 'like', this.pMetric));
            
            [~, idx(:,1)] = sort(this.pMetric,'descend');
                    
            if N > length(idx)
                NN = length(idx);
            else
                NN = N;
            end
                                    
            if isempty(coder.target)
                % Use this's subsref implementation
                s.type = '()';
                s.subs = {idx(1:NN)};
                strongest = subsref(this,s);
            else
                strongest = getIndexedObj(this, idx(1:NN));
            end
        end        

        %------------------------------------------------------------------
        function pointsOut = selectUniform(this, numPoints, imageSize)
            % selectUniform Return a uniformly distributed subset of feature points
            %   pointsOut = selectUniform(pointsIn, N, imageSize) keeps N
            %   points with the strongest metrics approximately uniformly
            %   distributed throughout the image. imageSize is a 2-element
            %   vector containing the size of the image.
            
            validateattributes(numPoints, {'numeric'}, {'scalar', 'integer', ...
                'positive', 'nonsparse', 'real'}, class(this));
            
            validateattributes(imageSize, {'numeric'}, {'vector', 'integer', ...
                'positive', 'nonsparse'}, class(this));
            if numel(imageSize) > 3
                validateattributes(imageSize, {'numeric'}, {'vector', 'integer', ...
                'positive', 'numel', 2}, class(this));
            end
            
            coder.varsize('metric', [inf, 1]);
            coder.varsize('origIdx', [1, inf]);
            coder.varsize('points', [inf, 2]);
            coder.varsize('idxOut', [inf, 1]);
            coder.varsize('idx', [inf, 1]);
            coder.varsize('idxNum', [1, inf]);
            
            imageSize = imageSize([2,1]);
            points = this.Location;
            
            metric = this.Metric;
            origIdx = 1:this.Count;
            
            idxOut = coder.nullcopy(zeros(size(this.pMetric), 'like', this.pMetric));
            
            if numPoints > length(idxOut)
                NN = length(idxOut);
            else
                NN = numPoints;
            end
            
            first = 1;
            if isempty(coder.target) && ~isa(this.Location, 'gpuArray')
                idxNum = visionSelectUniformPoints(double(points), imageSize,...
                    double(metric), NN);
                idxNum = sort(idxNum);
                idx = false(size(origIdx));
                idx(idxNum) = true;
            else
                idx = selectPoints(points, imageSize, metric, NN);
                idxNum = origIdx(idx);
            end
            idxOut(first:numel(idxNum)) = idxNum';
            first = numel(idxNum) + 1;
            
            while(first <= NN)
                origIdx = origIdx(~idx);
                points = points(~idx, :);
                metric = metric(~idx);
                n = NN - (first - 1);
                
                if isempty(coder.target) && ~isa(this.Location, 'gpuArray')
                    idxNum = visionSelectUniformPoints(double(points), imageSize,...
                        double(metric), n);
                    idx = false(size(points,1), 1);
                    idx(idxNum) = true;
                    idxNum = origIdx(idx);
                else
                    idx = selectPoints(points, imageSize, metric, n);
                    idxNum = origIdx(idx);
                end

                idxOut(first:first+numel(idxNum)-1) = idxNum';
                first = first+numel(idxNum);
            end
            
            if isempty(coder.target)
                s.type = '()';
                s.subs = {idxOut(1:NN)};
                pointsOut = subsref(this, s);
            else
                pointsOut = getIndexedObj(this, idxOut(1:NN));
            end
        end
        
        %------------------------------------------------------------------
        % Note:  NUMEL is not overridden because it interferes with the
        %        desired operation of this object. FeaturePoints is a scalar
        %        object which pretends to be a vector. NUMEL is used during
        %        subsref operations and therefore needs to represent true
        %        number of elements for the object, which is always 1.
        %------------------------------------------------------------------
        function out = length(this)
            %length Returns number of points
            out = this.Count;
        end
        
        %------------------------------------------------------------------
        function out = isempty(this)
            %isempty Returns true if the object is empty
            out = this.Count == 0;
        end
        
        %-------------------------------------------------------------------
        function ind = end(this,varargin)
            %END Last index in indexing expression for FeaturePoints
            %   end(V,K,N) is called for indexing expressions involving the
            %   FeaturePoints vector V when END is part of the K-th index out of
            %   N indices. For example, the expression V(end-1,:) calls the
            %   FeaturePoints vector's END method with END(V,1,2).
            %
            %   See also end
            
            if isempty(varargin) || varargin{1} == 1
                ind = this.Count;
            else
                ind = 1;
            end
        end
        %-----------------------------------------------
        function this = set.Location(this, in)
            this.checkForResizing(in);
            this.checkLocation(in);
            this.pLocation(:) = single(in);
        end
        function out = get.Location(this)
            out = this.pLocation;
        end
        %------------------------------------------------
        function this = set.Metric(this, in)
            this.checkForResizing(in);
            this.checkMetric(in);
            this.pMetric(:) = single(in);
        end
        function out = get.Metric(this)
            out = this.pMetric;
        end
        %-------------------------------------------------
        function out = get.Count(this)
            out = size(this.Location,1);
        end
                
    end
    methods(Access = protected)
        
        function inputs = parseInputs(~, varargin)
            
            if isempty(coder.target)
                % Parse the PV pairs
                parser = inputParser;
                parser.addRequired('Location')
                parser.addParameter('Metric', single(0));
                
                % Parse input
                parser.parse(varargin{:});
                
                inputs = parser.Results;                
                
            else
                defaultsNoVal = struct('Metric', uint32(0));
                
                properties = struct( ...
                    'CaseSensitivity', false, ...
                    'StructExpand',    true, ...
                    'PartialMatching', false);
                
                inputs.Location = single(varargin{1});
                               
                defaults = vision.internal.FeaturePointsImpl.getParameterDefaults();
                                                                 
                optarg = eml_parse_parameter_inputs(defaultsNoVal, properties, varargin{2:end});
                
                inputs.Metric = (eml_get_parameter_value( ...
                    optarg.Metric, defaults.Metric, varargin{2:end}));
                
            end
        end
        
        function validate(this, inputs)
            
            this.checkLocation(inputs.Location);
            this.checkMetric(inputs.Metric);
            
            numPts = size(inputs.Location,1);
            % Parameters must have the same number of elements or be a scalar
            vision.internal.FeaturePointsImpl.validateParamLength(numel(inputs.Metric), 'Metric', numPts);
            
        end
                
        function checkForResizing(this, in)
            % Prevent resizing of public properties
            coder.internal.errorIf(size(in,1) ~= this.Count, ...
                'vision:FeaturePoints:cannotResizePoints', class(this));
        end
                             
        %------------------------------------------------------------------
        function this = configure(this,inputs)                                                         
            
            if ~isempty(coder.target)
                if eml_is_const(size(inputs.Location))                    
                    eml_invariant(all(size(inputs.Location) > 0) , ...
                      eml_message('vision:FeaturePoints:constSizeEmpty'));   
                end
            end
            
            n = size(inputs.Location,1);
                     
            % If either location or metric is a gpuArray then store both as
            % gpuArrays.
            if isa(inputs.Metric, 'gpuArray') || isa(inputs.Location, 'gpuArray')                
                prototype = zeros(0,1,'single','gpuArray');            
            else
                % built-in type/codegen code path
                prototype = zeros(0,1,'single');
            end
                                
            this.pLocation = coder.nullcopy(zeros(n,2,'like',prototype));
            
            this.pLocation = single(inputs.Location);
            
            this.pMetric = coder.nullcopy(zeros(n,1,'like',prototype));            
                                             
            this.pMetric(:) = ...
                vision.internal.FeaturePointsImpl.assignValue(single(inputs.Metric),n);
            
        end
        
        function checkLocation(this, location)
            
            if isa(location, 'gpuArray')
                checkGPULocation(this, location);                                                        
            else
                validateattributes(location, {'numeric'}, {'nonnan', ...
                'finite', 'nonsparse', 'real', 'positive', 'size',[NaN,2]}, ...
                class(this)); %#ok<*EMCA>
            end
        end
        
        function checkGPULocation(this, location)
            hValidateAttributes(location, {'numeric'}, {'nonnan', ...
                'finite','real'}, ...
                class(this)); %#ok<*EMCA>
            
            % positive
            if any(location(:) <= 0)
                validateattributes(-1, {'numeric'}, {'positive'}, class(this));                
            end
            
            % size
            if size(location,2) ~= 2
                validateattributes(ones(3,3),{'numeric'},{'size',[NaN,2]},class(this));                
            end
        end
        
        function checkMetric(this, metric)
            checkParam(metric, class(this),'Metric');
        end
        
        function checkScale(this, scale)
            checkParam(scale,class(this),'Scale');
        end
        
        function checkOrientation(this, orientation)
            checkParam(orientation, class(this),'Orientation');
        end
    end
    
    methods (Static, Access = protected)      
                     
        function validateParamLength(numelParam, paramName, numPts)
            coder.internal.errorIf(~(numelParam == 1 || numelParam == numPts), ...
                'vision:FeaturePoints:invalidParamLength', paramName);
        end
        
        function defaults = getParameterDefaults()
            defaults = struct('Metric', single(0));
        end
        
        function v = assignValue(x,N)
            % copy x into v, expanding scalars if needed
            coder.inline('always');
            v = coder.nullcopy(ones(N,1,'like',x));
            if isscalar(x)
                v = repmat(x(:),N,1);                
            else
                v = x(:);                
            end
        end
    end
end

function checkParam(in,fname,pname)
if isa(in, 'gpuArray')
    hValidateAttributes(in, {'numeric'},...
        {'nonnan', 'finite', 'real','vector'},...
        fname, pname);
else
    validateattributes(in, {'numeric'},...
        {'nonnan', 'finite', 'nonsparse','real','vector'},...
        fname, pname);
end
end

%--------------------------------------------------------------------------
function pointsIdx = selectPoints(points, imageSize, metric, numPoints)
if numPoints == 1
    [~, numericIdx] = max(metric);
    pointsIdx = false(size(points, 1), 1);
    pointsIdx(numericIdx) = true;
    return;
end

aspectRatio = imageSize(1) / imageSize(2);
h = max(floor(sqrt(numPoints / aspectRatio)), 1);
w = max(floor(h * aspectRatio), 1);

nBins = [w, h];
gridStep = imageSize ./ (nBins + 1);

binIdx = zeros(nBins);

for i = 1:size(points, 1)
    whichBin = min([floor(points(i, :) ./ gridStep) + 1; nBins]);
    idx = binIdx(whichBin(1), whichBin(2));
    if idx < 1 || metric(idx) < metric(i)
        binIdx(whichBin(1), whichBin(2)) = i;
    end
end
numericIdx = binIdx(binIdx > 0);
numericIdx = numericIdx(:);
pointsIdx = false(size(points, 1), 1);
pointsIdx(numericIdx) = true;
end

%  In order for method help to work properly for subclasses, this classdef
%  file cannot have a comment block at the top, so the following remark and
%  copyright/version information are provided here at the end. Please do
%  not move them.

% Copyright 2013 The MathWorks, Inc.
