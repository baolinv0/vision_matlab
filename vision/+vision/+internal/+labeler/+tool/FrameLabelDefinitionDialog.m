% This class defines the Frame Label definition dialog. A user can define
% new Frame Label using this dialog.
classdef FrameLabelDefinitionDialog < vision.internal.uitools.OkCancelDlg
    
    properties
        LabelName; 
        Description;
        InvalidLabelNames = {};
    end    
    
    properties(Access=private)
        IsNewMode;
        
        LabelEditBox;
        DescriptionEditBox;  
        
        SessionFrameLabelSet;
    end
    
    %----------------------------------------------------------------------
    methods
        function this = FrameLabelDefinitionDialog(groupName, data)
           
            dlgTitle = vision.getMessage('vision:labeler:AddNewFrameLabel');
            
            this = this@vision.internal.uitools.OkCancelDlg(groupName, dlgTitle);
         
            this.DlgSize = [300 200];
            
            createDialog(this);
            
            if isa(data, 'vision.internal.labeler.FrameLabelSet')
                this.IsNewMode = true;
            else
                this.IsNewMode = false;
            end
                        
            if this.IsNewMode
                this.LabelName = char.empty;
                this.Description = char.empty;
            else
                this.LabelName = data.Label;
                this.Description = data.Description;
            end

            addLabelNameEditBox(this);
            addDescriptionEditBox(this);
                
            if this.IsNewMode
                this.SessionFrameLabelSet = data;

                % Set focus to the edit box.
                uicontrol(this.LabelEditBox);
            end
        end
        
        function data = getDialogData(this)
            data = vision.internal.labeler.FrameLabel(this.LabelName, this.Description);
        end
    end
    
    %----------------------------------------------------------------------
    methods(Access = protected)
        function onOK(this, ~, ~)
            
            % This drawnow is required to ensure that text typed into the
            % edit box is captured prior to proceeding.
            drawnow;
            
            this.LabelName = get(this.LabelEditBox, 'String');            
            this.Description = get(this.DescriptionEditBox, 'String');            
            
            isValidName = true;
            if this.IsNewMode
                % check if the same label definition already exists.
                isValidName = this.SessionFrameLabelSet.validateLabelName(this.LabelName);
                
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
                'String', vision.getMessage('vision:labeler:FrameLabeNameEditBox'));      
            
            this.LabelEditBox = uicontrol('Parent', this.Dlg,'Style','edit',...
                'String',this.LabelName,...
                'Units', 'normalized',...
                'Position', [0.1, 0.75, 0.5, 0.1],...
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
                'String', vision.getMessage('vision:labeler:FrameLabelDescriptionEditBox'));
            
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