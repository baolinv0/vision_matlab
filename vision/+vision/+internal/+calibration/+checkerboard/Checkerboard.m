%#codegen

classdef Checkerboard < handle
    properties(GetAccess=public, SetAccess=public)
        isValid = false;
        Energy = single(inf);        
        BoardCoords;
        BoardIdx;
    end
    
    properties(Access=private)        
        Points;      
        IsDirectionBad = false(1, 4);
        LastExpandDirection = 1; %'up'
        PreviousEnergy = single(inf);
    end
    
    methods        
        function this = Checkerboard()
            this.BoardIdx = 0;
            this.BoardIdx = zeros(3, 3);      
            this.BoardCoords = 0;
            this.BoardCoords = zeros(3, 3, 2);  
        end
        
        function initialize(this, seedIdx, points, v1, v2)
            % Constructor. Creates a 4x4 checkerboard with the seed point
            % in the center. points is an Mx2 matrix of x,y coordinates of
            % all possible checkerboard corners. seedIdx is the index of
            % the seed point. The coordinates of the seed point are
            % points(seedIdx, :). e1 and e2 are 2-element vectors
            % specifying the edge orientations at the seed point.
            
            this.BoardIdx = 0;
            this.BoardIdx = zeros(3, 3);                                
            this.IsDirectionBad = false(1, 4);
            this.BoardCoords = 0;
            this.BoardCoords = zeros(3, 3, 2);            
            this.Points = points;
            center = this.Points(seedIdx, :);            
            this.BoardIdx(2, 2) = seedIdx;
            this.BoardCoords(2, 2, :) = center;
            this.LastExpandDirection = 1; %'up';
            this.PreviousEnergy = single(inf);
            this.isValid = false;
            
            % compute distances from all the points to the center
            pointVectors = bsxfun(@minus, this.Points, center);
            euclideanDists = hypot(pointVectors(:, 1), pointVectors(:, 2));
            
            % find vertical and horizontal neighbors
            [this.BoardIdx(2, 3)] = findNeighbor(this, pointVectors, euclideanDists, v1);
            [this.BoardIdx(2, 1)] = findNeighbor(this, pointVectors, euclideanDists, -v1);            
            [this.BoardIdx(3, 2)] = findNeighbor(this, pointVectors, euclideanDists, v2);            
            [this.BoardIdx(1, 2)] = findNeighbor(this, pointVectors, euclideanDists, -v2);
            
            if any(this.BoardIdx(:) < 0)
                this.isValid = false;
                return;
            end
            
            r = this.Points(this.BoardIdx(2, 3), :);
            this.BoardCoords(2, 3, :) = r;
            l = this.Points(this.BoardIdx(2, 1), :);
            this.BoardCoords(2, 1, :) = l;
            d = this.Points(this.BoardIdx(3, 2), :);
            this.BoardCoords(3, 2, :) = d;
            u = this.Points(this.BoardIdx(1,2), :);
            this.BoardCoords(1, 2, :) = u;
                       
            % find diagonal neighbors
            up    = u - center;
            down  = d - center;
            right = r - center;
            left  = l - center;
            
            [this.BoardIdx(1, 1)] = findNeighbor(this, pointVectors, euclideanDists, up + left);
            [this.BoardIdx(3, 1)] = findNeighbor(this, pointVectors, euclideanDists, down + left);
            [this.BoardIdx(3, 3)] = findNeighbor(this, pointVectors, euclideanDists, down + right);
            [this.BoardIdx(1, 3)] = findNeighbor(this, pointVectors, euclideanDists, up + right);
            this.isValid = all(this.BoardIdx(:) > 0);
            if ~this.isValid
                return;
            end
            
            this.BoardCoords(1, 1, :) = this.Points(this.BoardIdx(1, 1), :);
            this.BoardCoords(3, 1, :) = this.Points(this.BoardIdx(3, 1), :);
            this.BoardCoords(3, 3, :) = this.Points(this.BoardIdx(3, 3), :);
            this.BoardCoords(1, 3, :) = this.Points(this.BoardIdx(1, 3), :);
            
            this.Energy = computeInitialEnergy(this);
            % a perfect initial board should have the energy of -9.
            maxEnergy = -7;
            this.isValid = this.Energy < maxEnergy;                        
        end
    end

    methods(Access=private)
        %------------------------------------------------------------------
        function e = computeInitialEnergy(this)
            if any(this.BoardIdx(:) < 0)
                e = single(inf);
                return;
            end
            
            e = single(0);
            
            % compute energy over rows
            row1 = this.getPoints(1, 1:3);
            row2 = this.getPoints(2, 1:3);
            row3 = this.getPoints(3, 1:3);
            
            num = row1 + row3 - 2 * row2;
            denom = row1 - row3;
            e = max(e, max(hypot(num(:, 1), num(:, 2)) ./ hypot(denom(:, 1), denom(:, 2))));
            
            % compute energy over columns
            col1 = this.getPoints(1:3, 1);
            col2 = this.getPoints(1:3, 2);
            col3 = this.getPoints(1:3, 3);
            
            num = col1 + col3 - 2 * col2;
            denom = col1 - col3;
            e = max(e, max(hypot(num(:, 1), num(:, 2)) ./ hypot(denom(:, 1), denom(:, 2))));
            
            boardSize = single(numel(this.BoardIdx));
            e = boardSize * e - boardSize;
        end
    end
    
    methods
        %------------------------------------------------------------------
        function this = expandBoardFully(this)
            % expands the board as far as possible
            if ~this.isValid
                return;
            end
            
            hasExpanded = true;
            while hasExpanded
                hasExpanded = this.expandBoardOnce();
            end
        end
        
        %------------------------------------------------------------------
        function plot(this)
            % plot the detected checkerboard points
            idx = this.BoardIdx';
            idx = idx(idx > 0);
            points = this.Points(idx, :);
            plot(points(:, 1), points(:, 2), 'r*-'); hold on;
            text(this.BoardCoords(1, 1, 1), this.BoardCoords(1, 1, 2), '(0,0)', 'Color', [1 0 0]);
        end
        
        %------------------------------------------------------------------
        function [points, boardSize] = toPoints(this)
            % returns the points as an Mx2 matrix of x,y coordinates, and
            % the size of the board
            
            if any(this.BoardIdx(:) == 0)
                points = [];
                boardSize = [0 0];
                return;
            end
            
            numPoints = size(this.BoardCoords, 1) * size(this.BoardCoords, 2);
            points = zeros(numPoints, 2);
            x = this.BoardCoords(:, :, 1)';
            points(:, 1) = x(:);
            y = this.BoardCoords(:, :, 2)';
            points(:, 2) = y(:);
            boardSize = [size(this.BoardCoords, 2)+1, size(this.BoardCoords, 1)+1];
        end
    end
    
    methods(Access=private)        
        %------------------------------------------------------------------
        function neighborIdx = findNeighbor(this, pointVectors, euclideanDists, v)
            % find the nearest neighbor point in the direction of vector v
            
            % compute normalized dot products
            angleCosines = pointVectors * v' ./ (euclideanDists * hypot(v(1), v(2)));
            
            % dists is a linear combination of euclidean distances and
            % "directional distances"
            dists = euclideanDists + 1.5 * euclideanDists .* (1 - angleCosines);
            
            % eliminate points already in the board
            dists(this.BoardIdx(this.BoardIdx > 0)) = inf; 
            
            % eliminate points "behind" the center
            dists(angleCosines < 0) = inf;
            
            % find the nearest neighbor
            [dirDist, neighborIdx] = min(dists);
            if isinf(dirDist)
                neighborIdx = -1;
            end
        end
                        
        %------------------------------------------------------------------
        function p = getPoints(this, i, j)
            p = single(this.Points(this.BoardIdx(i, j), :));
        end
        
        %------------------------------------------------------------------
        function success = expandBoardOnce(this)
            %directions = {'up', 'down', 'left', 'right'};      
            %directions = [1 2 3 4];
            this.PreviousEnergy = this.Energy;            
            for i = 1:4
                if ~this.IsDirectionBad(i)
                    this.LastExpandDirection = i;
                    expandBoardDirectionally(this, i);
                    if this.Energy < this.PreviousEnergy
                        success = true;
                        return;
                    else
                        this.undoLastExpansion();
                        this.IsDirectionBad(i) = true;
                    end
                end
            end                
            success = false;
        end
        
        %------------------------------------------------------------------
        function undoLastExpansion(this)
            this.Energy = this.PreviousEnergy;            
            switch this.LastExpandDirection
                case 1 %'up'
                    this.BoardIdx = this.BoardIdx(2:end, :);
                    this.BoardCoords = this.BoardCoords(2:end, :, :);

                case 2 %'down'
                    this.BoardIdx = this.BoardIdx(1:end-1, :);
                    this.BoardCoords = this.BoardCoords(1:end-1, :, :);
                    
                case 3 %'left'
                    this.BoardIdx = this.BoardIdx(:, 2:end);
                    this.BoardCoords = this.BoardCoords(:, 2:end, :);
                    
                case 4 %'right'
                    this.BoardIdx = this.BoardIdx(:, 1:end-1);
                    this.BoardCoords = this.BoardCoords(:, 1:end-1, :);
            end
        end        
                
        %------------------------------------------------------------------
        function expandBoardDirectionally(this, direction)
            oldEnergy = (this.Energy + numel(this.BoardIdx)) / numel(this.BoardIdx);
            switch direction
                case 1 %'up'
                    idx = 1:3;
                    predictedPoints = predictPointsVertical(this, idx);
                    newIndices = findClosestIndices(this, predictedPoints);                    
                    [this.BoardIdx, this.BoardCoords] = expandBoardUp(this, newIndices);
                    newEnergy = computeNewEnergyVertical(this, idx, oldEnergy);
                    
                case 2 %'down'
                    numRows = size(this.BoardCoords, 1);
                    idx = numRows:-1:numRows-2;
                    predictedPoints = predictPointsVertical(this, idx);
                    newIndices = findClosestIndices(this, predictedPoints);
                    [this.BoardIdx, this.BoardCoords] = expandBoardDown(this, newIndices); 
                    idx = idx + 1;
                    newEnergy = computeNewEnergyVertical(this, idx, oldEnergy);
                                     
                case 3 %'left'
                    idx = 1:3;
                    predictedPoints = predictPointsHorizontal(this, idx);
                    newIndices = findClosestIndices(this, predictedPoints);
                    [this.BoardIdx, this.BoardCoords] = expandBoardLeft(this, newIndices);     
                    newEnergy = computeNewEnergyHorizontal(this, idx, oldEnergy);
                                     
                case 4 %'right'
                    numCols = size(this.BoardCoords, 2);
                    idx = numCols:-1:numCols-2;
                    predictedPoints = predictPointsHorizontal(this, idx);
                    newIndices = findClosestIndices(this, predictedPoints);                    
                    [this.BoardIdx, this.BoardCoords] = expandBoardRight(this, newIndices);  
                    idx = idx + 1;
                    newEnergy = computeNewEnergyHorizontal(this, idx, oldEnergy);  
                otherwise
                    newEnergy = single(inf);
                    
            end
            
            this.Energy = newEnergy;
        end
        
        %------------------------------------------------------------------
        function newPoints = predictPointsVertical(this, idx)
            p1 = squeeze(this.BoardCoords(idx(2), :, :));
            p2 = squeeze(this.BoardCoords(idx(1), :, :));
            newPoints = p2 + p2 - p1;
        end
        
        %------------------------------------------------------------------
        function newPoints = predictPointsHorizontal(this, idx)
            p1 = squeeze(this.BoardCoords(:, idx(2), :));
            p2 = squeeze(this.BoardCoords(:, idx(1), :));
            newPoints = p2 + p2 - p1;
        end
        
        %------------------------------------------------------------------
        function indices = findClosestIndices(this, predictedPoints)
            % returns indices of points closest to the predicted points
            
            indices = zeros(1, size(predictedPoints, 1));
            for i = 1:size(predictedPoints, 1)
                p = predictedPoints(i, :);
                diffs = bsxfun(@minus, this.Points, p);
                dists = hypot(diffs(:, 1), diffs(:, 2));
                dists(indices(indices > 0)) = inf;
                [~, indices(i)] = min(dists);
            end
        end
        
        %------------------------------------------------------------------
        function [newBoard, newBoardCoords] = expandBoardUp(this, indices)
            newBoard = zeros(size(this.BoardIdx, 1)+1, size(this.BoardIdx, 2));
            newBoard(1, :) = indices;
            newBoard(2:end, :) = this.BoardIdx;
            
            newBoardCoords = zeros(size(this.BoardCoords, 1)+1, ...
                size(this.BoardCoords, 2), size(this.BoardCoords, 3));
            newBoardCoords(1, :, :) = this.Points(indices, :);
            newBoardCoords(2:end, :, :) = this.BoardCoords;
        end

        %------------------------------------------------------------------
        function [newBoard, newBoardCoords] = expandBoardDown(this, indices)
            newBoard = zeros(size(this.BoardIdx, 1)+1, size(this.BoardIdx, 2));
            newBoard(end, :) = indices;
            newBoard(1:end-1, :) = this.BoardIdx;
            
            newBoardCoords = zeros(size(this.BoardCoords, 1)+1, ...
                size(this.BoardCoords, 2), size(this.BoardCoords, 3));
            newBoardCoords(end, :, :) = this.Points(indices, :);
            newBoardCoords(1:end-1, :, :) = this.BoardCoords;
        end

        %------------------------------------------------------------------
        function [newBoard, newBoardCoords] = expandBoardLeft(this, indices)
            newBoard = zeros(size(this.BoardIdx, 1), 1 + size(this.BoardIdx, 2));
            newBoard(:, 1) = indices;
            newBoard(:, 2:end) = this.BoardIdx;
            
            newBoardCoords = zeros(size(this.BoardCoords, 1), ...
                size(this.BoardCoords, 2) + 1, size(this.BoardCoords, 3));
            newBoardCoords(:, 1, :) = this.Points(indices, :);
            newBoardCoords(:, 2:end, :) = this.BoardCoords;            
        end
        
        %------------------------------------------------------------------
        function [newBoard, newBoardCoords] = expandBoardRight(this, indices)
            newBoard = zeros(size(this.BoardIdx, 1), 1 + size(this.BoardIdx, 2));
            newBoard(:, end) = indices;
            newBoard(:, 1:end-1) = this.BoardIdx;
            
            newBoardCoords = zeros(size(this.BoardCoords, 1), ...
                size(this.BoardCoords, 2) + 1, size(this.BoardCoords, 3));
            newBoardCoords(:, end, :) = this.Points(indices, :);
            newBoardCoords(:, 1:end-1, :) = this.BoardCoords;                        
        end        
        
        %------------------------------------------------------------------
        function newEnergy = computeNewEnergyVertical(this, idx, oldEnergy)
            num = squeeze(this.BoardCoords(idx(1),:,:) + this.BoardCoords(idx(3),:,:) ...
                - 2*this.BoardCoords(idx(2),:,:));
            denom = squeeze(this.BoardCoords(idx(1),:,:) - this.BoardCoords(idx(3),:,:));
            newEnergy = max(oldEnergy, ...
                max(hypot(num(:, 1), num(:,2)) ./ hypot(denom(:, 1), denom(:, 2))));
            
            for i = 1:size(this.BoardCoords, 2)-2
                num = this.BoardCoords(idx(1), i, :) + this.BoardCoords(idx(1), i+2, :)...
                    - 2*this.BoardCoords(idx(1), i+1, :);
                denom = this.BoardCoords(idx(1), i, :) - this.BoardCoords(idx(1),i+2,:);
                newEnergy = max(newEnergy, norm(num(:)) ./ norm(denom(:)));
            end
            newEnergy = newEnergy * numel(this.BoardIdx) - numel(this.BoardIdx);
        end
        
        %------------------------------------------------------------------
        function newEnergy = computeNewEnergyHorizontal(this, idx, oldEnergy)
            num = squeeze(this.BoardCoords(:,idx(1),:) + this.BoardCoords(:,idx(3),:) ...
                - 2*this.BoardCoords(:,idx(2),:));
            denom = squeeze(this.BoardCoords(:,idx(1),:) - this.BoardCoords(:,idx(3),:));
            newEnergy = max(oldEnergy, ...
                max(hypot(num(:, 1), num(:,2)) ./ hypot(denom(:, 1), denom(:, 2))));
            
            for i = 1:size(this.BoardCoords, 1)-2
                num = this.BoardCoords(i, idx(1), :) + this.BoardCoords(i+2, idx(1), :)...
                    - 2*this.BoardCoords(i+1, idx(1), :);
                denom = this.BoardCoords(i, idx(1), :) - this.BoardCoords(i+2,idx(1),:);
                newEnergy = max(newEnergy, norm(num(:)) ./ norm(denom(:)));
            end
            newEnergy = newEnergy * numel(this.BoardIdx) - numel(this.BoardIdx);
        end        
    end
end