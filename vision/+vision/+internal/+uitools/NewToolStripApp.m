% NewToolStripApp the base class for the toolstrip-based apps
%
%  This is a base class for toolstrip apps using the new Toolstrip MCOS
%  API. It contains the toolgroup object and the session information.
%
%  NewToolStripApp properties:
%    ToolGroup      - the matlab.ui.internal.desktop.ToolGroup object
%    TabGroup       - the matlab.ui.internal.Toolstrip.TabGroup object
%    Session        - the session object, containing the App's data
%    SessionManager - the object that should handle session loading/saving
%
%  NewToolStripApp methods:
%    removeViewTab - remove the View tab, which is enabled by default
%    addFigure     - add a figure to the app (protected)
%    getGroupName  - return group name
%    getToolGroup  - return toolgroup
%    getTabGroup   - return main TabGroup
%    hideTab       - make tab invisible
%    showTab       - make tab visible
%    removeViewTab - remove default view tab
%    addFigure     - add figure and unregister drag-drop
%    removeQuickAccess      - remove quick access bar
%    removeDocumentTabs     - remove document bar
%    askForSavingOfSession  - popup save session dialog
%    configureQuickAccessBarHelpButton - specify callback for QAB help

%
%   Notes
%   -----
%   Note that this infrastructure is currently set up to only allow
%   Toolstrip apps that use a single tab group, i.e. contextual tab groups
%   aren't supported. Contextual tabs are supported, just not contextual
%   tab groups.

% Copyright 2016 The MathWorks, Inc.

