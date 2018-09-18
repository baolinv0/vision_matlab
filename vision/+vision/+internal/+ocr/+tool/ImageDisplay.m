classdef ImageDisplay < vision.internal.uitools.AppFigure
    properties
        KeyPressFcn
        MouseButtonDownFcn
        SelectionChangeFcn
        OpenSelectionFcn
        RemoveSelectionFcn       
        Tag = 'MainImageDisplay'                          
    end
    
    %----------------------------------------------------------------------
    % UI components
    %----------------------------------------------------------------------
    properties
        Panel
        ImageBrowser
        Axes
        EditBox
        EditBoxLabel
        JEditBox
        Text                     
    end
    
    %----------------------------------------------------------------------
    % Edit box callbacks
    %----------------------------------------------------------------------
    properties
        EditBoxCallbackFcn       
        EditBoxDeleteFcn        
        EditBoxKeyTypedFcn
        EditBoxKeyPressedFcn
        EditBoxFont
    end
    
    methods
        % Construct main image display. Requires key press and button down
        % callbacks to be provided.
        function this = ImageDisplay() 
            this = this@vision.internal.uitools.AppFigure('Image');  
            
            % Use painters to avoid rendering issues
            set(this.Fig, 'Renderer', 'painters'); 
        end                   
        
        %------------------------------------------------------------------
        function set.KeyPressFcn(this, fcn)
            this.KeyPressFcn = fcn;
            this.Fig.KeyPressFcn = fcn;            
        end
        
        %------------------------------------------------------------------
        function drawCharacters(this, patches, whichChar, whichBox, label)
            
            if isempty(patches)
                return;
            end
            
            makeHandleVisible(this);
            
            this.Panel = findobj(this.Fig, 'Type','uipanel');                                   
            
            if isempty(this.Panel) || ~ishandle(this.Panel) % make panel if needed.
                                
                this.Panel = uipanel('Parent', this.Fig, ...
                    'Units', 'Normalized',...
                    'Position', [0 0 1 0.88],...
                    'BackgroundColor', [1 1 1],...
                    'BorderType', 'none');
                
                this.EditBoxLabel = uicontrol('Parent',this.Fig,'Style','text', ...
                    'Units','normalized','Position',[0 .92 .11 0.054],...
                    'String',vision.getMessage('vision:ocrTrainer:CharacterLabel'),...
                    'HorizontalAlignment','center','Visible','off',...
                    'BackgroundColor',[1 1 1], ...
                    'TooltipString', vision.getMessage('vision:ocrTrainer:CharLabelTooltip'));
                                                                                       
                this.JEditBox = javaObjectEDT('javax.swing.JTextField');
                
                % Parent edit box to figure.
                [~, this.EditBox] = javacomponent(this.JEditBox, [0 0 1 1], this.Fig);
                
                % Set edit box tag for FINDOBJ use.
                this.EditBox.Tag = 'JTextField';
                                
                % Center alignment of text.
                % JTextField.CENTER is 0:
                %    http://developer.classpath.org/doc/javax/swing/SwingConstants.html#CENTER
                javaMethodEDT('setHorizontalAlignment',this.JEditBox, 0)     
                javaMethodEDT('setToolTipText', this.JEditBox, ...
                    vision.getMessage('vision:ocrTrainer:CharLabelTooltip'));
                                                                                                           
                this.EditBox.Units = 'Normalized';
                this.positionLabelBox();
                
                % attach callback to editbox
                addlistener(this.JEditBox, 'ActionPerformedCallback',{this.EditBoxCallbackFcn, whichChar});
                
                h = handle(this.JEditBox,'CallbackProperties');
                
                % Action when user presses enter in text field.
                set(h, 'ActionPerformedCallback', {this.EditBoxCallbackFcn,whichChar});
                                
                % Action when user presses printable character. Used
                % primarily for ctrl-a.
                set(h, 'KeyPressedCallback', {this.EditBoxKeyPressedFcn,this.JEditBox});   
                
            else
                % clear panel contents. image browser will render into it.
                % if this is not done, the image browser will add more axes
                % to the panel.
                if ishandle(this.Panel.Children)
                    delete(this.Panel.Children);
                end
            end
            
            % add static text message for unknown chars
            if strcmpi(label, char(0))
                                
                this.Text = uicontrol('Parent', this.Fig, 'Style','text',...
                    'String', vision.getMessage('vision:ocrTrainer:TrainingUnknownsMsg'),...
                    'HorizontalAlignment', 'right',...
                    'FontSize', 14, ...
                    'Units', 'normalized',...
                    'BackgroundColor','white');
                
                positionLabelBoxAndText(this);
                this.Fig.SizeChangedFcn = @(~,~)positionLabelBoxAndText(this);
                
            else
                this.Fig.SizeChangedFcn = @(~,~)positionLabelBox(this);
            end                                   
            
            javaMethodEDT('setFont', this.JEditBox, java.awt.Font(...
                this.EditBoxFont,java.awt.Font.PLAIN,24));                        
                
            % enable context menu only if not the unknown char
            enableContextMenu =  ~strcmp(label,char(0));
            
            this.ImageBrowser = ...
                vision.internal.ocr.tool.ImageBrowser(...
                this.Panel, patches, [100 100], enableContextMenu);                       
            
            function scrollwheel(varargin)               
                this.ImageBrowser.mouseWheelFcn(varargin{:});
            end
            
            this.Fig.WindowScrollWheelFcn = @scrollwheel;
            
            % set figure properties to enable smoother keyboard navigation.
            this.Fig.Interruptible = 'off'; 
            this.Fig.BusyAction = 'cancel';
            
            addlistener(this.ImageBrowser,'SelectionChange',...
                this.SelectionChangeFcn);
            
            addlistener(this.ImageBrowser, 'OpenSelection', ...
                this.OpenSelectionFcn);
            
            addlistener(this.ImageBrowser, 'RemoveSelection', ...
                this.RemoveSelectionFcn);
                       
            % set text first. calling selection callback next will trigger
            % selection event which gets text label from edit box. If this
            % is not done here, then labe will be empty.
            this.JEditBox.setText(label);  
            
            % Select a box.
            this.selectBox(whichBox);
            
            % synchronise visibility so it appears as though all UI
            % elements render at once.
            this.EditBoxLabel.Visible = 'on';
            this.EditBox.Visible      = 'on';
            
            updateEditBox(this, label);
            javaMethodEDT('requestFocusInWindow',this.JEditBox);                                
            
            lockFigure(this);            
 
        end
        
        %------------------------------------------------------------------
        % Update static text and edit box position on figure size change.
        %------------------------------------------------------------------
        function positionLabelBoxAndText(this)
            
            positionLabelBox(this);
            
            pos = hgconvertunits(this.Fig, [0 0 80 1.80], 'characters', 'normalized', this.Fig);
            pos(1) = 1 - pos(3);
            pos(2) = 1 - pos(4);
                        
            this.Text.Position = pos;
        end
        
        %------------------------------------------------------------------
        % Update edit box position on figure size change.
        %------------------------------------------------------------------
        function positionLabelBox(this)
            
            labelPos = hgconvertunits(this.Fig, [0 0 20 1.4], 'characters', 'normalized', this.Fig);
            
            labelPos(1) = 0;
            labelPos(2) = 1 - 2*labelPos(4);
            
            this.EditBoxLabel.Position = labelPos;
            
            editPos = hgconvertunits(this.Fig, [0 0 10 3], 'characters', 'normalized', this.Fig);
                 
            editPos(1) = labelPos(1) + labelPos(3) + 0.001;
            editPos(2) = 1 - 1.1*editPos(4);
            this.EditBox.Position = editPos;
        end
        
        %------------------------------------------------------------------
        function doKeyPress(this, key, modifier)     
            
            % ImageBrowser takes MATLAB KeyData events. However, the app
            % can produce java KeyEvents too. To handle both, call sites
            % must pass the Key and Modifier to this function, which will
            % then package the data for the ImageBrowser key press
            % function.
            src.Key = key;
            if nargin == 3
                src.Modifier = modifier;            
            else
                src.Modifier = '';
            end
            
            this.ImageBrowser.keyPressFcn(this.Fig,src);
        end
        
        %------------------------------------------------------------------
        function updateFont(this, font)
            this.EditBoxFont = font;
            javaMethodEDT('setFont', this.JEditBox, java.awt.Font(...
                font,java.awt.Font.PLAIN,24));
        end
        
        %------------------------------------------------------------------
        function wipeFigure(this)
            % Take care of deleting java edit box. This does not get
            % cleared by calling CLF(this.Fig).
            
            eb = findobj(this.Fig,'Tag','JTextField');
            
            if ishandle(eb)
                delete(eb);
            end                                       
                       
            % wipe remaining UI elements
            wipeFigure@vision.internal.uitools.AppFigure(this);    
        end                               
       
        %------------------------------------------------------------------
        function selectBox(this, whichBox)
            
            this.ImageBrowser.setSelection(whichBox);
           
        end
        
        %------------------------------------------------------------------
        function unselectBox(this, ~)
            
            this.ImageBrowser.setSelection([]);
            
        end
              
        %------------------------------------------------------------------
        function p = getPatch(this, which)
            tag = sprintf('montage_bboxPatch%d',which);
            p = findobj(this.Fig, 'Type','patch','Tag', tag);
        end
        
        %------------------------------------------------------------------
        function updateEditBox(this, label)   
            if strcmpi(label,'unknown')
                label = char(0);
            else
                label = this.parseUserLabel(label);
            end
               
            if ishandle(this.EditBox)
                javaMethodEDT('setText',this.JEditBox,label);
                javaMethodEDT('selectAll',this.JEditBox);
                javaMethodEDT('requestFocusInWindow',this.JEditBox);
            end
        end
        
        %------------------------------------------------------------------
        % Return single character label for ASCII labels. For non-ascii
        % return the entire label as it could be a multi-character unicode
        % symbol.
        %------------------------------------------------------------------
        function label = parseUserLabel(~, label)
            
            if numel(label) > 1
                if char(label(1)) <= char(127) 
                    label = label(1);
                end
            end
        end
        
        %------------------------------------------------------------------
        function setFocusOnEditBox(this)                        
            figure(this.Fig); % give focus to display first
            javaMethodEDT('requestFocusInWindow',this.JEditBox);
        end
        
        %------------------------------------------------------------------
        function str = getEditBoxString(this)
            str = javaMethodEDT('getText',this.JEditBox);
            
            str = char(str);
            
            str = this.parseUserLabel(str);
        end
       
    end
end
