classdef FeaturePoints < vision.internal.FeaturePointsImpl
    
    properties(Hidden, Access = protected)
        % Amount to scale unit circle used to represent the smallest scale
        % of the detected features.
        PlotScaleFactor = 1;
    end
    
    methods (Access='public')
        function this = FeaturePoints(varargin)
            this = this@vision.internal.FeaturePointsImpl(varargin{:});
        end
        %------------------------------------------------------------------
        function varargout = size(this, varargin)
            %SIZE Size of FeaturePoints points.
            %
            %   SZ = size(V) returns the vector [length(V), 1].
            %
            %   SZ = size(V, 1) returns the length of V.
            %
            %   SZ = size(V, N), for N >= 2, returns 1.
            %
            %   [M, N] = size(V) returns length(V) for M and 1 for N.
            %
            
            try
                % Use the builtin function to validate the inputs and
                % outputs.
                switch nargout
                    case 0
                        % size(obj)       :  ans = [this.Count 1]
                        % size(obj, 1)    :  ans = this.Count
                        % size(obj, 2)    :  ans = 1
                        % size(obj, d > 2):  ans = 1
                        [varargout{1:nargout}] = ...
                            builtin('size', this, varargin{:});
                        if isempty(varargin)
                            % size(obj)
                            varargout{1}(1) = this.Count;
                        elseif numel(varargin) == 1 && varargin{1} ~= 1
                            % size(obj, 2), size(obj,n) n~=1 = 1
                            varargout{1} = 1;
                        else
                            % size(obj, 1)
                            varargout{1} = this.Count;
                        end
                        
                    case 1
                        % D = size(obj)       :  D = [this.Count, 1]
                        % n = size(obj, 1)    :  n = this.Count
                        % m = size(obj, 2)    :  m = 1
                        % p = size(obj, d > 2):  p = 1
                        n = builtin('size', this, varargin{:});
                        if isempty(varargin)
                            % D = size(obj);
                            varargout{1} = [this.Count, 1];
                        elseif numel(varargin) == 1 && varargin{1} ~= 1
                            % m = size(obj, 2);
                            % p = size(obj, d > 3);
                            varargout{1} = n;
                        else
                            % n = size(obj, 1);
                            varargout{1} = this.Count;
                        end
                        
                    case 2
                        % [n, m] = size(obj);
                        % [n, m] = size(obj, d) --> issues error
                        [n, ~] = builtin('size', this, varargin{:});
                        varargout{1} = this.Count;
                        varargout{2} = n;
                        
                    otherwise
                        % [n, m, p, ...] = size(obj)
                        % [n, m, p, ...] = size(obj, d) ---> issues error
                        %  p, ... are always 1
                        [n, ~, varargout{3:nargout}] = ...
                            builtin('size', this, varargin{:});
                        varargout{1} = this.Count;
                        varargout{2} = n;
                end
            catch e
                % throwAsCaller(e) in order to prevent the line:
                % Error using FeaturePoints/size. Issue only
                % the error message.
                throwAsCaller(e);
            end
        end
        
        %-------------------------------------------------------------------
        function varargout = plot(this, supportsScaleAndOrientation, varargin)
            %plot Plot feature points
            %
            %   featurePoints.plot plots feature points in the current axis.
            %
            %   featurePoints.plot(AXES_HANDLE,...) plots using axes with
            %   the handle AXES_HANDLE instead of the current axes (gca).
            %
            nargoutchk(0,1);
            
            if nargin == 1
                supportsScaleAndOrientation = false;
            end
                                                               
            [axes, inputs] = parsePlotInputs(supportsScaleAndOrientation, ...
                varargin{:});                                                
            
            ax = newplot(axes);

            % mark centers with a '+'
            plot(ax, this.pLocation(:,1), this.pLocation(:,2),'g+');
            
            isFeatureSetEmpty = (this.Count == 0);
            if (inputs.showScale || inputs.showOrientation) && ~isFeatureSetEmpty
                
                phi = linspace(0,2*pi);
                x = cos(phi);  % will cause horizontal line +90 for vertical
                y = sin(phi);
                
                if inputs.showOrientation % Plot orientation
                    % the two zeros result in a horizontal line which
                    % will be rotated at a later stage
                    unitCircle = [x 0; y 0];
                else
                    unitCircle = [x; y];
                end
                
                wasHeld = ishold;
                                
                circlesX = [];
                circlesY = [];
                for k = 1:this.Count
                    scale  = this.PlotScaleFactor*this.Scale(k);
                    pt     = this.Location(k,:)';
                    % negate the orientation so that it's adjusted for
                    % plotting in the HG's "image" type which assumes that Y
                    % axis is pointing downward
                    orient = -this.Orientation(k);
                    
                    rotationMat = [cos(orient) -sin(orient);...
                        sin(orient) cos(orient)];
                    
                    featureCircle = scale*rotationMat*unitCircle + ...
                        pt*ones(1,size(unitCircle,2));
                
                    % insert the NaNs to separate the individual circles
                    circlesX = [circlesX, featureCircle(1,:), NaN]; %#ok<AGROW>
                    circlesY = [circlesY, featureCircle(2,:), NaN]; %#ok<AGROW>                    
                end

                % turn the hold state on, otherwise the next plot command
                % will overwrite the previous plot result
                if k==1 && ~wasHeld
                    hold('on');
                end
                
                plot(ax, circlesX, circlesY,'g-');
                
                if ~wasHeld
                    hold('off'); % restore original states of hold
                end
            end
                                 
            if nargout == 1
                varargout{1} = ax;
            end 
            
            drawnow();
            
        end
                
        %-------------------------------------------------------------------
        function varargout = subsref(this,s)
            
            try
                switch s(1).type
                    case '()'
                        nargoutchk(0,1);
                        this = subsref_data(this, s(1));
                        
                        % invocation of plot or disp would result in setting
                        % isDotMethod
                        if numel(s) >= 2
                            isDotMethod = any(strcmp(s(2).subs, {'plot','disp'}));
                        else
                            isDotMethod = false;
                        end
                        
                        % protect against indexing that would affect integrity
                        % of the object
                        if (~isDotMethod)
                            if ~(   size(this.pLocation,2) == 2 && ...
                                    size(this.pMetric,2)   == 1 && ...
                                    ismatrix(this.pMetric)      && ...
                                    numel(s)               <= 2 )
                                error(message('vision:FeaturePoints:invalidIndexingOperation'));
                            end
                        end
                        
                        if numel(s) <= 1
                            varargout{1} = this;
                        else
                            if  isDotMethod && nargout ==  0
                                % avoid setting "ans" with the following syntax:
                                % pts(1).plot
                                builtin('subsref',this,s(2:end));
                            else
                                varargout{1} = builtin('subsref',this,s(2:end));
                            end
                        end
                        
                    case '{}'
                        % use of {} indexing is not supported by FeaturePoints;
                        % let the builtin function error out as appropriate
                        builtin('subsref',this,s);
                        
                    case '.'
                        % don't set "ans" for disp and plot
                        if  strcmp(s(1).subs, 'disp') || ...
                                (strcmp(s(1).subs, 'plot') && nargout == 0)
                            builtin('subsref',this,s);
                        else
                            if nargout == 0
                                varargout{1} = builtin('subsref',this,s);
                            else
                                varargout{1:nargout} = builtin('subsref',this,s);
                            end
                        end 
                end
            catch e
                throwAsCaller(e);
            end
        end
        
        %-------------------------------------------------------------------
        function out = subsasgn(this,s,in)
            try
                switch s(1).type
                    case '()'
                        if numel(s) == 2
                            % Location is Mx2 and must be handled specially
                            % to make assignment like p(1).Location = [2 3]
                            % work. The code below transforms the (1) index
                            % to (1,:).
                            if strcmp(s(2).subs,'Location')  && ...
                                    numel( s(1).subs ) == 1
                                s(1).subs{2} = ':';
                            end
                            
                            this.(s(2).subs) = subsasgn(this.(s(2).subs), s(1), in);
                            
                        else
                            
                            % Error out if the right hand side of the assignment
                            % is not [] or non-empty FeaturePoints
                            if ~( (isa(in,'vision.internal.FeaturePoints') && ~isempty(in)) || ...
                                    (isa(in,'double') && isempty(in)) )
                                error(message('vision:FeaturePoints:badAssignmentInput',...
                                    class(this)));
                            end
                            
                            this = subsasgn_data(this, s, in);
                        end
                        
                        out = this;
                    case {'{}', '.'}
                        out = builtin('subsasgn',this,s,in);
                end
            catch e
                throwAsCaller(e);
            end
        end
        
        %-------------------------------------------------------------------
        % All of the methods below have to be managed because they can
        % create non-scalar arrays of objects and FeaturePoints is strictly
        % a scalar object.
        %-------------------------------------------------------------------
        function out = cat(dim,varargin)
            try
                validateattributes(dim, {'numeric'}, {'nonempty','finite',...
                    'integer'},mfilename,'Dimension');
                
                if dim ~= 2
                    error(message('vision:FeaturePoints:badCatDim'));
                end
                out = vertcat(varargin{:});
            catch e
                throwAsCaller(e)
            end
        end
        %
        function out = horzcat(varargin) %#ok<STOUT>
            try
                error(message('vision:FeaturePoints:noHorzcatAllowed',...
                    class(varargin{1})));
            catch e
                throwAsCaller(e);
            end
        end
        %
        function out = vertcat(varargin)
            try
                
                if ~all(cellfun(@(x)isa(x,class(varargin{1})),varargin))
                    error(message('vision:FeaturePoints:badCatTypes',class(varargin{1})));
                end
                
                out = vertcatObj(varargin{:});
      
            catch e
                throwAsCaller(e);
            end
        end
        %
        function out = repmat(varargin) %#ok<STOUT>
            try
                error(message('vision:FeaturePoints:noRepmatAllowed',...
                    class(varargin{1})));
            catch e
                throwAsCaller(e);
            end
        end        
    end
    
    methods (Hidden)
        function sz = numArgumentsFromSubscript(~, ~, callingContext)   
            switch callingContext.char
                case 'Statement'  % this(1:n).prop, this.plot
                    sz = 0;
                case {'Assignment', ... % [this(1:n).prop] = val
                      'Expression'}     % sin(this(1:n).prop)
                    sz = 1;
            end
        end
    end
    
    methods (Access='protected')
        %------------------------------------------------------------------       
        % Copy data for subsref. This method is used in subsref
        %------------------------------------------------------------------
        function this = subsref_data(this, option)
            % Location is an Mx2 matrix while Metric is an Mx1 matrix. When
            % the indices for sub-referencing is a 1-D array, we explicitly
            % specify the size for the second dimension.
            opt1 = option;
            opt2 = option;
            if length(option.subs) == 1
                opt1.subs{2} = 1;
                opt2.subs{2} = 1:2;
            end
            this.pMetric   = subsref(this.pMetric,opt1);
            this.pLocation = subsref(this.pLocation,opt2);
        end
        
        %------------------------------------------------------------------      
        % Copy data for subsasgn. This method is used in subsasgn
        %------------------------------------------------------------------
        function this = subsasgn_data(this, option, in)
            locS = option; % modify index to access Mx2 location matrix
            locS.subs{2} = ':';
            
            if isempty(in)
                this.pLocation = subsasgn(this.pLocation, locS,   in);
                this.pMetric   = subsasgn(this.pMetric,   option, in);
            else
                this.pLocation = ...
                    subsasgn(this.pLocation, locS,   in.pLocation);
                this.pMetric = ...
                    subsasgn(this.pMetric,   option, in.pMetric);
            end
        end
        
        %------------------------------------------------------------------
        % Concatenate data for vertcat. This method is used in vertcat.
        %------------------------------------------------------------------
        function obj = vertcatObj(varargin)
            obj = varargin{1};
            for i=2:nargin
                obj.pLocation = [obj.pLocation; varargin{i}.pLocation];
                obj.pMetric   = [obj.pMetric  ; varargin{i}.pMetric];
            end
        end
    end