classdef NewToolStripApp < handle
    properties(Access = protected)
        % ToolGroup the matlab.ui.internal.desktop.ToolGroup object.
        %  This object must be instantiated in the derived class 
        ToolGroup;
        
        % TabGroup the matlab.ui.internal.toolstrip.TabGroup object. 
        %  This object must be instantiated in the derived class
        TabGroup;
        
        % SessionManager object that handles saving/loading of the session
        %  This object must be instantiated in the derived class
        SessionManager;
    end
    
    properties(Hidden,GetAccess=public,SetAccess = protected)
        % Session the object containing the App's data
        %  This object must be instantiated in the derived class
        Session         
        
    end
    
    methods(Abstract, Access = protected)
        %------------------------------------------------------------------ 
        % closeAllFigures Abstract method for removing all app figures. App
        % authors must implement this function. Its role is to delete all
        % app managed figures.
        %------------------------------------------------------------------
        closeAllFigures(this);        
    end
    
    methods
        %------------------------------------------------------------------  
        % Common delete method for tool strip based apps. This
        % implementation handles the work required for most apps. Namely,
        % deleting the main ToolGroup and all the figures associated with
        % the app.
        % -----------------------------------------------------------------
        function delete(this)
            
            this.ToolGroup.close(); % close the UI            
            this.closeAllFigures(); % shut down all figures  
            
            drawnow();  % allow time for closing of all figures
        end
        
        %------------------------------------------------------------------
        % Return the name of the ToolGroup. This is a convenience function
        % use in apps to when invoking some of the tool strip APIs.
        %------------------------------------------------------------------
        function name = getGroupName(this)
            name = this.ToolGroup.Name;
        end
        
        %------------------------------------------------------------------
        % Return the ToolGroup object. This is a convenience function for
        % use in apps.
        %------------------------------------------------------------------
        function toolGroup = getToolGroup(this)
            toolGroup = this.ToolGroup;
        end
        
        %------------------------------------------------------------------
        % Return the TabGroup object. This is a convenience function for
        % use in apps.
        %------------------------------------------------------------------
        function tabGroup = getTabGroup(this)
            tabGroup = this.TabGroup;
        end
        
        %------------------------------------------------------------------
        % For contextual tab support. Makes tab invisible.
        %------------------------------------------------------------------
        function hideTab(this, tab)
            this.TabGroup.remove(getToolTab(tab));
        end
        
        %------------------------------------------------------------------
        % For contextual tab support. Makes tab visible.
        %------------------------------------------------------------------
        function showTab(this, tab)
            
            this.TabGroup.add(getToolTab(tab));
        end
        
        %------------------------------------------------------------------
        % Remove the view tab. Removes the view tab from the app. If you do
        % not call this method, the view tab will be on by default. 
        %------------------------------------------------------------------
        function removeViewTab(this)
            
            this.ToolGroup.hideViewTab();
        end
        
        %------------------------------------------------------------------
        % Remove the Quick Access toolbar. Removes the Quick Access toolbar
        % from the app. If you do not call this method, the Quick Access
        % toolbar will be on by default.
        %------------------------------------------------------------------
        function removeQuickAccess(this)
            
            filter = com.mathworks.toolbox.images.QuickAccessFilter.getFilter();
            group = this.ToolGroup.Peer.getWrappedComponent;
            group.putGroupProperty(...
                com.mathworks.widgets.desk.DTGroupProperty.QUICK_ACCESS_TOOL_BAR_FILTER,...
                filter);
        end
        
        %------------------------------------------------------------------
        % Remove Document Bar. Removes the document bar above the document.
        % If you do not call this method, the Document bar is visible by
        % default.
        %------------------------------------------------------------------
        function removeDocumentTabs(this)

            group = this.ToolGroup.Peer.getWrappedComponent;

            % Leave only a single document window without a tab and other
            % decorations
            group.putGroupProperty(com.mathworks.widgets.desk.DTGroupProperty.SHOW_SINGLE_ENTRY_DOCUMENT_BAR, false);
            % the line below cleans up the title of the app once there is only a single document in place            
            group.putGroupProperty(com.mathworks.widgets.desk.DTGroupProperty.APPEND_DOCUMENT_TITLE, false);
        end
       
        %------------------------------------------------------------------
        % Attach help call back to quick access bar help button. Note
        % you must call call this method before calling open(ToolGroup) in
        % your app.
        %------------------------------------------------------------------
        function configureQuickAccessBarHelpButton(this, helpCallback)
            
            this.ToolGroup.setContextualHelpCallback(helpCallback);
        end
        
        %------------------------------------------------------------------
        % Set Status bar text. Set the Status bar text (bottom bar).
        %------------------------------------------------------------------
        function setStatusText(this, text)
            
            % Get the JAVA Frame hosting the toolgroup.
            md = com.mathworks.mlservices.MatlabDesktopServices.getDesktop;
            fr = md.getFrameContainingGroup(this.ToolGroup.Name);
            
            if ~isempty(fr)
                javaMethodEDT('setStatusText', fr, text);
            end
        end
    end
        
    methods
        %------------------------------------------------------------------
        % Add a figure to the app and disable drag-and-drop into it.
        %------------------------------------------------------------------
        function addFigure(this, fig)
            
            this.ToolGroup.addFigure(fig);
            
            this.ToolGroup.getFiguresDropTargetHandler().unregisterInterest(...
               fig);
        end
               
    end
    
    methods(Static, Access = protected)
        %------------------------------------------------------------------
        % Pops up dialog asking if session should be saved. Returns the
        % dialog selection: yes, no, or cancel. Should be called during
        % when closing a session or creating a new session when a session
        % already open.
        %------------------------------------------------------------------
        function selection = askForSavingOfSession(~)
            
            yes    = vision.getMessage('MATLAB:uistring:popupdialogs:Yes');
            no     = vision.getMessage('MATLAB:uistring:popupdialogs:No');
            cancel = vision.getMessage('MATLAB:uistring:popupdialogs:Cancel');
            
            selection = questdlg(vision.getMessage...
                ('vision:uitools:SaveSessionQuestion'), ...
                vision.getMessage('vision:uitools:SaveSessionTitle'), ...
                yes, no, cancel, yes);
            
            if isempty(selection) % dialog was destroyed with a click
                selection = cancel;
            end
        end
    end
end
