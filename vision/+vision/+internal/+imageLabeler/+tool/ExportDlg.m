% Copyright 2016 The MathWorks, Inc.

classdef ExportDlg < vision.internal.uitools.OkCancelDlg
    properties
        VarName;
        VarFormat;
    end
    
    properties(Access=private)
        Prompt;        
        EditBox;
        FormatPrompt;
        FormatComboBox;
        FormatLabel;
        
        PromptX = 10;
        EditBoxX = 207;
    end
    
    methods
        %------------------------------------------------------------------
        function this = ExportDlg(groupName, paramsVarName, enableFormat)
            dlgTitle = vision.getMessage('vision:uitools:ExportTitle');
            this = this@vision.internal.uitools.OkCancelDlg(...
                groupName, dlgTitle);
            
            this.VarName = paramsVarName;            
            this.Prompt = getString(message('vision:uitools:ExportPrompt'));
            
            this.FormatPrompt = getString(message(...
                'vision:trainingtool:ExportFormatPrompt'));
            this.DlgSize = [400, 120];
            createDialog(this);
            
            addParamsVarPrompt(this);            
            addParamsVarEditBox(this);
            addFormatPrompt(this);
            addFormatComboBox(this, enableFormat);
        end
        
        %------------------------------------------------------------------
        function disableFormat(this)
            this.FormatLabel.Enable    = 'off';
            this.FormatComboBox.Enable = 'off';
        end
    end
    
    methods(Access=private)
        %------------------------------------------------------------------
        function addParamsVarPrompt(this)
            uicontrol('Parent',this.Dlg,'Style','text',...
                'Position',[this.PromptX, 78, 200, 20], ...
                'HorizontalAlignment', 'left',...
                'String', this.Prompt, ...
                'ToolTipString', ...
                vision.getMessage('vision:caltool:ExportParametersNameToolTip'));                
        end
        
        %------------------------------------------------------------------
        function addParamsVarEditBox(this)
            this.EditBox = uicontrol('Parent', this.Dlg,'Style','edit',...
                'String',this.VarName,...
                'Position', [this.EditBoxX, 77, 180, 25],...
                'HorizontalAlignment', 'left',...
                'BackgroundColor',[1 1 1], ...
                'Tag', 'varEditBox',...
                'ToolTipString', ...
                vision.getMessage('vision:caltool:ExportParametersNameToolTip'));
        end        
        
        %------------------------------------------------------------------
        function addFormatPrompt(this)
             this.FormatLabel = uicontrol('Parent',this.Dlg,'Style','text',...
                'Position',[this.PromptX, 48, 200, 20], ...
                'HorizontalAlignment', 'left',...
                'String', this.FormatPrompt, ...
                'ToolTipString', ...
                getString(message('vision:imageLabeler:ExportFormatToolTip')));     
        end
        
        %------------------------------------------------------------------
        function addFormatComboBox(this, enableFormat)
            formats = {getString(message('vision:imageLabeler:GroundTruthFormat')), ...
                getString(message('vision:imageLabeler:TableFormat'))};
            
            this.FormatComboBox = uicontrol('Parent', this.Dlg,'Style','popupmenu',...
                'String', formats,...
                'Position', [this.EditBoxX, 47, 180, 25],...
                'HorizontalAlignment', 'left',...
                'BackgroundColor',[1 1 1], ...
                'Tag', 'formatComboBox',...
                'ToolTipString', ...
                getString(message('vision:imageLabeler:ExportFormatToolTip')));
            
            if ~enableFormat
                this.disableFormat();
            end
        end                
    end
    
    
    methods(Access = protected)
        %------------------------------------------------------------------
        function onOK(this, ~, ~)
            this.VarName = get(this.EditBox, 'String');
            this.VarFormat = this.FormatComboBox.String{this.FormatComboBox.Value};
            if ~isvarname(this.VarName)
                errordlg(getString(message('vision:uitools:invalidExportVariable')));
            else
                this.IsCanceled = false;
                close(this);
            end
        end
    end
end