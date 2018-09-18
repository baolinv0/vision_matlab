% This class defines the ROI Label definition dialog. A user can define new
% ROI Label using this dialog.
classdef ROILabelDefinitionDialog < vision.internal.uitools.OkCancelDlg
    
    properties
        LabelName;
        Description;
        Shape = labelType.Rectangle;
        InvalidLabelNames = {};
    end
    
    properties(Access=private)
        IsNewMode;
        
        LabelEditBox;
        ShapePopUpMenu;
        DescriptionEditBox;
        
        SessionROILabelSet;
        
        SupportedROILabelTypes
        
    end
    
    %----------------------------------------------------------------------
    methods
        function this = ROILabelDefinitionDialog(groupName, data, supportedLabelTypes)
            
            dlgTitle = vision.getMessage('vision:labeler:AddNewROILabel');
            
            this = this@vision.internal.uitools.OkCancelDlg(groupName, dlgTitle);
            
            this.DlgSize = [350 200];
            
            this.SupportedROILabelTypes = supportedLabelTypes;
            
            createDialog(this);
            
            if isa(data, 'vision.internal.labeler.ROILabelSet')
                this.IsNewMode = true;
            else
                this.IsNewMode = false;
            end
            
            if this.IsNewMode
                this.LabelName = char.empty;
                this.Description = char.empty;
                if isempty(data.DefinitionStruct)
                    this.Shape = labelType.Rectangle;
                else
                    % Choose last defined shape.
                    this.Shape = data.DefinitionStruct(end).Type;
                end
            else
                % modifying existing ROI label
                this.LabelName = data.Label;
                this.Description = data.Description;
                this.Shape = data.ROI;
            end
            
            addLabelNameEditBox(this);
            addLabelShapePopUpMenu(this);
            %Tabbing does not move further from description box g176576
            addDescriptionEditBox(this);
            
            if this.IsNewMode
                this.SessionROILabelSet = data;
                
                % Set focus to the edit box.
                uicontrol(this.LabelEditBox);
            end
        end
        
        function data = getDialogData(this)
            data = vision.internal.labeler.ROILabel(this.Shape, this.LabelName, this.Description);
        end
    end
    
    %----------------------------------------------------------------------
    methods(Access = protected)
        function onOK(this, ~, ~)
            
            % This drawnow is required to ensure that text typed into the
            % edit box is captured prior to proceeding.
            drawnow;
            
            selectedIndex    = get(this.ShapePopUpMenu, 'Value');
            this.Shape       = this.SupportedROILabelTypes(selectedIndex);
            
            this.LabelName   = get(this.LabelEditBox, 'String');
            this.Description = get(this.DescriptionEditBox, 'String');
            
            isValidName = true;
            if this.IsNewMode
                % check if the same label definition already exists.
                isValidName = this.SessionROILabelSet.validateLabelName(this.LabelName);
                
                if isValidName && ismember(this.LabelName, this.InvalidLabelNames)
                    errordlg(...
                        vision.getMessage('vision:labeler:LabelNameInvalidDlgMsg',this.LabelName),...
                        vision.getMessage('vision:labeler:LabelNameInvalidDlgName'),...
                        'modal');
                    isValidName = false;
                end
                
            end
            
            if isValidName
                this.IsCanceled = false;
                close(this);
            end
        end
        
        function addLabelNameEditBox(this)
            uicontrol('Parent',this.Dlg,'Style','text',...
                'Units', 'normalized',...
                'Position', [0.1, 0.85, 0.5, 0.1],...
                'HorizontalAlignment', 'left',...
                'String', vision.getMessage('vision:labeler:ROILabeNameEditBox'));
            
            this.LabelEditBox = uicontrol('Parent', this.Dlg,'Style','edit',...
                'String',this.LabelName,...
                'Units', 'normalized',...
                'Position', [0.1, 0.75, 0.45, 0.1],...
                'HorizontalAlignment', 'left',...
                'BackgroundColor',[1 1 1], ...
                'Tag', 'varLabelNameEditBox', ...
                'FontAngle', 'normal', ...
                'ForegroundColor',[0 0 0], ...
                'Enable', 'on');
            
            if ~this.IsNewMode
                this.LabelEditBox.Enable = 'off';
            end
            
            % Handle pressing of 'return' or 'escape' key while typing into
            % the edit box.
            this.LabelEditBox.KeyPressFcn = @this.onKeyPress;
        end
        
        function addDescriptionEditBox(this)
            uicontrol('Parent',this.Dlg,'Style','text',...
                'Units', 'normalized',...
                'Position', [0.1, 0.6, 0.6, 0.1],...
                'HorizontalAlignment', 'left',...
                'String', vision.getMessage('vision:labeler:ROILabelDescriptionEditBox'));
            
            this.DescriptionEditBox = uicontrol('Parent', this.Dlg,'Style','edit',...
                'Max', 5,...
                'String',this.Description,...
                'Units', 'normalized',...
                'Position', [0.1, 0.2, 0.8, 0.4],...
                'HorizontalAlignment', 'left',...
                'BackgroundColor',[1 1 1], ...
                'Tag', 'varDescriptionEditBox', ...
                'FontAngle', 'normal', ...
                'ForegroundColor',[0 0 0], ...
                'Enable', 'on');
            
            % Place the edit box in focus if dialog is opened for edit.
            if ~this.IsNewMode
                uicontrol(this.DescriptionEditBox);
            end
            
            % Handle pressing of 'return' or 'escape' key while typing into
            % the edit box.
            this.DescriptionEditBox.KeyPressFcn = @this.onEditBoxKeyPress;
        end
        
        function addLabelShapePopUpMenu(this)
            % labelTypeChoices An array of labelType enums listing what
            % should be shown.
            
            labelTypeChoices = this.SupportedROILabelTypes;
            
            strList = cell(numel(labelTypeChoices),1);
            
            
            labeTypeIcons  = { ...
                'Rectangle', ...
                'Line', ...
                'Scene', ...
                'Custom', ...
                'Pixel label'
                };
            
            for i = 1:numel(labelTypeChoices)
                strList{i} = labeTypeIcons{double(labelTypeChoices(i))+1}; % +1 b/c enum starts at zero.
            end
            
            this.ShapePopUpMenu = uicontrol('Parent', this.Dlg,'Style','popupmenu',...
                'Units', 'normalized',...
                'String', strList ,...
                'Value',1,'Position',[0.6,0.665,0.3,0.2]);
            
            this.ShapePopUpMenu.Value = find(this.SupportedROILabelTypes == this.Shape);
            
            if ~this.IsNewMode
                this.ShapePopUpMenu.Enable = 'off';
            end
        end
        
        function onKeyPress(this, ~, evd)
            
            % OkCancelDlg has an onKeyPress. Re-define it here so we don't
            % react to space bar.
            switch(evd.Key)
                case {'return'}
                    onOK(this);
                case {'escape'}
                    onCancel(this);
            end
        end
        
        %g1600578
        function onEditBoxKeyPress(this, ~, evd)
            if ~isempty(evd.Modifier)
                modifierKeys = {'control','command'};

                if (strcmp(evd.Modifier, modifierKeys{ismac()+1}) && strcmp(evd.Key, 'return'))
                    onOK(this);
                end
            else
                if strcmp(evd.Key, 'escape')
                    onCancel(this);
                end
            end
        end
    end
end