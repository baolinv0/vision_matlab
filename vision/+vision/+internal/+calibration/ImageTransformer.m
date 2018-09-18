% ImageTransformer Object for applying an arbitrary transformation to an image.
%
% transformer = ImageTransformer returns an image transformer object.
%
% ImageTransformer methods:
% -------------------------
% transformImage - Apply a transformation to an image.
% needToUpdate   - Returns true if the map needs to be updated.
% update         - Recompute the map.

% Copyright 2012-2013 MathWorks, Inc.

%#codegen

classdef ImageTransformer < handle
    
    properties (GetAccess=public, SetAccess=private)
        % the map
        Xmap = 0;
        Ymap = 0;
        
        XmapSingle = single(0);
        YmapSingle = single(0);
        
        NewOrigin = [0 0];
    end
    
    properties(Access=private)
        % needed for lazy evaluation
        SizeOfImage = [0 0];
        ClassOfImage = 'a';        
        
        % Output bounds
        OutputView = 'same';
        XBounds = [-1 -1];
        YBounds = [-1 -1];    
        
        IsIppOn = 1;
    end
    
    methods(Access=public)        
        
        function this = ImageTransformer()
            % make variables var-size for codegen.
            this.SizeOfImage = [0 0];
            this.SizeOfImage = [0 0 0];
            this.ClassOfImage = 'a';
            this.ClassOfImage = 'uint8';
            this.OutputView = 'a';
            this.OutputView = 'same';
            
            this.Xmap = zeros(2);
            this.Ymap = zeros(2);
            
            this.XmapSingle = zeros(2, 'single');
            this.YmapSingle = zeros(2, 'single');            
        end
        
        % needToUpdate Returns true if the image has changed and the map 
        % needs to be recomputed.
        function tf = needToUpdate(this, I, outputView)  
           sameSize = isequal(this.SizeOfImage, size(I));
           sameClass = strcmp(class(I), this.ClassOfImage);
           sameOutputView = isequal(this.OutputView, outputView);
           sameIpp = ~isempty(coder.target) || (this.IsIppOn == ippl());
           
           tf = ~(sameSize && sameClass && sameOutputView && sameIpp);
        end
                
        % update Recompute the map if the image has changed
        function this = update(this, I, intrinsicMatrix, radialDist,...
                tangentialDist, outputView, ...
                xBounds, yBounds, H)

            if isempty(coder.target)
                this.IsIppOn = ippl();
            end
            
            this.SizeOfImage  = size(I);
            this.ClassOfImage = class(I);
            this.OutputView = outputView;
            this.XBounds = xBounds;
            this.YBounds = yBounds;
            this.NewOrigin = [this.XBounds(1), this.YBounds(1)] - 1;
            
            if nargin > 8
                computeMap(this, intrinsicMatrix, radialDist, tangentialDist, H);
            else
                computeMap(this, intrinsicMatrix, radialDist, tangentialDist);
            end            
        end
        
        % transformImage Apply the transformation to an image
        % [J, newOrigin] = transformImage(this, I, interp, inversFcn, fillValues) 
        % transforms image I. 
        function [J, newOrigin] = transformImage(this, I, interp, fillValues)            
            if isempty(coder.target)
                if isa(I, 'double')
                    J = vision.internal.calibration.interp2d(I, this.Xmap, this.Ymap, ...
                        interp, fillValues);
                else
                    J = vision.internal.calibration.interp2d(I, this.XmapSingle, ...
                        this.YmapSingle, interp, fillValues);
                end
            else
                if isa(I, 'double')
                    J = images.internal.coder.interp2d(I, this.Xmap, this.Ymap, ...
                        interp, fillValues, false);
                else
                    J = images.internal.coder.interp2d(I, this.XmapSingle, ...
                        this.YmapSingle, interp, fillValues, false);
                end
            end
            
            newOrigin = [this.XBounds(1), this.YBounds(1)] - 1;
        end
    end
    
    methods(Access=private)                                      
        %------------------------------------------------------------------
        % Compute the map for image transformation.
        %------------------------------------------------------------------
        function computeMap(this, intrinsicMatrix, radialDist, tangentialDist, H)
            [X, Y] = meshgrid(this.XBounds(1):this.XBounds(2),...
                this.YBounds(1):this.YBounds(2));
            ptsIn = [X(:) Y(:)]; % remapmex requires singles
            
            if nargin > 4
                ptsIn = H.transformPointsInverse(ptsIn);
            end
            
            if isempty(coder.target)
                ptsOut = visionDistortPoints(ptsIn, ...
                    intrinsicMatrix', radialDist, tangentialDist);
            else
                ptsOut = vision.internal.calibration.distortPoints(ptsIn, ...
                    intrinsicMatrix, radialDist, tangentialDist);                
            end
            
            clear ptsIn; % be careful with memory
            
            m = this.YBounds(2) - this.YBounds(1) + 1;
            n = this.XBounds(2) - this.XBounds(1) + 1;
            
            if isempty(coder.target)
                if ippl()
                    pad = -1;
                else
                    pad = 0;
                end
            else
                pad = 0;
            end
            
            if strcmp(this.ClassOfImage, 'double')
                this.Xmap = reshape(ptsOut(:,1),[m n]) + pad;
                this.Ymap = reshape(ptsOut(:,2),[m n]) + pad;
            else
                this.XmapSingle = cast(reshape(ptsOut(:,1),[m n]), 'single') + ...
                    single(pad);
                this.YmapSingle = cast(reshape(ptsOut(:,2),[m n]), 'single') + ...
                    single(pad);
            end                        
        end
    end
end

