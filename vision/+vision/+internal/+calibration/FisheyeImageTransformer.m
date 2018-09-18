% FisheyeImageTransformer Object for applying an arbitrary transformation to an image.
%
% transformer = FisheyeImageTransformer returns an image transformer object.
%
% FisheyeImageTransformer methods:
% -------------------------
% transformImage - Apply a transformation to an image.
% needToUpdate   - Returns true if the map needs to be updated.
% update         - Recompute the map.

% Copyright 2017 MathWorks, Inc.

%#codegen

classdef FisheyeImageTransformer < handle
    
    properties (GetAccess=public, SetAccess=private)
        % the map
        Xmap = 0;
        Ymap = 0;
        
        XmapSingle = single(0);
        YmapSingle = single(0);        
    end
    
    properties(Access=private)
        % needed for lazy evaluation
        SizeOfImage = [0 0];
        ClassOfImage = 'a';        
        
        % Output bounds
        OutputView = 'same';
        XBounds = [-1 -1];
        YBounds = [-1 -1];    
        
        % Focal length
        FocalLength = [0 0];
        % Principal point
        PrincipalPoint = [0 0];
        
        IsIppOn = 1;
        
        MappingPoints = 0;
        MappingMethod = 'approximate';
    end
    
    properties(Dependent)
        Intrinsics;
    end
    
    methods(Access=public)        
        
        function this = FisheyeImageTransformer()
            % make variables var-size for codegen.
            this.SizeOfImage = [0 0];
            this.SizeOfImage = [0 0 0];
            this.ClassOfImage = 'a';
            this.ClassOfImage = 'uint8';
            this.OutputView = 'a';
            this.OutputView = 'same';
            this.MappingMethod = 'exact';
            this.MappingMethod = 'approximate';
            
            this.Xmap = zeros(2);
            this.Ymap = zeros(2);
            
            this.XmapSingle = zeros(2, 'single');
            this.YmapSingle = zeros(2, 'single');            
        end
        
        % needToUpdate Returns true if the image has changed and the map 
        % needs to be recomputed.
        function tf = needToUpdate(this, I, outputView, focalLength, method)  
           sameSize = isequal(this.SizeOfImage, size(I));
           sameClass = strcmp(class(I), this.ClassOfImage);
           sameOutputView = isequal(this.OutputView, outputView);
           sameFocalLength = isequal(this.FocalLength, focalLength);
           sameIpp = ~isempty(coder.target) || (this.IsIppOn == ippl());
           sameMethod = strcmp(this.MappingMethod, method);
           
           tf = ~(sameSize && sameClass && sameOutputView ...
               && sameFocalLength && sameIpp && sameMethod);
        end
                
        % update Recompute the map if the configuration has changed
        function this = update(this, I, mappingCoefficients, stretchMatrix,...
                distortionCenter, outputView, xBounds, yBounds, ...
                focalLength, principalPoint, method)

            if isempty(coder.target)
                this.IsIppOn = ippl();
            end
            
            this.SizeOfImage  = size(I);
            this.ClassOfImage = class(I);
            this.OutputView = outputView;
            
            skipMappingStep = false;
            if (isequal(this.XBounds, xBounds) && ...
                isequal(this.YBounds, yBounds) && ...
                isequal(this.FocalLength, focalLength) && ...
                isequal(this.PrincipalPoint, principalPoint) && ...
                strcmp(this.MappingMethod, method))
                skipMappingStep = true;
            else
                this.XBounds = xBounds;
                this.YBounds = yBounds;
                this.FocalLength = focalLength;
                this.PrincipalPoint = principalPoint;
                this.MappingMethod = method;
            end
            computeMap(this, mappingCoefficients, stretchMatrix, ...
                distortionCenter, method, skipMappingStep);
        end
        
        % transformImage Apply the transformation to an image
        function J = transformImage(this, I, interp, fillValues)
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
        end        
    end
    
    methods
        %------------------------------------------------------------------
        function intrinsics = get.Intrinsics(this)
            imageSize = [this.YBounds(2)-this.YBounds(1)+1, ...
                         this.XBounds(2)-this.XBounds(1)+1];
            intrinsics = cameraIntrinsics(this.FocalLength, ...
                this.PrincipalPoint, imageSize);
        end
    end
    
    methods(Access=private)                                      
        %------------------------------------------------------------------
        % Compute the map for image transformation.
        %------------------------------------------------------------------
        function computeMap(this, mappingCoefficients, stretchMatrix, ...
                distortionCenter, method, skipMappingStep)
            if ~skipMappingStep
                
                [X, Y] = meshgrid(this.XBounds(1):this.XBounds(2),...
                    this.YBounds(1):this.YBounds(2));
                points = [X(:) Y(:)]; % remapmex requires singles

                u = (points(:, 1) - this.PrincipalPoint(1)) / this.FocalLength(1);
                v = (points(:, 2) - this.PrincipalPoint(2)) / this.FocalLength(2);
                points3D = [u, v, ones(numel(u), 1)];

                if strcmp(method, 'exact')
                    ptsOut = vision.internal.calibration.computeImageProjection(...
                        points3D, mappingCoefficients, stretchMatrix, distortionCenter);
                else
                    ptsOut = vision.internal.calibration.computeApproxImageProjection(...
                        points3D, mappingCoefficients, stretchMatrix, distortionCenter);
                end
                
                clear points3D; % be careful with memory
                this.MappingPoints = ptsOut;
            end
            
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
                this.Xmap = reshape(this.MappingPoints(:,1),[m n]) + pad;
                this.Ymap = reshape(this.MappingPoints(:,2),[m n]) + pad;
            else
                this.XmapSingle = cast(reshape(this.MappingPoints(:,1),[m n]), 'single') + ...
                    single(pad);
                this.YmapSingle = cast(reshape(this.MappingPoints(:,2),[m n]), 'single') + ...
                    single(pad);
            end                        
        end
    end
end

      
