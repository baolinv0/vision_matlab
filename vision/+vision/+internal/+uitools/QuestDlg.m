% QuestDlg Dialog with Yes and No buttons

% Copyright 2017 The MathWorks, Inc.

classdef QuestDlg < vision.internal.uitools.AbstractDlg
    properties
       YesButton;
       NoButton;
       
       IsYes = false;
       IsNo = true;
    end
    
    properties(Access=private)
        ButtonSize = [60, 30];
        ButtonSpace = 10;
        
        IconWidth = 32;
        IconHeight = 32;
        IconXOffset= 10;
        IconYOffset = 30;
        
        Icon;
        QuestionText;
        
        MsgTxtWidth;
        MsgTxtHeight;
    end
    
    properties(Constant)
        IconYBufferSize = 15;
        MsgTextXBuffer = 10;
        ButtonYPosition = 10;
        TopSpacing = 10;
        
        InitialDialogSize = [300 100];
    end
    
    methods
        function this = QuestDlg(groupName, question, dlgTitle)
            this = this@vision.internal.uitools.AbstractDlg(...
                groupName, dlgTitle);
            this.DlgSize = this.InitialDialogSize;
            createDialog(this, question);
        end
       
        %------------------------------------------------------------------
        function createDialog(this, question)
            createDialog@vision.internal.uitools.AbstractDlg(this);
            addYes(this);
            addNo(this);
            addIcon(this);
            addQuestion(this,question);
            
            reposition(this);
        end
    end
    
    methods(Access=protected)
        %------------------------------------------------------------------
        function onYes(this, ~, ~)
            this.IsYes = true;
            this.IsNo = false;
            close(this);
        end
        
        %------------------------------------------------------------------
        function onNo(this, ~, ~)
            this.IsYes = false;
            this.IsNo = true;
            close(this);
        end
        
               
        %------------------------------------------------------------------
        function onKeyPress(this, ~, evd)
            switch(evd.Key)
                case {'return','space'}
                    onYes(this);
                case {'escape'}
                    onNo(this);
            end
        end        
    end
    
    methods(Access=protected)
       
       %------------------------------------------------------------------
        function addYes(this)
            x = (this.DlgSize(1) / 2) - (this.ButtonSpace/2) - (this.ButtonSize(1));

            this.YesButton = uicontrol('Parent', this.Dlg, ...
                'Style', 'pushbutton','Callback', @this.onYes,...              
                'Position', [x, this.ButtonYPosition, this.ButtonSize], ...
                'String',...
                getString(message('MATLAB:uistring:popupdialogs:Yes')));
        end
        
       %------------------------------------------------------------------
        function addNo(this)
            x = (this.DlgSize(1) / 2) + (this.ButtonSpace/2);
            
            this.NoButton = uicontrol('Parent', this.Dlg, ...
                'Style', 'pushbutton', 'Callback', @this.onNo,...              
                'Position', [x, this.ButtonYPosition, this.ButtonSize], ...
                'String',...
                getString(message('MATLAB:uistring:popupdialogs:No')));
        end
       
        %------------------------------------------------------------------
        function addIcon(this)
            buttonYPosition = this.YesButton.Position(2);
            buttonHeight = this.ButtonSize(2);
            
            this.IconYOffset = buttonYPosition + buttonHeight + this.IconYBufferSize;
            
            this.Icon = axes(...
                'Parent'      , this.Dlg             , ...
                'Units'       ,'Pixels'              , ...
                'Position'    ,[this.IconXOffset this.IconYOffset this.IconWidth this.IconHeight], ...
                'NextPlot'    ,'replace'             , ...
                'Tag'         ,'IconAxes'              ...
                );
            
            set(this.Dlg ,'NextPlot','add');
            
            [iconData, alphaData] = matlab.ui.internal.dialog.DialogUtils.imreadDefaultIcon('quest');
            Img=image('CData',iconData, 'AlphaData', alphaData, 'Parent',this.Icon);
            set(this.Icon, ...
                'Visible','off'           , ...
                'YDir'   ,'reverse'       , ...
                'XLim'   ,get(Img,'XData')+[-0.5 0.5], ...
                'YLim'   ,get(Img,'YData')+[-0.5 0.5]  ...
                );
        end
        
       
       %------------------------------------------------------------------
       function addQuestion(this, question)
          
           msgTxtXOffset = this.IconXOffset + this.IconWidth + this.MsgTextXBuffer;
           msgTxtYOffset =  this.IconYOffset;
           
           this.MsgTxtWidth = this.DlgSize(1) - msgTxtXOffset;
           this.MsgTxtHeight = this.DlgSize(2) - msgTxtYOffset;

           MsgHandle=uicontrol(this.Dlg            , ...
               'Style'              ,'text'         , ...
               'Position'           ,[msgTxtXOffset msgTxtYOffset  this.MsgTxtWidth this.MsgTxtHeight]  , ...
               'String'             ,{' '}          , ...
               'Tag'                ,'Question'     , ...
               'HorizontalAlignment','left'         , ...
               'FontWeight'         ,'bold'          , ...
                'BackgroundColor'    ,[0 0 0] ...
               );
           question = {question};
           [WrapString,NewMsgTxtPos]=textwrap(MsgHandle,question,75);
           
            AxesHandle=axes('Parent',this.Dlg,'Position',[0 0 1 1],'Visible','off');
           
            this.QuestionText = text( ...
                'Parent'              ,AxesHandle                      , ...
                'Units'               ,'pixels'                        , ...
                'HorizontalAlignment' ,'left'                          , ...
                'VerticalAlignment'   ,'bottom'                        , ...
                'String'              ,WrapString                      , ...
                'Interpreter'         ,'none'                          , ...
                'Tag'                 ,'Question'                        ...
                );
            
            textExtent = get(this.QuestionText, 'Extent');

            this.MsgTxtWidth = max( [textExtent(3) NewMsgTxtPos(3)] );
            this.MsgTxtHeight= max( [textExtent(4) NewMsgTxtPos(4)] );
            
            dlgSizeX = max([ this.DlgSize(1) msgTxtXOffset + this.MsgTxtWidth]);
            dlgSizeY = max([ this.DlgSize(2) msgTxtYOffset + this.MsgTxtHeight]);
            
            this.DlgSize = [dlgSizeX dlgSizeY];
            this.Dlg.Position(3) = dlgSizeX;
            this.Dlg.Position(4) = dlgSizeY;
            
            delete(MsgHandle);
            
            set(this.QuestionText, 'Position',[msgTxtXOffset msgTxtYOffset]);
       end        
    end
    
    methods(Access=private)
        function reposition(this)
            if this.MsgTxtHeight > this.IconHeight
                spacing = (this.MsgTxtHeight - this.IconHeight) / 2;
                currentPosition = this.QuestionText.Position(2);
                newPosition = currentPosition + spacing;
                this.Icon.Position(2) = newPosition;
                this.Dlg.Position(4) = this.Dlg.Position(4) + this.TopSpacing;
            else
                currentPosition = this.QuestionText.Position(2);
                newPosition = currentPosition + this.TopSpacing;
                this.QuestionText.Position(2) = newPosition;
            end
            
            dialogPosition = this.Dlg.Position;
            
            buttonHandles = {this.YesButton this.NoButton};
            for i = 1:2
                buttonHandles{i}.Position(1) = buttonHandles{i}.Position(1) + (dialogPosition(3)/2) - (this.InitialDialogSize(1)/2);
            end

        end
    end
    
end
