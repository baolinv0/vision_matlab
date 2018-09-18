% This class defines the new ocr training session dialog.
classdef SessionInitializationDlg < vision.internal.uitools.OkCancelDlg
   
    %----------------------------------------------------------------------
    % UI components
    %----------------------------------------------------------------------
    properties(Access = private)
        
        % Session intro
        IntroPanel
        IntroText
        
        % Output settings
        OutputPanel
        LanguageName
        LanguageNameText
        OutputDir
        OutputDirText
        OutputDirButton
        
        % Add images
        AddImagesPanel
        AddButton
        RemoveButton
        ImageList
        
        % Labeling options
        LabelingPanel
        OCROptionsPanel
        LabelingBtnGroup
        LabelManuallyButton
        LabelOCRButton
        OCRLanguageLabel
        OCRLanguageName
        CustomLanguageBox
        CustomLanguageBrowse                      
        OCRCharacterSetCheckBox
        OCRCharacterSetEditBox
        
    end
                
    %----------------------------------------------------------------------
    properties
        % UserData - Contains user data entered in dialog.
        UserData 
        
        % DefaultDirectory - Initial value for the output directory.
        DefaultDirectory
        
        OCRCharacterSet      
    end
    
    %----------------------------------------------------------------------
    methods
        function this = SessionInitializationDlg(groupName, defaultDir)
            dlgTitle = vision.getMessage('vision:ocrTrainer:SessionInitDialogTitle');            
            this = this@vision.internal.uitools.OkCancelDlg(groupName, dlgTitle);
                                                    
            this.DefaultDirectory = defaultDir;
            
            
            this.DlgSize = [500 600];
            
            createDialog(this);
            
            doLayout(this);
            
        end
            
    end
    
    %----------------------------------------------------------------------
    methods(Access = protected)
        function onOK(this, ~, ~)
            validInput = validateUserInput(this);
            
            if validInput                        
                this.UserData = this.getDialogData();
                this.IsCanceled = false;
                close(this);                                            
            end
        end
        
        %------------------------------------------------------------------
        function data = getDialogData(this)
                       
            [data.LanguageName, data.OutputDirectory] = getOutputSettings(this);                                        
            
            [data.AutoLabel, data.OCRLanguage] = getLabelingData(this);
            
            data.CharacterSet = getCharacterSet(this);
                    
            data.Files = getAddedImages(this);
                
        end
        
        %------------------------------------------------------------------
        function charset = getCharacterSet(this)
          
            if this.OCRCharacterSetCheckBox.Value
                charset = this.OCRCharacterSet;
            else
                charset = '';
            end
            
        end    
        
        %------------------------------------------------------------------
        function [autoLabel, lang] = getLabelingData(this)
            
            selectedButton = this.LabelingBtnGroup.SelectedObject;
            
            switch selectedButton.Tag
                case 'ManualLabel'
                    autoLabel  = false;
                    lang       = [];
                    
                case 'AutoLabel'
                    autoLabel = true;                    
                    
                    lang = this.OCRLanguageName.String{this.OCRLanguageName.Value};
                    
                    if ~isempty(strfind(lang, 'Custom'))
                        lang = this.CustomLanguageBox.String;
                    end
                    
                otherwise
                    assert('Unreachable');
            end
        end
        
        %------------------------------------------------------------------
        function [langName, outputDir] = getOutputSettings(this)
            langName  = this.LanguageName.String;
            outputDir = this.OutputDir.String;
            
        end
        
        %------------------------------------------------------------------
        function files = getAddedImages(this)
            files = this.ImageList.String;
            if strcmpi(files, ...
                    vision.getMessage('vision:ocrTrainer:AddImagesDefaultString'))
                files = {};
            end                        
        end
    end
    
    %----------------------------------------------------------------------
    methods(Access = private)        
        
        %------------------------------------------------------------------
        function doLayout(this)
            
            this.IntroPanel = uipanel('Parent', this.Dlg, ...
                'Title', vision.getMessage('vision:ocrTrainer:OCRSettingsTitle'), ...
                'Units', 'pixels',...
                'Position', [26 530 450 65],...
                'Tag', 'Intro Panel');
            
            this.IntroText = uicontrol('Parent', this.IntroPanel, 'Style', 'text',...
                'Units', 'pixels', ...
                'Position', [20 0 410 45], ...
                'HorizontalAlignment', 'left', ...
                'String', vision.getMessage('vision:ocrTrainer:SessionIntro'), ...
                'Tag', 'intro text');
            
            this.OutputPanel = uipanel('Parent', this.Dlg, ...
                'Title', vision.getMessage('vision:ocrTrainer:SessionInitOutputSettings'), ...
                'Units', 'pixels',...
                'Position', [26 435 450 90],...
                'Tag', 'Output Panel');
                
                                
            this.LanguageNameText = uicontrol('Parent', this.OutputPanel, 'Style', 'text',...
                'Units', 'pixels', ...
                'Position', [1 47.200000 146.288000 23.100000], ...
                'HorizontalAlignment', 'right', ...
                'String', vision.getMessage('vision:ocrTrainer:LanguageName'), ...
                'Tag', 'Lang name text',...
                'TooltipString', vision.getMessage('vision:ocrTrainer:OutputLangToolTip'));
            
            %
            this.LanguageName = uicontrol('Parent', this.OutputPanel, 'Style', 'edit', ...
                'Units', 'pixels',...
                'HorizontalAlignment', 'left', ...:
                'Position', [159.330000 47.200000 223 26.180000],...
                'String', 'myLang', ...
                'Callback', @(h,d)doModifyLanguage(this,h,d),...
                'Tag','LanguageName');
                     
            this.OutputDirText = uicontrol('Parent', this.OutputPanel, 'Style', 'text',...
                'Units', 'pixels', ...
                'Position', [1 9 146 23], ...
                'HorizontalAlignment', 'right', ...
                'String', vision.getMessage('vision:ocrTrainer:OutDirPanel'),...
                'Tag', 'OutputDirText', ...
                'TooltipString', vision.getMessage('vision:ocrTrainer:OutputDirToolTip'));
            
            %
            this.OutputDir = uicontrol('Parent', this.OutputPanel, 'Style', 'edit', ...
                'Units', 'pixels',...
                'HorizontalAlignment', 'left', ...
                'Position', [159 9 223 26],...
                'String', this.DefaultDirectory, ...
                'Callback', @(h,d)doModifyOutputDirectory(this,h,d),...
                'Tag', 'OutputDir');
            
            %
            this.OutputDirButton =  uicontrol('Parent', this.OutputPanel, 'Style', 'pushbutton', ...
                'Units', 'pixels',...
                'Position', [387 9 56 26], ...
                'String', vision.getMessage('vision:ocrTrainer:BrowseButton'),...
                'Callback', @(h,d)doChooseOutputDirectory(this,h,d),...
                'Tag', 'OutputDirButton');
            
            % Labeling panel
            this.LabelingPanel = uipanel('Parent', this.Dlg, ...
                'Title', vision.getMessage('vision:ocrTrainer:LabelingMethodTitle'), ...
                'Units', 'pixels',...
                'Position', [26 155 450 270],...
                'Tag','LabelingPanel');
            
            % 
            this.LabelingBtnGroup = uibuttongroup('Parent', this.LabelingPanel, ...
                'Units', 'pixels',...
                'Position', [23 195 401 58],...
                'SelectionChangeFcn', @(h,d)doLabelingMethod(this,h,d),...
                'Tag','BtgGroup',...
                'BorderType', 'none');                      
            
            this.LabelManuallyButton = uicontrol('Parent', this.LabelingBtnGroup,...
                'Style', 'radiobutton', ...
                'Units', 'pixels',...
                'Position',[4.980000 31.250000 358.200000 16.500000], ...
                'String', vision.getMessage('vision:ocrTrainer:LabelManually'),...
                'Tag', 'ManualLabel', ...
                'TooltipString', vision.getMessage('vision:ocrTrainer:LabelingMethodManualToolTip'));
            
            this.LabelOCRButton =  uicontrol('Parent', this.LabelingBtnGroup,...
                'Style', 'radiobutton', ...
                'Units', 'pixels',...
                'String', vision.getMessage('vision:ocrTrainer:PreLabel'),...
                'Position', [4.980000 9.250000 358.200000 16.500000],...
                'Tag', 'AutoLabel',...
                'TooltipString', vision.getMessage('vision:ocrTrainer:LabelingMethodOCRToolTip'));
                         
            this.LabelingBtnGroup.SelectedObject = this.LabelOCRButton ;                                   
                   

            this.OCROptionsPanel = uipanel('Parent', this.LabelingPanel, ...
                'Units', 'pixel',...
                'Title', vision.getMessage('vision:ocrTrainer:OCROptions'), ...
                'Position', [46 17 380 175], ...                
                'Tag', 'ocr language');
            
            this.OCRLanguageLabel = uicontrol('Parent', this.OCROptionsPanel, 'Style', 'text',...
                'Units', 'pixels', ...
                'Position', [5 125 72 23], ...
                'HorizontalAlignment', 'left', ...
                'String', vision.getMessage('vision:ocrTrainer:LanguageLabel'),...
                'Tag', 'ocr lang panel',...
                'TooltipString', vision.getMessage('vision:ocrTrainer:OCRLangToolTip'));
            
            this.OCRLanguageName = uicontrol('Parent', this.OCROptionsPanel, 'Style', 'popupmenu',...
                'Units', 'pixels', ...
                'Position', [80 135 155.220000 14.200000], ...
                'HorizontalAlignment', 'left', ...
                'String', getLanguageList(this),...
                'Callback', @(h,d)doOCRLanguage(this,h,d),...
                'Tag', 'OCRLangPopup',...
                'TooltipString', vision.getMessage('vision:ocrTrainer:OCRLangToolTip'));
            
            this.CustomLanguageBox = uicontrol('Parent', this.OCROptionsPanel, 'Style', 'edit',...
                'Units', 'pixels', ...
                'Position', [80 95 155.220000 25.560000], ...
                'HorizontalAlignment', 'left', ...                
                'Enable', 'off',...
                'Callback', @(h,d)doCustomEditBox(this,h,d),...
                'Tag','CustomLangBox');
            
            this.CustomLanguageBrowse =  uicontrol('Parent', this.OCROptionsPanel, 'Style', 'pushbutton', ...
                'Units', 'pixels',...                
                'Position', [238 94 59.700000 26.980000], ...
                'String', vision.getMessage('vision:ocrTrainer:BrowseButton'),...                
                'Enable', 'off', ...
                'Callback', @(h,d)doCustomBrowse(this,h,d),...
                'Tag','CustomLangBrowseBtn');         
            
            this.OCRCharacterSetCheckBox =  uicontrol('Parent', this.OCROptionsPanel, 'Style', 'checkbox', ...
                'Units', 'pixels',...                
                'Position', [5 62 117 17], ...
                'String', vision.getMessage('vision:ocrTrainer:CharSet'),... 
                'Callback', @(h,d)doCharsetCheckbox(this,h,d), ...
                'Tag','CharSetCheckBox',...
                'TooltipString', vision.getMessage('vision:ocrTrainer:OCRCharSetToolTip'));
            
             this.OCRCharacterSetEditBox =  uicontrol('Parent', this.OCROptionsPanel, 'Style', 'edit', ...
                'Units', 'pixels',...                
                'Position', [23 30 309 26], ...                 
                'HorizontalAlignment', 'left', ...
                'Enable', 'off', ...
                'Tag','CharSetEditBox',...
                'TooltipString', vision.getMessage('vision:ocrTrainer:OCRCharSetToolTip'));
            
            % Add Images panel
            this.AddImagesPanel = uipanel('Parent', this.Dlg, ...
                'Title',vision.getMessage('vision:ocrTrainer:AddTrainingImagesPanel'), ...
                'Units', 'pixels', ...
                'Position', [26 35 450 110],...
                'Tag', 'add images panel');
            
            %
            this.AddButton = uicontrol('Parent', this.AddImagesPanel, 'Style', 'pushbutton', ...
                'Units', 'pixels',...                
                'Position', [15 57 79.388000 29.550000], ...
                'String', vision.getMessage('vision:ocrTrainer:SessionInitAddButton'), ...
                'Callback', @(h,d)this.doAddImages(h,d),...
                'Tag','AddImageButton');
            
            %
            this.RemoveButton = uicontrol('Parent', this.AddImagesPanel, 'Style', 'pushbutton', ...
                'Units', 'pixels',...                
                'Position', [15 15 79.388000 29.550000], ...
                'String', vision.getMessage('vision:ocrTrainer:RemoveButton'), ...
                'Callback', @(h,d)this.doRemoveImages(h,d),...
                'Tag','RemoveImageButton');
            
            %
            this.ImageList = uicontrol('Parent', this.AddImagesPanel, 'Style', 'listbox', ...
                'Units', 'pixels',...                
                'Position', [112.500000 10.850000 312.200000 73.360000], ...
                'String', vision.getMessage('vision:ocrTrainer:AddImagesDefaultString'),...
                'FontAngle', 'italic',...
                'Tag','ImageList');
        end
        
        %------------------------------------------------------------------
        function list = getLanguageList(~)
            
            if vision.internal.ocr.ocrSpkgInstalled()
                list = vision.internal.ocr.languagesInSupportPackage();
                % make English and Japanese first two in list.
                engIdx = strcmpi('English', list);                
                list(engIdx) = [];
                jpnIdx = strcmpi('Japanese',list);
                list(jpnIdx) = [];
                list = ['English' 'Japanese' list];
            else
                list = {'English', 'Japanese'};
            end
            list = [list 'Custom...'];
        end               
        
        %------------------------------------------------------------------
        function isValid = validateUserInput(this)
            isValid = true;                       
            
            % check for empty directory output
            if isempty(this.OutputDir.String)
                msg   = vision.getMessage('vision:ocrTrainer:SessionEditBoxEmpty','output directory');
                title = vision.getMessage('vision:ocrTrainer:SessionEditBoxEmptyTitle');
                errordlg(msg,title,'modal');                
                isValid = false;
                return;
            end
                        
            isValid = isValid & ...
                vision.internal.ocr.tool.validateOutputDirectory(...
                this.OutputDir.String);         
                             
            isActive = strcmpi(this.CustomLanguageBox.Enable,'on') && ...
                strcmpi(this.CustomLanguageBox.Visible,'on');
            
            if isActive && isempty(this.CustomLanguageBox.String)
                msg   = vision.getMessage('vision:ocrTrainer:SessionEditBoxEmpty','custom language');
                title = vision.getMessage('vision:ocrTrainer:SessionEditBoxEmptyTitle');
                errordlg(msg,title,'modal');                
                isValid = false;
            end
            
            if isActive && ~isempty(this.CustomLanguageBox.String)
                [pathname, filename, ext] = fileparts(this.CustomLanguageBox.String);
            
                isValid = validateCustomLanguageFile(this, pathname, [filename ext]);
                if ~isValid
                    return
                end
            end
            
            % validate character set edit box
            isChecked = this.OCRCharacterSetCheckBox.Value;
            
            if isChecked                
                                
                try                    
                    this.OCRCharacterSet = eval(this.OCRCharacterSetEditBox.String);
                catch EX                    
                    msg   = vision.getMessage('vision:ocrTrainer:SessionCharsetEvalFailed', EX.message);
                    title = vision.getMessage('vision:ocrTrainer:SessionCharsetEvalFailedTitle');
                    errordlg(msg,title,'modal');
                    isValid = false;
                    return;
                end
                
                if isempty(this.OCRCharacterSet)
                    msg   = vision.getMessage('vision:ocrTrainer:SessionEditBoxEmpty','character set');
                    title = vision.getMessage('vision:ocrTrainer:SessionEditBoxEmptyTitle');
                    errordlg(msg,title,'modal');
                    isValid = false;  
                    return
                end    
                                
                if ~ischar(this.OCRCharacterSet)
                    msg   = vision.getMessage('vision:ocrTrainer:InvalidCharSet');
                    title = vision.getMessage('vision:ocrTrainer:SessionCharsetEvalFailedTitle');
                    errordlg(msg,title,'modal');
                    isValid = false;  
                end
                
            end            
        end
    end
    
    %----------------------------------------------------------------------
    % Output setting callbacks
    %----------------------------------------------------------------------
    methods
        
        function doModifyLanguage(this, varargin)
            
            % get user entered value, ignorning trailing white space.
            userLang = deblank(this.LanguageName.String);
            
            % Convert user input to valid identifier if needed.
            [lang, userInputModified] = matlab.lang.makeValidName(userLang);
            
            if userInputModified
                
                % update edit box with modified string
                this.LanguageName.String = lang; 
                
                % display message indicating user input was modified.
                title = vision.getMessage(...
                    'vision:ocrTrainer:InvalidLanguageTitle');                
                msg   = vision.getMessage(...
                    'vision:ocrTrainer:InvalidLanguage',userLang,lang);                
                dlg   = vision.internal.ocr.tool.MessageDialog(...
                    this.GroupName, title, msg);
                
                wait(dlg);
            end                        
            
        end
        
        %------------------------------------------------------------------
        function doModifyOutputDirectory(this, varargin)
            
            % get user entered value, ignorning trailing white space.
            dirname = deblank(this.OutputDir.String);
            
            updateOutputDirectory(this, dirname);
                 
        end
        
        %------------------------------------------------------------------
        function doChooseOutputDirectory(this, varargin)
            dirname = uigetdir(this.DefaultDirectory);
            if(dirname==0) % cancelled
                return;
            end
            
            updateOutputDirectory(this, dirname);            
        end
        
        %------------------------------------------------------------------
        function updateOutputDirectory(this, dirname)
            if isempty(dirname)
                return;
                % onOK all active edit boxes are checked. leaving this
                % uncheck allows users to click on browse button without
                % getting an error message.
            else                
                vision.internal.ocr.tool.validateOutputDirectory(dirname);
                                                 
                this.OutputDir.String = dirname;
            end
        end                                
    end       
    
    %----------------------------------------------------------------------
    % Labeling method callbacks
    %----------------------------------------------------------------------
    methods(Access = private)
          
        %------------------------------------------------------------------
        function doLabelingMethod(this, varargin)
            % radio button toggle
            selection = this.LabelingBtnGroup.SelectedObject;
            
            % enable/disable OCR options if for manual labeling
            switch selection.Tag
                case 'ManualLabel'
                    this.OCRLanguageLabel.Enable        = 'off';
                    this.OCRLanguageName.Enable         = 'off';                                                            
                    this.CustomLanguageBox.Enable       = 'off';                    
                    this.CustomLanguageBrowse.Enable    = 'off';
                    this.OCRCharacterSetCheckBox.Enable = 'off';
                    this.OCRCharacterSetEditBox.Enable  = 'off';
                    
                case 'AutoLabel'
                    this.OCRLanguageLabel.Enable        = 'on';
                    this.OCRLanguageName.Enable         = 'on';                                                                           
                    this.OCRCharacterSetCheckBox.Enable = 'on';
                    
                    this.doOCRLanguage(); % enable/disable correctly
                    
                    if this.OCRCharacterSetCheckBox.Value
                        this.OCRCharacterSetEditBox.Enable  = 'on';
                    else
                        this.OCRCharacterSetEditBox.Enable  = 'off';
                    end
            end
        end
                 
        %------------------------------------------------------------------
        function doOCRLanguage(this, varargin)
            % popupmenu 
            
            selection = this.OCRLanguageName.Value;
            lang = this.OCRLanguageName.String{selection};
                        
            % enable/disable custom edit box and button for Custom language
            if strcmp(lang, 'Custom...')
                 this.CustomLanguageBox.Enable    = 'on';    
                 this.CustomLanguageBrowse.Enable = 'on';
            else
                this.CustomLanguageBox.Enable    = 'off';    
                this.CustomLanguageBrowse.Enable = 'off';
            end
                
        end
        
        %------------------------------------------------------------------
        function doCharsetCheckbox(this, varargin)                        
            isChecked = this.OCRCharacterSetCheckBox.Value;
                        
            if isChecked
                this.OCRCharacterSetEditBox.Enable = 'on';
            else
                this.OCRCharacterSetEditBox.Enable = 'off';
            end
            
        end               
        
        %------------------------------------------------------------------
        function isValid = validateCustomLanguageFile(~, pathname, filename)
            isValid = true;
            
            if isempty(fullfile(pathname, filename))
                return;
                % Delay this error condition in case the user wants to push
                % on browse. onOK this box will be verified for empty.
            else
                               
                % check if file is .traineddata
                if isempty(strfind(filename, '.traineddata'))
                    msg   = vision.getMessage('vision:ocrTrainer:SessionInitCustomLangInvalid',filename);
                    title = vision.getMessage('vision:ocrTrainer:SessionInitCustomLangInvalidTitle');
                    errordlg(msg,title,'modal');                      
                    isValid = false;
                    return;
                end
                
                % check if file is in tessdata folder as required by OCR
                fullpath = fullfile(pathname,filename);
                idx = regexpi(fullpath,...
                    'tessdata[\/\\]+(\w+)\.traineddata$','start');
                
                if isempty(idx)
                    msg   = vision.getMessage('vision:ocrTrainer:SessionInitCustomLangTessdata',filename);
                    title = vision.getMessage('vision:ocrTrainer:SessionInitCustomLangTessdataTitle');
                    errordlg(msg,title,'modal');                    
                    isValid = false;
                end
            end
        end
        
        %------------------------------------------------------------------
        function doCustomBrowse(this, varargin)
            % custom browse button
            [filename, pathname] = uigetfile('*.traineddata', ...
                'Select Custom OCR Language Data File');
            
            if filename % is 0 if user presses cancel
               isValid = validateCustomLanguageFile(this, pathname, filename);
               if isValid
                    this.CustomLanguageBox.String = fullfile(pathname, filename);
               end
            else
                % user pressed cancel                
            end
        end
        
        %------------------------------------------------------------------
        function doCustomEditBox(this, varargin)
            % custom edit box
            [pathname, filename, ext] = fileparts(this.CustomLanguageBox.String);
            
            validateCustomLanguageFile(this, pathname, [filename ext]);
        end                
              
    end
    %----------------------------------------------------------------------
    % Add images callbacks
    %----------------------------------------------------------------------
    methods(Access = private)
        %------------------------------------------------------------------
        function doAddImages(this, varargin)
             
            [files, isUserCanceled] = imgetfile('MultiSelect', true);
            if isUserCanceled
                return;
            end
            
            if ~isempty(files)
               % populate listbox
                if strcmp(this.ImageList.String, ...
                        vision.getMessage('vision:ocrTrainer:AddImagesDefaultString'))
                    % no images yet, assign files.
                    this.ImageList.String = files;
                else
                    % images exist in list, only add unique ones.
                    uniqueImageFileNames = unique(...
                    [this.ImageList.String; files(:)]);
                
                    this.ImageList.String = uniqueImageFileNames;
                end
            end
            
        end
        
        %------------------------------------------------------------------
        function doRemoveImages(this, varargin)
            
            % get selected item from listbox
            selectedItem = this.ImageList.Value;
            
            if strcmp(this.ImageList.String,...
                    vision.getMessage('vision:ocrTrainer:AddImagesDefaultString'))
                return; % nothing to remove
            end
            
            % remove seleted item, making sure to keep selected item within
            % range of remaining list. When all files are removed, the "Add
            % images..." placeholder is inserted".
            files = this.ImageList.String;            
            files(selectedItem) = [];
            
            if isempty(files)
                selectedItem = 1;
                files = vision.getMessage('vision:ocrTrainer:AddImagesDefaultString');                
            else                
                selectedItem = min(selectedItem, numel(files));
            end
            this.ImageList.Value = selectedItem;
            this.ImageList.String = files;
            
        end                        
    end
    
end
