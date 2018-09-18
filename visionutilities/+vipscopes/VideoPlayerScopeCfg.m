classdef (Hidden) VideoPlayerScopeCfg < matlabshared.scopes.SystemObjectScopeSpecification & scopeextensions.MPlayScopeCfg
    %VideoPlayerScopeCfg   Define the VideoPlayerScopeCfg class.
    
    %   Copyright 2009-2011 The MathWorks, Inc.
    
    methods      
      function this = VideoPlayerScopeCfg(varargin)
         % Prevent clear classes warnings
         mlock;
         this@matlabshared.scopes.SystemObjectScopeSpecification(varargin{:});
      end
      
      function appName = getScopeTag(~)
        appName = 'Video Player';
      end
      
      function configurationFile = getConfigurationFile(~)
        configurationFile = 'videoplayer.cfg';
      end
      
      function hiddenExts = getHiddenExtensions(~)
        hiddenExts = {'Tools:Instrumentation Sets', 'Tools:Measurements', ...
          'Tools:Plot Navigation', 'Visuals:Time Domain'};
      end
      
      function b = needsMenuGroups(~)
          b = true;
      end
      
      function b = showPrintAction(~, ~)
          b = false;
      end
      
      function [mApp, mExample, mAbout] = createHelpMenuItems(~, mHelp)
        mapFileLocation = fullfile(docroot,'toolbox','vision','vision.map');
        
        mApp(1) = uimenu(mHelp, ...
          'Tag', 'uimgr.uimenu_vision.VideoPlayer', ...
          'Label', 'vision.VideoPlayer &Help', ...
          'Callback', @(hco,ev) helpview(mapFileLocation, 'scvideoplayer'));
        
        mApp(2) = uimenu(mHelp, ...
          'Tag', 'uimgr.uimenu_VIPBlks', ...
          'Label', '&Computer Vision System Toolbox Help', ...
          'Callback', @(hco,ev) helpview(mapFileLocation, 'visioninfo'));
        
        mExample = uimenu(mHelp, ...
          'Tag', 'uimgr.uimenu_VIPBlks Demos', ...
          'Label', 'Computer Vision System Toolbox &Examples', ...
          'Callback', @(hco,ev) visiondemos);
        
        % Want the "About" option separated, so we group everything above
        % into a menugroup and leave "About" as a singleton menu
        mAbout = uimenu(mHelp, ...
          'Tag', 'uimgr.uimenu_About', ...
          'Label', '&About Computer Vision System Toolbox', ...
          'Callback', @(hco,ev)aboutvipblks);
      end
      function b = shouldShowControls(this, id)
          if strcmp(id, 'Snapshot')
              % Default setting is to hide the snapshot action on the
              % system object scope.
              b = true;
          else
              b = shouldShowControls@matlabshared.scopes.SystemObjectScopeSpecification(this, id);
          end
      end
    end
    
    methods (Hidden)
        function b = useMCOSExtMgr(~)
            b = true;
        end
    end
end

% [EOF]
