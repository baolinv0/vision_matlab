classdef imrectButtonDown < iptui.imcropRect
    
    % This undocumented class may be removed in a future release.    
    %   Copyright 2008-2013 The MathWorks, Inc.
    
    % Inheriting from iptui.imcropRect to force ROIs to capture whole
    % pixels
    
    methods
        
        function obj = imrectButtonDown(h_img,evt) %#ok<INUSD>
            
            h_ax = ancestor(h_img,'axes');
            
            currentPoint = get(h_ax,'CurrentPoint');
            initial_x = currentPoint(1,1);
            initial_y = currentPoint(1,2);
            
            % get image extent for boundary constraints
            [x_extent, y_extent] = iptui.getImageExtent(h_img);
            constraint_fcn = makeConstrainToRectFcn('imrect',...
                x_extent,...
                y_extent);
            
            initial_position = drawImrectAffordance(h_ax,...
                initial_x,...
                initial_y,...
                constraint_fcn);
            
            initial_position = snapPositionToPixels(initial_position, h_img);
            obj = obj@iptui.imcropRect(h_ax,initial_position, h_img);
            
        end
       
    end
    
    methods(Static,Hidden)
        %------------------------------------------------------------------
        % Let user draw and ROI into an image given by a image handle.
        % Returns empty or a valid ROI object. Use the static isvalid
        % method to check validity in clients.
        %------------------------------------------------------------------
        function roi = drawROI(hImage)
             
            try
                % the drawnow() below is critical since in rapid-fire
                % drawing not having it can lead to de-synchronization of
                % events
                drawnow();
                
                roi = vision.internal.uitools.imrectButtonDown(hImage);
            catch
                roi = [];
            end
            
            if isempty(roi)
                return;
            end
            
            % Left click on the image does not create empty ROIs
            roiPos = roi.getPosition();            
            if ~any(roiPos(3:4))
                roi.delete();                                                                         
            end
                       
            drawnow(); % Finish all the drawing before moving on           
            
        end
        
        %------------------------------------------------------------------
        % Return true if drawn ROI is valid.
        %------------------------------------------------------------------
        function tf = isValidROI(roi)
            tf = ~isempty(roi) && isvalid(roi);
        end
    end
end
%------------------------------------------------------------------

function finalPos = snapPositionToPixels(initialPos, hImage)
    % Copied helper function from IMCROP since makeConstrainToRectFcn() 
    % does not support IMCROP

    % initialize crop rect to the "identity" cropping rectangle
    x_data = get(hImage,'xdata');
    y_data = get(hImage,'ydata');
    
    % generate transformation from spatial to pixel space
    im_height = size(get(hImage,'CData'),1);
    im_width  = size(get(hImage,'CData'),2);
    
    x_scale_s2p = (im_width  -1) / (x_data(2)-x_data(1));
    y_scale_s2p = (im_height -1) / (y_data(2)-y_data(1));
    scale_s2p = [x_scale_s2p y_scale_s2p];
    
    x_scale_s2p = scale_s2p(1);
    y_scale_s2p = scale_s2p(2);
    
    % get image extent for boundary constraints
    [x_extent, y_extent] = iptui.getImageExtent(hImage);
    
    % setup boundary constraint functions
    boundary_constraint_fcn = makeConstrainToRectFcn('imrect',...
        x_extent,y_extent);
    
    % if our image is one pixel wide or tall, do not impose snap2pixel
    % constraint
    if isnan(x_scale_s2p) || isnan(y_scale_s2p)
        finalPos = boundary_constraint_fcn(initialPos);
    else
        % get corner points in pixel coordinates
        p1_spatial_pos = initialPos(1:2) - [x_data(1) y_data(1)];
        p2_spatial_pos = p1_spatial_pos + initialPos(3:4);
        
        % scale to image units
        p1_pixel_pos = p1_spatial_pos .* scale_s2p;
        p2_pixel_pos = p2_spatial_pos .* scale_s2p;
        
        p1_pixel_pos = round(p1_pixel_pos + 0.5) - 0.5;
        p2_pixel_pos = round(p2_pixel_pos + 0.5) - 0.5;
        
        % scale back to spatial units
        p1_spatial_pos = p1_pixel_pos ./ scale_s2p;
        p2_spatial_pos = p2_pixel_pos ./ scale_s2p;
        
        % translate back to spatial origin
        p1_spatial_pos = p1_spatial_pos + [x_data(1) y_data(1)];
        p2_spatial_pos = p2_spatial_pos + [x_data(1) y_data(1)];
        
        % find new rect
        spatial_pos = p1_spatial_pos;
        spatial_size = [p2_spatial_pos(1) - p1_spatial_pos(1) ...
            p2_spatial_pos(2) - p1_spatial_pos(2)];
        
        % refresh cached constrained position.  this is a workaround for an
        % issue where multiple constraint functions are acting on an ROI.
        % the cached position in the boundary constraint function's
        % workspace needs to be kept up to date with what the other
        % constraint functions have done.
        finalPos = boundary_constraint_fcn([spatial_pos spatial_size]);
    end
            
