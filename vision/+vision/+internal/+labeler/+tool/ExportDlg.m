% Copyright 2016 The MathWorks, Inc.

classdef ExportDlg < vision.internal.uitools.OkCancelDlg
    properties
        VarName;
        VarTitle;
    end
    
    properties(Access = private)
        Prompt;        
        EditBox;
        
        PromptX = 10;
        EditBoxX = 170;
    end
    
    methods
        %------------------------------------------------------------------
        function this = ExportDlg(groupName, paramsVarName)
            dlgTitle = vision.getMessage('vision:uitools:ExportTitle');
            this = this@vision.internal.uitools.OkCancelDlg(...
                groupName, dlgTitle);
            
            this.VarName = paramsVarName;            
            this.Prompt = getString(message('vision:uitools:ExportPrompt'));
            
            this.DlgSize = [300, 100];
            createDialog(this);
            
            addParamsVarPrompt(this);            
            addParamsVarEditBox(this);
        end
    end
    
    methods(Access = private)
        %------------------------------------------------------------------
        function addParamsVarPrompt(this)
            uicontrol('Parent',this.Dlg,'Style','text',...
                'Position',[this.PromptX, 58, 220, 20], ...
                'HorizontalAlignment', 'left',...
                'String', this.Prompt, ...
                'ToolTipString', ...
                vision.getMessage('vision:caltool:ExportParametersNameToolTip'));                
        end
        
        %------------------------------------------------------------------
        function addParamsVarEditBox(this)
            this.EditBox = uicontrol('Parent', this.Dlg,'Style','edit',...
                'String',this.VarName,...
                'Position', [this.EditBoxX, 57, 120, 25],...
                'HorizontalAlignment', 'left',...
                'BackgroundColor',[1 1 1], ...
                'Tag', 'varEditBox',...
                'ToolTipString', ...
                vision.getMessage('vision:caltool:ExportParametersNameToolTip'));
        end        
    end
    
    methods(Access = protected)
        %------------------------------------------------------------------
        function onOK(this, ~, ~)
            this.VarName = get(this.EditBox, 'String');
            if ~isvarname(this.VarName)
                errordlg(getString(message('vision:uitools:invalidExportVariable')));
            else
                this.IsCanceled = false;
                close(this);
            end
        end
    end
end