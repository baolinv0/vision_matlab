% Adds 3d scene control to figure for point cloud viewing.
function initializePCSceneControl(hFigure, currentAxes, vertAxis, vertAxisDir, ptCloudThreshold, varargin)

% Equal axis is required for cameratoolbar
if numel(varargin) > 0 && varargin{1}
    axis(currentAxes, 'equal');
end

vision.internal.pc.initializeVerticalAxis(currentAxes, vertAxis, vertAxisDir);
resetplotview(currentAxes,'SaveCurrentView');

% Initialize interation mode before setting callbacks.
initUIMode(hFigure);

% Register callbacks. Left click rotate, wheel zoom.
registerCallbacks(hFigure,vertAxis,vertAxisDir,ptCloudThreshold);

% Initialize user data
initUserData(hFigure,currentAxes,ptCloudThreshold);

% Switch to Camera pan/zoom mode
enableCameraPanZoomMode(currentAxes);

end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Register Callbacks
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function registerCallbacks(hFigure,vertAxis,vertAxisDir,ptCloudThreshold)
% Replace rotate3d's callback;
currentAxes = get(hFigure,'CurrentAxes');

% Enable rotate3d so we can get the registered mode.
rotate3d(currentAxes,'on');
hui = getuimode(hFigure,'Exploration.Rotate3d');

set(hui,'WindowButtonDownFcn',{@localBtnDown,hFigure,vertAxis,vertAxisDir});
set(hui,'WindowScrollWheelFcn',{@localScrollWheel,hFigure});
set(hui,'WindowButtonMotionFcn',@localPointerChange);
% Do not do anything extra than (un)click buttons/menu entries.
% This can preserve the context menu.
set(hui,'ModeStartFcn',{@localRotateStartMode,hFigure});
set(hui,'ModeStopFcn',{@localRotateStopMode,hFigure});

% Do not allow keyboard interaction
set(hui,'KeyReleaseFcn','');
set(hui,'KeyPressFcn','');

% Add context menu items
initContextMenu(hFigure, hui,vertAxis, vertAxisDir);

udata = getUData(hFigure);
if ~isfield(udata,'pcCallbackRegistered') || isempty(udata.pcCallbackRegistered)
    % If there is no userdata, register listeners
    addlistener(hFigure,'WindowMousePress',@(o,e)localDownsample(o,e,ptCloudThreshold));
    addlistener(hFigure,'WindowMouseRelease',@(o,e)resetWindowMotion(o,e));  
end

udata.pcCallbackRegistered = true;
setUData(hFigure,udata);
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Rotate mode starts, click the button
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function localRotateStartMode(hFigure)
localToggleRotateState(hFigure,'on');
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Rotate mode stop
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function localRotateStopMode(hFigure)
localToggleRotateState(hFigure,'off');

end

function localToggleRotateState(hFigure,state)
% pop back the button, uncheck the menu entry
btn = findall(hFigure,'tag','Exploration.Rotate');
if ~isempty(btn)
    btn.State = state;
end

rmenu = findall(hFigure,'tag','figMenuRotate3D');
if ~isempty(rmenu)
    rmenu.Checked = state;
end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Change the pointer when over an axes.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function localPointerChange(obj,~)
% Change the icon to indicate the rotation
if strcmpi(obj.Pointer,'custom');
    %We already have custom icon
    return;
end
SetData = setptr('rotate');
set(obj, SetData{:});
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Initialize User Data
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function initUserData(hFigure,currentAxes,ptCloudThreshold)
udata = getUData(currentAxes);
% Do not show rotation axis by default
if isfield(udata,'pcShowRAxis') && udata.pcShowRAxis
    % Remove Rotation Axis if it exists
    removeRAxis(currentAxes);
end
udata.pcShowRAxis = false;

% Do not downsample by default
udata.pcNeedsDownsample = false;
% Flush out caches
udata.pcCacheScatter = {};
udata.pcCachePlot3 = {};
udata.pcCacheScatterCdata = {};
udata.pcCachePlot3Cdata = {};

udata.pcshowMouseData = [];
setUData(currentAxes,udata);

% Determine if current axes needs downsample
localSetDownsample(hFigure,currentAxes,ptCloudThreshold);

