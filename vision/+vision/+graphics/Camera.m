classdef Camera < handle
    properties(SetAccess=private)
        Parent;
    end
    
    properties(Hidden, SetAccess=private)
        Group = [];
    end
    
    properties(Dependent)
        % Size The size of the camera's base
        Size;
        
        % Location Camera's 3-D location specified as a 3-element vector
        Location;
        
        % Orientation Camera's 3-D orientation specified as a 3-by-3 rotation matrix
        Orientation;
        
        % Visible A logical scalar that controls visibility of the camera
        Visible;
        
        % AxesVisible A logical scalar that controls visibility of camera axes
        AxesVisible;
        
        % ButtonDownFcn A callback to be executed when you click on the camera
        ButtonDownFcn;
        
        % Color Color of the camera
        Color;
        
        % Opacity A scalar in the range [0,1] specifying the opacity of the camera
        Opacity;
        
        % Label A string displayed next to the camera
        Label;
    end
    
    properties(Access=private)
        SizeInternal = 1;
        LocationInternal = [0 0 0];
        RotationInternal = eye(3);
        
        Wireframe;
        LensFace;
        Faces;
        HLabel;
        CameraAxes;        
    end
    
    methods(Static, Hidden)
        function cam = plotCameraImpl(camSize, location, orientation, parent)
            cam = vision.graphics.Camera(camSize, location, orientation, parent);
        end
    end
    
    methods        
        %------------------------------------------------------------------
        function set.Size(this, camSize) 
            vision.graphics.Camera.checkCameraSize(camSize);
            this.SizeInternal = camSize;
            this.updateTransform();
        end
        
        %------------------------------------------------------------------
        function camSize = get.Size(this)
            camSize = this.SizeInternal;
        end
                
        %------------------------------------------------------------------
        function location = get.Location(this)
            location = this.LocationInternal;
        end
                
        %------------------------------------------------------------------
        function set.Location(this, location)
            vision.graphics.Camera.checkLocation(location);
            this.LocationInternal = location(:)';
            this.updateTransform();
        end
        
        %------------------------------------------------------------------
        function set.Orientation(this, orientation)
            vision.graphics.Camera.checkOrientation(orientation);
            this.RotationInternal = orientation;
            this.updateTransform();
        end
        
        %------------------------------------------------------------------
        function R = get.Orientation(this)
            R = this.RotationInternal;
        end
        
        %------------------------------------------------------------------
        function set.Visible(this, isVisible)
            vision.graphics.Camera.checkVisible(isVisible);
            if isVisible
                this.Group.Visible = 'on';
            else
                this.Group.Visible = 'off';
            end
        end

        %------------------------------------------------------------------
        function isVisible = get.Visible(this)
            isVisible = strcmp(this.Group.Visible, 'on');
        end
        
        %------------------------------------------------------------------
        function set.AxesVisible(this, isVisible)
            vision.graphics.Camera.checkAxesVisible(isVisible);
            if isVisible
                this.CameraAxes.Visible = 'on';
            else
                this.CameraAxes.Visible = 'off';
            end
        end

        %------------------------------------------------------------------
        function isVisible = get.AxesVisible(this)
            isVisible = strcmp(this.CameraAxes.Visible, 'on');
        end
        
        %------------------------------------------------------------------
        function set.Color(this, c)
            vision.graphics.Camera.checkColor(c);
            this.HLabel.Color = c;
            this.Wireframe.Color = c;
            this.LensFace.EdgeColor = c;
            for i = 1:numel(this.Faces)
                this.Faces{i}.EdgeColor = c;
                this.Faces{i}.FaceColor = c;
            end
        end
        
        %------------------------------------------------------------------
        function c = get.Color(this)
            c = this.Wireframe.Color;
        end
        
        %------------------------------------------------------------------
        function set.Opacity(this, opacity)
            vision.graphics.Camera.checkOpacity(opacity);
            this.LensFace.FaceAlpha = opacity;
            for i = 1:numel(this.Faces)
                this.Faces{i}.FaceAlpha = opacity;
            end
        end
        
        %------------------------------------------------------------------
        function opacity = get.Opacity(this)
            opacity = this.LensFace.FaceAlpha;
        end
        
        %------------------------------------------------------------------
        function set.ButtonDownFcn(this, fun)
            vision.graphics.Camera.checkCallback(fun);
            this.Group.ButtonDownFcn = fun;
        end
        
        %------------------------------------------------------------------
        function fun = get.ButtonDownFcn(this)
            fun = this.Group.ButtonDownFcn;
        end
        
        %------------------------------------------------------------------
        function set.Label(this, label)
            vision.graphics.Camera.checkLabel(label);
            this.HLabel.String = label;
        end
        
        %------------------------------------------------------------------
        function label = get.Label(this)
            label = this.HLabel.String;
        end
        
        %------------------------------------------------------------------
        function delete(this)
            delete(this.Group);
        end
    end
    
    methods(Access=private)
        function this = Camera(camSize, location, orientation, parent)            
            this.Parent = parent;
            newplot(this.Parent);
            this.Group = hgtransform('Parent', parent);
            camPts = getCamPts();
            defaultColor = 'r';
            this.Wireframe = plot3(this.Group, camPts(:,1), camPts(:,2),...
                camPts(:,3), '-', 'linewidth', 1.5, 'Color', defaultColor,...
                'HitTest', 'off');
            label = '';
            this.HLabel = text(2, 2, 2, label, 'Parent', this.Group, ...
                'Color', defaultColor, 'HitTest', 'off');
            
            colorCameraSurfaces(this, camPts, 0);
            
            plotCameraAxes(this);
            
            this.SizeInternal = camSize;
            this.LocationInternal = location;
            [U, ~, V] = svd(orientation);
            this.RotationInternal = U * V';
            this.updateTransform();
            
            % Cache handle to hobject in hg hierarchy so that if user
            % loses handle to h_obj, object still lives in HG
            % hierarchy. This makes rois behave more like HG objects.
            setappdata(this.Group,'cameraObjectReference', this);
            
            % When the hgtransform that is part of the HG tree is
            % destroyed, the object is no longer valid and must be
            % deleted.
            setappdata(this.Group,'graphicsDeletedListener',...
                iptui.iptaddlistener(this.Group,...
                'ObjectBeingDestroyed',@(varargin) this.delete()));
        end
        
        %------------------------------------------------------------------
        function updateTransform(this)
            S = makehgtform('scale', this.SizeInternal);
            T = makehgtform('translate', this.LocationInternal);
            T(1:3, 1:3) = this.RotationInternal';
            this.Group.Matrix = T * S;
        end
        
        %------------------------------------------------------------------
        function colorCameraSurfaces(this, camPts, alpha)
            
            camColor = this.Color;
            
            % cam 'lens'
            lensPatch = struct('vertices', camPts, 'faces', 17:21);
            h = patch(lensPatch, 'Parent', this.Group);
            set(h,'FaceColor', [0 0.8 1], 'FaceAlpha', alpha, ...
                'EdgeColor', camColor, 'HitTest', 'off');
            this.LensFace = h;
            
            % cam back
            rimPatch = struct('vertices', camPts, 'faces', 1:5);
            h = patch(rimPatch, 'Parent', this.Group);
            set(h,'FaceColor', camColor, 'FaceAlpha', alpha, ...
                'EdgeColor', camColor, 'HitTest', 'off');
            this.Faces{1} = h;
            
            % cam sides
            sidePatch = struct('vertices', camPts, 'faces',...
                [5 6 7 8 5; 8 9 10 11 8; 11 12 13 14 11; 14 5 6 13 14]);
            h = patch(sidePatch, 'Parent', this.Group);
            set(h,'FaceColor', camColor, 'FaceAlpha', alpha, ...
                'EdgeColor', camColor, 'HitTest', 'off');
            this.Faces{2} = h;
            
            % cam rim
            rimPatch = struct('vertices', camPts, 'faces',...
                [21 22 23 24  21; 24 25 26  27 24;...
                27 28 29 30 27; 30 31 32 21 30]);
            
            h = patch(rimPatch, 'Parent', this.Group);
            set(h,'FaceColor', camColor, 'FaceAlpha', alpha, ...
                'EdgeColor', camColor, 'HitTest', 'off');
            this.Faces{3} = h;
        end
        
        %------------------------------------------------------------------
        function plotCameraAxes(this)
            camAxesPts = getCamAxesPts();
            this.CameraAxes = hgtransform('Parent', this.Group);
            holdState = get(this.Parent, 'NextPlot');
            set(this.Parent, 'NextPlot', 'add');
            plot3(this.CameraAxes, camAxesPts(:,1),camAxesPts(:,2),camAxesPts(:,3),'k-',...
                'linewidth',1.5, 'HitTest', 'off');
            
            plotAxesLabels(this, camAxesPts);
            set(this.Parent, 'NextPlot', holdState); % restore the state
        end
        
        %------------------------------------------------------------------
        function plotAxesLabels(this, camAxesPts)
            text( camAxesPts(2,1), camAxesPts(2,2), camAxesPts(2,3), 'X_c', 'Parent', this.CameraAxes);
            text( camAxesPts(4,1), camAxesPts(4,2), camAxesPts(4,3), 'Y_c', 'Parent', this.CameraAxes);
            text( camAxesPts(6,1), camAxesPts(6,2), camAxesPts(6,3), 'Z_c', 'Parent', this.CameraAxes);
        end
    end
    
    methods(Static, Hidden)
        %------------------------------------------------------------------
        function tf = checkLocation(location)
            validateattributes(location, {'numeric'}, ...
                {'real', 'nonsparse', 'finite', 'vector', 'numel', 3}, ...
                'plotCamera', 'Location');
            tf = true;
        end
        
        %------------------------------------------------------------------
        function tf = checkCameraSize(camSize)
            validateattributes(camSize, {'numeric'},...
                {'real', 'nonsparse', 'finite', 'scalar', 'positive'}, ...
                'plotCamera', 'Size');
            tf = true;
        end
        
        %------------------------------------------------------------------
        function tf = checkOrientation(orientation)
            vision.internal.inputValidation.validateRotationMatrix(orientation, ...
                'plotCamera', 'Orientation');
            tf = true;
        end
        
        %------------------------------------------------------------------
        function tf = checkColor(camColor)
            fileName = 'plotCamera';
            if isnumeric(camColor)
                validateattributes(camColor, ...
                    {'numeric'},...
                    {'real','nonsparse','nonnan', 'finite', 'vector', 'numel', 3}, ...
                    fileName, 'Color');
            else
                validateattributes(camColor, {'char'}, {}, fileName, 'Color');
                if isscalar(camColor)
                    supportedColorStr = {'b', 'g', 'r', 'c', 'm', 'y', 'k', 'w'};
                else
                    supportedColorStr = {'blue','green','red','cyan','magenta', ...
                        'yellow','black','white'};
                end
                validatestring(camColor, supportedColorStr, fileName, 'Color');
            end
            tf = true;            
        end
        
        %------------------------------------------------------------------
        function tf = checkLabel(label)
            validateattributes(label, {'char'}, {}, 'plotCamera', 'Label');
            tf = true;
        end
        
        %------------------------------------------------------------------
        function tf = checkVisible(visible)
            vision.internal.inputValidation.validateLogical(visible, 'Visible');
            tf = true;
        end
        
        %------------------------------------------------------------------
        function tf = checkAxesVisible(visible)
            vision.internal.inputValidation.validateLogical(visible, 'Visible');
            tf = true;
        end
        
        %------------------------------------------------------------------
        function tf = checkOpacity(opacity)
            validateattributes(opacity, {'numeric'}, ...
                {'real', 'nonsparse', 'finite', 'scalar', 'nonnegative', '<=', 1},...
                'plotCamera', 'Opacity');
            tf = true;
        end
        
        %------------------------------------------------------------------
        function tf = checkCallback(fun)
            if ~isempty(fun)
                if iscell(fun)
                    checkFunctionHandle(fun{1});
                else
                    checkFunctionHandle(fun);
                end
            end
            tf = true;
        end
    end
