% ExportDlg Dialog for exporting the results of calibration

% Copyright 2014 The MathWorks, Inc.

classdef ExportDlg < vision.internal.uitools.OkCancelDlg
    properties
        ParamsVarName;
        ErrorsVarName;
        ShouldExportErrors;
        
        CheckBox;
    end
    
    properties(Access=private)
        ParamsPrompt;        
        ParamEditBox;
        
        ErrorsPrompt;
        ErrorsEditBox;
        
        PromptX = 10;
        EditBoxX = 207;
    end
    
    methods
        %------------------------------------------------------------------
        function this = ExportDlg(groupName, paramsPrompt, ...
                paramsVarName, errorsVarName, shouldExportErrors)
            dlgTitle = vision.getMessage('vision:uitools:ExportTitle');
            this = this@vision.internal.uitools.OkCancelDlg(...
                groupName, dlgTitle);
            
            this.ParamsVarName = paramsVarName;            
            this.ParamsPrompt = paramsPrompt;
            
            this.ErrorsVarName = errorsVarName;
            this.ErrorsPrompt = ...
                vision.getMessage('vision:caltool:ErrorsExportPrompt');
            
            this.ShouldExportErrors = shouldExportErrors;
            
            this.DlgSize = [400, 180];
            createDialog(this);
            
            addParamsVarPrompt(this);            
            addParamsVarEditBox(this);
            addErrorsVarPrompt(this);
            addErrorsVarEditBox(this);
            addErrorsCheckBox(this);
        end
    end
    
    methods(Access=private)
        %------------------------------------------------------------------
        function addParamsVarPrompt(this)
            % Prompt
            uicontrol('Parent',this.Dlg,'Style','text',...
                'Position',[this.PromptX, 128, 200, 20], ...
                'FontUnits', 'normalized', 'FontSize', 0.6,...
                'HorizontalAlignment', 'left',...
                'String', this.ParamsPrompt);                
        end
        
        %------------------------------------------------------------------
        function addParamsVarEditBox(this)
            this.ParamEditBox = uicontrol('Parent', this.Dlg,'Style','edit',...
                'String',this.ParamsVarName,...
                'Position', [this.EditBoxX, 127, 180, 25],...
                'FontUnits', 'normalized', 'FontSize', 0.6,...
                'HorizontalAlignment', 'left',...
                'BackgroundColor',[1 1 1], ...
                'Tag', 'varEditBox',...
                'ToolTipString', ...
                vision.getMessage('vision:caltool:ExportParametersNameToolTip'));
        end
        
        %------------------------------------------------------------------
        function addErrorsVarPrompt(this)
            uicontrol('Parent',this.Dlg,'Style','text',...
                'Position',[this.PromptX, 48, 200, 20],...
                'FontUnits', 'normalized', 'FontSize', 0.6,...
                'HorizontalAlignment', 'left',...
                'String', this.ErrorsPrompt);                
        end
        
        %------------------------------------------------------------------
        function addErrorsVarEditBox(this)
            this.ErrorsEditBox = uicontrol('Parent', this.Dlg,'Style','edit',...
                'String',this.ErrorsVarName,...
                'Position',[this.EditBoxX, 47, 180, 25],...
                'FontUnits', 'normalized', 'FontSize', 0.6,...
                'HorizontalAlignment', 'left',...
                'BackgroundColor',[1 1 1], ...
                'ToolTipString', ...
                vision.getMessage('vision:caltool:ExportErrorsNameToolTip'));
        end
        
        %------------------------------------------------------------------
        function addErrorsCheckBox(this)
            % prompt
            uicontrol('Parent', this.Dlg, 'Style', 'text', ...
                'Position', [this.PromptX + 20, 72, 200, 20],...
                'HorizontalAlignment', 'left', ...
                'FontUnits', 'normalized', 'FontSize', 0.6,...
                'String', ...
                vision.getMessage('vision:caltool:ExportErrorsCheckboxLabel'), ...
                'ToolTipString',...
                vision.getMessage('vision:caltool:EnableExportErrorsToolTip'));
            
            this.CheckBox = uicontrol('Parent', this.Dlg, ...
                'Style', 'checkbox', ...
                'Position', [this.PromptX, 74, 20, 20], ...
                'FontUnits', 'normalized', 'FontSize', 0.6,...
                'Callback', @checkBoxCallback,...
                'HorizontalAlignment', 'left', 'Value', this.ShouldExportErrors);
            
            if ~this.ShouldExportErrors
                disableErrors(this);
            end
            
            %--------------------------------------------------------------
            function checkBoxCallback(h, ~)
                if get(h, 'Value')
                    enableErrors(this);
                else
                    disableErrors(this);
                end
            end
        end
            
        %------------------------------------------------------------------
        function disableErrors(this)
            set(this.ErrorsEditBox, 'Enable', 'off');
        end
        
        %------------------------------------------------------------------
        function enableErrors(this)
            set(this.ErrorsEditBox, 'Enable', 'on');
        end
    end
    
    methods(Access=protected)
        %------------------------------------------------------------------
        function onOK(this, ~, ~)
            this.ShouldExportErrors = get(this.CheckBox, 'Value');
            this.ParamsVarName = get(this.ParamEditBox, 'String');
            this.ErrorsVarName = get(this.ErrorsEditBox, 'String');
            if ~isvarname(this.ParamsVarName)
                errordlg(getString(message('vision:uitools:invalidExportVariable')));
            elseif ~isvarname(this.ErrorsVarName)
                errordlg(getString(message('vision:uitools:invalidExportVariable')));             
            else
                this.IsCanceled = false;
                close(this);
            end
        end
    end
end