end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Initialize Interaction UI mode
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function initUIMode(hFigure)
% Reset zoom and pan, enable rotation mode
zoom(hFigure,'off');
pan(hFigure,'off');
rotate3d(hFigure,'on');
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Initialize right click context menu
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function initContextMenu(hFigure, huimode,vertAxis, vertAxisDir)

if isempty(findall(hFigure,'tag','contextPCDownsample'))
    props_context.Parent = hFigure;
    props_context.Tag = 'PCRotateContextMenu';
    huimode.UIContextMenu = uicontextmenu(props_context);
    hui = huimode.UIContextMenu;
    
    % Generic attributes for all rotate context menus
    % Full View context menu
    props = [];
    props.Label = getString(message('MATLAB:uistring:pan:ResetToOriginalView'));
    props.Tag = 'ResetView';
    props.Separator = 'off';
    props.Callback = {@localResetView,hFigure};
    ufullview = uimenu(hui,props); %#ok
    
    % Down sample flag
    props = [];
    props.Label = getString(message('vision:pointcloud:localDownSample'));
    props.Tag = 'contextPCDownsample';
    props.Visible = 'off';
    props.Separator = 'off';
    props.Callback = {@toggleDsampleBtn,hFigure};
    udsample = uimenu(hui,props); %#ok
    
    % Show Rotation Axis
    props = [];
    props.Label = getString(message('vision:pointcloud:localRotationAxis'));
    props.Tag = 'contextPCShowRotationAxis';
    props.Separator = 'off';
    props.Callback = {@toggleRAxisBtn,hFigure,vertAxis,vertAxisDir};
    uraxis = uimenu(hui,props); %#ok
else
    % Reset to default state
    ufullview = findall(hFigure,'tag','ResetView');
    ufullview.Checked = 'off';
    udsample = findall(hFigure,'tag','contextPCDownsample');
    udsample.Checked = 'off';
    uraxis = findall(hFigure,'tag','contextPCShowRotationAxis');
    uraxis.Checked = 'off';
end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Register button callbacks
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function localBtnDown(src,~,hFigure,vertAxis,vertAxisDir)
switch src.SelectionType
    case 'normal'
        src.WindowButtonMotionFcn = {@localRotate,hFigure,vertAxis,vertAxisDir};
end

end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Rotation callback
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function localRotate(src,~,hFigure,vertAxis,vertDir)

currentAxes = hFigure.CurrentAxes;
udata = getUData(currentAxes);
if ~isfield(udata,'pcshowMouseData')
    return;
end

if isempty(udata.pcshowMouseData)
    udata.pcshowMouseData = hFigure.CurrentPoint;
    setUData(currentAxes,udata);
end
% Previous mouse position
hData = udata.pcshowMouseData;

% Grab current mouse point in pixels
pt = hgconvertunits(src,[0 0 src.CurrentPoint],...
    src.Units,'pixels',src.Parent);
pt = pt(3:4);

% Change in mouse position
deltaPix  = -(pt-hData);

% Update mouse position
udata.pcshowMouseData = pt;
setUData(currentAxes,udata);

% Rotation center set to axes center
Xc = (currentAxes.XLim(2)+currentAxes.XLim(1))/2;
Yc = (currentAxes.YLim(2)+currentAxes.YLim(1))/2;
Zc = (currentAxes.ZLim(2)+currentAxes.ZLim(1))/2;
rotCenter = [Xc,Yc,Zc];
showRAxis = udata.pcShowRAxis;
vision.internal.pc.rotateAxes(currentAxes,deltaPix(1),deltaPix(2),rotCenter,vertAxis,vertDir,showRAxis);
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Scroll wheel zoom callback
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function localScrollWheel(~,evt,hFigure)
currentAxes = get(hFigure,'CurrentAxes');
zoomlevel = 0.9;
if evt.VerticalScrollCount < 0
    camzoom(currentAxes,1/zoomlevel);
elseif evt.VerticalScrollCount > 0
    camzoom(currentAxes,zoomlevel);