end


%--------------------------------------------------------------------------
% Plot input parser
%--------------------------------------------------------------------------
function [h, inputs] = parsePlotInputs(supportsScaleAndOrientation, varargin)

% Parse the PV pairs
parser = inputParser;

parser.addOptional('AXIS_HANDLE', [], ...
    @vision.internal.inputValidation.validateAxesHandle)

if supportsScaleAndOrientation
    parser.addParameter('showScale',       true,  @checkFlag);
    parser.addParameter('showOrientation', false, @checkFlag);
end

% Parse input
parser.parse(varargin{:});

% Assign return values
h = parser.Results.AXIS_HANDLE;

if supportsScaleAndOrientation
    inputs.showScale        = logical(parser.Results.showScale);
    inputs.showOrientation  = logical(parser.Results.showOrientation);
else
    inputs.showScale = false;
    inputs.showOrientation = false;
end

end

%--------------------------------------------------------------------------
function tf = checkFlag(in)

validateattributes(in, {'logical','numeric'},...
    {'nonnan', 'scalar', 'real','nonsparse'},...
    mfilename);

tf = true;
end

%  In order for method help to work properly for subclasses, this classdef
%  file cannot have a comment block at the top, so the following remark and
%  copyright/version information are provided here at the end. Please do
%  not move them.

%FeaturePoints Object for storing feature points
%
%   FeaturePoints object describes feature points.
%

% Copyright 2013 The MathWorks, Inc.
