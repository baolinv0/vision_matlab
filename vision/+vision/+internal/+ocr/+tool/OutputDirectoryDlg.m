% This class defines a dialog for specifying session output direcotory.
classdef OutputDirectoryDlg < vision.internal.uitools.OkCancelDlg
   
    %----------------------------------------------------------------------
    % UI components
    %----------------------------------------------------------------------
    properties(Access = private)
        MessageText            
        OutputDir
        OutputDirText
        OutputDirButton     
    end
    
    properties
        OutputDirectory
    end
    
    %----------------------------------------------------------------------
    methods
        function this = OutputDirectoryDlg(groupName)
            dlgTitle = vision.getMessage('vision:ocrTrainer:OutputDirDialogTitle');            
            this = this@vision.internal.uitools.OkCancelDlg(groupName, dlgTitle);

            % simple dlg for output directory only
                        
            this.DlgSize = [450 215];
            
            createDialog(this);
                                
            addOK(this);     
            
            doOutputDirectoryLayout(this);
            
        end
                
    end        
    
    %----------------------------------------------------------------------
    methods(Access = protected)
        function onOK(this, ~, ~)
            validInput = validateUserInput(this);
            
            if validInput  
                this.OutputDirectory = this.OutputDir.String;
                this.IsCanceled = false;
                close(this);                                            
            end
        end       
    end
    
    %----------------------------------------------------------------------
    methods(Access = private)
        
        function doOutputDirectoryLayout(this)

            this.OutputDirText = uicontrol('Parent', this.Dlg, 'Style', 'text',...
                'Units', 'pixels', ...
                'Position', [1 80 146 23], ...
                'HorizontalAlignment', 'right', ...
                'String', 'Output Directory',...
                'Tag', 'OutputDirText');
            
            %
            this.OutputDir = uicontrol('Parent', this.Dlg, 'Style', 'edit', ...
                'Units', 'pixels',...
                'HorizontalAlignment', 'left', ...
                'Position', [159 80 223 26],...
                'String', '', ...
                'Tag', 'OutputDir');
            
            %
            this.OutputDirButton =  uicontrol('Parent', this.Dlg, 'Style', 'pushbutton', ...
                'Units', 'pixels',...
                'Position', [387 80 56 26], ...
                'String', 'Browse',...
                'Callback', @(h,d)doChooseOutputDirectory(this,h,d),...
                'Tag', 'OutputDirButton');
            
            this.MessageText = uicontrol('Parent', this.Dlg, 'Style', 'text',...
                'Units', 'pixels', ...
                'Position', [5 110 400 72], ...
                'HorizontalAlignment', 'left', ...
                'String', vision.getMessage('vision:ocrTrainer:OutputDirDialog'), ...
                'Tag', 'OutputDirIntro');
        end
                               
        %------------------------------------------------------------------
        function isValid = validateUserInput(this)
            
            % check for empty directory output
            if isempty(this.OutputDir.String)
                msg   = vision.getMessage('vision:ocrTrainer:SessionEditBoxEmpty','output directory');
                title = vision.getMessage('vision:ocrTrainer:SessionEditBoxEmptyTitle');
                errordlg(msg,title,'modal');                
                isValid = false;               
                return;
            end                       
            
            isValid = vision.internal.ocr.tool.validateOutputDirectory(...
                this.OutputDir.String);
            
        end
              
    end
    
    %----------------------------------------------------------------------
    % Output setting callbacks
    %----------------------------------------------------------------------
    methods
              
        %------------------------------------------------------------------
        function doModifyOutputDirectory(this, varargin)
            
            % get user entered value, ignorning trailing white space.
            dirname = deblank(this.OutputDir.String);
            
            updateOutputDirectory(this, dirname);
                 
        end
        
        %------------------------------------------------------------------
        function doChooseOutputDirectory(this, varargin)
            dirname = uigetdir(pwd);
            if(dirname==0) % cancelled
                return;
            end
            
            updateOutputDirectory(this, dirname);            
        end
        
        %------------------------------------------------------------------
        function updateOutputDirectory(this, dirname)
            if isempty(dirname)
                return;
                % onOK all active edit boxes are check for isemtpy. leaving
                % this uncheck allows users to click on browse button
                % without getting an error message.
            else
                isValid = vision.internal.ocr.tool.validateOutputDirectory(dirname);
                      
                if isValid                
                    this.OutputDir.String = dirname;                    
                else
                    this.OutputDir.String = '';
                end
            end
        end                                
    end       
        
end