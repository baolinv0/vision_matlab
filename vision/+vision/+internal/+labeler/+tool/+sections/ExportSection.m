% This class is for internal use only and may change in the future.

% This class defines the videoLabeler export section.

% Copyright 2016 The MathWorks, Inc.

classdef ExportSection < vision.internal.uitools.NewToolStripSection
    
    properties
        ExportButton
        ExportAnnotationsToFile
        ExportAnnotationsToWS
    end
    
    methods
        function this = ExportSection()
            this.createSection();
            this.layoutSection();
        end
    end
    
    methods (Access = protected)
        function toolTipID = getExportButtonToolTip(~)
            % return tool tip. Override tool tip by sub-classing and
            % reimplementing just this method.
            toolTipID = 'vision:labeler:ExportAnnotationsToolTip';
        end
    end
    
    methods (Access = private)
        function createSection(this)
            
            exportSectionTitle = getString( message('vision:uitools:ExportSection') );
            exportSectionTag   = 'sectionExport';
            
            this.Section = matlab.ui.internal.toolstrip.Section(exportSectionTitle);
            this.Section.Tag = exportSectionTag;
        end
        
        function layoutSection(this)
            
            this.addExportButton();
            
            col = this.addColumn();
            col.add(this.ExportButton);
        end
        
        function addExportButton(this)
            
            import matlab.ui.internal.toolstrip.*;
            import matlab.ui.internal.toolstrip.Icon.*;
            
            icon    = EXPORT_24;
            titleID = 'vision:labeler:ExportAnnotations';
            tag     = 'btnExport';
            this.ExportButton = this.createDropDownButton(icon,titleID,tag);
            toolTipID = this.getExportButtonToolTip();
            this.setToolTipText(this.ExportButton, toolTipID);   
            
            % To File
            text = vision.getMessage('vision:labeler:ToFile');
            icon = SAVE_16;
            this.ExportAnnotationsToFile = ListItem(text,icon);
            this.ExportAnnotationsToFile.ShowDescription = false;
            this.ExportAnnotationsToFile.Tag = 'itemExportToFile';
            
            % To Workspace
            text = vision.getMessage('vision:labeler:ToWS');
            icon = EXPORT_16;
            this.ExportAnnotationsToWS = ListItem(text,icon);
            this.ExportAnnotationsToWS.ShowDescription = false;
            this.ExportAnnotationsToWS.Tag = 'itemExportToWS';
            
            % Construct definitions popup
            defsPopup = PopupList();
            defsPopup.add(this.ExportAnnotationsToFile);
            defsPopup.add(this.ExportAnnotationsToWS);
            this.ExportButton.Popup = defsPopup;               
        end
    end
end
