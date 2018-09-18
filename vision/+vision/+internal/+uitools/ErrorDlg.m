% ErrorDlg Dialog with Yes and No buttons

% Copyright 2017 The MathWorks, Inc.

classdef ErrorDlg < vision.internal.uitools.AbstractDlg
    properties
       OkButton;
    end
    
    properties(Access=private)
        ButtonSize = [60, 30];
        
        IconWidth = 32;
        IconHeight = 32;
        IconXOffset= 10;
        IconYOffset = 30;
        
        Icon;
        Text;
        
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
        function this = ErrorDlg(groupName, text, dlgTitle)
            this = this@vision.internal.uitools.AbstractDlg(...
                groupName, dlgTitle);
            this.DlgSize = this.InitialDialogSize;
            createDialog(this, text);
        end
       
        %------------------------------------------------------------------
        function createDialog(this, errorText)
            createDialog@vision.internal.uitools.AbstractDlg(this);
            addOK(this);
            addIcon(this);
            addText(this,errorText);
            
            reposition(this);
        end
    end
    
    methods(Access=protected)
        %------------------------------------------------------------------
        function onOK(this,~,~)
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
        function addOK(this)
            x = (this.DlgSize(1) / 2) - (this.ButtonSize(1)/2);

            this.OkButton = uicontrol('Parent', this.Dlg, ...
                'Style', 'pushbutton', 'Tag', 'OKButton','Callback', @this.onOK,...              
                'Position', [x, this.ButtonYPosition, this.ButtonSize], ...
                'String',...
                getString(message('MATLAB:uistring:popupdialogs:OK')));
        end
        
        %------------------------------------------------------------------
        function addIcon(this)
            buttonYPosition = this.OkButton.Position(2);
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
            
            [iconData, alphaData] = matlab.ui.internal.dialog.DialogUtils.imreadDefaultIcon('error');
            Img=image('CData',iconData, 'AlphaData', alphaData, 'Parent',this.Icon);
            set(this.Icon, ...
                'Visible','off'           , ...
                'YDir'   ,'reverse'       , ...
                'XLim'   ,get(Img,'XData')+[-0.5 0.5], ...
                'YLim'   ,get(Img,'YData')+[-0.5 0.5]  ...
                );
        end
        
       
       %------------------------------------------------------------------
       function addText(this, errorText)
          
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
           errorText = {errorText};
           [WrapString,NewMsgTxtPos]=textwrap(MsgHandle,errorText,75);
           
            AxesHandle=axes('Parent',this.Dlg,'Position',[0 0 1 1],'Visible','off');
           
            this.Text = text( ...
                'Parent'              ,AxesHandle                      , ...
                'Units'               ,'pixels'                        , ...
                'HorizontalAlignment' ,'left'                          , ...
                'VerticalAlignment'   ,'bottom'                        , ...
                'String'              ,WrapString                      , ...
                'Interpreter'         ,'none'                          , ...
                'Tag'                 ,'ErrorText'                        ...
                );
            
            textExtent = get(this.Text, 'Extent');

            this.MsgTxtWidth = max( [textExtent(3) NewMsgTxtPos(3)] );
            this.MsgTxtHeight= max( [textExtent(4) NewMsgTxtPos(4)] );
            
            dlgSizeX = max([ this.DlgSize(1) msgTxtXOffset + this.MsgTxtWidth]);
            dlgSizeY = max([ this.DlgSize(2) msgTxtYOffset + this.MsgTxtHeight]);
            
            this.DlgSize = [dlgSizeX dlgSizeY];
            this.Dlg.Position(3) = dlgSizeX;
            this.Dlg.Position(4) = dlgSizeY;
            
            delete(MsgHandle);
            
            set(this.Text, 'Position',[msgTxtXOffset msgTxtYOffset]);
       end        
    end
    
    methods(Access=private)
        function reposition(this)
            if this.MsgTxtHeight > this.IconHeight
                spacing = (this.MsgTxtHeight - this.IconHeight) / 2;
                currentPosition = this.Text.Position(2);
                newPosition = currentPosition + spacing;
                this.Icon.Position(2) = newPosition;
                this.Dlg.Position(4) = this.Dlg.Position(4) + this.TopSpacing;
            else
                currentPosition = this.Text.Position(2);
                newPosition = currentPosition + this.TopSpacing;
                this.Text.Position(2) = newPosition;
            end
            
            dialogPosition = this.Dlg.Position;
            
            this.OkButton.Position(1) = this.OkButton.Position(1) + (dialogPosition(3)/2) - (this.InitialDialogSize(1)/2);
        end
    end
    
end