end


%--------------------------------------------------------------------------

function initial_position = drawImrectAffordance(h_ax,init_x,init_y,...
    constraint_fcn)

h_fig = ancestor(h_ax,'figure');

% In the future, we should move lineSymbol into +iptui. For now, use
% imuitoolsgate because lineSymbol has a lot of dependencies on
% imuitools/private.
warnstate = warning('off','images:imuitoolsgate:undocumentedFunction');
rectSymbol = imuitoolsgate('FunctionHandle','wingedRect');
warning(warnstate);

h_group_temp = hggroup('Parent',h_ax);

% The rectSymbol renderer wants to know about translateFcn,resizeFcn, and
% cornerResizeFcn to wire ButtonDownFcn for each HG object managed by the
% renderer. The lifecycle of the imrectButtonDown object is only for
% one buttonDown/buttonUp sequence during interactive placement in imtool,
% so we just specify no-op function handles to rectSymbol. These function
% handles will never actually be called.
draw_rect_api = rectSymbol();
draw_rect_api.initialize(h_group_temp,'','','');

color_choices = iptui.getColorChoices();
draw_rect_api.setColor(color_choices(1).Color);

drag_id = iptaddcallback(h_fig,'WindowButtonMotionFcn',@drawRect);
stop_id = iptaddcallback(h_fig,'WindowButtonUpFcn',@stopDraw);

uiwait(h_fig);
delete(h_group_temp);

%--------------------------------------------------------------------------
    function drawRect(varargin)
        
        % wrap in try/catch to avoid rapid image changes causing errors
        % due to no longer valid handles
        try
            % We only need to setVisible the first time through drawLine, but
            % this won't cause a noticeable performance difference. Calling
            % setVisible any earlier causes a flicker.
            draw_rect_api.setVisible(true);
            
            pos = getCurrentPosition();
            pos = constraint_fcn(pos);
            
            draw_rect_api.updateView(pos);
        catch
            % skip
        end
    end

%----------------------------------------------------------------------
    function stopDraw(varargin)

        % wrap in try/catch to avoid rapid image changes causing errors
        % due to no longer valid handles
        try
            pos = getCurrentPosition();
            pos = constraint_fcn(pos);
            
            draw_rect_api.updateView(pos);
            
            initial_position = pos;
            
            iptremovecallback(h_fig,'WindowButtonMotionFcn',drag_id);
            iptremovecallback(h_fig,'WindowButtonUpFcn',stop_id);
            uiresume(h_fig);
        catch
            % skip
        end
        
    end

%----------------------------------------------------------------------
    function pos = getCurrentPosition
        
        currentPoint = get(h_ax,'CurrentPoint');
        current_x = currentPoint(1,1);
        current_y = currentPoint(1,2);
        
        xmin = min(init_x,current_x);
        ymin = min(init_y,current_y);
        pos = [xmin ymin abs(init_x-current_x) abs(init_y-current_y)];
        
    end

end

