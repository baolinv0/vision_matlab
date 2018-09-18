classdef StereoCalibrationImageDisplay < vision.internal.calibration.tool.CalibrationImageDisplay
% StereoCalibrationImageDisplay Class that encapsulates the main image display
%   in the Stereo Calibrator App
%
% StereoCalibrationImageDisplay methods:
%   drawBoard - display the calibration image pair with annotations
    
    % Copyright 2014 The MathWorks, Inc.
    
    properties(Access=private)
        RectifyButton = [];
        IsImage1Valid = true;
        IsImage2Valid = true;
    end
    
    methods
        function this = StereoCalibrationImageDisplay(groupName)
            if nargin < 1
                groupName = '';
            end
            
            title = vision.getMessage('vision:uitools:MainImageFigure');
            this = this@vision.internal.calibration.tool.CalibrationImageDisplay(title);
            this.RectifyButton = vision.internal.calibration.tool.ToggleButton(groupName);
        end
        
        %------------------------------------------------------------------
        function drawBoard(this, board, boardIndex, stereoParams)
        % drawBoard Display the calibration image with annotations.
        %   drawBoard(obj, board, boardIdx, stereoParams) renders the
        %   calibration image, detected points, and board axes labels. If
        %   cameraParams input is non-empty, the method also plots the
        %   reprojected points.
        %
        %   Inputs:
        %   ------
        %   obj          - A StereoCalibrationImageDisplay object
        %
        %   board        - A struct containing the following fields:
        %                  boardSize      - [rows,cols]
        %                  fileName       - 2-element cell array of image file names
        %                  label          - title of the image axes
        %                  detectedPoints - M-by-2-by-1-by-2 array of x-y coordinates
        %
        %   boardIdx     - Index of this image/board
        %
        %   stereoParams - A stereoParameters object    
            if ~ishandle(this.Fig)
                return;
            end
            
            drawOriginalImages(this, board, boardIndex, stereoParams);
            
            if isempty(this.RectifyButton.Button) || ~ishandle(this.RectifyButton.Button)
                this.createRectifyButton();
            end
            
            if isempty(stereoParams)
                hide(this.RectifyButton);
            else
                reset(this.RectifyButton);
                this.RectifyButton.UnpushedFcn = @drawOriginalImagesCallback;
                this.RectifyButton.PushedFcn = @drawRectifiedImagesCallback;
            end
            
            drawnow();
            
            %--------------------------------------------------------------
            function drawOriginalImagesCallback(~, ~)
                drawOriginalImages(this, board, boardIndex, stereoParams);
            end
            
            %--------------------------------------------------------------
            function drawRectifiedImagesCallback(~, ~)
                drawRectifiedImages(this, board, stereoParams);
            end
                
        end
    end
    
    methods(Access=private)
        %------------------------------------------------------------------
        function drawOriginalImages(this, board, boardIndex, stereoParams)
            [I1, I2] = readImages(this, board.fileName);
            
            [I, offset] = ...
                vision.internal.calibration.tool.fuseWithSeparator(I1, I2);
            
            makeHandleVisible(this);
            drawImage(this, I);
            
            [p1, p2] = getDetectedPoints(this, board, offset);
                
            center1 = round([size(I1, 1), size(I1, 2)] / 2); 
            center2 = [center1(1), center1(2) + offset];
            showMissingImageWarnings(this, center1, center2, board.fileName);
                            
            if this.IsImage1Valid || this.IsImage2Valid
                plotDetectedPoints(this, p1, p2);                
                
                if ~isempty(stereoParams) && (boardIndex <= stereoParams.NumPatterns)
                    plotReprojectedPoints(this, stereoParams, boardIndex, offset);
                end
                
                drawCoordinateAxes(this, board.boardSize, p1, p2);
                
                showLegend(this);
            end
            setTitle(this, board.label);  
            
            drawCameraLabels(this, I1, I);
            
            holdOff(this);
            set(this.Fig,'HandleVisibility','callback');
        end
        
        %------------------------------------------------------------------
        function [I1, I2] = readImages(this, fileNames)
            % Read image 1
            try
                I1 = imread(fileNames{1});
                this.IsImage1Valid = true;
            catch
                I1 = [];
                this.IsImage1Valid = false;
            end
            
            % Read image 2
            try
                I2 = imread(fileNames{2});
                this.IsImage2Valid = true;
            catch
                I2 = [];
                this.IsImage2Valid = false;
            end
                        
            % Deal with missing images
            if isempty(I1) && isempty(I2)
                emptyImageSize = [480, 640];
                I1 = zeros(emptyImageSize);
                I2 = zeros(emptyImageSize);
            elseif isempty(I1)
                I1 = zeros(size(I2), 'like', I2);
            elseif isempty(I2)
                I2 = zeros(size(I1), 'like', I1);
            end
            
            % Handle the case when one image is grayscale and the other RGB
            if size(I1, 3) ~= size(I2, 3)
                if ismatrix(I1)
                    I1 = repmat(I1, [1,1,3]);
                else
                    I2 = repmat(I2, [1,1,3]);
                end
            end
        end
        
        %------------------------------------------------------------------
        function [p1, p2] = getDetectedPoints(this, board, offset)
            if this.IsImage1Valid
                p1 = board.detectedPoints(:,:,:, 1);
            else
                p1 = zeros(0, 2);
            end
            
            if this.IsImage2Valid
                p2 = board.detectedPoints(:,:,:, 2);
                p2(:, 1) = p2(:, 1) + offset;
            else
                p2 = zeros(0, 2);
            end
        end
        
        %------------------------------------------------------------------
        function showMissingImageWarnings(this, center1, center2, fileNames)
            hAxes = getImageAxes(this);
            if ~this.IsImage1Valid
                text(center1(2), center1(1), ['Cannot read ', fileNames{1}], ...
                'Color', 'w', 'Parent', hAxes, 'HorizontalAlignment', 'center');
            end
            
            if ~this.IsImage2Valid
                text(center2(2), center2(1), ['Cannot read ', fileNames{2}], ...
                'Color', 'w', 'Parent', hAxes, 'HorizontalAlignment', 'center');
            end
        end            
            
        %------------------------------------------------------------------
        function drawCameraLabels(this, I1, I)
            loc1 = [size(I1, 2)-10, size(I, 1) - 20];
            drawCameraLabel(this, loc1, 'Camera 1');
            
            loc2 = [size(I, 2)-10, size(I, 1) - 20];
            drawCameraLabel(this, loc2, 'Camera 2');
        end
        
        %------------------------------------------------------------------
        function drawCameraLabel(this, loc, label)
            fontSize = 0.05;
            text(loc(1), loc(2), label, 'Parent', getImageAxes(this), ...
                'Color', 'black',...
                'FontUnits', 'normalized', 'FontSize', fontSize, ...
                'BackgroundColor', 'white',...
                'EdgeColor', 'black',...
                'Clipping', 'on', 'HorizontalAlignment', 'right');
        end
        
        %------------------------------------------------------------------
        function drawRectifiedImages(this, board, stereoParams)
            [I1, I2] = readImages(this, board.fileName);        
            try
                prevWarning = warning('OFF', 'vision:calibrate:switchValidViewToFullView');
                cl = onCleanup(@()warning(prevWarning));
                [I1, I2] = rectifyStereoImages(I1, I2, stereoParams);
                cl.delete();
            catch e
                error(message('vision:caltool:unableToRectifyImages'));
            end
            
            I = vision.internal.calibration.tool.fuseWithSeparator(I1, I2);            
            drawImage(this, I);
            plotEpipolarLines(this, I);
            
            drawCameraLabels(this, I1, I);
            
            setTitle(this, board.label);
            holdOff(this);
            set(this.Fig,'HandleVisibility','callback');
        end
            
        %------------------------------------------------------------------
        function plotEpipolarLines(this, I)
            numLines = 10;
            
            X = [1; size(I, 2)];
            X = repmat(X, [1, numLines]);
            
            interval = floor(size(I, 1) / (numLines + 1));            
            Y = interval:interval:size(I, 1)-interval+1;
            Y = [Y; Y];
            
            hAxes = getImageAxes(this);
            line(X, Y, 'Parent', hAxes);
        end
        
        %------------------------------------------------------------------
        function plotDetectedPoints(this,p1, p2)
            hAxes = getImageAxes(this);
            
            pointsToPlot = [p1(2:end, :); p2(2:end, :)];
            plot(hAxes, pointsToPlot(:,1), pointsToPlot(:,2),'go','LineWidth', 1,'MarkerSize', 10);
            
            detectedLegend = vision.getMessage('vision:caltool:DetectedLegend');
            this.LegendEntries = {detectedLegend};
        end
        
        %------------------------------------------------------------------
        function drawCoordinateAxes(this, boardSize, p1, p2)
            hAxes = getImageAxes(this);
            import vision.internal.calibration.tool.*;
            if this.IsImage1Valid
                drawCoordinateAxes(boardSize, hAxes, p1);
            end
            
            if this.IsImage2Valid
                drawCoordinateAxes(boardSize, hAxes, p2);
            end
            
            if this.IsImage1Valid || this.IsImage2Valid
                originLegend = vision.getMessage('vision:caltool:CheckerboardOrigin');
                this.LegendEntries{end+1} = originLegend;
            end
        end
            
        %------------------------------------------------------------------
        function plotReprojectedPoints(this, stereoParams, boardIndex, offset)
            
            if this.IsImage1Valid
                p1 = stereoParams.CameraParameters1.ReprojectedPoints(:, :, boardIndex);
            else
                p1 = zeros(0, 2);
            end
            
            if this.IsImage2Valid
                p2 = stereoParams.CameraParameters2.ReprojectedPoints(:, :, boardIndex);
                p2(:, 1) = p2(:, 1) + offset;
            else
                p2 = zeros(0, 2);
            end
            
            if this.IsImage1Valid || this.IsImage2Valid
                hAxes = getImageAxes(this);
                pointsToPlot = [p1; p2];
                plot(hAxes, pointsToPlot(:,1), pointsToPlot(:,2),'r+','LineWidth', 1,'MarkerSize', 8);
                
                reprojectedLegend = vision.getMessage('vision:caltool:ReprojectedLegend');
                this.LegendEntries{end+1} = reprojectedLegend;
            end
        end
        
        %------------------------------------------------------------------
        function createRectifyButton(this)
            this.RectifyButton.Parent = this.Fig;
            this.RectifyButton.UnpushedName = ...
                vision.getMessage('vision:caltool:ShowRectified');
            this.RectifyButton.UnpushedToolTip = ...
                vision.getMessage('vision:caltool:ShowRectifiedStereoImagesToolTip');
            this.RectifyButton.PushedName = ...
                vision.getMessage('vision:caltool:UndistortOriginal');
            this.RectifyButton.PushedToolTip = ...
                vision.getMessage('vision:caltool:ShowOriginalStereoImagesToolTip');                
            this.RectifyButton.Tag = 'RectifyButton';
            this.RectifyButton.Position = [5 5 140 20];
            create(this.RectifyButton);
        end        
    end
end
       