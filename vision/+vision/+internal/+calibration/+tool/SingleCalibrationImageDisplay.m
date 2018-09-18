classdef SingleCalibrationImageDisplay < vision.internal.calibration.tool.CalibrationImageDisplay
% SingleCalibrationImageDisplay Class that encapsulates the main image display 
%   in the Camera Calibrator App
%
% SingleCalibrationImageDisplay methods:
%    drawBoard  - display the calibration image with annotations
    
    
% Copyright 2014 The MathWorks, Inc.
       
    properties(Access=private)
        UndistortButton = [];
    end
    
    methods
        function this = SingleCalibrationImageDisplay()            
            title = vision.getMessage('vision:uitools:MainImageFigure');
            this = this@vision.internal.calibration.tool.CalibrationImageDisplay(title);
            this.UndistortButton = vision.internal.calibration.tool.ToggleButton;   
        end
        
        %------------------------------------------------------------------
        function drawBoard(this, board, boardIdx, cameraParams)
        % drawBoard Display the calibration image with annotations.
        %   drawBoard(obj, board, boardIdx, cameraParams) renders the
        %   calibration image, detected points, and board axes labels. If
        %   cameraParams input is non-empty, the method also plots the
        %   reprojected points.
        %
        %   Inputs:
        %   -------
        %   obj          - A SingleCalibrationImageDisplay object
        %
        %   board        - A struct containing the following fields:
        %                  boardSize      - [rows,cols]
        %                  fileName       - 1-element cell array containing image file
        %                  label          - title of the image axes
        %                  detectedPoints - M-by-2 array of x-y coordinates
        %
        %   boardIdx     - Index of this image/board
        %
        %   cameraParams - A cameraParameters object
            if ~ishandle(this.Fig)
                return;
            end
            
            drawBoardImpl(this, board, boardIdx, cameraParams);              
            
            if isempty(this.UndistortButton.Button) || ~ishandle(this.UndistortButton.Button)
                this.createUndistortButton();
            end
            
            if isempty(cameraParams)
                hide(this.UndistortButton);
            else
                reset(this.UndistortButton);
                this.UndistortButton.UnpushedFcn = @drawImageCallback;
                this.UndistortButton.PushedFcn = @drawUndistortedImageCallback;                
            end

            drawnow();
            
            %--------------------------------------------------------------
            function drawImageCallback(~, ~)
                drawBoardImpl(this, board, boardIdx, cameraParams); 
            end
            
            %--------------------------------------------------------------
            function drawUndistortedImageCallback(~, ~)
                drawUndistortedBoard(this, board, cameraParams);
            end            
        end        
    end
    
    methods(Access=private)
        %------------------------------------------------------------------
        function drawBoardImpl(this, board, boardIdx, camParams)
            try
                I = imread(board.fileName{1});
                
                makeHandleVisible(this);
                
                drawImage(this, I);
                
                plotDetectedPoints(this, board);
                
                if ~isempty(camParams) && (boardIdx <= camParams.NumPatterns)
                    % draw the reprojection errors only if they are available
                    % for the particular board; they may not be available if a
                    % new set of boards was added to a session which already
                    % involved a successful calibration
                    plotReprojectedPoints(this, board, boardIdx, camParams);
                end
                
                showLegend(this);
                setTitle(this, board.label);
                holdOff(this);
                set(this.Fig,'HandleVisibility','callback');

            catch
                handleMissingImage(this, board.label);
            end                                    
        end       

        %------------------------------------------------------------------
        function handleMissingImage(this, fileName)
            I = zeros(480, 640);
            makeHandleVisible(this);
            drawImage(this, I);
            hAxes = getImageAxes(this);
            text(320, 240, ['Cannot read ', fileName], ...
                'Color', 'w', 'Parent', hAxes, 'HorizontalAlignment', 'center');
            holdOff(this);
            set(this.Fig,'HandleVisibility','callback');
        end
        
        %------------------------------------------------------------------
        function plotDetectedPoints(this, board)
            hAxes = getImageAxes(this);
            p = board.detectedPoints;
            plot(hAxes, p(2:end,1),p(2:end,2),'go','LineWidth', 1,'MarkerSize', 10);
            
            % add a legend
            %-------------
            detectedLegend = vision.getMessage('vision:caltool:DetectedLegend');
            this.LegendEntries = {detectedLegend};
                        
            vision.internal.calibration.tool.drawCoordinateAxes(board.boardSize, hAxes, p);          
            originLegend = vision.getMessage('vision:caltool:CheckerboardOrigin');            
            this.LegendEntries{end+1} = originLegend;
        end
        
        %------------------------------------------------------------------
        function plotReprojectedPoints(this, board, boardIndex, camParams)
            hAxes = getImageAxes(this);
            reprojectedLegend = vision.getMessage('vision:caltool:ReprojectedLegend');
            this.LegendEntries{end+1} = reprojectedLegend;
            p = board.detectedPoints;
            rp = p + camParams.ReprojectionErrors(:,:,boardIndex);
            plot(hAxes, rp(:,1),rp(:,2),'r+','LineWidth', ...
                1,'MarkerSize', 8);
        end
        
        %------------------------------------------------------------------
        function drawUndistortedBoard(this, board, camParams)
            try
                I = imread(board.fileName{1});
                I = undistortImage(I, camParams);
                
                drawImage(this, I);
                setTitle(this, board.label);
                holdOff(this);
            catch
                handleMissingImage(this, board.label);
            end
        end
        
        %------------------------------------------------------------------
        function createUndistortButton(this)
            this.UndistortButton.Parent = this.Fig;
            this.UndistortButton.UnpushedName = ...
                vision.getMessage('vision:caltool:UndistortUndistorted');
            this.UndistortButton.UnpushedToolTip = ...
                vision.getMessage('vision:caltool:UndistortUndistortedToolTip');
            this.UndistortButton.PushedName = ...
                vision.getMessage('vision:caltool:UndistortOriginal');
            this.UndistortButton.PushedToolTip = ...
                vision.getMessage('vision:caltool:UndistortOriginalToolTip');
            this.UndistortButton.Tag = 'UndistortButton';
            this.UndistortButton.Position = [5 5 140 20];
            create(this.UndistortButton);
        end        
    end
end
