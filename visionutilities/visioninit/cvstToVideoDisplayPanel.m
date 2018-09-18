function flag = cvstToVideoDisplayPanel(varargin)
% CVSTTOVIDEODISPLAYPANEL Create a figure for vision.DeployableVideoPlayer.

% Copyright 2008 The MathWorks, Inc.

method = varargin{1};

% Get the handle of the function we are calling
switch method
    case {'objectDeleting','objectLoading', 'objectPlayerOpen'}
        
        flag = SCOMPDisplayManager(varargin{:});
    otherwise
        error('unhandled case');
end

end

%% ========================================================================
function flag = SCOMPDisplayManager(varargin)
persistent nInstances
if isempty(nInstances)
    nInstances = 0;
end

[CREATE_VIDEO_WINDOW,DESTROY_VIDEO_WINDOW,IS_PLAYER_OPEN, ...
    GET_WINDOW_POS_SIZE,RENAME_VIDEO_WINDOW] = deal(0,1,2,3,4); %#ok<ASGLU>

flag = false;
method = varargin{1};

switch method
    case 'objectLoading' 
        %  lock the function so that "clear all" does not clear persistsent
        %  variables

        % No need to explicitly load the library.
        % First call to tvdhostlib uses loadLibrary to load tvdhostlib;
        nInstances = nInstances + 1;
        if nInstances == 1 
           mlock;
        end 
        
    case 'objectDeleting' % called by vision.DeployableVideoPlayer delete method
        id = varargin{2};
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
        
    case 'objectPlayerOpen' % called by vision.DeployableVideoPlayer delete method
        id = varargin{2};
        if (nInstances>0)
            flag(:) = tvdmask2hostlib(IS_PLAYER_OPEN, id); 
        end
end

end
