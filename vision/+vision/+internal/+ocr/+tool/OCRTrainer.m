% This class is for internal use only and may change in the future.

% OCRTrainer returns an instance of the ocr training app.

% Copyright 2015 The MathWorks, Inc.

classdef OCRTrainer < vision.internal.uitools.ToolStripApp        
    
    
    %----------------------------------------------------------------------
    % UI Components
    %----------------------------------------------------------------------
    properties        
        
        % Tabs
        TrainingTab 
        BoxEditTab
        TrainingImageTab
        
        % Data Browser
        ImageStrip
        TrainingImageStrip
        
        % App documents (a.k.a. displays)
        ImageDisplay
        BoxEditDisplay
        TrainingImageDisplay
        
        % Status bar
        StatusText
        
    end
    
    %----------------------------------------------------------------------
    % App properties that hold state.
    %----------------------------------------------------------------------
    properties
        
        % AxesTags - Contains tags for various displays.       
        AxesTags              
        
        % OpenSessionPath - Path used for opening a session
        OpenSessionPath
        
        % CurrentSelection - current selection in the data browswer
        CurrentSelection
        
        % CurrentBoxEditSelection - current selection in the box edit
        % display.
        CurrentBoxEditSelection
        
        % CurrentBoxEditImageSelection - current image being displayed in
        % the box edit display
        CurrentBoxEditImageSelection
        
        % CurrentBoxEditCharacterSelection - current character selected in
        % the data browswer. Actual character not the index, which is
        % stored in CurrentSelection.
        CurrentBoxEditCharacterSelection
        
        % TrainingImageStartIndex - starting index for processing newly
        % added images.
        TrainingImageStartIndex
                       
        % GiveFocusToEditBox - whether or not focus should be given to edit
        % box after drawing character montage.
        GiveFocusToEditBox;
        
        % CurrentTrainingImageSelection - current image selected in the
        % training image view. Tracks displayed image during when multiple
        % images are selected in the data browser.
        CurrentTrainingImageSelection
    end    
       
    %----------------------------------------------------------------------
    % Public methods
    %----------------------------------------------------------------------
    methods                               
        function this = OCRTrainer()
            
            [~, name] = fileparts(tempname);
            this.ToolGroup = ...
                toolpack.desktop.ToolGroup(name, 'OCR Trainer');                                               
            
            % Initialize tabs                        
            this.TrainingTab = ...
                vision.internal.ocr.tool.TrainingTab(this); 
            
            this.BoxEditTab = ...
                vision.internal.ocr.tool.BoxEditTab(this); 
            
            this.TrainingImageTab = ...
                vision.internal.ocr.tool.TrainingImageTab(this);
           
            
            add(this.ToolGroup, getToolTab(this.TrainingTab), 1);
            add(this.ToolGroup, getToolTab(this.BoxEditTab), 1);
            add(this.ToolGroup, getToolTab(this.TrainingImageTab), 1);
            
            % Initialize data browser
            this.displayInitialDataBrowserMessage(...
                vision.getMessage('vision:ocrTrainer:NewSessionFirstMsg'));                                        
            
            % Initialize Axes tags
            this.AxesTags.MainImage = 'TrainingImageAxes';
            
            this.SessionManager = vision.internal.uitools.SessionManager;
            this.SessionManager.AppName      = 'OCR Trainer';
            this.SessionManager.SessionField = 'ocrTrainingSession';
            this.SessionManager.SessionClass = 'vision.internal.ocr.tool.Session';
            
            % Initialize Session 
            this.Session = vision.internal.ocr.tool.Session;
            this.Session.OutputDirectory = pwd; 
            font = this.getFontByPlatform();
            this.Session.updateFont(font);
            
            % Initialize image strip
            configureImageStrip(this);   
            
             % handle closing of the group
            this.setClosingApprovalNeeded(true);
            addlistener(this.ToolGroup, 'GroupAction', ...
                @(es,ed)doClosingSession(this, es, ed));
            
            % manageToolInstances
            this.addToolInstance();
            
            % set the path for opening sessions to the current directory
            this.OpenSessionPath = pwd;
            
            this.CurrentSelection = -1;
            
            % setup app preferences
            vision.internal.ocr.tool.OCRTrainer.setupPreferences();
            
            % By default do not give focus to edit box. This flag is used
            % to trigger edit box focus when automatically moving to the
            % next char when the last box is labeled. All other times, edit
            % box focus is request manually.
            this.GiveFocusToEditBox = false;
        end                                         
                        
        %------------------------------------------------------------------
        % Instantiate ImageStrip and attach callbacks
        %------------------------------------------------------------------
        function configureImageStrip(this)
            this.ImageStrip = ...
                vision.internal.uitools.ImageStrip(...
                this.ToolGroup, this.Session);
            
            % Image selection callback
            this.ImageStrip.SelectionCallback = @this.doCharacterSelection;
            
            % Mouse press callback, for right-click, context menus, etc
            this.ImageStrip.MousePressedCallback = @this.doImageStripPopup;
            
            % Key press callback
            this.ImageStrip.KeyPressedCallback = @this.doImageStripKeyPress;    
        end
        
        %------------------------------------------------------------------
        % Instantiate ImageStrip and attach callbacks
        %------------------------------------------------------------------
        function configureTrainingImageStrip(this)
            
            % set the training image strip with a empty session. This image
            % strip is used to just display the added images, and uses a
            % separate session object for the main char view.
            session = vision.internal.ocr.tool.Session;
            
            % set remove mode for training image strip's image set.
            % The remove mode is required to support moving chars which
            % also use the same ImageStrip class.
            session.ImageSet.RemoveMode = 'remove';
            
            this.TrainingImageStrip = ...
                vision.internal.uitools.ImageStrip(...
                this.ToolGroup, session);
            
            % Image selection callback
            this.TrainingImageStrip.SelectionCallback = ...
                @this.doTrainingImageSelection;
            
            % Mouse press callback, for right-click, context menus, etc
            this.TrainingImageStrip.MousePressedCallback = ...
                @this.doTrainingImageStripPopup;
            
            % Key press callback
            this.TrainingImageStrip.KeyPressedCallback = ...
                @this.doTrainingImageStripKeyPress;    
        end     
        
        %------------------------------------------------------------------
        % Add shared status bar to app. status area is used to display
        % output directory.
        %------------------------------------------------------------------
        function configureStatusBar(this)
            md = com.mathworks.mlservices.MatlabDesktopServices.getDesktop;
            f = md.getFrameContainingGroup(this.getGroupName);
            
            % Create a new shared status bar
            sb = javaObjectEDT('com.mathworks.mwswing.MJStatusBar');
            javaMethodEDT('setSharedStatusBar', f, sb);
            
            % Add Java components to the status bar
            this.StatusText = javaObjectEDT('javax.swing.JLabel', '');
            
            lowerbevel = javax.swing.BorderFactory.createLoweredBevelBorder();
            
            javaMethodEDT('setBorder', this.StatusText, lowerbevel);
            
            sb.add(this.StatusText);
            
        end
        
        %------------------------------------------------------------------
        %  Gets the UI to the starting point, as if nothing has been loaded
        %------------------------------------------------------------------
        function resetAll(this)
            
            % reset the message in the data browser
            this.displayInitialDataBrowserMessage(...
                vision.getMessage('vision:ocrTrainer:NewSessionFirstMsg'));
            
            % wipe the visible figures
            this.ImageDisplay.wipeFigure();            
            
            % reset the session
            this.Session.reset();
            
            this.updateButtonStates();
            
            this.CurrentSelection = -1;
            this.TrainingImageStartIndex = [];
            
            this.setStatusText('');
            
            this.ToolGroup.Title = 'OCR Trainer';
            
        end
        
        %------------------------------------------------------------------
        % New session button callback
        %------------------------------------------------------------------
        function newSession(this)
            
            % First check if we need to save anything before wiping the
            % existing data
            isCanceled = this.processSessionSaving();
            if isCanceled
                return;
            end
            
            % Wipe the UI clean
            this.resetAll();
            
            % Update Button states
            this.updateButtonStates();            
                        
            % Launch session initialization dialog
            dlg = vision.internal.ocr.tool.SessionInitializationDlg(...
                this.getGroupName(), this.OpenSessionPath);
            
            wait(dlg);                        
            
            if ~dlg.IsCanceled
                this.Session.OutputDirectory = dlg.UserData.OutputDirectory;
                this.Session.OutputLanguage = dlg.UserData.LanguageName;
                this.Session.AutoLabel   = dlg.UserData.AutoLabel;
                this.Session.OCRLanguage = dlg.UserData.OCRLanguage;                                
                this.Session.OCRCharacterSet = dlg.UserData.CharacterSet;
                
                if ~isempty(dlg.UserData.Files)
                    addImagesToSession(this, dlg.UserData.Files)
                end
                                
                initializeNewSession(this);                                
                
            end
                
        end
        
        %------------------------------------------------------------------
        function initializeNewSession(this)
            % Update app title bar
            this.ToolGroup.Title = ...
                sprintf('OCR Trainer - %s',this.Session.OutputLanguage);
            
            configureStatusBar(this);
            
            % Update Status text
            this.setStatusText(...
                this.createStatusText(this.Session.OutputDirectory));
            
            this.Session.IsInitialized = true;
            this.Session.IsChanged = true;
            
            this.updateCanTrain();            
            
            this.updateButtonStates();
            
            if ~this.Session.hasAnyImages
                % update the browser message
                % Initialize data browser
                this.displayInitialDataBrowserMessage(...
                    vision.getMessage('vision:ocrTrainer:AddImagesFirstMsg'));
                
            end
        end
        %------------------------------------------------------------------
        function isCanceled = processSessionSaving(this)
            
            isCanceled = false;
            
            sessionChanged = this.Session.IsChanged;
            
            yes    = vision.getMessage('MATLAB:uistring:popupdialogs:Yes');
            no     = vision.getMessage('MATLAB:uistring:popupdialogs:No');
            cancel = vision.getMessage('MATLAB:uistring:popupdialogs:Cancel');
            
            if sessionChanged
                selection = this.askForSavingOfSession();
            else
                selection = no;
            end
            
            switch selection
                case yes
                    this.saveSession();
                case no
                    
                case cancel
                    isCanceled = true;
            end            
        end
        
        %------------------------------------------------------------------
        % Save session button callback
        %------------------------------------------------------------------
        function saveSession(this, fileName)
            % If we didn't save the session before, ask for the filename
            if nargin < 2
                if isempty(this.Session.FileName)
                    fileName = vision.internal.uitools.getSessionFilename(...
                        this.SessionManager.DefaultSessionFileName);
                    if isempty(fileName)
                        return;
                    end
                else
                    fileName = this.Session.FileName;
                end
            end
            
            this.SessionManager.saveSession(this.Session, fileName);
        end
        
        %------------------------------------------------------------------
        function saveSessionAs(this)
            fileName = vision.internal.uitools.getSessionFilename(...
                this.SessionManager.DefaultSessionFileName);
            if ~isempty(fileName)
                this.saveSession(fileName);
            end
        end        
        
        %------------------------------------------------------------------
        function doClosingSession(this, group, event)
            if strcmp(event.EventData.EventType, 'CLOSING') && ...
                    group.isClosingApprovalNeeded
                this.closingSession(group)
            end                        
        end     
               
        %------------------------------------------------------------------
        % Open session button callback
        %------------------------------------------------------------------
        function openSession(this)

            % First check if we need to save anything before we wipe
            % existing data
            isCanceled = this.processSessionSaving();
            if isCanceled
                return;
            end
            
            ocrFilesString = vision.getMessage('vision:ocrTrainer:SessionFiles');
            allFilesString = vision.getMessage('vision:uitools:AllFiles');
            selectFileTitle = vision.getMessage('vision:uitools:SelectFileTitle');
            
            [filename, pathname] = uigetfile( ...
                {'*.mat', [ocrFilesString,' (*.mat)']; ...
                '*.*', [allFilesString, ' (*.*)']}, ...
                selectFileTitle, this.OpenSessionPath);
            
            wasCanceled = isequal(filename,0) || isequal(pathname,0);
            if wasCanceled
                return;
            end            
            
            % preserve the last path for next time
            this.OpenSessionPath = pathname;            

            % Indicate that this is going to take some time
            setWaiting(this.ToolGroup, true);
             
            preserveExistingSession = false;
            
            this.processOpenSession(pathname, filename, preserveExistingSession)
                       
            setWaiting(this.ToolGroup, false);
        end
        
        %------------------------------------------------------------------
        % Add multiple sessions to current session button callback       
        %------------------------------------------------------------------
        function addToCurrentSession(this)
        
            trainingFilesString = vision.getMessage...
                ('vision:trainingtool:LabelingSessionFiles');
            allFilesString = vision.getMessage('vision:uitools:AllFiles');
            selectFileTitle = vision.getMessage('vision:uitools:SelectFileTitle');
            
            [filename, pathname] = uigetfile( ...
                {'*.mat', [trainingFilesString,' (*.mat)']; ...
                '*.*', [allFilesString, ' (*.*)']}, ...
                selectFileTitle, this.OpenSessionPath);
            
            wasCanceled = isequal(filename,0) || isequal(pathname,0);
            if wasCanceled
                return;
            else
                % preserve the last path for next time
                this.OpenSessionPath = pathname;
            end
            
            setWaiting(this.ToolGroup, true);
            
            preserveExistingSession = true;
            
            this.processOpenSession(pathname, filename, preserveExistingSession);            

            setWaiting(this.ToolGroup, false);
            
        end
        
        %------------------------------------------------------------------          
        function closingSession(this, group)
            
            sessionChanged = this.Session.IsChanged;
            
            yes    = vision.getMessage('MATLAB:uistring:popupdialogs:Yes');
            no     = vision.getMessage('MATLAB:uistring:popupdialogs:No');
            cancel = vision.getMessage('MATLAB:uistring:popupdialogs:Cancel');
            
            if sessionChanged
                selection = this.askForSavingOfSession();
            else
                selection = no;
            end
            
            switch selection
                case yes
                    this.saveSession();
                    group.approveClose
                    this.deleteToolInstance();
                case no,
                    group.approveClose
                    this.deleteToolInstance();
                case cancel
                    group.vetoClose
                otherwise
                    group.vetoClose
            end
            
        end
                
        %------------------------------------------------------------------
        function processOpenSession(this, pathname, filename,...
                preserveExistingSession)
                                    
            isNewSession = false;
            session = this.SessionManager.loadSession(pathname, filename);          
            if isempty(session)
                return;
            end
           
            % if opening a session into a fresh session, check if the
            % output directory is valid. ask user for new output directory
            % if it is not valid.
            if ~this.Session.IsInitialized && ...
                    ~this.Session.ImageSet.hasAnyImages() 
                
                isValid = vision.internal.ocr.tool.validateOutputDirectory(...
                    session.OutputDirectory, false);
                
                if ~isValid
                    dlg = vision.internal.ocr.tool. ...
                        OutputDirectoryDlg(this.getGroupName);
                    
                    wait(dlg);
                    
                    if dlg.IsCanceled
                        % abort open session
                        return;
                    else
                        session.OutputDirectory = dlg.OutputDirectory;
                    end
            
                end
            end
            
            if ~preserveExistingSession
                this.resetAll();  % Start fresh
                this.Session.FileName = [pathname, filename];
                isNewSession = true;                               
            end
            
            % If existing session has nothing, use loaded session.
            if ~this.Session.ImageSet.hasAnyImages()
  
                session.ImageSet.resetIcons(); % regenerate icons so text is re-rendered in correct locale.
                this.Session = session;                               
                this.ImageStrip.Session = this.Session; 
                
                if this.Session.ImageSet.hasAnyImages
                    % loaded session has images
                this.CurrentSelection = 1;
                else                    
                    % loaded session has no images.
                    this.CurrentSelection = -1;
                end
                   
                this.initializeNewSession();
             
            else
                                
                % cache selected char so it can be used after sessions are
                % merged to keep current selection.
                c = this.Session.ImageSet.getCharacterByIndex(...
                this.CurrentSelection);
                
                addedImages = this.Session.ImageSet.addImageStructToCurrentSession(...
                    session.ImageSet);
                
                % Return if no new images are added
                if ~addedImages
                    return;
                end
                
                this.Session.IsChanged = true;    
                this.Session.CanTrain  = true;
                
                % get the updated character position
                newPosition = this.Session.ImageSet.getCharacterIndex(c);
                
                % update current selection if new char is added
                % above the current selection as the index will be
                % different.
                if newPosition ~= this.CurrentSelection
                    this.CurrentSelection = newPosition;
                end
                               
            end
            
            if ~isempty(this.Session.ImageSet.ImageStruct)
                
                this.ImageStrip.Session = this.Session;
                
                this.ImageStrip.update(); % Restore image strip                                                                
                
                this.ImageStrip.setSelectedImageIndex(this.CurrentSelection);
                
                this.ImageStrip.makeSelectionVisible(this.CurrentSelection);
                
                this.ImageDisplay.EditBoxFont = this.Session.Font;
                
                this.drawCharacters();                                                           
                
                this.ImageDisplay.setFocusOnEditBox();
            end
                        
            this.updateButtonStates();
            if isNewSession
                this.Session.IsChanged = false;
            end
        end
        
        %------------------------------------------------------------------
        function show(this)
                                                
            this.removeViewTab();
            
            this.removeDocumentTabs();                                                    
            
            this.hideTab(this.BoxEditTab);
            
            this.hideTab(this.TrainingImageTab);                       
                   
            % Attach callback to quick bar help button. Must call before ToolGroup.open
            this.configureQuickAccessBarHelpButton(@this.doHelp);
            
            % open the tool
            this.ToolGroup.open();
            
            % create figures and lay them out the way we want them
            imageslib.internal.apputil.ScreenUtilities.setInitialToolPosition(this.ToolGroup.Name);
           
            % update button states to indicate the tool's current state
            this.updateButtonStates();
            
            % create default window layout
            this.createDefaultLayout();
            
            drawnow;
        end
        
        %------------------------------------------------------------------
        % This method is used for testing
        %------------------------------------------------------------------
        function setClosingApprovalNeeded(this, in)
            this.ToolGroup.setClosingApprovalNeeded(in);
        end
        
        %------------------------------------------------------------------
        % Creates and initializes an empty data browswer
        function displayInitialDataBrowserMessage(this, msg)
            
            % Use Java list to display the message
            label = javaObjectEDT('javax.swing.JLabel', ...
                {msg});
            
            label.setName('InitialDataBrowser');
            
            % Add JList to a panel container
            layout = java.awt.BorderLayout;
            panel = javaObjectEDT('javax.swing.JPanel', layout);
            
            % Use nice white background just like the rest of the tool
            panel.setBackground(java.awt.Color.white);
            
            % Add the panel to the tool group
            panel.add(label, java.awt.BorderLayout.NORTH);
            this.ToolGroup.setDataBrowser(panel);
            
            drawnow;
        end
        
        %------------------------------------------------------------------
        % Add images button callback
        %------------------------------------------------------------------
        function addImages(this)
            
            % Get image file names
            [files, isUserCanceled] = imgetfile('MultiSelect', true);
            if isUserCanceled
                return;
            end
            addImagesToSession(this, files);
            
        end
        
        %------------------------------------------------------------------
        % Add images to a session
        %------------------------------------------------------------------
        function addImagesToSession(this, files)
            
            % If a single file is selected convert the string into a cell
            % array before passing it to the Session object
            if ~isa(files, 'cell')
                files = {files};
            end
            
            try
                setWaiting(this.ToolGroup, true);                                      
                
                [startingIndex, addedFiles] = this.Session.ImageSet.addImagesToSession(files);
                
                if isempty(startingIndex)
                    setWaiting(this.ToolGroup, false);
                    dlg = warndlg(...
                        getString(message('vision:uitools:NoImagesAddedMessage')),...
                        getString(message('vision:uitools:NoImagesAddedTitle')),...
                        'modal');
                    uiwait(dlg);
                    return; % This would indicate presence of duplicates
                end
                
                this.Session.IsChanged = true;
                
                if ~this.Session.hasAnyImages()
                    setWaiting(this.ToolGroup, false);
                    errordlg('No valid image files found',...
                        vision.getMessage...
                        ('vision:uitools:LoadingImagesFailedTitle'), 'modal');
                    drawnow;
                    return;
                end  
                
                % set previous region filters as the default. app remembers
                % the last settings.
                if startingIndex > 1                   
                    values = this.Session.ImageSet.TextDetectionParams(startingIndex-1);
                else
                    values = this.Session.ImageSet.TextDetectionParams(startingIndex);
                end
                
                % cache the starting location of the training images
                this.TrainingImageStartIndex = startingIndex;
                                
                session = this.TrainingImageStrip.Session;    
                
                % The image set char view mode to false.
                this.Session.ImageSet.CharView = false;                                           
                session.ImageSet.CharView = false;
                
                % reset the training image strip so only the added images
                % are displayed.                
                session.reset();   
                                                
                switchToTrainingImageView(this);                                
                
                % add the images to the training strip session.
                startingIndex = session.ImageSet.addImagesToSession(addedFiles);                                                               
                session.ImageSet.setTextDetectionParams(values);
                
                this.TrainingImageStrip.update();
                
                % Update selection in the list. This triggers image
                % selection callback which renders the image display.
                this.TrainingImageStrip.setSelectedImageIndex(startingIndex)
                this.TrainingImageStrip.makeSelectionVisible(startingIndex)                                
                
                drawnow;
                                
                setWaiting(this.ToolGroup, false);
                                
                                
            catch loadingEx
                
                if ~isvalid(this)
                    % we already went through delete sequence; this can
                    % happen if the images did not yet load and someone
                    % already closed the tool
                    return;
                end
                
                setWaiting(this.ToolGroup, false); % if it errors out set the toolgroup busy to false
                
                errordlg(loadingEx.message,...
                    vision.getMessage('vision:uitools:LoadingImagesFailedTitle'),...
                    'modal');
                return;
            end
            
        end
        
        %------------------------------------------------------------------
        % Help button callback
        %------------------------------------------------------------------
        function doHelp(~,~,~)
           
            mapfile_location = fullfile(docroot,'toolbox',...
                'vision','vision.map');
            doc_tag = 'visionOCRTrainer';
                       
            helpview(mapfile_location, doc_tag);
        end
        
        %------------------------------------------------------------------
        function numAdded = boxAndLabelImages(this, startingIndex, params)

            ocrOptions.Language     = this.Session.OCRLanguage;
            ocrOptions.CharacterSet = this.Session.OCRCharacterSet;
            
            this.Session.ImageSet.addTextROI(params, startingIndex);
                    
            % total being added to session. images without text are removed
            % and not added to session during boxAndLabel
            total = this.Session.ImageSet.Count - startingIndex + 1;   
            
            imagesWithoutText = this.Session.ImageSet.boxAndLabelImages(...
                startingIndex, ocrOptions, this.Session.AutoLabel);
            
            numNoText = numel(imagesWithoutText);                            
            numAdded = total - numNoText;
            if numNoText > 0                                                
                dlg = vision.internal.ocr.tool.AutoLabelCompleteDlg(...
                    this.getGroupName, numNoText, total, imagesWithoutText);            
                wait(dlg);                                    
            end      
        end
        
        %------------------------------------------------------------------
        function autoBoxImages(this, startingIndex)
            this.Session.ImageSet.detectText(startingIndex);                          
        end
        
        %------------------------------------------------------------------
        % Run auto labeling using OCR. Displays diaglog box if any images
        % with no text are found.
        %------------------------------------------------------------------
        function autoLabel(this, startingIndex)  
                        
            imagesWithText = this.Session.ImageSet.autoLabel(startingIndex,this.Session.OCRLanguage);                       
                                    
            n = sum(imagesWithText);    
            
            % total being added to session
            total = this.Session.ImageSet.Count - startingIndex + 1;   
            
            if n ~= total                            
                dlg = vision.internal.ocr.tool.AutoLabelCompleteDlg(this.getGroupName,n,total);            
                wait(dlg);                                    
            end
        end
        
        %------------------------------------------------------------------
        function drawImages(this)
            
            if ~ishandle(this.ImageDisplay.Fig)
                return; % figure was destroyed
            end
            
            % Handle the case of wiping the data out
            if isempty(this.Session.ImageSet.ImageStruct)
                return; % this can happen in rapid testing
            end
            
            currentIndex = this.ImageStrip.getSelectedImageIndex();
            
            try % image can disappear from the disk
                [imageMatrix, imageLabel] = this.Session.ImageSet.getImages(currentIndex);                
            catch missingFileEx
                errordlg(missingFileEx.message,...
                    vision.getMessage...
                    ('vision:uitools:LoadingImagesFailedTitle'), 'modal');
                return;
            end
            
            % pass data to ImageDisplay for drawing
            bboxes    = this.Session.ImageSet.getBoxes(currentIndex);
            selected  = this.Session.ImageSet.getSelectedBoxes(currentIndex);
            charLabel = this.Session.ImageSet.getCharLabel(currentIndex, selected);
            this.ImageDisplay.draw(imageMatrix, imageLabel, currentIndex, bboxes, selected, charLabel);                         
            
        end % drawImages   
        
        %------------------------------------------------------------------
        function drawCharacters(this)
            
            if ~ishandle(this.ImageDisplay.Fig)
                return; % figure was destroyed
            end
            
            % Handle the case of wiping the data out
            if isempty(this.Session.ImageSet.CharMap)
                return; % this can happen in rapid testing
            end
            
            currentIndex = this.ImageStrip.getSelectedImageIndices();                        
            
            if numel(currentIndex) > 1
                return; % no-op in case of multi-select
            end
            
            label = this.Session.ImageSet.getCharacterByIndex(currentIndex);                     
            
            this.Session.ImageSet.resetSelectionMap(label);
            
            patches = this.Session.ImageSet.getPatches(label);
            
            selectedBox  = this.Session.ImageSet.getSelectedBoxes(currentIndex);
            
            this.ImageDisplay.drawCharacters(patches, currentIndex, selectedBox, label);   
            
            if this.GiveFocusToEditBox
                this.ImageDisplay.setFocusOnEditBox();
                
                % reset this to avoid giving focus to edit box when user
                % manually selects char from the browswer. This flag is in
                % place to allow auto char selection while labeling. When
                % the last char box is labeled we automatically go to the
                % next char in the browswer. In that situation this flag is
                % set so that the edit box can get focus.
                this.GiveFocusToEditBox = false; 
            else
                drawnow; 
                
                % give focus to the image strip.
                this.ImageStrip.setFocus();               
            end
            
        end % drawCharacters
             
        %------------------------------------------------------------------
        % Edit box delete callback executes whenever a user switches to
        % another image.
        function doEditBoxDeleteFcn(this, varargin)       
            % run the normal edit box callback to save the entered text.            
            this.doEditBoxCallback(varargin{:});
        end
        
        %------------------------------------------------------------------
        function doBoundingBoxMoveToUnknown(this, browser, ~)
       
            selected = browser.currentSelection;
            
            currChar = this.Session.ImageSet.getCharacterByIndex(...
                this.CurrentSelection);
            
            if strcmp(currChar, char(0))
                % No-op for unknown chars
                return;
            end
            
            % get number of character samples. This is the numel of the
            % actual chars that are labeled with the current char selected
            % in the browswer. 
            numBoxes = this.Session.ImageSet.getNumBoxes();
                       
            % number of samples that will be deleted after the remove
            % operation.
            numBoxesToRemove = numel(selected);
            
            if numBoxes == numBoxesToRemove
                
                % movel all char samples.                
                doMoveCharacterToUnknown(this);           
                
            else % individual char removal                                               
                            
                this.Session.ImageSet.setCharLabel(selected,char(0));
                
                this.Session.ImageSet.updateCharMap(selected, currChar); 
                
                this.Session.ImageSet.SelectionMap(selected,:) = [];
                
                % get num boxes after removal for computing next selection
                numBoxes = this.Session.ImageSet.getNumBoxes();
                
                if numBoxes > 0
                    next = max(selected) + 1; % next in list before removal
                    
                    next = next - numel(selected); % index after removal
                   
                    next = min(next, numBoxes); 
                    
                    next = max(1, next);
                    
                    % due to dynamic list update, get the char position.
                    whichChar = this.ImageStrip.getSelectedImageIndex();
                    
                    % Save box selection
                    this.Session.ImageSet.setSelectedBoxes(whichChar, next);
                    
                    [imageIndex, charIndex] = ...
                        this.Session.ImageSet.getImageIndex(next);
                    
                    % update label in edit box
                    label = this.Session.ImageSet.getCharLabel(imageIndex, charIndex);
                    this.ImageDisplay.updateEditBox(label);
                    
                    this.ImageDisplay.selectBox(next);
                end
            end
                        
            % get the updated character position
            newPosition = this.Session.ImageSet.getCharacterIndex(currChar); 
            
            if ~isempty(newPosition) % check if old char was removed.
                % update current selection if new char is added
                % above the current selection as the index will be
                % different.
                if newPosition ~= this.CurrentSelection
                    this.CurrentSelection = newPosition;
                end
            end
            
            % update the list
            this.ImageStrip.updateListItems(this.CurrentSelection);
            
            this.updateCanTrain();
            
            this.updateButtonStates();
            
        end
        
        %------------------------------------------------------------------
        function doBoundingBoxRemove(this, browser, ~)
       
            selected = browser.currentSelection;
            
            currChar = this.Session.ImageSet.getCharacterByIndex(...
                this.CurrentSelection);
            
            % get number of character samples. This is the numel of the
            % actual chars that are labeled with the current char selected
            % in the browswer. 
            numBoxes = this.Session.ImageSet.getNumBoxes();
                       
            % number of samples that will be deleted after the remove
            % operation.
            numBoxesToRemove = numel(selected);
            
            if numBoxes == numBoxesToRemove
                
                % removing all char samples. do full removal.
                doCharacterStripRemove(this);
                
            else % individual char removal                                               
               
                % remove selected char samples from the char map.
                for i = 1:numel(selected)
                    
                    bidx = selected(i);
                    
                    selectedChar = this.Session.ImageSet.getBoxLabel(bidx);
                                                            
                    % defer removal of selected char when it is the same as
                    % the current char selected in the browser. This
                    % prevents the char view from going away until the user
                    % selects another item in the browser.
                    if strcmp(selectedChar{1}, currChar)
                        shouldDeferRemoval = true;
                    else
                        shouldDeferRemoval = false;
                    end                              
                    
                    this.Session.ImageSet.removeCharSample(bidx,...
                        shouldDeferRemoval);
                                        
                end                               
                
                % finally update current selection map
                this.Session.ImageSet.SelectionMap(selected,:) = [];
                
                % get num boxes after removal for computing next selection
                numBoxes = this.Session.ImageSet.getNumBoxes();
                
                if numBoxes > 0
                    next = max(selected) + 1; % next in list before removal
                    
                    next = next - numel(selected); % index after removal
                   
                    next = min(next, numBoxes); 
                    
                    next = max(1, next);
                    
                    % due to dynamic list update, get the char position.
                    whichChar = this.ImageStrip.getSelectedImageIndex();
                    
                    % Save box selection
                    this.Session.ImageSet.setSelectedBoxes(whichChar, next);
                    
                    [imageIndex, charIndex] = ...
                        this.Session.ImageSet.getImageIndex(next);
                    
                    % update label in edit box
                    label = this.Session.ImageSet.getCharLabel(imageIndex, charIndex);
                    this.ImageDisplay.updateEditBox(label);
                    
                    this.ImageDisplay.selectBox(next);
                end
            end
            
            this.Session.CanTrain = true;
            
            % get the updated character position
            newPosition = this.Session.ImageSet.getCharacterIndex(currChar);
            
            % update current selection if new char is added
            % above the current selection as the index will be
            % different.
            if newPosition ~= this.CurrentSelection
                this.CurrentSelection = newPosition;
            end
            
            % update the list
            this.ImageStrip.updateListItems(newPosition);
                                                         
            this.updateButtonStates();
            
        end
               
        %------------------------------------------------------------------
        function doBoundingBoxOpenSelection(this, browser, event)
            % handles double click and return events
            this.doBoundingBoxSelection(browser, event);
           
            % due to dynamic list update, get the char position.
            whichChar = this.ImageStrip.getSelectedImageIndices();
            
            % now that box selection is taken care of, open box edit
            % view if user double clicks on a box.
            selected = this.Session.ImageSet.getSelectedBoxes(whichChar);
            if numel(selected) == 1
                doBoxEdit(this);
            end
            
        end
        
        %------------------------------------------------------------------
        function doBoundingBoxSelection(this, browser, ~)
            
            % due to dynamic list update, get the char position.
            whichChar = this.ImageStrip.getSelectedImageIndices();
            
            whichBox = browser.currentSelection;
           
            if isempty(whichBox)
                % this is empty when browser fires removal event.
                selection = this.Session.ImageSet.getSelectedBoxes(whichChar);
                this.ImageDisplay.selectBox(selection);
                return;
            end
            
            if numel(whichChar) > 1
                % multiple chars are selected in browser. Unselect them
                % before doing bounding box click.
                setSelectedImageIndex(this.ImageStrip, this.CurrentSelection);
                whichChar = this.CurrentSelection;
            end
            
            if numel(whichBox) > 1 % multi-select, ctrl or shift click
                
                disableEditBoxButton(this.TrainingTab);
                
                this.Session.ImageSet.setSelectedBoxes(whichChar, whichBox);
                
                this.ImageDisplay.setFocusOnEditBox();
                
            else % a single box is selected.                
                
                % due to dynamic list update, get the char position.
                whichChar = this.ImageStrip.getSelectedImageIndex();
                
                % Save box selection
                this.Session.ImageSet.setSelectedBoxes(whichChar, whichBox);
                
                [imageIndex, charIndex] = ...
                    this.Session.ImageSet.getImageIndex(whichBox);
                
                % update label in edit box
                label = this.Session.ImageSet.getCharLabel(imageIndex, charIndex);
                this.ImageDisplay.updateEditBox(label);
                
                
            end                                              
            
            numSelected = this.Session.ImageSet.getNumSelectedBoxes(whichChar);
            
            if numSelected == 1
                enableEditBoxButton(this.TrainingTab);
            else
                disableEditBoxButton(this.TrainingTab);
            end
            
        end
        
        %------------------------------------------------------------------
        % Updates the assigned char label only if the label is different
        % that the one currently assigned. If a label is updated, the
        % training button is activated.
        %------------------------------------------------------------------
        function updateLabelIfChanged(this, whichBox)
            
            if nargin == 1
                % get latest selections
                whichChar = this.ImageStrip.getSelectedImageIndex();
                
                whichBox = this.Session.ImageSet.getSelectedBoxes(whichChar);                
            end
            
            newLabel  = this.ImageDisplay.getEditBoxString();
            prevLabel = this.Session.ImageSet.getBoxLabel(whichBox);                      
            
            % Skip bad char labels. char(0) is used for unknowns. Skip
            % these in case the user just keeps clicking around the
            % unknowns. Space may appear if user deletes edit box content
            % then clicks on another box.
            if all(~strcmp(newLabel, {char(0), char(32)})) && ~isempty(newLabel)
                
                % update label for the box, only if it's changed
                if any(~strcmp(newLabel, prevLabel))
                    this.Session.ImageSet.setCharLabel(whichBox, newLabel);
                    this.Session.CanTrain = true;
                    
                    % get the currently selected character. In case the
                    % char list has to be updated, we will need the
                    % character to find the new index of the char in the
                    % list so that the same character is selected.
                    c = this.Session.ImageSet.getCharacterByIndex(this.CurrentSelection);
                    
                    % update the char map
                    updated = this.Session.ImageSet.updateCharMap(whichBox, c);
                    
                    if updated
                                         
                        % get the updated character position
                        newPosition = this.Session.ImageSet.getCharacterIndex(c);
                        
                        % update current selection if new char is added
                        % above the current selection as the index will be
                        % different.
                        if newPosition ~= this.CurrentSelection
                            this.CurrentSelection = newPosition;                                                        
                        end
                        
                        % update the list
                        this.ImageStrip.updateListItems(newPosition);
                     
                        this.updateCanTrain();
                    end
                  
                    this.updateButtonStates();
                   
                end
                
                this.updateBorderColorIfDifferent(whichBox, newLabel);
                
            end
        end
        
        %------------------------------------------------------------------
        function updateBorderColorIfDifferent(this, whichBox, label)
            
            if ~isempty(label) && ~any(isspace(label))
            currChar = ...
                this.Session.ImageSet.getCharacterByIndex(...
                this.CurrentSelection);
            
            if strcmp(currChar, label)
                color = uint8([255 255 255]);
            else
                color = uint8([170 170 170]);
            end
            
            
            this.ImageDisplay.ImageBrowser.setImageBorderColor(...
                whichBox, color);
            end
            
        end
        
        %------------------------------------------------------------------
        function selectBox(this, whichBox, whichChar)                                             
            
            this.ImageDisplay.selectBox(whichBox);
            
            % Save selection
            this.Session.ImageSet.selectBox(whichChar, whichBox);            
            
        end
        
        %------------------------------------------------------------------
        function unselectBox(this, whichBox, whichChar)                                             
            
            this.ImageDisplay.unselectBox(whichBox);
            
            % Save selection
            this.Session.ImageSet.unselectBox(whichChar, whichBox);            
            
        end
        
        %------------------------------------------------------------------
        function selectAllBoxes(this)            
            
            % due to dynamic list update, get the char position.
            whichChar = this.ImageStrip.getSelectedImageIndices();
            
            if numel(whichChar) > 1
                % multiple chars are selected in browser. Unselect them.
                % before doing bounding box click.
                setSelectedImageIndex(this.ImageStrip, this.CurrentSelection);               
            end    
            
            % Forward ctrl-a to ImageDisplay.            
            this.ImageDisplay.doKeyPress('a','control');
            
        end               
        
        %------------------------------------------------------------------
        function highlightNewBox(this, current, next, whichChar)
            
            this.ImageDisplay.unselectBox(current);                       
            
            this.ImageDisplay.selectBox(next);
            
            % Save selection            
            this.Session.ImageSet.setSelectedBoxes(whichChar, next);
                  
            [imageIndex, charIndex] = ...
                        this.Session.ImageSet.getImageIndex(next);       
            
            % update label in edit box
            label = this.Session.ImageSet.getCharLabel(imageIndex, charIndex);
            this.ImageDisplay.updateEditBox(label);
            
        end               
                
        %------------------------------------------------------------------
        function assignEditBoxStringToBox(this, editBox, whichChar)
            if ishandle(editBox) % could be deleted
                if numel(whichChar) > 1
                    % no-op for multiselected images.
                else
                              
                    whichBox = this.Session.ImageSet.getSelectedBoxes(whichChar);                                                                 
                    
                    updateLabelIfChanged(this, whichBox);                                            
                end
            end
        end
               
        %------------------------------------------------------------------
        function doEditBoxCallback(this, editBox, ~, ~)
                            
            
            isValid = this.validateLabel();
            if ~isValid
                return;
            end
            
            % dynamic list update during assignment may have modified char
            % position. get a fresh reading.
            whichChar = this.ImageStrip.getSelectedImageIndex();
            
            % move to the next box in reading order.                        
            current = this.Session.ImageSet.getSelectedBoxes(whichChar);
            
            numBoxes = this.Session.ImageSet.getNumBoxes();
            
            if numel(current) == 1 % only if single select
                                                        
                if current == numBoxes 
                    % last char box labeled. move to next char in browser.
                    
                    assignEditBoxStringToBox(this, editBox, whichChar);
                    
                    this.autoSwitchToNextChar();
                                        
                else                
 
                    updateLabelIfChanged(this, current);      
         
                    next = this.getNextBox(current);                                                                                
                    
                    % update border color if new box label is different
                    % than the current browser selection.
                    newLabel  = this.ImageDisplay.getEditBoxString();                   
                    this.updateBorderColorIfDifferent(current, newLabel);
                                       
                    % update the display
                    this.ImageDisplay.selectBox(next);
                end
            else
                
                assignEditBoxStringToBox(this, editBox, whichChar);
                
                if numBoxes == numel(current)
                    % doing select all assignment, then move to next char
                    % in browser.
                    
                    this.autoSwitchToNextChar();
                end
                
            end
                       
        end
        
        %------------------------------------------------------------------
        function isValid = validateLabel(this)
            % Label must be a single char
            
            str = this.ImageDisplay.getEditBoxString();
            
            % check length of string if ascii. unicode strings can have
            % more than one char.
            isAscii = ~isempty(str) && str(1) <= 127;
            
            if isempty(str) || (numel(str) ~= 1 && isAscii) || any(isspace(str))
                msg   = vision.getMessage('vision:ocrTrainer:BoxLabelError');
                title = vision.getMessage('vision:ocrTrainer:BoxLabelErrorTitle');
                errordlg(msg,title,'modal');
                isValid = false;
            else
                isValid = true;
            end
        end
        
        %------------------------------------------------------------------
        function autoSwitchToNextChar(this)
            % set the flag to give the edit box focus once the next
            % char is selected. Without this it is not possible to
            % request focus from this callback. It must be done in
            % the drawCharacters callback.
            this.GiveFocusToEditBox = true;
            
            % go to next char in browser
            this.ImageStrip.changeImage(1);
        end
        
        %------------------------------------------------------------------
        % Returns the next box selected given the current selection. Try to
        % look forward for the next box to select (carefully skipping over
        % already deleted boxes. If none are found look backward for next
        % box. There should always be one left.
        %------------------------------------------------------------------        
        function next = getNextBox(this, currentSelection)                        
            
            numBoxes = this.Session.ImageSet.getNumBoxes();
            
            % Try selecting next box.
            next = max(currentSelection) + 1; % select next box                            
            next = min(next, numBoxes);
            
        end
        
        %------------------------------------------------------------------
        function next = getPreviousBox(~, currentSelection)
            
            % Try selecting previous box.
            next = min(currentSelection) - 1; % select next box
            next = max(next, 1);
                       
        end
            
        %------------------------------------------------------------------        
        function doEditBoxKeyPressedFcn(this, varargin)
            
            keyEvent = varargin{2};
           
            isCtrl = keyEvent.getModifiers() == keyEvent.CTRL_MASK;
            
            % REMOVE CTRL-A with edit box focus should select all boxes.
            if isCtrl && keyEvent.getKeyCode == keyEvent.VK_A                
                selectAllBoxes(this);                 
            end   
            
            isShift =  keyEvent.getModifiers == keyEvent.SHIFT_MASK;
            
            if isShift && isCtrl
                % no action 
                return;
            end
            
            modifier = '';
            
            if isShift
                modifier = 'shift';
            end
            
            if isCtrl
                modifier = 'control';
            end                                        
            
            switch keyEvent.getKeyCode
                
                case keyEvent.VK_UP
                    this.ImageDisplay.doKeyPress('uparrow', modifier);
                    
                case keyEvent.VK_DOWN
                    this.ImageDisplay.doKeyPress('downarrow', modifier);
                    
                case keyEvent.VK_LEFT
                    this.ImageDisplay.doKeyPress('leftarrow', modifier);
                    
                case keyEvent.VK_RIGHT
                    this.ImageDisplay.doKeyPress('rightarrow', modifier);
                    
                case keyEvent.VK_PAGE_DOWN
                    doPageDown(this);
                    
                case keyEvent.VK_PAGE_UP
                    doPageUp(this);
                    
                otherwise
                    % check text length. keep only first ASCII char
                    tfield = varargin{3};
                    txt = char(tfield.getText());
                    multipleAscii = numel(txt) > 1 && txt(1) <= 127;    
                  
                    if multipleAscii
                        % only keep first ascii char
                        tfield.setText(txt(1));
                    elseif isempty(deblank(txt));
                        % zero out strings that are ''
                        tfield.setText('');
                    end
            end
           

        end
        
        %------------------------------------------------------------------
        function doPageUp(this)
            updateLabelIfChanged(this);
            this.GiveFocusToEditBox = true;
            this.ImageStrip.changeImage(-1);
        end
        
        %------------------------------------------------------------------
        function doPageDown(this)
            updateLabelIfChanged(this);
            this.GiveFocusToEditBox = true;
            this.ImageStrip.changeImage(1);
        end
        
        %------------------------------------------------------------------
        function setStatusText(this, str)                                                                                  
            if ~isempty(this.StatusText)
                if isempty(str)
                    javaMethodEDT('setVisible', this.StatusText, false);
                else
                    this.StatusText.setText({str});
                end
            end
        end

        %------------------------------------------------------------------
        function str = createStatusText(this,str)
            str = vision.getMessage(...
                    'vision:ocrTrainer:OutputDirectory',...
                    fullfile(str, this.Session.OutputLanguage));
        end
                    
        %------------------------------------------------------------------
        function createDefaultLayout(this)
            % create all the required figures
            
            % char labeling view
            configureImageDisplay(this);
            
            this.addFigure(this.ImageDisplay.Fig);                        
                        
            makeFigureVisible(this.ImageDisplay);
                        
            % box editing view
            configureBoxEditDisplay(this);
            
            this.addFigure(this.BoxEditDisplay.Fig);
            
            makeFigureInvisible(this.BoxEditDisplay);
                        
            % training image view
            configureTrainingImageStrip(this);
            
            configureTrainingImageDisplay(this);
            
            this.addFigure(this.TrainingImageDisplay.Fig);
            
            makeFigureInvisible(this.TrainingImageDisplay);
            
        end
            
        %------------------------------------------------------------------
        function configureImageDisplay(this)
            this.ImageDisplay = vision.internal.ocr.tool.ImageDisplay();
            
            % attach callbacks
            this.ImageDisplay.KeyPressFcn         = @this.doImageFigureKeyPress;
            this.ImageDisplay.MouseButtonDownFcn  = @this.imageClick;
            this.ImageDisplay.EditBoxCallbackFcn  = @this.doEditBoxCallback;
            this.ImageDisplay.EditBoxDeleteFcn    = @this.doEditBoxDeleteFcn;            
            this.ImageDisplay.EditBoxKeyPressedFcn= @this.doEditBoxKeyPressedFcn;
            this.ImageDisplay.SelectionChangeFcn  = @this.doBoundingBoxSelection;  
            this.ImageDisplay.OpenSelectionFcn    = @this.doBoundingBoxOpenSelection;            
            this.ImageDisplay.RemoveSelectionFcn  = @this.doBoundingBoxMoveToUnknown;           
            
            % set the font for the edit box
            this.ImageDisplay.EditBoxFont = this.Session.Font;
        end
        
         %------------------------------------------------------------------
        function configureBoxEditDisplay(this)
            this.BoxEditDisplay = vision.internal.ocr.tool.BoxEditDisplay();
            
            % attach callbacks
            this.BoxEditDisplay.KeyPressFcn              = @this.doBoxEditFigureKeyPress;            
            this.BoxEditDisplay.BoundingBoxButtonDownFcn = @this.doBoxEditClick;   
            this.BoxEditDisplay.NewPositionCallbackFcn   = @this.doBoxEditROINewPosition;
            this.BoxEditDisplay.MouseButtonDownFcn       = @this.doBoxEditAddROI;
        end
        
         %------------------------------------------------------------------
        function configureTrainingImageDisplay(this)
            this.TrainingImageDisplay = vision.internal.ocr.tool.TrainingImageDisplay();
            
            % attach callbacks
            this.TrainingImageDisplay.KeyPressFcn         = @this.doTrainingImageKeyPress;
            this.TrainingImageDisplay.MouseButtonDownFcn  = @this.doTrainingImageAddROI;          
            this.TrainingImageDisplay.ROINewPositionFcn   = @this.doTrainingImageROINewPosition;
            this.TrainingImageDisplay.RemoveROIFcn        = @this.doTrainingImageRemoveROI;
            this.TrainingImageDisplay.MouseOverFcn        = @this.doTrainingImageMouseOver;
        end
        
        %------------------------------------------------------------------
        function hideDataBrowser(this)            
            md = com.mathworks.mlservices.MatlabDesktopServices.getDesktop;
            md.hideClient('DataBrowserContainer', this.getGroupName());
        end
        
        %------------------------------------------------------------------
        function showDataBrowser(this)            
            md = com.mathworks.mlservices.MatlabDesktopServices.getDesktop;
            md.showClient('DataBrowserContainer', this.getGroupName());
        end
        
        %------------------------------------------------------------------
        % Control the updating of the button states depending on the
        % current state of the session.
        %------------------------------------------------------------------
        function updateButtonStates(this)            
            % Enable the training button only if images are loaded.      
            
            if this.Session.IsInitialized
                enableAddImagesButton(this.TrainingTab);
                enableSaveButton(this.TrainingTab);
                if this.Session.hasAnyImages()
                    enableEditBoxButton(this.TrainingTab);
                    enableSettingsButton(this.TrainingTab);
                else
                    disableEditBoxButton(this.TrainingTab);
                    disableSettingsButton(this.TrainingTab);                    
                end
            else
                disableAddImagesButton(this.TrainingTab);
                disableSaveButton(this.TrainingTab);
                disableEditBoxButton(this.TrainingTab);
                disableSettingsButton(this.TrainingTab);
            end
            
            if this.Session.CanTrain
                enableTrainingButton(this.TrainingTab);
            else                             
                disableTrainingButton(this.TrainingTab);               
            end        
            
            if this.Session.IsTrained
                enableEvaluateButton(this.TrainingTab);
            else
                disableEvaluateButton(this.TrainingTab);
            end
        end
        
        %------------------------------------------------------------------
        function updateFont(this, font)            
            this.Session.updateFont(font);
            this.ImageDisplay.updateFont(font);
        end
        
        %------------------------------------------------------------------
        function deleteToolInstance(this)
            imageslib.internal.apputil.manageToolInstances('remove',...
                'ocrTrainer', this);
            delete(this);
        end
        
        %------------------------------------------------------------------
        function addToolInstance(this)
            imageslib.internal.apputil.manageToolInstances('add',...
                'ocrTrainer', this);           
        end
        
    end
      
    %======================================================================
    % Static public methods
    %======================================================================
    methods (Static, Hidden)                
        
        %------------------------------------------------------------------
        function deleteAllTools
            imageslib.internal.apputil.manageToolInstances('deleteAll',...
                'ocrTrainer');
        end
        
        %------------------------------------------------------------------
        function deleteAllToolsForce
            imageslib.internal.apputil.manageToolInstances('deleteAllForce',...
                'ocrTrainer');
        end
        
        %------------------------------------------------------------------
        function setupPreferences()
            
            if ~ispref('cvstOCRTrainer', 'showTrainingImagesDialog')
                addpref('cvstOCRTrainer','showTrainingImagesDialog', true);
            end
                       
        end
        
        %------------------------------------------------------------------
        function removePreferences
            
            if ispref('cvstOCRTrainer')
                
                rmpref('cvstOCRTrainer');
            end
        end
        
        %------------------------------------------------------------------
        function setTrainingImagesDialogPref(value)
            
            vision.internal.ocr.tool.OCRTrainer.setPref(...
                'showTrainingImagesDialog', value);
        end
        
        %------------------------------------------------------------------
        function setPref(whichOne, value)
            if ispref('cvstOCRTrainer', whichOne)
                setpref('cvstOCRTrainer', whichOne, value);
            end
        end
        
        %------------------------------------------------------------------
        function value = getShowDialogPref(whichOne)
            if ispref('cvstOCRTrainer',whichOne)
                value = getpref('cvstOCRTrainer',whichOne);
            else
                value = true;
            end
        end
        
        %------------------------------------------------------------------
        function value = showTrainingImagesDialog()
            value = vision.internal.ocr.tool.OCRTrainer.getShowDialogPref(...
                'showTrainingImagesDialog');
        end
        
        %------------------------------------------------------------------
        function resetPreferences
            % by default, show the training images dialog
            vision.internal.ocr.tool.OCRTrainer.setPref(...
                'showTrainingImagesDialog', true);                            
        end
        
        %------------------------------------------------------------------
        function wasCanceled = confirmCharacterRemoval(itemsToRemove)
            
            N = numel(itemsToRemove);
           
            cancel = getString(message('MATLAB:uistring:popupdialogs:Cancel')); 
            if N > 1
                choice = questdlg(vision.getMessage('vision:ocrTrainer:RemoveCharactersPrompt'),...
                    vision.getMessage('vision:ocrTrainer:RemoveCharactersTitle'),...
                    vision.getMessage('vision:uitools:Remove'), cancel, cancel);
            else
                choice = questdlg(vision.getMessage('vision:ocrTrainer:RemoveCharacterPrompt'),...
                    vision.getMessage('vision:ocrTrainer:RemoveCharacterTitle'),...
                    vision.getMessage('vision:uitools:Remove'), cancel, cancel);
            end
            
            % Handle of the dialog is destroyed by the user
            % closing the dialog or the user pressed cancel
            wasCanceled = isempty(choice) || strcmp(choice, cancel);
            
        end
        
        %------------------------------------------------------------------
        function font = getFontByPlatform()
            if ispc
                font = 'Arial Unicode MS';
            elseif ismac
                font = 'Arial Unicode';
            else
                font = 'DejaVuSans';
            end
        end
    end
    
    %======================================================================
    % Image strip related callback methods
    %======================================================================
    methods(Access = protected)
        %--------------------------------------------------------------
        function doImageStripPopup(this, ~,hData)
            
            if hData.getButton == 3 % right-click
                
                % Get the list widget
                list = hData.getSource;
                
                % Get current mouse location
                point = hData.getPoint();
                
                % Figure out the index of the board immediately under
                % the mouse button
                jIdx = list.locationToIndex(point); % 0-based java idx
                
                idx = jIdx + 1;
                
                % Figure out the index list in the case of multi-select
                idxMultiselect = this.ImageStrip.getSelectedImageIndices();
                
                if ~any(idx == idxMultiselect)
                    % If the mouse is not over the selected area;
                    % select whatever is under the mouse and override
                    % the multi-selection index
                    this.ImageStrip.setSelectedImageIndex(idx);                   
                end
                
                % Create a popup
                
                % Removing Images
                item = vision.getMessage('vision:ocrTrainer:MoveToUnknown');
                itemName = 'moveToUnknown';
                
                menuItemRemove = javaObjectEDT('javax.swing.JMenuItem',...
                    item);
                menuItemRemove.setName(itemName);
                
                % There is no keyboard accelerator associated with the move
                % action.
                               
                removeActionListener = addlistener(menuItemRemove,'Action',...
                        @this.doMoveCharacterToUnknown); % main popup callback
                    
                % Prevent it from going out of scope, add to Misc struct.
                this.ImageStrip.Misc.PopupActionListener = removeActionListener;
                
                jmenu = javaObjectEDT('javax.swing.JPopupMenu');
                
                jmenu.add(menuItemRemove);
                
                % Display the popup
                jmenu.show(list, point.x, point.y);
                jmenu.repaint;
                
            end
        end               
        
        %
        function doMoveCharacterToUnknown(this, varargin)
            charsToRemove = this.ImageStrip.getSelectedImageIndices();
            if any(charsToRemove == this.CurrentSelection)
                this.CurrentSelection = -1;            
            end                                                             
            
            % The RemoveMode is set to 'move' to conditionally call the
            % move operation instead of the remove operation from
            % ImageSet.removeItem. The call to
            % ImageStrip.removeSelectedItems below, will invoke
            % ImageSet.removeItem.
            this.Session.ImageSet.RemoveMode = 'move';
            
            % call image strip remove, but do not show dialog because we
            % have shown a custom one.
            showConfirmationDialog = false;
            this.ImageStrip.removeSelectedItems(showConfirmationDialog);                          
                 
            this.updateCanTrain();
                       
            this.updateButtonStates();  
                        
            this.Session.ImageSet.RemoveMode = 'remove';
        end
        
        %------------------------------------------------------------------
        % Remove images from training image strip and the session image
        % set.
        %------------------------------------------------------------------
        function doTrainingImagePopupRemove(this, varargin)
            
            strip = this.TrainingImageStrip;
            
            selected = strip.getSelectedImageIndices();
            
            % remove from training image strip. pops up confirmation dialog
            wasCanceled = strip.removeSelectedItems();
            
            if ~wasCanceled
                % remove images from main session
                
                numImages = this.Session.ImageSet.Count;
                
                addedImageIndices = this.TrainingImageStartIndex:numImages;
                
                this.CurrentTrainingImageSelection = -1; % force redraw
                
                this.Session.ImageSet.removeItem(addedImageIndices(selected));
                                
            end
            
            if ~strip.Session.hasAnyItems
                % reset the training view session
                this.TrainingImageDisplay.wipeFigure();
                
                strip.Session.reset();
                
                % nothing left close the training view and go back to main
                % session. 
                doTrainingImageClose(this);
                         
            end
                       
        end
        
        %------------------------------------------------------------------
        function doCharacterStripRemoveWithConfirm(this, varargin)
             % Confirm character removal
                wasCanceled = ...
                    vision.internal.ocr.tool.OCRTrainer. ...
                    confirmCharacterRemoval(1);
                
                if wasCanceled
                    return;
                end
                
                this.doCharacterStripRemove(varargin{:});
        end
        
        %------------------------------------------------------------------
        function doCharacterStripRemove(this,varargin)                               
            
            charsToRemove = this.ImageStrip.getSelectedImageIndices();
            if any(charsToRemove == this.CurrentSelection)
                this.CurrentSelection = -1; % force redraw
            end                        
            
            % call image strip remove, but do not show dialog because we
            % have shown a custom one.
            showConfirmationDialog = false;
            this.ImageStrip.removeSelectedItems(showConfirmationDialog);
                        
            if ~this.Session.hasAnyItems
                % reset the message in the data browser                
                this.resetAll();                
            end
        end
                
        %------------------------------------------------------------------
        % Responds to the image strip key press callback.
        %------------------------------------------------------------------
        function doImageStripKeyPress(this, ~, eventData)
            
            if eventData.getKeyCode == eventData.VK_DELETE
                
               doCharacterStripRemoveWithConfirm(this);
                
            end
            
        end        
        
        %------------------------------------------------------------------
        % Character selection callback. Show character montage for selected
        % character.
        %------------------------------------------------------------------
        function doCharacterSelection(this, ~, ~) 
           
            selection = this.ImageStrip.getSelectedImageIndices();
           
            isSingleSelection = numel(selection) == 1;                        
            
            % enable box edit button on if single char is selected in
            % browswer and only 1 box is selected in current montage.
            if isSingleSelection                    
                if this.Session.ImageSet.getNumSelectedBoxes(selection) == 1                   
                    enableEditBoxButton(this.TrainingTab);
                else
                    disableEditBoxButton(this.TrainingTab);
                end
            else
                disableEditBoxButton(this.TrainingTab);
            end
            
            % Only update char view if actually switching to another
            % character. Dynamic update of the image strip invokes this
            % callback and we do not want the currect char montage to be
            % destroyed unless the user has picked another character to
            % view.
            if isSingleSelection && selection ~= this.CurrentSelection
                
                % cache previous selection
                previous = this.CurrentSelection;
                
                % update current selection
                this.CurrentSelection = selection;
                
                currChar = ...
                    this.Session.ImageSet.getCharacterByIndex(...
                    this.CurrentSelection);
                
                if ishandle(this.ImageDisplay.Fig)
                    wipeFigure(this.ImageDisplay);
                                        
                    % perform deferred work
                    updated = this.Session.ImageSet.removeDeffered(previous); 
                    
                    this.updateCanTrain();
                    
                    % get the updated character position
                    newPosition = ...
                        this.Session.ImageSet.getCharacterIndex(currChar);
                    
                    % update current selection if new char is added
                    % above the current selection as the index will be
                    % different.
                    if newPosition ~= this.CurrentSelection
                        this.CurrentSelection = newPosition;
                    end
                    
                    if updated
                        this.ImageStrip.updateListItems(newPosition);
                    end           
                   
                    this.drawCharacters();
                end
            end
        end
    end
    
    %======================================================================
    % Callback methods for ocr training
    %======================================================================
    methods
        
        function doTraining(this)            
            
            lang = this.Session.OutputLanguage;
            dest = this.Session.OutputDirectory;
            
            % check whether previous training results exist. If they do,
            % ask user if they want to overwrite.
            outdir = fullfile(dest,lang);
            traineddataFile = fullfile(outdir,'tessdata',[lang '.traineddata']);
            
            if isdir(outdir) && exist(traineddataFile,'file')
                
                yes = vision.getMessage('MATLAB:uistring:popupdialogs:Yes');
                no  = vision.getMessage('MATLAB:uistring:popupdialogs:No');
                
                title    = vision.getMessage('vision:ocrTrainer:OverWriteTitle');
                question = vision.getMessage(...
                    'vision:ocrTrainer:OverWriteQuestion',...
                    [lang '.traineddata']);
                
                userChoice = questdlg(question, title, yes, no, no);
                
                if strcmpi(userChoice,yes)
                    delete(traineddataFile);                                 
                else
                    return;
                end
            end
            
            % check if training images exist on disk. If not, abort
            % training. 
            trainingImages = {this.Session.ImageSet.ImageStruct(:).imageFilename};
            
            validImages = cellfun(@(x) (exist(x,'file')==2), trainingImages);
            if ~all(validImages)
                
                invalidImages = trainingImages(~validImages);
                list = sprintf('%s\n',invalidImages{:});    
                msg = vision.getMessage('vision:ocrTrainer:MissingTrainingImages',list);
                title = vision.getMessage('vision:ocrTrainer:MissingTrainingImagesTitle');               
                errordlg(msg,title,'modal');
                return;                    
                
            end
            
            [imgSet, bboxData] = this.Session.getTrainingData();
            
            %--------------------------------------------------------------
            function out = localFindText(in,params)
                % second output is segmented text map. 
                [~, out] = this.Session.ImageSet.findText(in,params);
                out = im2uint8(out); % convert to non-logical for tesseract.
            end
                        
            imgSet.CustomFcn = @(x,y)localFindText(x,y);
            
            setWaiting(this.ToolGroup, true);
            
            % Call training routine. 
            try
                status = vision.internal.ocr.trainOCR(lang, imgSet, bboxData, ...
                    'OutputDirectory',dest, 'DisplayWaitbar', true);
                
            catch trainingException
                
                % catch all errors
               
                if string(trainingException(1).message).contains('NULL clusterer')
                    errordlg(...
                        vision.getMessage('vision:ocrTrainer:NullCluster'),...
                        vision.getMessage...
                        ('vision:ocrTrainer:TrainingError'), 'modal');
                else
                    
                    errordlg(trainingException.message,...
                        vision.getMessage...
                        ('vision:ocrTrainer:TrainingError'), 'modal');
                end
                setWaiting(this.ToolGroup, false);
                return;
            end                        
            
            setWaiting(this.ToolGroup, false);
            
            this.Session.CanTrain  = false;
            
            this.TrainingTab.setTrainingButtonToolTip(...
                'vision:ocrTrainer:TrainButtonToolTipTrained');
            
            this.Session.IsTrained = true;
            
            this.updateButtonStates();
            
            outputDir = fullfile(this.Session.OutputDirectory,...
                this.Session.OutputLanguage);
            
            % Show training complete dialog            
            if isempty(status.failedImages)
                dlg = vision.internal.ocr.tool.TrainingCompleteDlg(...
                    this.getGroupName(), this.Session.OutputLanguage, outputDir);
            else
                dlg =  vision.internal.ocr.tool.TrainingCompleteWithErrorsDlg(...
                    this.getGroupName(), this.Session.OutputLanguage,...
                    outputDir, status);
            end
            
            wait(dlg);                        
        end
        
        %------------------------------------------------------------------
        function session = getSession(this)
            session = this.Session;
        end
    
    end
        
    %======================================================================
    % Callback methods for training image view
    %======================================================================
    methods
        
        %------------------------------------------------------------------
        function doTrainingImageSelection(this, varargin)
            
            % disable region filter listeners to avoid double updates.
            this.TrainingImageTab.disableRegionFilterListener();      
                        
            reenableListener = onCleanup(...
                @()this.TrainingImageTab.enableRegionFilterListener());
            
            if ~ishandle(this.TrainingImageDisplay.Fig)
                return;
            end
            
            % Handle the case of wiping the data out
            if isempty(this.TrainingImageStrip.Session.ImageSet.ImageStruct)
                return; % this can happen in rapid testing
            end
                                           
            currentIndex = this.TrainingImageStrip.getSelectedImageIndices();
            
            if isempty(currentIndex) || numel(currentIndex) > 1 
                this.TrainingImageDisplay.resetPointerBehavior();
                return; % don't draw for multiselect
            end   
            
            if this.CurrentTrainingImageSelection == currentIndex
                % do not draw.
                return                
            else
                this.CurrentTrainingImageSelection = currentIndex; 
            end
            
            wipeFigure(this.TrainingImageDisplay);
            
            try % image can disappear from the disk
                I = ...
                    this.TrainingImageStrip.Session.ImageSet.getImages(currentIndex);
                
                [~, BW] = this.TrainingImageStrip.Session.ImageSet.detectTextInImage(currentIndex);                               
                
            catch missingFileEx
                errordlg(missingFileEx.message,...
                    vision.getMessage...
                    ('vision:uitools:LoadingImagesFailedTitle'), 'modal');
                return;
            end            
            
            filterParams = this.TrainingImageStrip.Session.ImageSet.TextDetectionParams(currentIndex);
            
            % update the region filter values. need to disable listener
            % before to allow for drawing.
            
            this.TrainingImageTab.setRegionFilterValues(filterParams);
            
            
            roi = filterParams.ROI;
            
            this.TrainingImageDisplay.draw(I, BW, roi);
            
            % Give image strip focus to help keyboard access
            this.TrainingImageStrip.setFocus();
                        
            drawnow;
                        
        end           
        
        %------------------------------------------------------------------
        function doTrainingImageRemoveROI(this, ~, ~)
            currentIndex = this.CurrentTrainingImageSelection;                  
            
            delete(this.TrainingImageDisplay.ROI);
            
            this.TrainingImageStrip.Session.ImageSet.TextDetectionParams(currentIndex).ROI = [];
            
            [~,BW] = ...
                this.TrainingImageStrip.Session.ImageSet.detectTextInImage(currentIndex);
            
            this.TrainingImageDisplay.updateDisplay(BW);
        end
        
        %------------------------------------------------------------------
        function doTrainingImageMouseOver(this, mode)
            md = com.mathworks.mlservices.MatlabDesktopServices.getDesktop;
            f = md.getFrameContainingGroup(this.getGroupName());
            
            if strcmpi(mode,'reset')
                javaMethodEDT('setStatusText', f, '');
            else
                javaMethodEDT('setStatusText', f, ...
                    vision.getMessage('vision:ocrTrainer:ROIStatusText'));
            end
        end
        
        %------------------------------------------------------------------
        function doTrainingImageAddROI(this, ~, ~, bbox)
            
            isTestMode = nargin == 4;                        
            
            if (isLeftClick(this.TrainingImageDisplay) || isTestMode)
                
                currentIndex = this.TrainingImageStrip.getSelectedImageIndices();
                
                if numel(currentIndex) == 1
                    % Remove existing ROI
                    if ~isempty(this.TrainingImageStrip.Session.ImageSet.TextDetectionParams(currentIndex).ROI)
                        delete(this.TrainingImageDisplay.ROI);
                    end
                    
                    if isTestMode
                        addROI(this.TrainingImageDisplay, bbox);
                        roi = this.TrainingImageDisplay.ROI;
                    else
                        % Let user draw ROI
                        roi = drawROI(this.TrainingImageDisplay);
                    end
                    
                    if vision.internal.uitools.imrectButtonDown.isValidROI(roi)
                        pos = roi.getPosition;
                        
                        this.TrainingImageStrip.Session.ImageSet.TextDetectionParams(currentIndex).ROI = pos;
                        
                        [~,BW] = ...
                            this.TrainingImageStrip.Session.ImageSet.detectTextInImage(currentIndex);
                        
                        this.TrainingImageDisplay.updateDisplay(BW);
                    end                                                       
                end
            end
        end
        
        %------------------------------------------------------------------
        function doTrainingImageROINewPosition(this, pos)
                                                     
            currentIndex = this.CurrentTrainingImageSelection;  
            
            [~,BW] = ...
                this.TrainingImageStrip.Session.ImageSet.detectTextInImage(currentIndex);
            
            this.TrainingImageDisplay.updateDisplay(BW);
        
            drawnow;

            this.TrainingImageStrip.Session.ImageSet.TextDetectionParams(currentIndex).ROI = pos;
            
        end
        
        %------------------------------------------------------------------
        function doTrainingImageStripPopup(this, ~, hData)
            if hData.getButton == 3 % right-click                               
                
                % Get the list widget
                list = hData.getSource;
                
                % Get current mouse location
                point = hData.getPoint();
                
                % Figure out the index of the board immediately under
                % the mouse button
                jIdx = list.locationToIndex(point); % 0-based java idx
                
                idx = jIdx + 1;
                
                % Figure out the index list in the case of multi-select
                idxMultiselect = this.TrainingImageStrip.getSelectedImageIndices();
                
                if ~any(idx == idxMultiselect)
                    % If the mouse is not over the selected area;
                    % select whatever is under the mouse and override
                    % the multi-selection index
                    this.TrainingImageStrip.setSelectedImageIndex(idx);                   
                end
                
                % Create a popup
                
                % Removing Images
                
                item = vision.getMessage('vision:uitools:Remove');
                
                % pad 'remove' text to get more separation between shortcut
                % and text. Otherwise it is too close together.
                item = [item ''];
                
                itemName = 'removeItem';
                
                menuItemRemove = javaObjectEDT('javax.swing.JMenuItem',...
                    item);
                menuItemRemove.setName(itemName);
                              
                removeActionListener = addlistener(menuItemRemove,'Action',...
                        @this.doTrainingImagePopupRemove); % main popup callback
                    
                % Prevent it from going out of scope, add to Misc struct.
                this.TrainingImageStrip.Misc.PopupActionListener = removeActionListener;
                
                jmenu = javaObjectEDT('javax.swing.JPopupMenu');
                
                jmenu.add(menuItemRemove);
                
                % Display the popup
                jmenu.show(list, point.x, point.y);
                jmenu.repaint;
                
            end
        end
        
        %------------------------------------------------------------------
        function doTrainingImageKeyPress(this, ~, src)             
            % process key up/down. all other key presses are no-ops.
            
            if ~this.TrainingImageStrip.Session.hasAnyItems()
                % Nothing to do if none of the images are loaded.
                return;
            end
            
            modifierKeys = {'control', 'command'};
            
            isShift = any(strcmpi(src.Modifier, 'shift'));
            isCtrl  = any(strcmpi(src.Modifier, modifierKeys{ismac+1}));
            
            if isShift && isCtrl
                return; % no action
            end
                        
            switch src.Key                
                case 'uparrow'
                    this.TrainingImageStrip.changeImage(-1);
                case 'downarrow'
                    this.TrainingImageStrip.changeImage(1);                                   
                otherwise
                    % no action
            end
        
        end
        
        %------------------------------------------------------------------
        function doTrainingImageStripKeyPress(this, ~, eventData)
              
            if eventData.getKeyCode == eventData.VK_DELETE
                
                this.doTrainingImagePopupRemove();
                
            end
        end
        
        %------------------------------------------------------------------
        function doTrainingImageZoom(this, src, ~)
            drawnow();
            
            if ~ishandle(this.TrainingImageDisplay.Fig)
                return; % figure was destroyed
            end
            
            this.TrainingImageDisplay.makeHandleVisible();
            
            % remove the listeners while we manipulate button
            % selections
            this.TrainingImageTab.ZoomPanel.removeListeners();
            drawnow();
            
            switch (src.Name)
                case 'btnZoomIn'
                    state = this.TrainingImageTab.ZoomPanel.ZoomInButtonState;
                    this.TrainingImageDisplay.setZoomInState(state);
                    this.TrainingImageTab.ZoomPanel.resetButtons();
                    drawnow();
                    this.TrainingImageTab.ZoomPanel.ZoomInButtonState = state;
                    
                case 'btnZoomOut'
                    state = this.TrainingImageTab.ZoomPanel.ZoomOutButtonState;
                    this.TrainingImageDisplay.setZoomOutState(state);
                    this.TrainingImageTab.ZoomPanel.resetButtons();
                    drawnow();
                    this.TrainingImageTab.ZoomPanel.ZoomOutButtonState = state;
                    
                case 'btnPan'
                    state = this.TrainingImageTab.ZoomPanel.PanButtonState;
                    this.TrainingImageDisplay.setPanState(state);
                    this.TrainingImageTab.ZoomPanel.resetButtons();
                    drawnow();
                    this.TrainingImageTab.ZoomPanel.PanButtonState = state;
                    
            end
            
            % let the button selections re-draw
            drawnow();                     
            
            % add back the listeners
            this.TrainingImageTab.ZoomPanel.addListeners(@this.doTrainingImageZoom);
            
            this.TrainingImageDisplay.makeHandleInvisible();
        end
        
        %------------------------------------------------------------------
        function doTrainingImageRegionFilter(this)
            if this.TrainingImageStrip.Session.hasAnyItems
                idx = this.CurrentTrainingImageSelection;
                
                this.TrainingImageTab.clipFilterValues();
                
                this.doTrainingImageUpdateRegionFilter();
                
                [~,BW] = ...
                    this.TrainingImageStrip.Session.ImageSet.detectTextInImage(idx);
                
                this.TrainingImageDisplay.updateDisplay(BW);
                
                drawnow;
            end
        end
        
        %------------------------------------------------------------------
        function doTrainingImageUpdateRegionFilter(this)            
            regionFilters = this.TrainingImageTab.getRegionFilterValues();
            
            if this.TrainingImageTab.applyRegionFiltersToAllImages()
                this.TrainingImageStrip.Session.ImageSet.setTextDetectionParams(regionFilters);
            else
                idx = this.CurrentTrainingImageSelection;
                this.TrainingImageStrip.Session.ImageSet.setTextDetectionParams(regionFilters, idx);
            end
        end
        
        %------------------------------------------------------------------
        % Set CanTrain to true only if there are some labeled chars
        %------------------------------------------------------------------
        function updateCanTrain(this)
            if this.Session.hasAllUnknowns
                this.Session.CanTrain = false;
                if this.Session.hasAnyItems()
                    this.TrainingTab.setTrainingButtonToolTip(...
                        'vision:ocrTrainer:TrainButtonToolTipUnknowns');
                else
                    this.TrainingTab.setTrainingButtonToolTip(...
                    'vision:ocrTrainer:TrainButtonToolTip');
                end
            else
                this.Session.CanTrain = true;
                this.TrainingTab.setTrainingButtonToolTip(...
                    'vision:ocrTrainer:TrainButtonToolTip');
            end
        end
        
        %------------------------------------------------------------------
        function doTrainingImageAccept(this, varargin)
            
            setWaiting(this.ToolGroup, true);
            
            if this.CurrentSelection >= 1
                % get current char selection to use for getting the
                % updated selection index in case new chars places
                % above current char after processing new images.
                currChar = this.Session.ImageSet.getCharacterByIndex(...
                    this.CurrentSelection);
            else
                currChar = [];
            end
            
            % process images to extract training samples. This displays
            % a progress bar.        
            numAdded = this.boxAndLabelImages(this.TrainingImageStartIndex, ...
                this.TrainingImageStrip.Session.ImageSet.TextDetectionParams);                   
                                              
            if numAdded > 0
                % Update session state
                this.Session.IsChanged = true;    
                
                this.updateCanTrain();
                               
            end          
            
            switchFromTrainingImageToChar(this, currChar);
            
            setWaiting(this.ToolGroup, false);
            
        end               
        
        %------------------------------------------------------------------
        function doTrainingImageClose(this,varargin)
            
            setWaiting(this.ToolGroup, true);
            
            if this.CurrentSelection >= 1
                % get current char selection to use for getting the
                % updated selection index in case new chars places
                % above current char after processing new images.
                currChar = this.Session.ImageSet.getCharacterByIndex(...
                    this.CurrentSelection);
            else
                % first time
                currChar = [];
            end
            
            numImages = this.Session.ImageSet.Count;
            
            toRemove = this.TrainingImageStartIndex:numImages;
            
            this.Session.ImageSet.removeItem(toRemove);
            
            switchFromTrainingImageToChar(this, currChar);
            
            setWaiting(this.ToolGroup, false);
        end
                
        %------------------------------------------------------------------
        function switchFromTrainingImageToChar(this, selectedChar)
            
            this.Session.ImageSet.CharView = true;
            this.Session.ImageSet.RemoveMode = 'move';            
                        
            % reset icon state to force icon redraw for char view
            this.Session.ImageSet.resetIcons();                         
            
            hideTab(this, this.TrainingImageTab);
            
            makeFigureInvisible(this.TrainingImageDisplay);                     
            
            showTab(this, this.TrainingTab);                                                           
            
            makeFigureVisible(this.ImageDisplay);  
            
            this.doTrainingImageMouseOver('reset'); % force status text reset
                                    
            drawnow();
            
            % Update the image strip
            this.ImageStrip.update();
                       
            if this.CurrentSelection >= 1
                
                % get the updated character position
                startingIndex = ...
                    this.Session.ImageSet.getCharacterIndex(selectedChar);
                
            else
                % first time. Leave CurrentSelection unset to force
                % draw.
                startingIndex = 1;
            end % current char selection
                                   
            %Update selection in the list. This triggers image
            % selection callback which renders the image display.
            this.ImageStrip.setSelectedImageIndex(startingIndex)
            this.ImageStrip.makeSelectionVisible(startingIndex)
            
            if this.CurrentSelection == startingIndex
                % A redraw of the char montage is required to handle cases
                % when new char samples are added to the current char
                % selection. Normal draw char callback will not fire unless
                % the selection is different from the previous. Hence we
                % have to force it here.                              
                
                this.drawCharacters();
                
                this.ImageDisplay.setFocusOnEditBox();
                
            end                                     
                        
                        
            if ~this.Session.hasAnyItems
                % update the browser message
                this.displayInitialDataBrowserMessage(...
                    vision.getMessage('vision:ocrTrainer:AddImagesFirstMsg'));                            
            end
            
            this.updateButtonStates();
            
            % reset selection state to allow redraw next time we switch to
            % training image view.
            this.CurrentTrainingImageSelection = -1;
            
            drawnow();
        end
    end
    
    %======================================================================
    % Callback methods for box editing
    %======================================================================
    methods
       
        %------------------------------------------------------------------
        % Switches to the box editing view. 
        %------------------------------------------------------------------
        function doBoxEdit(this)
                      
            if ~ishandle(this.BoxEditDisplay.Fig)
                return; % figure was destroyed
            end            
            
            % Indicate that this is going to take some time
            setWaiting(this.ToolGroup, true);
            
            % Handle the case of wiping the data out
            if isempty(this.Session.ImageSet.ImageStruct)
                return; % this can happen in rapid testing
            end
                        
            
            whichChar = this.ImageStrip.getSelectedImageIndices();
            
            if numel(whichChar) > 1
                % this should never happen because the edit box button should be
                % disabled. bail in case.
                return
            end
            
            whichBox = this.Session.ImageSet.getSelectedBoxes(whichChar);
            
            % update label of box selected when box edit was pushed in case
            % the edit box callbacks (focus lost or user action) didn't get
            % triggered to register update of box label.
            updateLabelIfChanged(this, whichBox);
                    
            [imageIndex, charIndex] = ...
                this.Session.ImageSet.getImageIndex(whichBox);                      
            
            drawnow(); % flush callbacks. important to flush edit box focus lost callback ...
            
            % set the current box edit char selection (i.e. the char
            % selected in the browswer to the box that was selected for
            % edit. This takes care of the case where the char browswer
            % selection is marked for deferred removal. 
            this.CurrentBoxEditCharacterSelection = ...
                this.Session.ImageSet.getBoxLabel(whichBox);
            
             this.CurrentBoxEditSelection      = charIndex;
             this.CurrentBoxEditImageSelection = imageIndex;
             
            % First do any deffered removal to handle changes to char map
            updated = this.Session.ImageSet.removeDeffered(...
                this.CurrentSelection);
            
            if updated
                this.drawCharacters(); % force redraw.
                
                this.ImageDisplay.setFocusOnEditBox();
                
                % get the updated character position
                newPosition = this.Session.ImageSet.getCharacterIndex(...
                    this.CurrentBoxEditCharacterSelection);
                
                % update current selection if new char is added
                % above the current selection as the index will be
                % different.
                if newPosition ~= this.CurrentSelection
                    this.CurrentSelection = newPosition;
                end
                
                % update the list
                this.ImageStrip.updateListItems(newPosition);
            end
            
            try % image can disappear from the disk
                [~, imageMatrix] = this.Session.ImageSet.detectTextInImage(imageIndex);
                imageFilename = ...
                     this.Session.ImageSet.getImageFilename(imageIndex);  
                
            catch missingFileEx
                errordlg(missingFileEx.message,...
                    vision.getMessage...
                    ('vision:uitools:LoadingImagesFailedTitle'), 'modal');
                return;
            end
                                    
            % wipe away previous content
            this.BoxEditDisplay.wipeFigure();
            
            % get boxes for current image
            bboxes = this.Session.ImageSet.getBoxes(imageIndex);
            
            % load display state
            this.BoxEditDisplay.Boxes = bboxes;
            this.BoxEditDisplay.BoxIDs = 1:size(bboxes,1);
            this.BoxEditDisplay.Text = this.Session.ImageSet.getText(imageIndex);
            this.BoxEditDisplay.IsChanged = false;
            
            % draw new content
            this.BoxEditDisplay.draw(imageMatrix, bboxes, charIndex);                         
                        
            % switch the view now
            makeFigureInvisible(this.ImageDisplay);    
            
            % drawnow to force image display to go away. Otherwise, there
            % is a noticeable "ghost" image of the char montage during the
            % switch.
            drawnow(); 
            
            hideDataBrowser(this);             
            
            makeFigureVisible(this.BoxEditDisplay);                                                       
            
            hideTab(this, this.TrainingTab);
            
            showTab(this, this.BoxEditTab);
            
            % Add and Merge are off initially
            disableMergeButton(this.BoxEditTab);          
            unselectAddButton(this.BoxEditTab);   
            
            drawnow();                        
            
            % show image file name in status bar
            txtstr = vision.getMessage('vision:ocrTrainer:ImageFilename');
            this.setStatusText(sprintf(' %s: %s', txtstr, imageFilename));
            
            % Indicate that this is going to take some time
            setWaiting(this.ToolGroup, false);
            
            updateStatusBarWithBoxCharLabel(this);
        end
                     
        %------------------------------------------------------------------
        function doBoxEditClose(this)
            
            switchToCharLabelingView(this);            
        end
        
        %------------------------------------------------------------------
        function doBoxEditAccept(this)
            setWaiting(this.ToolGroup, true);
            
            if ~this.BoxEditDisplay.IsChanged
                % nothing was modified.
                
                switchToCharLabelingView(this);
                
                
            else                                
                
                % Assume everything was modified. Remove all old boxes and
                % chars from the CharMap. This is a conservative (brute force)
                % approach to avoid keeping track of all user changes.
                
                oldText = this.Session.ImageSet.getText(...
                    this.CurrentBoxEditImageSelection);
                
                for i = 1:numel(oldText)
                    if ischar(oldText{i})
                        this.Session.ImageSet.removeFromCharMap(...
                            oldText{i}, this.CurrentBoxEditImageSelection, ...
                            i);
                    end
                end
                
                % Get new box information as captured in the BoxEditDisplay and
                % update the ImageSet.
                newText  = this.BoxEditDisplay.Text;
                newBoxes = this.BoxEditDisplay.Boxes;
                
                this.Session.ImageSet.setText(...
                    this.CurrentBoxEditImageSelection, newText);
                
                this.Session.ImageSet.setBoxes(...
                    this.CurrentBoxEditImageSelection, newBoxes);
                
                % Now add the new set of char data to the CharMap.
                this.Session.ImageSet.addToCharMap(this.CurrentBoxEditImageSelection);
                
                % set all icons to false, forcing them to generate when we
                % switch back to the char view. This ensures the data shown is
                % up-to-date. Note: this causes all the selected boxes to reset
                % to the first box when we return to the char view.
                this.Session.ImageSet.initialize();
                
                % update the list to re-render all the icons.
                this.ImageStrip.update()
                
                % Get the correct position in the char browser and make sure to
                % account for new chars that may have been inserted above the
                % previous selection.
                newPosition = this.Session.ImageSet.getCharacterIndex(...
                    this.CurrentBoxEditCharacterSelection);
                
                if isempty(newPosition) % char was removed!
                    % keep selection the same, limiting it to current
                    % number of items in the browser if needed.
                    this.CurrentSelection = min(this.CurrentSelection, ...
                        this.Session.ImageSet.getNumel);
                else                
                    if newPosition ~= this.CurrentSelection
                        this.CurrentSelection = newPosition;
                    end
                end                               
                
                % mark the correct selection in the browswer.
                this.ImageStrip.setSelectedImageIndex(this.CurrentSelection);
                this.ImageStrip.makeSelectionVisible(this.CurrentSelection);
                                
                if this.Session.hasAnyItems
                    % re-draw the montage to refresh the view after
                    % merge/split/addition of new boxes.
                    this.drawCharacters();
                    
                    switchToCharLabelingView(this);
                    
                    this.updateCanTrain();
                    
                    this.updateButtonStates();
                    
                    this.ImageDisplay.setFocusOnEditBox();
                else
                    % no more boxes left in the session. reset the app back
                    % to starting point. 
                    switchToCharLabelingView(this);
                    
                    this.resetAll(); 
                end
               
            end
            
            setWaiting(this.ToolGroup, false);
            
        end
        
        %------------------------------------------------------------------
        function switchToTrainingImageView(this)
            
            hideTab(this, this.BoxEditTab);
            
            hideTab(this, this.TrainingTab);
            
            showTab(this, this.TrainingImageTab);
                                    
            showDataBrowser(this);
            
            makeFigureInvisible(this.BoxEditDisplay);
            
            makeFigureInvisible(this.ImageDisplay);
            
            if vision.internal.ocr.tool.OCRTrainer.showTrainingImagesDialog()
                dlg = ...
                    vision.internal.ocr.tool. ...
                    TrainingImageBinarizationDlg(this.getGroupName());
                wait(dlg);
                
                vision.internal.ocr.tool.OCRTrainer. ...
                    setTrainingImagesDialogPref(dlg.ShowDialogAgain);
            end
            
            % clean figure show previous does not display
            wipeFigure(this.TrainingImageDisplay);
            drawnow;
            
            makeFigureVisible(this.TrainingImageDisplay);           
            drawnow();
            
            % the 'remove' mode in the training image view is an actual
            % remove.
            this.Session.ImageSet.RemoveMode = 'remove';
        end
        
        %------------------------------------------------------------------
        function switchToCharLabelingView(this)
            
            hideTab(this, this.BoxEditTab);
            
            showTab(this, this.TrainingTab);
            
            showDataBrowser(this);
            
            makeFigureInvisible(this.BoxEditDisplay);
            
            makeFigureVisible(this.ImageDisplay);
            
            this.setStatusText(...
                this.createStatusText(this.Session.OutputDirectory));
            
            this.CurrentBoxEditSelection = [];
                       
            this.updateStatusBarWithBoxCharLabel();  % [] CurrentBoxEditSelection forces this to reset
            
            this.BoxEditTab.ZoomPanel.resetButtons();
            
            % the 'remove' mode in the char image view is a move.            
            this.Session.ImageSet.RemoveMode = 'move';
            
            drawnow();
        end
        
        %------------------------------------------------------------------
        function doBoxEditClick(this, ~, ~, selectedBox, testmode)
            
            if nargin < 5                
                leftClick   = isLeftClick(this.BoxEditDisplay); 
                doubleClick = isDoubleClick(this.BoxEditDisplay);
                ctrlClick   = isCtrlClick(this.BoxEditDisplay);
            else
                % test hook
                leftClick   = false;
                doubleClick = false;
                ctrlClick   = false;
                switch testmode
                    case 'left'
                        leftClick = true;
                    case 'double'                        
                        doubleClick = true;
                    case 'ctrl'
                        ctrlClick = true;
                end
            end
            
            if leftClick || doubleClick
                
                currentSelection = this.CurrentBoxEditSelection;
                
                if numel(currentSelection) > 1
                    % If in multi-select mode and given a single click. Get
                    % back to single select mode where one box has an ROI
                    % around it.
                    
                    % first unhighlight all the boxes
                    this.BoxEditDisplay.unhighlightBox(currentSelection);
                    
                    % no make the selected box active
                    this.BoxEditDisplay.selectBox(selectedBox);
                    
                    % update the box selection state
                    this.CurrentBoxEditSelection = selectedBox;
                                                            
                else
                                    
                    if isempty(currentSelection) || selectedBox ~= currentSelection
                        % if box is not already selected
                        
                        % unselect previous box
                        this.BoxEditDisplay.unselectBox(currentSelection);
                                              
                        % select the new box
                        this.BoxEditDisplay.selectBox(selectedBox);
                        
                        % update the box selection state
                        this.CurrentBoxEditSelection = selectedBox;
                    end
                end
                
            elseif ctrlClick
               
                
                currentSelection = this.CurrentBoxEditSelection;
                
                if numel(currentSelection) == 1 && currentSelection == selectedBox
                    % no-op
                    return;                                    
                end
                
                if any(currentSelection == selectedBox)
                    % One of the multi-selected boxes clicked on again.
                    % Make it unselected.
                                        
                    this.BoxEditDisplay.unhighlightBox(selectedBox);
                    
                    toRemove = this.CurrentBoxEditSelection == selectedBox;
                    
                    this.CurrentBoxEditSelection(toRemove) = [];
                     
                    if numel(this.CurrentBoxEditSelection) == 1
                        % put ROI back because only one box left
                        this.BoxEditDisplay.selectBox(this.CurrentBoxEditSelection);
                        
                    end
                else
                    
                    if numel(currentSelection) == 1
                        % get rid of roi for multi-select 
                        this.BoxEditDisplay.unselectBox(currentSelection);
                        
                        % high-light it
                        this.BoxEditDisplay.highLightBox(currentSelection);
                    end
                    
                    % newly selected box. high light it
                    this.BoxEditDisplay.highLightBox(selectedBox);
                                        
                    % add it to the list
                    this.CurrentBoxEditSelection(end+1) = selectedBox;
                end                               
                
            end
            
            updateStatusBarWithBoxCharLabel(this);
            
            updateMergeButton(this);
                
        end
        
        %------------------------------------------------------------------        
        function updateStatusBarWithBoxCharLabel(this)
            % show current box label in status bar
            md = com.mathworks.mlservices.MatlabDesktopServices.getDesktop;
            f = md.getFrameContainingGroup(this.getGroupName());
            
            if numel(this.CurrentBoxEditSelection) == 1
                label = this.BoxEditDisplay.getText(this.CurrentBoxEditSelection);
                
                % set font to session font to ensure unicode chars display                
                f.setFont(java.awt.Font(this.Session.Font,java.awt.Font.PLAIN,12));
                
                if strcmp(label,char(0))
                    label = vision.getMessage('vision:ocrTrainer:UnknownString');
                end
                txt = vision.getMessage('vision:ocrTrainer:BoxEditCharLabel', ...
                    label);
                javaMethodEDT('setStatusText', f, txt);                 
            else
                javaMethodEDT('setStatusText', f, '');
            end
        end
        
        %------------------------------------------------------------------
        function doBoxEditZoom(this, src, ~)
            drawnow();
            
            if ~ishandle(this.BoxEditDisplay.Fig)
                return; % figure was destroyed
            end  
            
            this.BoxEditDisplay.makeHandleVisible();
            
            % remove the listeners while we manipulate button
            % selections
            this.BoxEditTab.ZoomPanel.removeListeners();
            drawnow();                                   
            
            switch (src.Name)
                case 'btnZoomIn'
                    state = this.BoxEditTab.ZoomPanel.ZoomInButtonState;
                    this.BoxEditDisplay.setZoomInState(state);
                    this.BoxEditTab.ZoomPanel.resetButtons();
                    drawnow();
                    this.BoxEditTab.ZoomPanel.ZoomInButtonState = state;
                    
                case 'btnZoomOut'
                    state = this.BoxEditTab.ZoomPanel.ZoomOutButtonState;
                    this.BoxEditDisplay.setZoomOutState(state);
                    this.BoxEditTab.ZoomPanel.resetButtons();
                    drawnow();
                    this.BoxEditTab.ZoomPanel.ZoomOutButtonState = state;
                    
                case 'btnPan'
                    state = this.BoxEditTab.ZoomPanel.PanButtonState;
                    this.BoxEditDisplay.setPanState(state);
                    this.BoxEditTab.ZoomPanel.resetButtons();
                    drawnow();
                    this.BoxEditTab.ZoomPanel.PanButtonState = state;
                    
            end
            
            % let the button selections re-draw
            drawnow();
            
            % enabling any of the zoom controls, untoggles the add button.
            if this.BoxEditTab.isROIMode && state
                this.BoxEditTab.unselectAddButton();                
            end                        
            
            % add back the listeners
            this.BoxEditTab.ZoomPanel.addListeners(@this.doBoxEditZoom);
            
            this.BoxEditDisplay.makeHandleInvisible();
        end
        
        %------------------------------------------------------------------
        function doResetBoxEditZoom(this,varargin)
            % reset zoom is called when the add button is selected but the
            % user now presses one of the zoom controls. First execute
            % normal zoom callback to properly setup zoom control state
            % (this also attaches the normal zoom callbacks,
            % doBoxEditZoom). Then reattach the draw roi callback so it
            % has precedence over the zoom callbacks.
            this.BoxEditDisplay.resetPointerBehavior();
            doBoxEditZoom(this, varargin{:}); 
            if this.BoxEditTab.isROIMode
                 this.BoxEditDisplay.attachDrawROICallback();                
            end
            
        end
        
        %------------------------------------------------------------------
        function doBoxEditAdd(this)
                        
            % Enabling the add button unselects the zoom controls. The zoom
            % listeners need to be changed to allow us to reattach the add
            % roi callback after the zoom listeners are installed.
            % Otherwise the zoom listeners override the add roi callbacks
            % and rois cannot be drawn.
            if this.BoxEditTab.isROIMode
                this.BoxEditTab.ZoomPanel.removeListeners();   
                drawnow; % important to flush callbacks
                this.BoxEditTab.ZoomPanel.resetButtons();
                drawnow; % important to flush callbacks
                this.BoxEditTab.ZoomPanel.addListeners(@this.doResetBoxEditZoom);                
                drawnow; % important to flush callbacks
                this.BoxEditDisplay.attachDrawROICallback();
                
                % change pointer behavior
                this.BoxEditDisplay.setPointerToCross();
            else               
                if ~this.BoxEditTab.ZoomPanel.ZoomOutButtonState && ...
                        ~this.BoxEditTab.ZoomPanel.ZoomInButtonState && ...
                        ~this.BoxEditTab.ZoomPanel.PanButtonState
                    
                    % reset pointer only if none of the zoom controls are
                    % selected. otherwise the zoom pointers are clobbered.
                    this.BoxEditDisplay.resetPointerBehavior();
                end
            end
        end
        
        %------------------------------------------------------------------
        function doBoxEditMerge(this)
                                    
            boxesToMerge = this.BoxEditDisplay.getBoxes(...
                this.CurrentBoxEditSelection);
                        
            xmin = boxesToMerge(:,1) + 0.5; % cvt to pixel coords
            ymin = boxesToMerge(:,2) + 0.5;
            
            w = boxesToMerge(:,3);
            h = boxesToMerge(:,4);
            
            xmax = xmin + w - 1;
            ymax = ymin + h - 1;                        
            
            xmin = min(xmin);
            ymin = min(ymin);
            
            xmax = max(xmax);
            ymax = max(ymax);
            
            w = xmax - xmin + 1;
            h = ymax - ymin + 1;                        
            
            mergedBox = [xmin-0.5 ymin-0.5 w h]; % back to spatial                                                 
    
            % remove the current selections from the display
            this.BoxEditDisplay.removeBox(this.CurrentBoxEditSelection);            
            
            % add a new box to the display
            this.CurrentBoxEditSelection = this.BoxEditDisplay.appendBox(mergedBox);
            
            % put a ROI around merged box
            this.BoxEditDisplay.selectBox(this.CurrentBoxEditSelection);                                                                               
                     
            % merge button should be disabled now that there is only 1
            % selected box.
            updateMergeButton(this);        
            
            showBoxEditLabelDialog(this);
            
            updateStatusBarWithBoxCharLabel(this);
        end
        
        %------------------------------------------------------------------        
        function showBoxEditLabelDialog(this)
             dlg = vision.internal.ocr.tool.BoxLabelDialog(...
                 this.getGroupName(), this.Session.Font);
            wait(dlg);
            
            if dlg.IsCanceled
                % mark as unknown using null char
                this.BoxEditDisplay.Text{end} = char(0);                
            else
                this.BoxEditDisplay.Text{end} = dlg.Label;
            end
        end
        
        %------------------------------------------------------------------
        function updateMergeButton(this)
            
            % enable merge button only if more than one box is selected.
            if numel(this.CurrentBoxEditSelection) > 1                
                enableMergeButton(this.BoxEditTab);
            else                
                disableMergeButton(this.BoxEditTab);
            end
        end
        
        %------------------------------------------------------------------        
        function doBoxEditFigureKeyPress(this, ~, src)
                      
            modifierKeys = {'control', 'command'};
            
            if strcmp(src.Modifier, modifierKeys{ismac+1})
               
            else
                switch src.Key                    
                    case 'delete'
                        doBoxEditDelete(this);
                end
            end
        end
        
        %------------------------------------------------------------------        
        function doBoxEditDelete(this)
            
            selected = this.CurrentBoxEditSelection;
            
            this.BoxEditDisplay.unselectBox(selected);
            
            this.BoxEditDisplay.removeBox(selected);
            
            this.CurrentBoxEditSelection = [];
            
            this.updateStatusBarWithBoxCharLabel();
            
            this.updateMergeButton();
            
        end
        
        %------------------------------------------------------------------        
        function doBoxEditROINewPosition(this, pos)
            selection = this.CurrentBoxEditSelection;
            
            this.BoxEditDisplay.resizeBox(selection, pos);
        end
        
        %------------------------------------------------------------------
        function doBoxEditAddROI(this, ~, ~, bbox)
            
            isTestMode = nargin == 4;
            
            isROIMode = this.BoxEditTab.isROIMode;
            
            if isROIMode && (isLeftClick(this.BoxEditDisplay) || isTestMode)
                
                % unselect all the boxes
                this.BoxEditDisplay.unselectBox(this.CurrentBoxEditSelection);
                
                if isTestMode
                    addROI(this.BoxEditDisplay, bbox);
                    roi = this.BoxEditDisplay.ROI;
                else
                    % Let user draw ROI
                    roi = drawROI(this.BoxEditDisplay);                        
                end
            
                if vision.internal.uitools.imrectButtonDown.isValidROI(roi)
                    
                    bbox = roi.getPosition();

                    % remove the prior to adding the patch via appendBox.
                    % Not doing this will prevent the user from moving the
                    % roi right after drawing.
                    delete(roi);
                    
                    % update display state with new box. set showBorder to
                    % false because ROI is already added so patch should
                    % not be shown at all.
                    showBorder = false;                    
                    newSelection = this.BoxEditDisplay.appendBox(bbox, showBorder);
                    
                    % mark the newly added box as the current selection
                    this.CurrentBoxEditSelection = newSelection;            
                    
                    % now add the roi 
                    this.BoxEditDisplay.selectBox(this.CurrentBoxEditSelection);
                    
                    showBoxEditLabelDialog(this);
                    
                    updateStatusBarWithBoxCharLabel(this);
                end
            end
        end
        
    end
      
    %======================================================================
    % Callback methods for export section
    %======================================================================
    methods
       
        %------------------------------------------------------------------
        function doEvaluateGenFunction(this)
            this.Session.generateEvaluationFunction();                        
        end
        
    end
    
    %======================================================================
    % Callback methods for settings section
    %======================================================================
    methods
        function doSettings(this, varargin)
            dlg = vision.internal.ocr.tool.SettingsDialog(...
                this.getGroupName, this.Session.Font);
                        
            wait(dlg);
            
            if ~dlg.IsCanceled
                
                this.updateFont(dlg.Font);
                                                                
                this.Session.ImageSet.resetIcons();
                                                
                this.ImageStrip.update();                                
                
                this.ImageStrip.setSelectedImageIndex(this.CurrentSelection);
                
                this.ImageStrip.makeSelectionVisible(this.CurrentSelection);                                
            end
        end
    end
    
    %======================================================================
    % Callback methods for keyboard shortcuts
    %======================================================================
    methods
        function doImageFigureKeyPress(this, obj, src)
                        
            if ~this.Session.hasAnyItems()
                % Nothing to do if none of the images are loaded.
                return;
            end
            
            modifierKeys = {'control', 'command'};
             
            isShift = any(strcmpi(src.Modifier, 'shift'));
            isCtrl  = any(strcmpi(src.Modifier, modifierKeys{ismac+1}));
            
            if isShift && isCtrl
                return; % no action
            end
            
            if isCtrl && strcmpi(src.Key,'a')
                selectAllBoxes(this);
            else                               
                
                switch src.Key
                    case 'escape'
                    case 'delete'
                        
                    case 'pagedown'
                        this.doPageDown;
                    case 'pageup'
                        this.doPageUp;
                    case 'uparrow'
                        this.ImageDisplay.doKeyPress(obj, src);
                    case 'downarrow'
                        this.ImageDisplay.doKeyPress(obj, src);
                    case 'leftarrow'
                        this.ImageDisplay.doKeyPress(obj, src);
                    case 'rightarrow'
                        this.ImageDisplay.doKeyPress(obj, src);
                    otherwise
                        % no action
                end
                                
            end            
        end
                   
    end
    
    methods(Hidden, Access = public)
        %------------------------------------------------------------------
        function closeAllFigures(this)
                         
            % clean up the figures
            this.ImageDisplay.close();
            
            this.BoxEditDisplay.close();
            
            this.TrainingImageDisplay.close();
            
        end      
    end
                      
end
