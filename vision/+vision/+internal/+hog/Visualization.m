%Visualization Displays HOG features.
%  Visualization is a visualization of HOG features extracted from an
%  image. This visualization is returned by the extractHOGFeatures function
%  and can be displayed using plot.
%
%  plot(visualization) plots the HOG features as an array of rose
%  plots. Each rose plot shows the distribution of edge directions within a
%  cell. The distribution is visualized by a set of directed lines whose
%  lengths are scaled to indicate the contribution made by the gradients in
%  that particular direction. The line directions are fixed to the bin
%  centers of the orientation histograms and are between 0 and 360 degrees
%  measured counterclockwise from the positive X axis. The bin centers are
%  recorded in the BinCenters property.
%
%  plot(visualization, AX) plots HOG features into the axes AX.
%
%  plot(..., Name, Value) specifies additional name-value pair arguments:
%
%   'Color'
%       <a href="matlab:doc('ColorSpec')">ColorSpec</a>
%       Specifies the color used to plot HOG features.
%
%  Visualization properties:
%
%  CellSize             - Size of cells in pixels
%  BlockSize            - Number of cells in each block
%  BlockOverlap         - Overlap between adjacent blocks
%  NumBins              - Number of orientation bins
%  UseSignedOrientation - Determines if signed orientation values are used
%  BinCenters           - Centers of the histogram bins
%
%  Example 1 - Visualize HOG features
%  ----------------------------------
%
%    I1 = imread('gantrycrane.png');
%    [~, visualization] = extractHOGFeatures(I1,'CellSize',[32 32]);
%    plot(visualization)
%
%  Example 2 - Overlay HOG features on an image
%  --------------------------------------------
%
%    I2 = imread('gantrycrane.png');
%    [~, visualization2] = extractHOGFeatures(I2,'CellSize',[32 32]);
%    figure;
%    imshow(I2);
%    hold on
%    plot(visualization2, 'Color', 'green')
%
%  See also extractHOGFeatures

