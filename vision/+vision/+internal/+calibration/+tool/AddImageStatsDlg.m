% AddImageStatsDlg Class for displaying add image statistics
%
% This object implements a dialog box for displaying the number of added,
% rejected and skipped images. 

% Copyright 2014 The MathWorks, Inc.

classdef AddImageStatsDlg < vision.internal.uitools.OkDlg       
    
    properties
        RejectedImagesBtn = [];
    end
    
    properties(Access=private)
        DlgHeight;
        TextHeight;
        StatsExtent = -1;
        StatsTextPosition;
        ButtonHeightDenom;
        
        NumRejected;        
        StatsString; 
    end
    
    properties(Access=protected)
        HeadingString;
        RejectedFileNames = {};
    end
    
    methods
        function this = AddImageStatsDlg(groupName, stats, rejectedFileNames)
            
            dlgTitle = vision.getMessage('vision:caltool:CalibrationCompleteTitle');
            this = this@vision.internal.uitools.OkDlg(groupName, dlgTitle);
            
            this.RejectedFileNames = rejectedFileNames;
            
            if stats.numDuplicates == 0
                initNoDuplicates(this, stats.numProcessed, stats.numAdded);
            else
                initWithDuplicates(this, stats.numProcessed, stats.numAdded,...
                    stats.numDuplicates)
            end
                        
            this.DlgSize = [380, this.DlgHeight];
            createDialog(this);
            addHeading(this);
            addStats(this);
            if ~isempty(this.RejectedFileNames)
                addShowRejectedImagesBtn(this);
            end
        end        
    end
    
    methods(Access=private)
        %------------------------------------------------------------------
        function initNoDuplicates(this, numProcessed, numAdded)
            this.DlgHeight = 120;
            this.TextHeight = 70;
            this.ButtonHeightDenom = 3;
            
            this.NumRejected = numProcessed - numAdded;
            setHeadingStringNoDuplicates(this);
            this.StatsString = sprintf('%d\n%d\n%d',...
                numProcessed, numAdded, this.NumRejected);
        end
        
        %------------------------------------------------------------------
        function initWithDuplicates(this, numProcessed, numAdded, numDuplicates)
            this.DlgHeight = 130;
            this.TextHeight = 80;
            this.ButtonHeightDenom = 4;
            
            this.NumRejected = numProcessed - numAdded - numDuplicates;
            setHeadingStringWithDuplicates(this);            
            this.StatsString = sprintf('%d\n%d\n%d\n%d',...
                numProcessed, numAdded, this.NumRejected, numDuplicates);
        end            
    end
       
    methods(Access=protected)
        %------------------------------------------------------------------
        function setHeadingStringNoDuplicates(this)
            this.HeadingString = vision.getMessage(...
                'vision:caltool:NumDetectedBoards');
        end
        
        %------------------------------------------------------------------
        function setHeadingStringWithDuplicates(this)
            this.HeadingString = vision.getMessage(...
                'vision:caltool:AddBoardStatistics');
        end
    end
    
    methods(Access=protected)                
        %------------------------------------------------------------------
        function addHeading(this)
            uicontrol('Parent',this.Dlg,'Style','text',...
                'Position',[20, 30, 260, this.TextHeight],...
                'FontUnits', 'normalized', 'FontSize', 0.2, ...
                'HorizontalAlignment', 'Left',...
                'String', this.HeadingString);
        end
        
        %------------------------------------------------------------------
        function addStats(this)
            this.StatsTextPosition = [220, 30, 50, this.TextHeight];
            hStatsText = uicontrol('Parent',this.Dlg,'Style','text',...
                'Position', this.StatsTextPosition,...
                'FontUnits', 'normalized', 'FontSize', 0.2, ...
                'HorizontalAlignment', 'Right',...
                'String', this.StatsString);
            this.StatsExtent = get(hStatsText, 'Extent');
        end
        
        %------------------------------------------------------------------
        function addShowRejectedImagesBtn(this)
            textSize = this.StatsExtent;
            textHeight = textSize(4);
            buttonHeight = round(textHeight/ this.ButtonHeightDenom);
            fudgeOffset = 4; % helps to better align the button with text
            buttonYPosition = this.StatsTextPosition(2)+this.StatsTextPosition(4)-...
                3*buttonHeight + fudgeOffset;
            
            this.RejectedImagesBtn = uicontrol('Parent', this.Dlg, ...
                'Callback', @this.showRejectedImagesDlg,...
                'Position', [this.StatsTextPosition(1) + 60, ...
                buttonYPosition, 90, buttonHeight], 'String', ...                
                vision.getMessage('vision:caltool:SeeImages'), ...
                'FontUnits', 'normalized', 'FontSize', 0.6, ...
                'Tag', 'btnSeeImages', 'ForegroundColor', 'b');
        end
        
        %------------------------------------------------------------------
        function showRejectedImagesDlg(this, ~, ~)
            dlg = vision.internal.calibration.tool.RejectedImagesDlg(...
                this.GroupName, this.RejectedFileNames);
            wait(dlg);
        end
    end            
end