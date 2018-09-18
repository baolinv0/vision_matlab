% ToolStripApp the base class for the toolstrip-based apps
%
%  This is a base class for toolstrip apps. It contains the toolgroup
%  object and the session information.
%
%  ToolStripApp properties:
%    ToolGroup      - the toolpack.desktop.ToolGroup object
%    Session        - the session object, containing the App's data
%    SessionManager - the object that should handle loading and saving of the session
%
%  ToolStripApp methods:
%    removeViewTab - remove the View tab, which is enabled by default
%    addFigure     - add a figure to the app (protected)
%

% Copyright 2014 The MathWorks, Inc.

classdef ToolStripApp < handle
    properties(Access = protected)
        % ToolGroup the toolpack.desktop.ToolGroup object.
        %  This object must be instantiated in the derived class 
        ToolGroup;
        
        % SessionManager object that handles saving/loading of the session
        %  This object must be instantiated in the derived class
        SessionManager;
        
        % Session the object containing the App's data
        %  This object must be instantiated in the derived class
        Session         
        
        % QuickAccessBarHelpListener Store listener for quick access bar's
        % help button. Use the configureQuickAccessBarHelpButton method
        % to initialize this. Note you must call this method before calling
        % open(ToolGroup) in your app.
        QuickAccessBarHelpListener
    end
    
    methods(Abstract, Access = public)
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
        % For contextual tab support. Makes tab invisible.
        %------------------------------------------------------------------
        function hideTab(this, tab)
            this.ToolGroup.remove(getToolTab(tab));
        end
        
        %------------------------------------------------------------------
        % For contextual tab support. Makes tab visible.
        %------------------------------------------------------------------
        function showTab(this, tab)
            this.ToolGroup.add(getToolTab(tab));
        end
        
        %------------------------------------------------------------------
        function removeViewTab(this)
        % removeViewTab Remove the view tab
        %   removeViewTab(app) removes the view tab from the app. If you do
        %   not call this method, the view tab will be on by default. app
        %   is the ToolStripApp object.
            group = this.ToolGroup.Peer.getWrappedComponent;
            % Group without a View tab (needs to be called before t.open)
            group.putGroupProperty(...
                com.mathworks.widgets.desk.DTGroupProperty.ACCEPT_DEFAULT_VIEW_TAB, ...
                false);
        end
        
        %------------------------------------------------------------------
        function removeQuickAccess(this)
        % removeQuickAccess Remove the Quick Access toolbar
        %   removeQuickAccess(app) removes the Quick Access toolbar from the app. If you do
        %   not call this method, the Quick Access toolbar will be on by default. app
        %   is the ToolStripApp object.
            filter = com.mathworks.toolbox.images.QuickAccessFilter.getFilter();
            group = this.ToolGroup.Peer.getWrappedComponent;
            group.putGroupProperty(...
                com.mathworks.widgets.desk.DTGroupProperty.QUICK_ACCESS_TOOL_BAR_FILTER,...
                filter);
        end
        
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
            
            % Create an action and wire to call helpCallback
            action = com.mathworks.toolbox.shared.controllib.desktop.TSUtils.getAction('My Help', javax.swing.ImageIcon);
            this.QuickAccessBarHelpListener = ...
                addlistener(action.getCallback, 'delayed', helpCallback);
            
            % Register the action with the Help button
            ctm = com.mathworks.toolstrip.factory.ContextTargetingManager;
            ctm.setToolName(action, 'help')
            
            % Set the context action BEFORE opening the ToolGroup
            ja = javaArray('javax.swing.Action', 1);
            ja(1) = action;
            c = this.ToolGroup.Peer.getWrappedComponent;
            c.putGroupProperty(...
                com.mathworks.widgets.desk.DTGroupProperty.CONTEXT_ACTIONS, ja);
        end
        
    end
        
    methods(Access=protected)
        %------------------------------------------------------------------
        function addFigure(this, fig)
            % addFigure Add a figure to the app and disable drag-and-drop into it.
            %  addFigure(app, fig) adds a figure to the app. app is the
            %  ToolStrip app object. fig is the figure handle.
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