end

%--------------------------------------------------------------------------
function checkFunctionHandle(fun)
validateattributes(fun, {'function_handle'}, {}, 'plotCamera', ...
                    'ButtonDownFcn');
end

%--------------------------------------------------------------------------
function camPts = getCamPts()

cu = 1;
ln = cu+cu;  % cam length

% back
camPts = [0  0   cu  cu 0;...
          0  cu  cu  0  0;...
          0  0   0   0  0];
% sides
camPts = [camPts, ...
    [0   0  0  0  cu cu cu cu cu cu 0; ...
     0   cu cu cu cu cu cu 0  0  0  0; ...
     ln  ln 0  ln ln 0  ln ln 0  ln ln]];

ro = cu/2;    % rim offset
rm = ln+2*ro; % rim z offset (extent)

% lens
camPts = [camPts, ...
    [ -ro  -ro     cu+ro   cu+ro  -ro; ...
      -ro   cu+ro  cu+ro  -ro     -ro; ...
       rm   rm     rm      rm      rm] ];

% rim around the lens
camPts = [camPts, ...
    [0   0  -ro    0  cu  cu+ro cu cu  cu+ro cu  0 ;...
     0   cu  cu+ro cu cu  cu+ro cu 0  -ro    0   0 ;...
     ln  ln  rm    ln ln  rm    ln ln  rm    ln  ln] ];

camPts = bsxfun(@minus, camPts, [cu/2; cu/2; cu]);
camPts = camPts';
end

%--------------------------------------------------------------------------
function camAxesPts = getCamAxesPts()
% cam axis
camAxesPts = 2*([0 1 0 0 0 0;
                 0 0 0 1 0 0;
                 0 0 0 0 0 1]);
camAxesPts = camAxesPts';
end
