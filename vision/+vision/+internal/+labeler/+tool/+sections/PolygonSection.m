classdef PolygonSection < vision.internal.uitools.NewToolStripSection
    
    % Copyright 2017 The MathWorks, Inc.
    
    properties
        PolygonButton
        SmartPolygonButton
    end
    
    properties (Constant)
        IconPath = fullfile(toolboxdir('vision'), 'vision', '+vision', '+internal','+labeler','+tool','+icons');
    end
    
    methods
        function this = PolygonSection()
            this.createSection();
            this.layoutSection();
        end
    end
    
    methods (Access = private)
        function createSection(this)
            polygonSectionTitle = getString( message('vision:labeler:Polygon') );
            polygonSectionTag   = 'sectionPolygon';
            
            this.Section = matlab.ui.internal.toolstrip.Section(polygonSectionTitle);
            this.Section.Tag = polygonSectionTag;
        end
        
        function layoutSection(this)
            this.addPolygonButton();
            this.addSmartPolygonButton();
            
            colAddSession = this.addColumn();
            colAddSession.add(this.PolygonButton);
            
            colAddSession = this.addColumn();
            colAddSession.add(this.SmartPolygonButton);
        end
        
        function addPolygonButton(this)
            import matlab.ui.internal.toolstrip.*;

            % New Session Button
            addPolygonTitleId = 'vision:labeler:Polygon';
            addPolygonIcon  = fullfile(this.IconPath, 'draw_polygon_24.png');
            addPolygonTag = 'btnAddPolygon';
            this.PolygonButton = this.createToggleButton(addPolygonIcon, ...
                addPolygonTitleId, addPolygonTag);
            toolTipID = 'vision:labeler:AddPolygonTooltip';
            this.setToolTipText(this.PolygonButton, toolTipID);       
        end
        
        function addSmartPolygonButton(this)
            import matlab.ui.internal.toolstrip.*;

            % New Session Button
            addSmartPolygonTitleId = 'vision:labeler:AddSmartPolygon';
            addSmartPolygonIcon = fullfile(this.IconPath, 'draw_polygon_24.png');
            addSmartPolygonTag = 'btnAddSmartPolygon';
            this.SmartPolygonButton = this.createToggleButton(addSmartPolygonIcon, ...
                addSmartPolygonTitleId, addSmartPolygonTag);
            toolTipID = 'vision:labeler:AddSmartPolygonTooltip';
            this.setToolTipText(this.SmartPolygonButton, toolTipID);       
        end
    end
end