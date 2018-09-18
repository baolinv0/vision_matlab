% ZoomPanel Encapsulates the zoom controls for the tool strip.
%
%  This class encapsulates a tool strip panel containing the zoom controls.
%  You can add this panel to a section of the toolstrip. You can also extend
%  this class to add more buttons to the panel.
%
%  zoomPanel = ZoomPanel() creates a tool strip panel containing the zoom 
%  controls.
%
%  ZoomPanel properties:
%  
%    Panel              - Tool strip panel object. 
%    ZoomInButtonState  - State of the zoom-in button
%    ZoomOutButtonState - State of the zoom-out button 
%    PanButtonState     - State of the pan button
% 
%  ZoomPanel methods:
%
%    addListeners       - Add listeners to the zoom control buttons
%    removeListeners    - Delete the button listeners
%    enableButtons      - Enable all zoom control buttons
%    disableButtons     - Disable (gray out) all zoom control buttons
%    resetButtons       - Un-click all zoom control buttons
    
% Copyright 2014 The MathWorks, Inc.

classdef ZoomPanel < vision.internal.uitools.ToolStripPanel
    properties(Access=protected)
        ZoomInButton;
        ZoomOutButton;
        PanButton;
        
        ZoomInListener;
        ZoomOutListener;
        PanListener;
    end
    
    properties(Dependent)
        % ZoomInButtonState A logical scalar representing the state of the 
        %   zoom-in button. 
        ZoomInButtonState;
        
        % ZoomOutButtonState A logical scalar representing the state of the 
        %   zoom-out button. 
        ZoomOutButtonState;
        
        % PanButtonState A logical scalar representing the state of the 
        %   pan button. 
        PanButtonState;
        
        % IsAnabled A logical scalar indicating whether all the buttons are
        %   enabled.
        IsEnabled;
    end
    
    methods
        %------------------------------------------------------------------
        function this = ZoomPanel()
            this.createPanel();            
            this.createButtons();
            this.addButtons();            
        end
                      
        %------------------------------------------------------------------
        function tf = get.IsEnabled(this)
            tf = this.ZoomInButton.Enabled && this.ZoomOutButton.Enabled && ...
                this.PanButton.Enabled;
        end
        
        %------------------------------------------------------------------
        function tf = get.ZoomInButtonState(this)
            tf = this.ZoomInButton.Selected;
        end
        
        %------------------------------------------------------------------
        function tf = get.ZoomOutButtonState(this)
            tf = this.ZoomOutButton.Selected;
        end
        
        %------------------------------------------------------------------
        function tf = get.PanButtonState(this)
            tf = this.PanButton.Selected;
        end            
        
        %------------------------------------------------------------------
        function set.ZoomInButtonState(this, tf)
            this.ZoomInButton.Selected = tf;
        end
        
        %------------------------------------------------------------------
        function set.ZoomOutButtonState(this, tf)
            this.ZoomOutButton.Selected = tf;
        end
        
        %------------------------------------------------------------------
        function set.PanButtonState(this, tf)
            this.PanButton.Selected = tf;
        end            
        
        %------------------------------------------------------------------
        function addListeners(this, callbackFun)
            % addListeners Add listeners to the zoom control buttons
            %   addListeners(zoomPanel, callbackFun) adds listeners to the zoom
            %   control buttons contained in zoomPanel. zoomPanel is a
            %   ZoomPanel object.  callbackFun is a handle of a callback function
            %   to be called when one of the buttons is pressed.
            this.ZoomInListener = ...
                addlistener(this.ZoomInButton, 'ItemStateChanged', callbackFun);
            this.ZoomOutListener = ...
                addlistener(this.ZoomOutButton, 'ItemStateChanged', callbackFun);
            this.PanListener = ...
                addlistener(this.PanButton, 'ItemStateChanged', callbackFun);
        end
        
        %------------------------------------------------------------------
        function removeListeners(this)
            % removeListeners Delete the zoom control button listeners.
            %   removeListeners(zoomPanel) deletes listeners from the zoom
            %   control buttons contained in zoomPanel. zoomPanel is a
            %   ZoomPanel object.
            delete(this.ZoomInListener);
            delete(this.ZoomOutListener);
            delete(this.PanListener);
        end
        
        %------------------------------------------------------------------
        function enableButtons(this)
            % enableButtons Enable all zoom control buttons
            %   enableButtons(zoomPanel) enables all zoom control buttons
            %   contained in zoomPanel.
            this.ZoomInButton.Enabled  = true;
            this.ZoomOutButton.Enabled = true;
            this.PanButton.Enabled     = true;
        end
        
        %------------------------------------------------------------------
        function disableButtons(this)
            % disableButtons Disable all zoom control buttons
            %   disableButtons(zoomPanel) disables all zoom control buttons
            %   contained in zoomPanel. The buttons will appear garyed-out.
            this.ZoomInButton.Enabled  = false;
            this.ZoomOutButton.Enabled = false;
            this.PanButton.Enabled     = false;
        end
        
        %------------------------------------------------------------------
        function resetButtons(this)
            % resetButtons Un-click all zoom control buttons
            %   resetButtons(zoomPanel) sets the state of all zoom control
            %   buttons to false.
            this.ZoomInButton.Selected  = false;
            this.ZoomOutButton.Selected = false;
            this.PanButton.Selected     = false;
        end
    end
    
    methods(Access=protected)
        %------------------------------------------------------------------
        function createPanel(this)
            this.Panel = toolpack.component.TSPanel('f:p,3dlu,p:g', 'p:g,p:g,p:g');
        end

        %------------------------------------------------------------------
        function createButtons(this)
            this.createZoomInButton();
            this.createZoomOutButton();
            this.createPanButton();
        end
        
        %------------------------------------------------------------------
        function addButtons(this)                        
            add(this.Panel, this.ZoomInButton,  'xy(3,1)');
            add(this.Panel, this.ZoomOutButton, 'xy(3,2)');
            add(this.Panel, this.PanButton,     'xy(3,3)');
        end
        
        %------------------------------------------------------------------
        function createZoomInButton(this)
            import vision.internal.uitools.*;
            zoomInIcon = toolpack.component.Icon.ZOOM_IN_16;
            this.ZoomInButton = this.createToggleButton(zoomInIcon, ...
                'vision:uitools:ZoomInButton', ...
                'btnZoomIn', 'horizontal');
            this.setToolTipText(this.ZoomInButton,...
                'vision:uitools:ZoomInToolTip');
        end
        
        %------------------------------------------------------------------
        function createZoomOutButton(this)
            import vision.internal.uitools.*;
            zoomOutIcon = toolpack.component.Icon.ZOOM_OUT_16;
            this.ZoomOutButton = this.createToggleButton(zoomOutIcon, ...
                'vision:uitools:ZoomOutButton', ...
                'btnZoomOut', 'horizontal');
            this.setToolTipText(this.ZoomOutButton,...
                'vision:uitools:ZoomOutToolTip');
        end
        
        %------------------------------------------------------------------
        function createPanButton(this)
            import vision.internal.uitools.*;
            panIcon = toolpack.component.Icon.PAN_16;
            this.PanButton = this.createToggleButton(panIcon, ...
                'vision:uitools:PanButton', ...
                'btnPan', 'horizontal');
            this.setToolTipText(this.PanButton,...
                'vision:uitools:PanToolTip');
        end
    end
        
end