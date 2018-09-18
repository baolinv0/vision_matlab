% AbstractDlg Base class for dialogs used with a toolgroup
%
% AbstractDlg class handles dialog creation, positioning, and closing.
%
%   dlg = AbstractDlg(groupName, dlgTitle) creates the AbstractDlg object. 
%   groupName is the name of the toolgroup (toolstrip app) using the
%   dialog. The dialog will be positioned in the center of the tool group
%   window.
%
% AbstractDlg properties:
%
%   Dlg       - Handle to the dialog object
%   DlgSize   - Size of the dialog [width, height] 
%   DlgTitle  - Title of the dialog
%   GroupName - Name of the toolgroup
%
% AbstractDlg methods:
%   
%   createDialog - Create and show the dialog.
%   wait         - Wait for the user to close the dialog.
%   close        - Close the dialog
%   delete       - Close the dialog
%
%   Abstract methods:
%   onKeyPress   - Handle the behaviour of enter, space, and escape keys.
%

% Copyright 2014-2015 The MathWorks, Inc.

classdef AbstractDlg < handle
    properties 
        % Dlg Handle to the dialog object
        Dlg;
        
        % DlgSize Size of the dialog [width, height] 
        DlgSize = [400, 200];
        
        % DlgTitle Title of the dialog as a string
        DlgTitle;
        
        % GroupName Name of the toolgroup. Used for positioning.
        GroupName;
    end
    
    methods
        %------------------------------------------------------------------
        function this = AbstractDlg(groupName, dlgTitle)
            this.GroupName = groupName;
            this.DlgTitle = dlgTitle;
        end
        
        %------------------------------------------------------------------
        function createDialog(this)
        % createDialog Create and shows the dialog window
        %   createDialog(dlg) creates and shows the dialog window. dlg is
        %   an AbstractDlg object.
            dlgPosition = getInitialDialogPosition(this);
            this.Dlg = dialog('WindowStyle', 'modal', 'Name', this.DlgTitle,...
                'Position', dlgPosition, ...
                'KeyPressFcn', @this.onKeyPress);
            
            % Dialog is positioned using ScreenUtilities, which in edge
            % cases may position the dialog off screen under certain
            % monitor configurations. Use movegui to bring dialog on screen
            % if this is the case.
            movegui(this.Dlg, 'onscreen');
        end
        
        %------------------------------------------------------------------
        function close(this, ~, ~)
        % CLOSE Close the dialog
        %   CLOSE(dlg)
            if ishandle(this.Dlg)
                close(this.Dlg);
            end
        end
        
        %------------------------------------------------------------------
        function wait(this)
        % WAIT Wait for the user to close the dialog.
        %   WAIT(dlg) wait untilt he user closes the dialog. dlg is an
        %   AbstractDlg object.
            uiwait(this.Dlg);
        end
        
        %------------------------------------------------------------------
        function delete(this)
        % DELETE Close the dialog
        %   DELETE(dlg)
            close(this);
        end
    end
    
    %----------------------------------------------------------------------
    methods(Abstract, Access=protected)
        % onKeyPress handle the behavior of enter, space, and escape keys.
        %   onKeyPress(dlg)
        onKeyPress(this)
    end
    %----------------------------------------------------------------------
   
    methods(Access=private)
        %------------------------------------------------------------------
        function pos = getInitialDialogPosition(this)
            if isempty(this.GroupName)
                pos = [100, 100, this.DlgSize];
            else
                pos = ...
                    imageslib.internal.apputil.ScreenUtilities.getModalDialogPos(...
                        this.GroupName, this.DlgSize);
            end
        end
    end
    
    methods(Access=protected)
        %------------------------------------------------------------------
        function ctrl = addTextLabel(this, position, string)
            ctrl = uicontrol('Parent', this.Dlg, ...
                'Style', 'text', ...
                'Position', position, ...
                'HorizontalAlignment', 'left', ...
                'String', string);
        end
        
        %------------------------------------------------------------------
        function ctrl = addCheckBox(this, position, state)
            ctrl = uicontrol('Parent', this.Dlg, ...
                'Style', 'checkbox', ...
                'Position', position, ...
                'HorizontalAlignment', 'left', 'Value', state);
        end
        
        %------------------------------------------------------------------
        function ctrl = addTextField(this, position)
            ctrl = uicontrol('Parent', this.Dlg, ...
                'Style', 'edit', 'Position', position, ...
                'HorizontalAlignment', 'left');
        end
                
    end
            
end
    