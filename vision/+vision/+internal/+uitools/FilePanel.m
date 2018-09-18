% FilePanel Tool strip file panel 
%
% Encapsulates the tool strip file panel that contains New
% Session, Open Session, Save Session, and Add Images buttons.
%
% panel = FilePanel() creates the file panel. After you create the panel
% you have to add the callbacks for each of the buttons.
%
% FilePanel properties:
%   The following properties are abstract and protected. They must be 
%   defined and set in the derived class:
%
%   NewSessionToolTip  - tool tip id for the New Session button
%   OpenSessionToolTip - tool tip id for the Open Session button
%   SaveSessionToolTip - tool tip id for the Save Session button
%   AddImagesToolTip   - tool tip id for the Add Images button
%   AddImagesIconFile  - image file for the Add Images button icon
%
% FilePanel methods:
%
%   setAllButtonsEnabled    - enable/disable all buttons
%   addNewSessionCallback   - add a callback for the New Session button
%   addOpenSessionCallback  - add a callback for the Open Session button
%   addSaveSessionCallbacks - add callbacks for the Save Session button
%   addAddImagesCallback    - add a callback for the Add Images button
%
% See also vision.internal.uitools.ToolStripPanel

classdef FilePanel < vision.internal.uitools.ToolStripPanel
    properties (Access=protected)
        NewSessionButton        
        SaveSessionButton
        OpenSessionButton
        AddImagesButton                             
    end
    
    properties (Abstract, Access=protected)
        % The tool tips and the icons differ between the apps.
        % For a specific app, write a derved class that defines and sets
        % these properties.
        
        % NewSessionToolTip tool tip message catalog id for the New Session button
        NewSessionToolTip;
        
        % OpenSessionToolTip tool tip message catalog id for the Open Session button
        OpenSessionToolTip;
        
        % SaveSessionToolTip tool tip message catalog id for the Save Session button
        SaveSessionToolTip;
        
        % AddImagesToolTip tool tip message catalog id for the Add Images button
        AddImagesToolTip;
        
        % AddImagesIconFile - image file for the Add Images button icon
        AddImagesIconFile;
    end
    
    methods 
        function this = FilePanel()
            this.createPanel();
            this.addButtons();
        end
        
        %------------------------------------------------------------------
        function setAllButtonsEnabled(this, state)
        % setAllButtonsEnabled Enable/disable all buttons
        %   setAllButtonsEnabled(panel, state) If state is true, enable all
        %   buttons on the panel. if state is fals, disable all buttons on
        %   the panel.
            this.AddImagesButton.Enabled = state;
            this.NewSessionButton.Enabled = state;
            this.OpenSessionButton.Enabled = state;
            this.SaveSessionButton.Enabled = state;
        end
            
        %------------------------------------------------------------------
        function addNewSessionCallback(this, fun)
        % addNewSessionCallback add a callback for the New Session button    
        %   addNewSessionCallback(panel, fun) adds a callback fun to the New
        %   Session button.
            this.addButtonCallback(this.NewSessionButton, fun);
        end
        
        %------------------------------------------------------------------
        function addOpenSessionCallback(this, fun)
        % addOpenSessionCallback add a callback for the Open Session button    
        %   addOpenSessionCallback(panel, fun) adds a callback fun to the
        %   Open Session button.
            this.addButtonCallback(this.OpenSessionButton, fun);
        end
        
        %------------------------------------------------------------------
        function addSaveSessionCallbacks(this, buttonFun, popupFun)
        % addSaveSessionCallbacks add callbacks for the Save Session button    
        %   and its popup.
        %   addSaveSessionCallbacks(panel, buttonFun, popupFun) adds
        %   buttonFun to the Save Session button, and popupFun to the
        %   button's popup.
            this.addButtonCallback(this.SaveSessionButton, buttonFun);
            this.addPopupCallback(this.SaveSessionButton, popupFun);
        end
        
        %------------------------------------------------------------------
        function addAddImagesCallback(this, buttonFun, popupFun)
        % addAddImagesCallback add a callback for the Add Images button
        %  addAddImagesCallback(panel, buttonFun) adds a callback buttonFun
        %  to the Add Images button.
        %
        %  addAddImagesCallback(..., popupFun) also adds a callback to the 
        %    button's  popup if it has one.        
            this.addButtonCallback(this.AddImagesButton, buttonFun);
            if nargin > 2
                this.addPopupCallback(this.AddImagesButton, popupFun);
            end
        end
        
    end
    
    methods(Access=protected)
        %------------------------------------------------------------------
        function createPanel(this)
            this.Panel = toolpack.component.TSPanel('f:p,f:p,f:p,2dlu,f:p',...
                'f:p');
        end
        
        %------------------------------------------------------------------
        function addButtons(this)
            this.addNewSessionButton();
            this.addOpenSessionButton();
            this.addSaveSessionButton();
            this.addAddImagesButton();
                                    
            add(this.Panel, this.NewSessionButton,'xy(1,1)');
            add(this.Panel, this.OpenSessionButton, 'xy(2,1)');            
            add(this.Panel, this.SaveSessionButton,'xy(3,1)');
            add(this.Panel, this.AddImagesButton,'xy(5,1)');
        end
        
        %------------------------------------------------------------------
        function addNewSessionButton(this)
            newSessionIcon = toolpack.component.Icon.NEW_24;
            nameId = 'vision:uitools:NewSessionButton';
            this.NewSessionButton = this.createButton(newSessionIcon,...
                nameId, 'btnNewSession', 'vertical');
            this.setToolTipText(this.NewSessionButton,...
                this.NewSessionToolTip);
        end
        
        %------------------------------------------------------------------
        function addOpenSessionButton(this)
            openSessionIcon = toolpack.component.Icon.OPEN_24;
            nameId = 'vision:uitools:OpenSessionButton';
            createOpenSessionButton(this, openSessionIcon, nameId);
            this.setToolTipText(this.OpenSessionButton,...
                this.OpenSessionToolTip);
        end
        
        %------------------------------------------------------------------
        function createOpenSessionButton(this, openSessionIcon, nameId)
            this.OpenSessionButton = this.createButton(openSessionIcon,...
                nameId, 'btnOpenSession', 'vertical');
        end
        
        %------------------------------------------------------------------
        function addSaveSessionButton(this)
            saveicon = toolpack.component.Icon.SAVE_24;
            nameId = 'vision:uitools:SaveSessionButton';
            this.SaveSessionButton = this.createVerticalSplitButton(...
                saveicon, nameId, 'btnSaveSession');
            this.setToolTipText(this.SaveSessionButton,...
                this.SaveSessionToolTip);
            
            this.SaveSessionButton.Popup = this.createSplitButtonPopup(...
                this.getSaveOptions(), 'SavePopup');
        end
        
        %------------------------------------------------------------------
        function addAddImagesButton(this)
            addImagesIcon = toolpack.component.Icon(this.AddImagesIconFile);
            nameId = 'vision:uitools:AddImagesButton';
            tag = 'btnAddImages';
            
            this.createAddImagesButton(addImagesIcon, nameId, tag);
            
            this.setToolTipText(this.AddImagesButton,...
                this.AddImagesToolTip);         
        end
        
        %------------------------------------------------------------------
        function createAddImagesButton(this, icon, nameId, tag)
            this.AddImagesButton = this.createButton(icon, ...
                nameId, tag, 'vertical');
        end
        
        % -----------------------------------------------------------------
        function items = getSaveOptions(~)
            % defining the option entries appearing on the popup of the 
            % Save Split Button.
            
            saveIcon = com.mathworks.common.icons.CommonIcon.SAVE;
            saveAsIcon = com.mathworks.common.icons.CommonIcon.SAVE_AS;

            items(1) = struct(...
                'Title', vision.getMessage('vision:uitools:SaveSessionOption'), ...
                'Description', '', ...
                'Icon', toolpack.component.Icon(saveIcon.getIcon), ...
                'Help', [], ...
                'Header', false);
            items(2) = struct(...
                'Title', vision.getMessage('vision:uitools:SaveSessionAsOption'), ...
                'Description', '', ...
                'Icon', toolpack.component.Icon(saveAsIcon.getIcon), ...
                'Help', [], ...
                'Header', false);
        end        
    end
    
    methods(Static)
        %------------------------------------------------------------------
        function addButtonCallback(button, fun)
            addlistener(button, 'ActionPerformed', fun);
        end
        
        %------------------------------------------------------------------
        function addPopupCallback(button, fun)
            addlistener(button.Popup, 'ListItemSelected', fun);
        end
    end
end

