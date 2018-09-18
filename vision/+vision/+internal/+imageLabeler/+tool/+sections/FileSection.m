% This class is for internal use only and may change in the future.

% This class defines the videoLabeler import section which houses the
% buttons to import videos, session and annotation.

% Copyright 2017 The MathWorks, Inc.

classdef FileSection < vision.internal.uitools.NewToolStripSection
    
    properties
        NewSessionButton
        LoadButton
        LoadImagesDirectory
        LoadImagesDatastore
        LoadDefinitions        
        LoadSession
        
        SaveButton
        SaveDefinitions
        SaveSession
        SaveAsSession
        
        ImportAnnotationsButton
        ImportAnnotationsFromFile
        ImportAnnotationsFromWS
        
    end
    
    properties (Constant)
        IconPath = fullfile(toolboxdir('vision'), 'vision', '+vision', '+internal','+labeler','+tool','+icons');
    end
    
    methods
        function this = FileSection()
            this.createSection();
            this.layoutSection();
        end
    end
    
    methods (Access = private)
        function createSection(this)
            
            fileSectionTitle = getString( message('vision:labeler:FileSectionTitle') );
            fileSectionTag   = 'sectionFile';
            
            this.Section = matlab.ui.internal.toolstrip.Section(fileSectionTitle);
            this.Section.Tag = fileSectionTag;
        end
        
        function layoutSection(this)
            
            this.addLoadButton();
            this.addSaveButton();
            this.addAnnotationButtons();
            
            colAddSession = this.addColumn();
            colAddSession.add(this.NewSessionButton);
            
            colAddSession = this.addColumn();
            colAddSession.add(this.LoadButton);
            
            colSaveSession = this.addColumn();
            colSaveSession.add(this.SaveButton);
            
            colAnnotations = this.addColumn();
            colAnnotations.add(this.ImportAnnotationsButton);
        end
        
        function addLoadButton(this)
            import matlab.ui.internal.toolstrip.*;
            import matlab.ui.internal.toolstrip.Icon.*;

            % New Session Button
            newSessionTitleId = 'vision:uitools:NewSessionButton';
            newSessionIcon = ADD_24;
            newSessionTag = 'btnNewSession';
            this.NewSessionButton = this.createButton(newSessionIcon, ...
                newSessionTitleId, newSessionTag);
            toolTipID = 'vision:imageLabeler:NewSessionButtonTooltip';
            this.setToolTipText(this.NewSessionButton, toolTipID);            
            
            % Load Dropdown
            loadTitleID = 'vision:uitools:Load';            
            loadIcon    = OPEN_24;
            loadTag     = 'btnLoad';
            this.LoadButton = this.createDropDownButton(loadIcon, loadTitleID, loadTag);
            toolTipID = 'vision:imageLabeler:LoadButtonTooltip';
            this.setToolTipText(this.LoadButton, toolTipID);
            
            % Load Images From Directory
            loadImagesDirectoryIcon    = ADD_16;
            loadImagesDirectoryTitleID = vision.getMessage('vision:imageLabeler:ImagesFromDirectory');
            this.LoadImagesDirectory = ListItem(loadImagesDirectoryTitleID, loadImagesDirectoryIcon);
            this.LoadImagesDirectory.Tag = 'itemLoadVideo';   
            this.LoadImagesDirectory.ShowDescription = false;
            
            % Load Images From Datastore
            loadImagesDatastoreTitleID  = vision.getMessage('vision:imageLabeler:ImagesFromDatastore');            
            loadImagesDatastoreIcon     = fullfile(this.IconPath, 'LoadImageSequence.png');
            this.LoadImagesDatastore = ListItem(loadImagesDatastoreTitleID, loadImagesDatastoreIcon);     
            this.LoadImagesDatastore.Tag = 'itemLoadImageSequence';
            this.LoadImagesDatastore.ShowDescription = false;
                        
            % Load Label Definitions Item
            
            loadLabelTitleID = vision.getMessage('vision:labeler:LabelDefinitions');
            loadLabelIcon = PROPERTIES_16;
            this.LoadDefinitions = ListItem(loadLabelTitleID,loadLabelIcon);
            this.LoadDefinitions.Tag = 'itemLoadLabelDefinition';
            this.LoadDefinitions.ShowDescription = false;
            
            % Load Session Item
            loadSessionTitleID  = vision.getMessage('vision:uitools:Session');            
            loadSessionIcon     = OPEN_16;
            this.LoadSession = ListItem(loadSessionTitleID, loadSessionIcon);     
            this.LoadSession.Tag = 'itemLoadSession';
            this.LoadSession.ShowDescription = false;
            
            % Construct definitions popup
            loadPopup = PopupList();
            
            dataSourceHeader = PopupListHeader(vision.getMessage('vision:labeler:DataSource'));
            loadPopup.add(dataSourceHeader);
            loadPopup.add(this.LoadImagesDirectory);
            loadPopup.add(this.LoadImagesDatastore);
            
            defsHeader = PopupListHeader(vision.getMessage('vision:labeler:LabelDefinitions'));
            loadPopup.add(defsHeader);
            loadPopup.add(this.LoadDefinitions);
            
            sessHeader = PopupListHeader(vision.getMessage('vision:uitools:Session'));
            loadPopup.add(sessHeader);
            loadPopup.add(this.LoadSession);
            
            this.LoadButton.Popup = loadPopup;            
        end
        
        function addSaveButton(this)
            
            import matlab.ui.internal.toolstrip.*;            
            import matlab.ui.internal.toolstrip.Icon.*;
            
            % Save Dropdown
            saveTitleID = 'vision:uitools:Save';            
            saveIcon    = SAVE_24;
            saveTag     = 'btnSave';
            this.SaveButton = this.createDropDownButton(saveIcon, saveTitleID, saveTag);
            toolTipID = 'vision:labeler:SaveButtonTooltip';
            this.setToolTipText(this.SaveButton, toolTipID);
            
            % Save Label Definitions Item
            saveLabelTitleID = vision.getMessage('vision:labeler:LabelDefinitions');
            saveLabelIcon = PROPERTIES_16;
            this.SaveDefinitions = ListItem(saveLabelTitleID,saveLabelIcon);
            this.SaveDefinitions.Tag = 'itemSaveLabelDefinition';            
            this.SaveDefinitions.ShowDescription = false;
            
            % Save Session Item
            saveSessionTitleID  = vision.getMessage('vision:uitools:Session');            
            saveSessionIcon     = SAVE_16;
            this.SaveSession = ListItem(saveSessionTitleID, saveSessionIcon);     
            this.SaveSession.Tag = 'itemSaveSession';
            this.SaveSession.ShowDescription = false;
            
            % Save As Session Item
            saveAsSessionTitleID  = vision.getMessage('vision:labeler:SessionAs');            
            saveAsSessionIcon     = SAVE_AS_16;
            this.SaveAsSession = ListItem(saveAsSessionTitleID, saveAsSessionIcon);     
            this.SaveAsSession.Tag = 'itemSaveAsSession';
            this.SaveAsSession.ShowDescription = false;
            
            % Construct definitions popup
            savePopup = PopupList();
            
            defsHeader = PopupListHeader(vision.getMessage('vision:labeler:LabelDefinitions'));
            savePopup.add(defsHeader);
            savePopup.add(this.SaveDefinitions);
            
            sessHeader = PopupListHeader(vision.getMessage('vision:uitools:Session'));
            savePopup.add(sessHeader);
            savePopup.add(this.SaveSession);
            savePopup.add(this.SaveAsSession);
            
            this.SaveButton.Popup = savePopup;             
        end
               
        function addAnnotationButtons(this)
            
            import matlab.ui.internal.toolstrip.*;            
            import matlab.ui.internal.toolstrip.Icon.*;
            
            importIcon      = IMPORT_24;
            importTitleID   = 'vision:labeler:ImportAnnotationsButtonTitle';
            importTag       = 'btnImportAnnotations';
            this.ImportAnnotationsButton = this.createDropDownButton(importIcon, importTitleID, importTag);
            toolTipID = 'vision:labeler:ImportAnnotationsButtonTooltip';
            this.setToolTipText(this.ImportAnnotationsButton, toolTipID);
            
            % From File
            text = vision.getMessage('vision:labeler:FromFile');
            icon = OPEN_16;
            this.ImportAnnotationsFromFile = ListItem(text,icon);
            this.ImportAnnotationsFromFile.ShowDescription = false;
            this.ImportAnnotationsFromFile.Tag = 'itemImportFromFile';            
            
            % From Workspace
            text = vision.getMessage('vision:labeler:FromWS');
            icon = IMPORT_16;
            this.ImportAnnotationsFromWS = ListItem(text,icon);
            this.ImportAnnotationsFromWS.ShowDescription = false;
            this.ImportAnnotationsFromWS.Tag = 'itemImportFromWS';            
            
            % Construct definitions popup
            defsPopup = PopupList();
            defsPopup.add(this.ImportAnnotationsFromFile);
            defsPopup.add(this.ImportAnnotationsFromWS);
            this.ImportAnnotationsButton.Popup = defsPopup;              
        end
    end
end