end
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Unset mouse motion callback
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function resetWindowMotion(src,~)
if localSupportedMode(src)    
    currentAxes = get(src,'CurrentAxes');
    src.WindowButtonMotionFcn = '';
    udata = getUData(currentAxes);
    sobj = localFindScatterData(currentAxes);
    pobj = localFindPlot3Data(currentAxes);
    if isempty(sobj) && isempty(pobj)
        return
    end
    % Restore axis limit mode 
    currentAxes.XLimMode = udata.XLimMode;
    currentAxes.YLimMode = udata.YLimMode;
    currentAxes.ZLimMode = udata.ZLimMode;

    udata.pcshowMouseData = [];
    needsDownsample = udata.pcNeedsDownsample;
    setUData(currentAxes, udata);
    if needsDownsample
        % Restore all Scatter3 Object
        pcCacheScatter = udata.pcCacheScatter;
        for i = 1:numel(pcCacheScatter)
            cdata = udata.pcCacheScatterCdata{i};
            sobj(i).XData = pcCacheScatter{i}.Location(:,1)';
            sobj(i).YData = pcCacheScatter{i}.Location(:,2)';
            sobj(i).ZData = pcCacheScatter{i}.Location(:,3)';
            sobj(i).CData = cdata;
        end
        % Restore all Plot3 Object
        pcCachePlot3 = udata.pcCachePlot3;
        for i = 1:numel(pcCachePlot3)
            cdata = udata.pcCachePlot3Cdata{i};
            pobj(i).XData = pcCachePlot3{i}.Location(:,1)';
            pobj(i).YData = pcCachePlot3{i}.Location(:,2)';
            pobj(i).ZData = pcCachePlot3{i}.Location(:,3)';
            pobj(i).Color = cdata;
        end
    end
end
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Find all point cloud object in an axes
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function sobj = localFindScatterData(ax)
% Finds all scatter3 data object in ax.
sobj = findobj(ax,'type','scatter');
end
function pobj = localFindPlot3Data(ax)
% Finds all plot3 data object in ax.
pobj = findobj(ax,'type','line','Marker','.');
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Cache current Point Cloud data for downsampling
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function cachePCdata(currentAxes)
udata = getUData(currentAxes);
sobj = localFindScatterData(currentAxes);
pobj = localFindPlot3Data(currentAxes);

udata.pcCacheScatter = {};
udata.pcCachePlot3 = {};
udata.pcCacheScatterCdata = {};
udata.pcCachePlot3Cdata = {};

