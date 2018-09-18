function vipToVideoDisplayPanel(varargin)
% VIPTOVIDEODISPLAYPANEL Create a figure for the To Video Display block.

% Copyright 2008 The MathWorks, Inc.

method = varargin{1}; %blockActionName
blkh = varargin{2}; % gcbh
blk  = varargin{3}; % gcb

persistent Blkh_Array
persistent oldGCB_Array
if isempty(Blkh_Array) && strcmpi(method, 'blockLoading')
   Blkh_Array(1) = blkh;
   oldGCB_Array{1} = blk;
end

if strcmpi(method, 'blockLoading') || strcmpi(method, 'blockCopying')
    if isempty(find(Blkh_Array==blkh,1))
        Blkh_Array(end+1) = blkh;
        oldGCB_Array{end+1} = blk;
    end
end

if strcmpi(method, 'blockClosing')
    idx = find(Blkh_Array==blkh);
    if ~isempty(idx)
        Blkh_Array(idx) = -1;
        oldGCB_Array{idx} = '';
    end
end

if strcmpi(method, 'blockNameChange')      
    idx = find(Blkh_Array==blkh);
    if ~isempty(idx)
        oldBlk = oldGCB_Array{idx};    
        % update block name
        oldGCB_Array{idx} = blk;
        varargin{end+1} = oldBlk;
    end
end

% Get the handle of the function we are calling
switch method
    % blockClosing: called when block being deleted, or model closing
    case {'blockClosing', 'blockNameChange',...
          'blockCopying', 'blockLoading', 'blockSaving',...
          'blockOpening'}   
        
         BLOCKDisplayManager(varargin{:});
    otherwise
        error('unhandled case');
end

end

%% ========================================================================
function BLOCKDisplayManager(varargin)
persistent nInstances
if isempty(nInstances)
    nInstances = 0;
end

[CREATE_VIDEO_WINDOW,DESTROY_VIDEO_WINDOW,IS_PLAYER_OPEN, ...
    GET_WINDOW_POS_SIZE,RENAME_VIDEO_WINDOW] = deal(0,1,2,3,4); %#ok<ASGLU>
    
method = varargin{1};
id = varargin{3};% gcb

% Switch over the method
switch method
    case {'blockCopying', 'blockLoading'}
        
        %  lock the function so that "clear all" does not clear persistsent
        %  variables

        % No need to explicitly load the library.
        % First call to tvdhostlib uses loadLibrary to load tvdhostlib;
        nInstances = nInstances + 1;
        if nInstances == 1 
           mlock;
        end 
        
    case {'blockClosing'}
        if (nInstances>0)
            tvdmask2hostlib(DESTROY_VIDEO_WINDOW, id);
        end

        % No need to explicitly unload the library.
        % First call to tvdmask2hostlib uses loadLibrary to load tvdmask2hostlib;
        % and it uses atExit function, so that when we exit matlab or call
        % clear mex, Matlab autiomatically calls the atExit function
        % (atExit function uses unloadLibrary to unload tvdmask2hostlib library)

        % Unlock
        nInstances = nInstances - 1;
        if nInstances == 0
           munlock;
        end    

    case {'blockNameChange'}
        if nInstances > 0
            % Inform the library of the name change
            oldBlk = varargin{end};
            newBlk = id;
            % only get block name (discard path i.e. subsystem names from gcb)
            windowName = strrep(get_param(newBlk, 'Name'), char(10), ' ');
            tvdmask2hostlib(RENAME_VIDEO_WINDOW, oldBlk, newBlk, windowName);
        end

    case {'blockSaving'}
        % Save the position just before saving
        if nInstances > 0
            [xy, wh] = tvdmask2hostlib(GET_WINDOW_POS_SIZE, id);
            curPosition = [xy wh];
 
            % tovideodevice library returns int32([-2 -2 -2 -2]) when
            % window does not exist        
            if ~(isequal(curPosition, int32([-2 -2 -2 -2])))
                % In headless display mode, width or height may become
                % negative. Avoid saving negative values.
                if ((curPosition(3)>=0) && (curPosition(4)>=0))
                    set_param(id, 'videoWindowX',      sprintf('%d', curPosition(1)));
                    set_param(id, 'videoWindowY',      sprintf('%d', curPosition(2)));
                    set_param(id, 'videoWindowWidth',  sprintf('%d', curPosition(3)));
                    set_param(id, 'videoWindowHeight', sprintf('%d', curPosition(4)));
                end
            end
        end
    case {'blockOpening'} % double clicked on block
        % block must be loaded before reaching this section

        % no need to check if the window is already open; createVideoWindow
        % will check that
        if (nInstances > 0)
            tmpPosition = [0 0 0 0];
            tmpPosition(1) = str2double(get_param(id, 'videoWindowX'));
            tmpPosition(2) = str2double(get_param(id, 'videoWindowY'));
            tmpPosition(3) = str2double(get_param(id, 'videoWindowWidth'));
            tmpPosition(4) = str2double(get_param(id, 'videoWindowHeight'));
    
            % Inform the library of the name change
            winXY = int32([tmpPosition(1) tmpPosition(2)]);
            windowWH = int32([tmpPosition(3) tmpPosition(4)]);
            %isFullScreen = strcmp(get_param(id, 'fullScreen'), 'on');
            %setSize = strcmp(get_param(id, 'saveWindowSize'), 'on');
            winMode = get_param(id, 'windowSizeMode');
            isFullScreen = strcmp(winMode, 'Full-screen (Esc to exit)');
            setSize      = strcmp(winMode, 'Normal');
            %id = gcb;
            openDialogOrScope(CREATE_VIDEO_WINDOW, ...
                id, isFullScreen, winXY, windowWH, setSize);    
        end   
    otherwise
        error(message('vision:vipToVideoDisplayPanel:invalidMethod'));
end
end



% ---------------------------------------------------------------
function openDialogWhileRunning(blk)

 open_system(blk, 'mask');
end

% ---------------------------------------------------------------
function openScopeWhileRunning(CREATE_VIDEO_WINDOW, ...
                           id, isFullScreen, winXY, windowWH, setSize)
 % id = gcb
 isFullScreen_ = uint8(isFullScreen);
 winXY_        = int32(winXY);
 windowWH_     = int32(windowWH);
 setSize_      = uint8(setSize);
 
 tvdmask2hostlib(CREATE_VIDEO_WINDOW, id, isFullScreen_, winXY_, windowWH_, setSize_);
end

% ---------------------------------------------------------------
function openDialogOrScope(CREATE_VIDEO_WINDOW, ...
                           id, isFullScreen, winXY, windowWH, setSize)
    % id = gcb
    status    =  get_param(bdroot(id),'simulationstatus');
    isRunning = strcmp(status,'running') || strcmp(status,'initializing') ...
        || strcmp(status,'updating'); % do not include 'paused'
    % During pause state, if the window is closed, if we create a new
    % window that will be black; so at paused state, we bring up the mask
    isExternal = strcmp(status,'external');

    % Need to open/re-open scope:
    if isRunning,
        openScopeWhileRunning(CREATE_VIDEO_WINDOW, ...
                           id, isFullScreen, winXY, windowWH, setSize);
    elseif isExternal
        % External or Rapid-accelerator sim modes
        openScopeWhileRunning(CREATE_VIDEO_WINDOW, ...
                           id, isFullScreen, winXY, windowWH, setSize);
    else
        openDialogWhileRunning(id);
    end
end

