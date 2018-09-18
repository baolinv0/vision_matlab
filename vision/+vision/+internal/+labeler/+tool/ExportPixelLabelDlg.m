% Copyright 2016 The MathWorks, Inc.

classdef ExportPixelLabelDlg < vision.internal.uitools.OkCancelDlg
    properties
        VarName;
        VarPath;
        CreatedDirectory;
    end
    
    properties(Access = private)
        Prompt;        
        EditBox;
        FolderTextBox;
        BrowseButton;
        
        ToFile;
        
        PromptX = 10;
        EditBoxX = 170;
        BrowseX = 210;
        
        CurrentlyBrowsing = false;
    end
    
    methods
        %------------------------------------------------------------------
        function this = ExportPixelLabelDlg(groupName, paramsVarName, dlgTitle, previousPath, toFile)
            
            this = this@vision.internal.uitools.OkCancelDlg(...
                groupName, dlgTitle);
            
            this.VarPath = previousPath;
            
            if isempty(this.VarPath)
                this.VarPath = pwd;
            end
            
            this.ToFile = toFile;
            
            this.VarName = paramsVarName;
            if this.ToFile
                this.Prompt = getString(message('vision:uitools:ExportFilePrompt'));
            else
                this.Prompt = getString(message('vision:uitools:ExportPrompt'));
            end
            
            this.DlgSize = [300, 170];
            createDialog(this);
            
            addParamsVarPrompt(this);            
            addParamsVarEditBox(this);
            addDirectoryPrompt(this);
            addDirectoryBox(this);
            addBrowseButton(this);
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
        
        function addDirectoryBox(this)
            % Text box to type folder path
            this.FolderTextBox = uicontrol('Parent', this.Dlg,...
                'Style', 'edit', ...
                'Position', [this.PromptX, 97, 190, 25],...
                'String', this.VarPath, ...
                'HorizontalAlignment', 'left',...
                'BackgroundColor',[1 1 1], ...
                'KeyPressFcn',@this.doLoadIfEntered,...
                'Tag','InputFolderTextBox');
        end
        
        function addBrowseButton(this)
            % Browse button
            this.BrowseButton = uicontrol('Parent', this.Dlg, ...
                'Style','pushbutton',...
                'Position', [this.BrowseX, 97, 80, 25],...
                'Callback', @this.doBrowse,...
                'String', vision.getMessage('vision:labeler:Browse'),...
                'Tag','BrowseButton');
        end
        
        function addDirectoryPrompt(this)
            uicontrol('Parent', this.Dlg,...
                'Style','text', ...
                'Position', [this.PromptX, 125, 280, 25],...
                'HorizontalAlignment', 'left',...
                'String', vision.getMessage('vision:labeler:ExportDirectoryDialog'));
        end
        
    end
    
    methods(Access = protected)
        %------------------------------------------------------------------
        function onOK(this, ~, ~)
            this.VarName = get(this.EditBox, 'String');
            this.VarPath = get(this.FolderTextBox, 'String');
            if ~isvarname(this.VarName)
                % Verify variable name
                errordlg(getString(message('vision:uitools:invalidExportVariable')));
            elseif ~isdir(this.VarPath)
                % Verify file path
                errorMessage = vision.getMessage('vision:labeler:InvalidFolder', this.VarPath);
                dialogName = vision.getMessage('vision:labeler:InvalidFolderTitle');
                errordlg(errorMessage, dialogName);
                
            else
                if this.ToFile
                    % Check if mat file already exists
                    varAlreadyExists = exist([fullfile(this.VarPath,this.VarName),'.mat'],'file') == 2;
                else
                    % Don't check for variable
                    varAlreadyExists = false;
                end
                    
                if varAlreadyExists
                
                    yes    = vision.getMessage('MATLAB:uistring:popupdialogs:Yes');
                    no     = vision.getMessage('MATLAB:uistring:popupdialogs:No');
                    cancel = vision.getMessage('MATLAB:uistring:popupdialogs:Cancel');

                    selection = askToOverwrite(this);

                    switch selection
                        case yes
                            % No-op
                        case no
                            return;
                        case cancel
                            this.IsCanceled = true;
                            onCancel(this);
                            return;
                    end
                
                end
                
                % Verify ability to create a directory on path
                tempDirectory = fullfile(this.VarPath, 'PixelLabelData');
                idx = 1;
                
                while isdir(tempDirectory)
                    % Add numbers to get unique directory
                    tempDirectory = fullfile(this.VarPath, ['PixelLabelData_' num2str(idx)]);
                    idx = idx+1;
                end
                
                status = mkdir(tempDirectory);
                
                if status
                    this.CreatedDirectory = tempDirectory;
                    this.IsCanceled = false;
                    close(this);
                else
                    errorMessage = vision.getMessage('vision:labeler:UnableToWrite', this.VarPath);
                    dialogName = vision.getMessage('vision:labeler:UnableToWriteTitle');
                    errordlg(errorMessage, dialogName);
                end
                
            end
        end
        
        function doLoadIfEntered(this, ~, event)
            if(strcmp(event.Key,'return') && strcmp(this.OkButton.Enable,'on'))
                drawnow; % Required to update text box string
                this.onOK();
            end
        end
        
        function doBrowse(this,varargin)
            if(this.CurrentlyBrowsing)
                return;
            end
            this.CurrentlyBrowsing = true;
            dirname = uigetdir(this.FolderTextBox.String, vision.getMessage('vision:labeler:TempDirectoryTitle'));
            if(dirname ~= 0)
                this.VarPath = dirname;
                this.FolderTextBox.String = this.VarPath;
            end
            this.CurrentlyBrowsing = false;
        end
        
        function selection = askToOverwrite(this)
            
            yes    = vision.getMessage('MATLAB:uistring:popupdialogs:Yes');
            no     = vision.getMessage('MATLAB:uistring:popupdialogs:No');
            cancel = vision.getMessage('MATLAB:uistring:popupdialogs:Cancel');
            
            selection = questdlg(vision.getMessage...
                ('vision:uitools:ExportOverwrite',this.VarName), ...
                vision.getMessage('vision:uitools:ExportOverwriteTitle'), ...
                yes, no, cancel, yes);
            
            if isempty(selection) % dialog was destroyed with a click
                selection = cancel;
            end
        end
        
    end
        
end