for i = 1:numel(sobj)
    ptcloud = pointCloud([sobj(i).XData',sobj(i).YData',sobj(i).ZData']);
    udata.pcCacheScatter{i} = ptcloud;
    udata.pcCacheScatterCdata{i} = sobj(i).CData;
end

for i = 1:numel(pobj)
    ptcloud = pointCloud([pobj(i).XData',pobj(i).YData',pobj(i).ZData']);
    udata.pcCachePlot3{i} = ptcloud;
    udata.pcCachePlot3Cdata{i} = pobj(i).Color;
end

setUData(currentAxes,udata);

end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Determine if current axes needs downsample
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function localSetDownsample(hFigure,currentAxes,ptCloudThreshold)
% Find all scatter3 and plot3 children
sobj = localFindScatterData(currentAxes);
pobj = localFindPlot3Data(currentAxes);

% Adaptive Downsample:
needsDownsample = false;
numDataScatter  = 0;
numDataPlot3= 0;
if ~isempty(sobj)
    numDataScatter = numel([sobj.XData]);
end
if ~isempty(pobj)
    numDataPlot3 = numel([pobj.XData]);
end

numData = numDataScatter + numDataPlot3;

if numData > ptCloudThreshold(1) && numData < ptCloudThreshold(2)
    needsDownsample = true;
    cachePCdata(currentAxes);
    btn = findobj(hFigure,'tag','contextPCDownsample');
    if ~strncmpi(btn,'on',2);
        toggleDsampleBtn(btn,false,hFigure);
    end
end
udata = getUData(currentAxes);
udata.pcNeedsDownsample = needsDownsample;
setUData(currentAxes,udata);
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Decide if we are in rotate/pan/zoom mode
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function supported = localSupportedMode(hFigure)
hManager = uigetmodemanager(hFigure);

supported = strcmpi(hFigure.SelectionType,'normal') && ~isempty(hManager.CurrentMode) ...
    && ismember(hManager.CurrentMode.Name,...
    {'Exploration.Rotate3d','Exploration.Pan','Exploration.Zoom'});
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Perform downsampling in current Axes
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function localDownsample(hFigure,~,ptCloudThreshold)

if localSupportedMode(hFigure)
    
    currentAxes = get(hFigure,'CurrentAxes');    
    
    sobj = localFindScatterData(currentAxes);
    pobj = localFindPlot3Data(currentAxes);
    
    if isempty(sobj) && isempty(pobj)
        % no  point cloud data available
        return;
    end
    
    % Determine if current axes needs downsample
    localSetDownsample(hFigure,currentAxes,ptCloudThreshold);

    % Perform downsample on all scatter3 and plot3 objects
    udata = getUData(currentAxes);
    
    % Set the axis limit to manual to prevent auto-snapping
    udata.XLimMode = currentAxes.XLimMode;
    udata.YLimMode = currentAxes.YLimMode;
    udata.ZLimMode = currentAxes.ZLimMode;
    setUData(currentAxes,udata);
    udata.XLimMode = 'manual';
    udata.YLimMode = 'manual';
    udata.ZLimMode = 'manual';
    
    needsDownsample = udata.pcNeedsDownsample;
    
    % Handle datacursormode
    dcm_obj = datacursormode(hFigure);
    cInfo = getCursorInfo(dcm_obj);
    % We do not downsample when there are datatips. The datatip relies on
    % the linear index of its underlying data, this will change when we
    % downsample the points. 
    
    hasDatatip = ~isempty(cInfo);
    
    % only needs to check isempty(pccache)
    if ~isempty(needsDownsample) &&  needsDownsample ...
        && ~hasDatatip 
        % Cache current axes
        cachePCdata(currentAxes);
        udata = getUData(currentAxes);

        % Downsample all scatter3 objects
        ptclouds = udata.pcCacheScatter;
        for i = 1:numel(ptclouds)
            ptcloud =  ptclouds{i};
            K = min(round(ptcloud.Count*0.5),ptCloudThreshold(1));
            indices = vision.internal.samplingWithoutReplacement(ptcloud.Count, K);
            if max(indices(:)) > numel(sobj(i).XData)
                % Renderer is not ready yet.
                continue;
            end
            sobj(i).XData = sobj(i).XData(indices);
            sobj(i).YData = sobj(i).YData(indices);
            sobj(i).ZData = sobj(i).ZData(indices);
            if numel(sobj(i).CData) > 3
                sobj(i).CData = sobj(i).CData(indices,:);
            end            
        end
        
        % Downsample all plot3 objects
        ptclouds = udata.pcCachePlot3;
        for i = 1:numel(ptclouds)
            ptcloud =  ptclouds{i};
            K = min(round(ptcloud.Count*0.5),ptCloudThreshold(1));
            indices = vision.internal.samplingWithoutReplacement(ptcloud.Count, K);
            if max(indices(:)) > numel(pobj(i).XData)
                % Renderer is not ready yet.
                continue;
            end

            pobj(i).XData = pobj(i).XData(indices);
            pobj(i).YData = pobj(i).YData(indices);
            pobj(i).ZData = pobj(i).ZData(indices);
            if numel(pobj(i).Color) > 3
                pobj(i).Color = pobj(i).Color(indices,:);
            end
        end
        
    end
    
end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Callback for toggling downsample option
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function localToggleDownsample(currentAxes,state)
needsDownsample = strncmpi(state,'on',2);
if ~needsDownsample
    % Flush out old cache
    udata = getUData(currentAxes);
    udata.pcCacheScatter = {};
    udata.pcCachePlot3 = {};
    udata.pcCacheScatterCdata = {};
    udata.pcCachePlot3Cdata = {};
    setUData(currentAxes,udata);
else
    cachePCdata(currentAxes)
end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Toggles Downsample option in context menu and figure menu
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function toggleDsampleBtn(src,~,hFigure)
currentAxes = get(hFigure,'CurrentAxes');

% Clicked from context menu, toggle downsample on current axes
% Toggle flag
udata = getUData(currentAxes);
udata.pcNeedsDownsample = ~udata.pcNeedsDownsample;
setUData(currentAxes,udata);

% Set context menu
state = convertButtonState(udata.pcNeedsDownsample);
contextBtn = src;
contextBtn.Checked = state;

% Toggle Downsample on Current Axes
localToggleDownsample(currentAxes,state);

end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Reset to default view callback
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function localResetView(~,~,hFigure)
currentAxes = get(hFigure,'CurrentAxes');
resetplotview(currentAxes,'ApplyStoredView');
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Remove rotation axis from axes
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function removeRAxis(currentAxes)
hline1 = findobj(currentAxes,'tag','pcViewerRAxis1');
hline2 = findobj(currentAxes,'tag','pcViewerRAxis2');
hline3 = findobj(currentAxes,'tag','pcViewerRAxis3');
if ~isempty(hline1)
    delete(hline1);
end
if ~isempty(hline2)
    delete(hline2);
end
if ~isempty(hline3)
    delete(hline3);
end
end


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Show/Hide rotation axis in current Axes
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function localToggleRAxis (currentAxes, vertAxis, vertAxisDir,state)
showRAxis = strncmpi(state,'on',2);
if ~showRAxis
    removeRAxis(currentAxes);
else
    Xc = mean(currentAxes.XLim);
    Yc = mean(currentAxes.YLim);
    Zc = mean(currentAxes.ZLim);
    origPoint = [Xc,Yc,Zc];
    
    currentPose = get(currentAxes,'cameraposition');
    up = get(currentAxes,'cameraupvector');
    
    vaxis = origPoint - currentPose;
    coordsysval = lower(vertAxis) - 'x' + 1;
    
    raxis = [0 0 0];
    if strcmpi(vertAxisDir,'down')
        raxis(coordsysval) = -1;
    else
        raxis(coordsysval) = 1;
    end
    XSpan = currentAxes.XLim(2)-currentAxes.XLim(1);
    YSpan = currentAxes.YLim(2)-currentAxes.YLim(1);
    ZSpan = currentAxes.ZLim(2)-currentAxes.ZLim(1);
    
    minSpan = min([XSpan,YSpan,ZSpan]);
    
    vlength = minSpan*0.2;
    raxis1 = raxis*vlength;
    raxis2 = cross(vaxis,raxis);
    raxis2 = raxis2/norm(raxis2)*vlength;
    upsidedown = (up(coordsysval) < 0);
    if upsidedown
        raxis2 = -raxis2;
    end
    raxis3 = crossSimple(raxis1,raxis2);
    raxis3 = raxis3/norm(raxis3)*vlength;
    
    hold(currentAxes,'on');
    line([origPoint(1),origPoint(1)+raxis1(1)],...
        [origPoint(2),origPoint(2)+raxis1(2)],...
        [origPoint(3),origPoint(3)+raxis1(3)],...
        'tag','pcViewerRAxis1','Parent',currentAxes);
    line([origPoint(1),origPoint(1)+raxis2(1)],...
        [origPoint(2),origPoint(2)+raxis2(2)],...
        [origPoint(3),origPoint(3)+raxis2(3)],...
        'color','red','tag','pcViewerRAxis2','Parent',currentAxes);
    line([origPoint(1),origPoint(1)+raxis3(1)],...
        [origPoint(2),origPoint(2)+raxis3(2)],...
        [origPoint(3),origPoint(3)+raxis3(3)],...
        'color','green','tag','pcViewerRAxis3','Parent',currentAxes);
    hold(currentAxes,'off');
end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Convert t/f to 'on'/'off'
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function state = convertButtonState(tf)
if tf
    state = 'on';
else
    state = 'off';
end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Toggles Show Rotation Axis option in context menu and figure menu
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function toggleRAxisBtn(~,~,hFigure,vertAxis,vertAxisDir)
currentAxes = get(hFigure,'CurrentAxes');
% Clicked from context menu, show/hide RAxis on current axes

% Toggle flag
udata = getUData(currentAxes);
udata.pcShowRAxis = ~udata.pcShowRAxis;
setUData(currentAxes,udata);

% Set context menu
state = convertButtonState(udata.pcShowRAxis);

% Draw/Delete Rotation Axis
localToggleRAxis(currentAxes,vertAxis,vertAxisDir,state);

end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Get/Set User Data
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function hData = getUData(hgHandle)
hData = getappdata(hgHandle,'PCUserData');
end
function setUData(hgHandle, data)
setappdata(hgHandle,'PCUserData',data);
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% simple cross product
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function c=crossSimple(a,b)
c(1) = b(3)*a(2) - b(2)*a(3);
c(2) = b(1)*a(3) - b(3)*a(1);
c(3) = b(2)*a(1) - b(1)*a(2);
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Limit Pan/Zoom mode is not suitable for Point Cloud application
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function enableCameraPanZoomMode(currentAxes)
z = zoom(currentAxes);
z.setAxes3DPanAndZoomStyle(currentAxes,'camera');
end