classdef(HandleCompatible) Visualization < matlab.mixin.CustomDisplay
    % ---------------------------------------------------------------------
    % Public read-only properties
    % ---------------------------------------------------------------------
    properties (GetAccess = public, SetAccess=protected)
        % CellSize - Size of a HOG cell in pixel units
        CellSize
        % BlockSize - Number of cells in each block
        BlockSize
        % BlockOverlap - Number of overlapping cells between adjacent 
        %                blocks
        BlockOverlap
        % NumBins - Number of orientation bins
        NumBins
        % UseSignedOrientation - Determines if signed orientation values
        % are used. When false, the orientation histogram range is
        % from 0 to 180 degrees. Otherwise it is between 0 and 360.
        UseSignedOrientation
        
    end
    
    % ---------------------------------------------------------------------
    % Public read-only properties
    % ---------------------------------------------------------------------
    properties(GetAccess = public, SetAccess = protected, Dependent = true)
        % BinCenters - Centers of the histogram bins
        BinCenters
    end
    
    % ---------------------------------------------------------------------
    % Protected properties
    % ---------------------------------------------------------------------   
    properties(Hidden, SetAccess = protected, GetAccess = protected) 
        Feature
        ImageSize
        Points        
    end
    
    % ---------------------------------------------------------------------
    % Hidden read-only properties
    % ---------------------------------------------------------------------
    properties(Hidden, SetAccess = protected, GetAccess = public)
        % WindowSize is accessed by external helper functions
        WindowSize
    end
    
    % ---------------------------------------------------------------------
    % Private properties
    % ---------------------------------------------------------------------
    properties(Hidden, Access = private, Dependent = true)
        BlockSizeInPixels
        BlockStepSize
    end
    
    methods    
        % -----------------------------------------------------------------
        % Plot method for visualizing HOG features
        % -----------------------------------------------------------------
        function hData = plot(this,varargin)
            %  plot(visualization) plots HOG features as an array of
            %  rose plots.
            %
            %  plot(visualization, AX) plots features into the axes AX.
            %
            %  plot(..., Name, Value) specifies additional name-value pair
            %  arguments:
            %
            %   'Color'
            %       <a href="matlab:doc('ColorSpec')">ColorSpec</a>
            %       Specifies the color used to plot HOG features.                        
            % 
            %  Example - Visualize HOG features
            %  ----------------------------------
            %
            %    I1 = imread('gantrycrane.png');
            %    [~, hogVis] = extractHOGFeatures(I1,'CellSize',[32 32]);
            %    plot(hogVis)
            
            [colorSpec, axes] = parseInputs(this, varargin{:});                        
            
            if isempty(this.Feature)
                warning(message('vision:extractHOGFeatures:nothingToPlot'));
                if nargout > 0
                    hData = [];
                end
            else
                                
                nBins  = this.NumBins;
                
                % average HOGs over overlapping cells
                numHOGs      = size(this.Feature,1);
                featureClass = class(this.Feature);
                avgHogs = zeros([floor(this.WindowSize./this.CellSize) nBins numHOGs], featureClass);
                for idx = 1:numHOGs
                    avgHogs(:,:,:,idx) = this.averageHOGs(idx);
                end
                
                [cellCentersXY, cIdx] = computeCellCenters(this);
                
                x = zeros(2, nBins, size(cellCentersXY,1), numHOGs);
                y = zeros(2, nBins, size(cellCentersXY,1), numHOGs);
                
                % compute spatial offset of HOG blocks when extracted around
                % point locations.
                if ~isempty(this.Points)
                    blockCenter = (this.WindowSize - mod(this.WindowSize,2))./2 + 1;                    
                    dxdy = bsxfun(@minus, round(this.Points), fliplr(blockCenter));
                else
                    dxdy = zeros(1,2);
                end
                
                endPoints = computeLineEndPoints(this);
                
                % scale factor based on cellSize, adjusted to look nice
                lineScale = min(this.CellSize)/2.5;
                
                for k = 1:numHOGs
                    f = avgHogs(:,:,:,k);
                    blockOffset = dxdy(k,:);
                    
                    for idx = 1:size(cellCentersXY,1)
                        startPoints  = ones([nBins 1])*(cellCentersXY(idx,:) + blockOffset);
                        
                        vals = squeeze(f(cIdx(idx,2), cIdx(idx,1), :));
                        
                        vals = vals./(norm(vals,2) + eps);
                        
                        if this.UseSignedOrientation
                            x1y1 = startPoints;
                        else
                            x1y1 = startPoints + lineScale .* bsxfun(@times,-endPoints,vals);
                        end
                        
                        x2y2 = startPoints + lineScale .* bsxfun(@times,endPoints,vals);
                        
                        pts = [x1y1 x2y2];
                        x(:,:,idx,k) = pts(:,[1 3])';
                        y(:,:,idx,k) = pts(:,[2 4])';
                    end
                end
                
                x = reshape(x,2,[]);
                y = reshape(y,2,[]);
                x(end+1,:) = NaN;
                y(end+1,:) = NaN;
                
                try
                    ax = newplot(axes);       
                    
                    % plot the hog cell lines and markers for cell centers.                    
                    lns = plot(x(:), y(:), '-', ...     
                        cellCentersXY(:,1), cellCentersXY(:,2), '.',...
                        'Color', colorSpec, ...
                        'Parent', ax, ...
                        'MarkerSize', 1);
                    
                    rects = zeros(1,numHOGs);
                    if ~isempty(this.Points)       
                        % add a rectangle around point locations
                        for k = 1:numHOGs
                            rects(k) = rectangle('Parent',ax,...
                                'EdgeColor',colorSpec,...
                                'Position',[dxdy(k,:)+0.5 ...
                                fliplr(this.CellSize.*this.BlockSize)]);
                        end                        
                    end
                catch aError
                    throwAsCaller(aError);
                end
                
                if ~ishold
                    ax = get(lns(1),'Parent');
                    set(ax,'Ydir','reverse','Color',[0 0 0]);                    
                    axis(ax,'image');
                    set(ax, ...
                        'XLim',[0 this.ImageSize(2)]+0.5, ...
                        'YLim',[0 this.ImageSize(1)]+0.5, ...
                        'YTickLabel','', ...
                        'XTickLabel','');
                end
                
                if nargout == 1
                    hData = [lns(1) rects];
                end
            end
        end
    end
    
    % ---------------------------------------------------------------------
    % Get methods for dependent properties
    % ---------------------------------------------------------------------
    methods
        % -----------------------------------------------------------------
        % Convert block size from cells to pixels
        % -----------------------------------------------------------------
        function sz = get.BlockSizeInPixels(this)
            sz = this.CellSize .* this.BlockSize;
        end
        
        % -----------------------------------------------------------------
        % Compute block step size from the overlap
        % -----------------------------------------------------------------
        function sz = get.BlockStepSize(this)
            sz = this.CellSize.*(this.BlockSize - this.BlockOverlap);
        end
        
        % -----------------------------------------------------------------
        % Compute bin centers based on NumBins and UseSignedOrientation
        % -----------------------------------------------------------------
        function centers = get.BinCenters(this)
            centers = computeBinCenters(this);
            if ~this.UseSignedOrientation
                centers = [centers; centers + 180];                
            end
            centers = double(sort(mod(centers, 360)));
        end
    end
    
    methods (Hidden)
        % -----------------------------------------------------------------
        % Constructor
        % -----------------------------------------------------------------
        function this = Visualization(features, params)
            if nargin > 0
                this.Feature    = features;
                this.NumBins    = single(params.NumBins);
                this.CellSize   = single(params.CellSize);
                this.ImageSize  = single(params.ImageSize);
                this.BlockSize  = single(params.BlockSize);
                this.WindowSize = single(params.WindowSize);
                this.BlockOverlap = single(params.BlockOverlap);
                this.UseSignedOrientation = params.UseSignedOrientation;  
                
                % check if HOG features are extracted around points
                if isfield(params,'Points')
                    if isnumeric(params.Points)
                        this.Points = params.Points;
                    else
                        this.Points = params.Points.Location;
                    end
                end
            end
        end
    end
    
    methods(Hidden, Access = private)
        % -----------------------------------------------------------------
        % Average HOG cells across overlapping blocks
        % -----------------------------------------------------------------
        function hog = averageHOGs(this, idx)
            
            numCellsPerWindow = floor(this.WindowSize./this.CellSize);                        
            accum = zeros([numCellsPerWindow this.NumBins], 'single');
            count = zeros(numCellsPerWindow);            
            
            hBlockSize = [this.NumBins this.BlockSize];
            
            numBlocks = single(vision.internal.hog.getNumBlocksPerWindow(this));
            
            % reshape features to simplify averaging
            features = reshape(this.Feature(idx,:), [prod(hBlockSize) numBlocks]);
            
            blockStep = this.BlockStepSize ./ this.CellSize;
            for j = 1:numBlocks(2)
                for i = 1:numBlocks(1)
                    hBlock = reshape(features(:,i,j), hBlockSize);
                    % offset for cells based on current block position
                    ox = (j-1)*blockStep(2);
                    oy = (i-1)*blockStep(1);
                    for x = 1:this.BlockSize(2)
                        for y = 1:this.BlockSize(1)
                            accum(oy+y, ox+x,:) = ...
                                squeeze(accum(oy+y,ox+x,:)) + hBlock(:,y,x);
                            count(oy+y, ox+x)   = count(oy+y, ox+x) + 1;
                        end
                    end
                end
            end
            
            % average overlapping cells
            count = repmat(count,[1 1 this.NumBins]);
            hog   = accum./(count + eps);
        end
    end
    
    % ---------------------------------------------------------------------
    % Custom display using matlab.mixin.CustomDisplay
    % ---------------------------------------------------------------------
    methods(Hidden, Access = protected)
        
        % -----------------------------------------------------------------
        % Create header for disp method
        % -----------------------------------------------------------------
        function header = getHeader(this)
            if ~isscalar(this)
                header = getHeader@matlab.mixin.CustomDisplay(this);
            else
                % Create a hyperlink that invokes the plot method
                headerStr = matlab.mixin.CustomDisplay.getClassNameForHeader(this);
                cmd = sprintf('<a href="matlab:plot(%s)">plot(%s)</a>',...
                    inputname(1),inputname(1));
                msg = sprintf('Type %s to visualize.', cmd);
                header = sprintf('%s\n\n   %s\n',headerStr,msg);
            end
            
        end
        % -----------------------------------------------------------------
        % Customize property display
        % -----------------------------------------------------------------
        function group = getPropertyGroups(~)
            plist = {'CellSize', 'BlockSize', 'BlockOverlap', ...
                'NumBins', 'UseSignedOrientation','BinCenters'};
            
            title = sprintf('Read-only properties:');
            group = matlab.mixin.util.PropertyGroup(plist,title);
            
        end
    end
    
    % ---------------------------------------------------------------------
    % Helper methods
    % ---------------------------------------------------------------------
    methods(Hidden, Access = protected)
        
        % -----------------------------------------------------------------
        % Compute cell centers in spatial and pixel coordinates
        % -----------------------------------------------------------------
        function [centers, indices] = computeCellCenters(this)
            cellSize = this.CellSize;            
            winSize  = this.WindowSize - rem(this.WindowSize,this.CellSize);
            
            % cell centers in spatial coordinates
            [cx,cy] = ndgrid(0.5 + (cellSize(2)/2:cellSize(2):winSize(2)),...
                0.5 + (cellSize(1)/2:cellSize(1):winSize(1)));
            
            % cell centers in pixel coordinates
            numCells = floor(this.WindowSize./this.CellSize);
            [cxIdx,cyIdy] = ndgrid(1:numCells(2),1:numCells(1));
            
            centers = [cx(:) cy(:)];
            indices = [cxIdx(:) cyIdy(:)];
        end
        
        % -----------------------------------------------------------------
        % Compute the bin centers in degrees
        % -----------------------------------------------------------------
        function binCenters = computeBinCenters(this)
            if this.UseSignedOrientation
                binRange = 360;
            else
                binRange = 180;
            end
            binWidth = binRange/this.NumBins;
            
            binCenters = (binWidth/2:binWidth:binRange)';  
            binCenters = binCenters + 90; % rotate to show edges
        end
        
        % -----------------------------------------------------------------
        % Compute the end points of the lines used to represent bin centers        
        % -----------------------------------------------------------------
        function endPoints = computeLineEndPoints(this)             
            centers = (computeBinCenters(this)) * pi/180;            
            endPoints = [cos(centers) -sin(centers)];
        end       
    end
end

% -------------------------------------------------------------------------
% Input parser for plot method
% -------------------------------------------------------------------------
function [colorSpec, axes] = parseInputs(x,varargin)

validateattributes(x,{'vision.internal.hog.Visualization'},...
    {'scalar'},'plot','',1);

p = inputParser;
addOptional  (p, 'axes', [], ...
    @vision.internal.inputValidation.validateAxesHandle);
addParameter(p, 'Color', 'white');

parse(p, varargin{:});

colorSpec = p.Results.Color;
axes      = p.Results.axes;

end
