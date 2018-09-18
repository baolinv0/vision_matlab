classdef ExceptionDialog < vision.internal.uitools.OkDlg
    %ExceptionDialog throw an app exception dialog with link to user code.
    %   This class can be used to display error messages in a dialog (not
    %   modal) in an App from user code.
    %   
    %   Inputs
    %   ------
    %   toolGroupName       - App tool group name.
    %   dlgTitle            - Title to be displayed on dialog.
    %   exception           - MException object containing error.
    %   textString          - Message to be displayed on dialog.
    %   internalCodePattern - Pattern used with regexp to trim error report
    %                         of exception object. If this input is not
    %                         provided, errors are trimmed to user code
    %                         coming from Ground Truth Labeler.
    %
    
    % Copyright 2016 The MathWorks, Inc.
    
    properties
        %Exception                  MException object with user code error
        Exception                   MException
        
        %InternalCodeSearchPattern  Cell array of pattern strings passed to
        %                           regexp to trim error report from.
        InternalCodeSearchPattern = {};
        
        %Panel                      UIPanel with text box & Java scrollpane                        
        Panel                       matlab.ui.container.Panel
        
        %TextBox                    UIControl text box
        TextBox                     matlab.ui.control.UIControl
        
        %TextString                 String to place in text box
        TextString                = getString(message('vision:labeler:ErrorEncounteredAlgo'));
        
        %PanelContainer             HG Container to javacomponent
        PanelContainer              matlab.ui.container.internal.JavaWrapper
    end
    
    methods
        %------------------------------------------------------------------
        function this = ExceptionDialog(toolGroupName, dlgTitle, exception, windowStyle,...
                textString, internalCodePattern)
            
            this = this@vision.internal.uitools.OkDlg(toolGroupName, dlgTitle);
            
            this.Exception = exception;
            
            if nargin > 4
                this.TextString = textString;
            end
            
            if nargin > 5
                this.InternalCodeSearchPattern = internalCodePattern;
            end
            
            % Make the dialog wider in order to fit entire error stack.
            this.DlgSize = [500, 300];
            createDialog(this);
            
            % This is not a modal dialog. Closing of the dialog needs to be
            % handled outside this class.
            this.Dlg.WindowStyle    =  windowStyle;
            this.Dlg.Tag            = 'ExceptionDialog';            
            
            addExceptionPanel(this);
        end
    end
    
    methods (Access = private)
        %------------------------------------------------------------------
        function addExceptionPanel(this)
            
            heightGap = 50;
            widthGap  = 0;
            
            % Create a panel to hold a text box and Java scrollpane
            this.Panel = uipanel(this.Dlg, 'Units', 'pixels', ...
                'Position', [widthGap heightGap this.DlgSize(1)-widthGap this.DlgSize(2)-heightGap]');
            
            % Text box saying 
            this.TextBox = uicontrol('Parent', this.Panel, ...
                'Style', 'text', ...
                'HorizontalAlignment', 'left',...
                'Tag','exceptionText',...
                'String', this.TextString);
            
            % Create a JAVA-based HTML text label
            jlinkHandler = javaObjectEDT(com.mathworks.mlwidgets.MatlabHyperlinkHandler);
            jlinkText    = javaObjectEDT(com.mathworks.widgets.HyperlinkTextLabel);
            jlinkText.setAccessibleName('exceptionLinkText');
            jlinkText.setHyperlinkHandler(jlinkHandler);
            
            % Place the error report (stack with hyper-links) in this
            % component.
            report = trimmedReport(this);
            jlinkText.setText(report);
            jlinkText.setBackgroundColor(java.awt.Color.white);
            
            % Place the text label in a scroll pane.
            hPanel = javaObjectEDT('javax.swing.JScrollPane',jlinkText.getComponent());
            hPanel.setBackground(java.awt.Color.white);
            
            [~, this.PanelContainer] = ...
                javacomponent(hPanel, [1 1 10 10], this.Panel);
            
            positionControls(this);
            
            this.Panel.SizeChangedFcn = @this.positionControls;
        end
        
        %------------------------------------------------------------------
        function report = trimmedReport(this)
            
            report = vision.internal.getTrimmedReport(...
                this.Exception, this.InternalCodeSearchPattern);
            
            % Convert to HTML breaks
            report = strrep(report, newline, '<br>');
        end
        
        %------------------------------------------------------------------
        function positionControls(this)
            
            canvas = getpixelposition(this.Panel);
            
            width  = canvas(3);
            height = canvas(4);
            bottom = height;
            
            % Pad on top
            bottom = bottom-20;
            
            % Place header
            headerHeight = 20;
            bottom         = bottom - headerHeight;
            this.TextBox.Position = ...
                [1, bottom, width, headerHeight];
            
            % Pad
            bottom = bottom-20;
            
            % Use all remaining height for image list box
            panelHeight  = bottom;
            this.PanelContainer.Position = [1, 1, width, panelHeight];
            
        end
    end
end