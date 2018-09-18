% fisheyeIntrinsics Object for storing intrinsic fisheye camera parameters.
%
%   intrinsics = fisheyeIntrinsics(mappingCoeffs, imageSize, distortionCenter)
%   returns fisheyeIntrinsics object with [a0, a2, a3, a4] polynomial
%   coefficients, size of the image produced by the camera as [mrows,
%   ncols], and center of distortion specified as [cx, cy].
%   See <a href="matlab:doc('fisheyeParameters')">fisheyeParameters</a> for more details.
%
%   intrinsics = fisheyeIntrinsics(..., stretchMatrix) additionally takes a
%   2-by-2 transformation matrix describes the alignment between the sensor
%   plane and the image plane. The default value is an identity matrix.
%
%   fisheyeIntrinsics methods:
%      pointsToWorld - Map image points onto X-Y plane in world coordinates
%      worldToImage  - Project world points into the image
%
%   fisheyeIntrinsics properties (read only):
%      MappingCoefficients  - A 4-element vector [a0, a2, a3, a4] as
%                             described by Scaramuzza's Taylor model for
%                             the polynomial coefficients of the projection
%                             function.
%      
%      DistortionCenter     - A 2-element vector [cx, cy] that specifies
%                             the center of distortion in pixels.
%
%      StretchMatrix        - A 2-by-2 transformation matrix that
%                             transforms a point from the sensor plane to a
%                             pixel in the camera image plane. The
%                             misalignment is caused by lens not being
%                             parallel to sensor and the digitization
%                             process.
%
%      ImageSize            - Image size [mrows, ncols], produced by the camera.
%
%
%   Example
%   -------
%   % Define fisheye camera intrinsic parameters while ignoring optical
%   % axis misalignment.
%   mappingCoeffs  = [880, -3e-4, 0, 0]; % mapping polynomial coefficients
%   imageSize      = [1500, 2000];  % in [mrows, ncols]
%   distortionCenter = [1000, 750]; % in pixels
%
%   intrinsics = fisheyeIntrinsics(mappingCoeffs, imageSize, distortionCenter);
%
% See also fisheyeParameters, estimateFisheyeParameters

% Copyright 2017 MathWorks, Inc.

classdef fisheyeIntrinsics < vision.internal.EnforceScalarValue
    
    properties (SetAccess='private', GetAccess='public')
        
        %MappingCoefficients Polynomial coefficients in Scaramuzza's Taylor model.
        %   MappingCoefficients is a 4-element vector [a0 a2 a3 a4],
        %   which are coefficients of a polynomial function, f, that maps
        %   the a world point [X Y Z] to a point [u v] in the sensor plane
        %   by the following equation: s * [u v f(w)] = [X Y Z], where
        %      - w = sqrt(u^2+v^2), is the radial euclidean distance from
        %      the camera center.
        %      - f(w) = a0 + a2 * w^2 + a3 * w^3 + a4 * w^4
        %      - s is a scalar
        MappingCoefficients;
        
        %ImageSize Image size produced by the camera.
        %   ImageSize is a vector [mrows, ncols] corresponding to the image
        %   size produced by the camera.
        ImageSize;        

        %DistortionCenter Center of distortion.
        %   DistortionCenter is a 2-element vector [cx, cy] that specifies
        %   the center of distortion in pixels.
        DistortionCenter;

        %StretchMatrix A 2-by-2 transformation matrix.
        %   StretchMatrix transforms a point from the sensor plane to a
        %   pixel in the camera image plane. The misalignment is caused by
        %   lens not being parallel to sensor and the digitization process.
        %
        StretchMatrix;
        
    end
    
    properties (Access=protected, Hidden)
       UndistortMap;
       MappingCoeffsInternal;
       Version = ver('vision');
    end

    
    methods
        %------------------------------------------------------------------
        % Constructor
        %------------------------------------------------------------------
        function this = fisheyeIntrinsics(varargin)

            parser = inputParser;
            
            parser.addRequired('mappingCoeffs', @this.checkCoefficients);
            parser.addRequired('imageSize', @this.checkImageSize);
            parser.addRequired('distortionCenter', @this.checkDistortionCenter);
            parser.addOptional('stretchMatrix', [1 0; 0 1], @this.checkStretchMatrix);
            
            % Parse and check parameters
            parser.parse(varargin{:});
            r = parser.Results;                        
            
            this.MappingCoefficients = r.mappingCoeffs(:)';
            
            this.StretchMatrix = r.stretchMatrix;
            % Enforce the stretch matrix to be [a b ; c 1]
            this.StretchMatrix(end) = 1;
            
            this.DistortionCenter = r.distortionCenter(:)';
            
            this.ImageSize = r.imageSize;

            % Use double if any of the key properties is double
            if (isa(this.MappingCoefficients, 'double') || ...
                    isa(this.StretchMatrix, 'double') || ...
                    isa(this.DistortionCenter, 'double'))
                this.MappingCoefficients = double(this.MappingCoefficients);
                this.StretchMatrix = double(this.StretchMatrix);
                this.DistortionCenter = double(this.DistortionCenter);
            end
            
            % Initialize the undistort map property. It must be done in the
            % constructor in order to successfully cache the undistortion
            % map inside a fisheyeIntrinsics object.
            this.UndistortMap = vision.internal.calibration.FisheyeImageTransformer;

            % Add the constant zero a1, so the full set is [a0 a1 a2 a3 a4]
            this.MappingCoeffsInternal = [this.MappingCoefficients(1), ...
                      zeros(1, 'like', this.MappingCoefficients), ...
                      this.MappingCoefficients(2:end)];
        end
                
        %------------------------------------------------------------------
        function imagePoints = worldToImage(this, rotationMatrix, ...
                translationVector, worldPoints)
            % worldToImage Project world points into the image
            %   imagePoints = worldToImage(intrinsics, rotationMatrix, 
            %   translationVector, worldPoints) projects 3-D world points 
            %   into the image given camera parameters.
            %
            %   Inputs:
            %   -------
            %   intrinsics        - fisheyeIntrinsics object
            %
            %   rotationMatrix    - 3-by-3 matrix representing rotation from 
            %                       world coordinates into camera coordinates.
            %
            %   translationVector - 3-element vector representing translation 
            %                       from world coordinates into camera coordinates. 
            %                       It must be in the same units as worldPoints.
            %
            %   worldPoints       - M-by-3 matrix containing [X,Y,Z] coordinates 
            %                       of the world points. The coordinates must 
            %                       be in the same units as translationVector.
            %
            %   Output:
            %   -------
            %   imagePoints       - M-by-2 matrix containing [x,y] coordinates 
            %                       of image points in pixels.
            %
            %   Class Support
            %   -------------
            %   rotationMatrix, translationVector, and worldPoints can be of 
            %   class double or single. imagePoints are the same class as worldPoints.
            %
            %   Example
            %   -------
            %   % Create a set of calibration images.
            %   images = imageDatastore(fullfile(toolboxdir('vision'), 'visiondata', ...
            %         'calibration', 'gopro'));
            %
            %   % Detect the checkerboard corners in the images. Leave the
            %   % last image for testing.
            %   [imagePoints, boardSize] = detectCheckerboardPoints(images.Files(1:end-1));
            %
            %   % Generate the world coordinates of the checkerboard corners in the
            %   % pattern-centric coordinate system, with the upper-left corner at (0,0).
            %   squareSize = 29; % in millimeters
            %   worldPoints = generateCheckerboardPoints(boardSize, squareSize);
            %
            %   % Calibrate the camera.
            %   I = imread(images.Files{end}); 
            %   imageSize = [size(I, 1), size(I, 2)];
            %   fisheyeParams = estimateFisheyeParameters(imagePoints, worldPoints, imageSize);
            %   intrinsics = fisheyeParams.Intrinsics;
            %
            %   figure
            %   imshow(I, 'InitialMagnification', 30)
            %
            %   % Find reference object in new image.
            %   imagePoints = detectCheckerboardPoints(I);
            %
            %   % Compute new extrinsics.
            %   [R, t] = extrinsics(imagePoints, worldPoints, intrinsics);
            %
            %   % Add a z-coordinate to the world points
            %   worldPoints = [worldPoints, zeros(size(worldPoints, 1), 1)];
            %
            %   % Project world points back into original image
            %   projectedPoints = worldToImage(intrinsics, R, t, worldPoints);
            %   hold on
            %   plot(projectedPoints(:,1), projectedPoints(:,2), 'g*-')
            %   legend('Projected points');
            %
            %   See also pointsToWorld, fisheyeIntrinsics,
            %       estimateFisheyeParameters, estimateWorldCameraPose, 
            %       extrinsics
            
            [R, t, pts, outputClass] = parseWorldToImageInputs(this,...
                rotationMatrix, translationVector, worldPoints);
            
            points = pts * R;
            points(:, 1) = points(:, 1) + t(1);
            points(:, 2) = points(:, 2) + t(2);
            points(:, 3) = points(:, 3) + t(3);
            
            imagePoints = vision.internal.calibration.computeImageProjection(...
                points, this.MappingCoeffsInternal, ...
                this.StretchMatrix, this.DistortionCenter);
                                
            imagePoints = cast(imagePoints, outputClass);
        end
        
        %------------------------------------------------------------------
        function worldPoints = pointsToWorld(this, rotationMatrix, ...
                translationVector, imagePoints)
            %pointsToWorld Determine world coordinates of image points. 
            %  worldPoints = pointsToWorld(intrinsics, rotationMatrix,
            %  translationVector, imagePoints) maps image points onto
            %  points on the X-Y plane in the world coordinates.
            %
            %  Inputs:
            %  -------
            %  intrinsics        - fisheyeIntrinsics object. 
            %
            %  rotationMatrix    - 3-by-3 matrix representing rotation 
            %                      of the camera in world coordinates.
            %
            %  translationVector - 3-element vector representing 
            %                      translation of the camera in world 
            %                      coordinates.  
            %
            %  imagePoints       - M-by-2 matrix containing [x, y] 
            %                      coordinates of image points. M is the
            %                      number of points.
            %
            %  Output:
            %  -------
            %  worldPoints       - M-by-2 matrix containing corresponding 
            %                      [X,Y] world coordinates. Z coordinate 
            %                      for every world point is 0.
            %
            %  Class Support
            %  -------------
            %  rotationMatrix, translationVector, and imagePoints must be
            %  real and nonsparse numeric arrays. worldPoints is of class
            %  double if imagePoints are double. Otherwise worldPoints is
            %  of class single.
            %
            %  Example
            %  -------
            %   % Create a set of calibration images.
            %   images = imageDatastore(fullfile(toolboxdir('vision'), 'visiondata', ...
            %         'calibration', 'gopro'));
            %
            %   % Detect the checkerboard corners in the images. Leave the
            %   % last image for testing.
            %   [imagePoints, boardSize] = detectCheckerboardPoints(images.Files(1:end-1));
            %
            %   % Generate the world coordinates of the checkerboard corners in the
            %   % pattern-centric coordinate system, with the upper-left corner at (0,0).
            %   squareSize = 29; % in millimeters
            %   worldPoints = generateCheckerboardPoints(boardSize, squareSize);
            %
            %   % Calibrate the camera.
            %   I = imread(images.Files{end}); 
            %   imageSize = [size(I, 1), size(I, 2)];
            %   fisheyeParams = estimateFisheyeParameters(imagePoints, worldPoints, imageSize);
            %   intrinsics = fisheyeParams.Intrinsics;
            %
            %   % Find reference object in new image.
            %   imagePoints = detectCheckerboardPoints(I);
            %
            %   % Compute new extrinsics.
            %   [R, t] = extrinsics(imagePoints, worldPoints, intrinsics);
            %
            %   % Map image points to the X-Y plane in the world coordinates.
            %   newWorldPoints = pointsToWorld(intrinsics, R, t, imagePoints);
            %   
            %   % Compare to the ground truth points
            %   plot(worldPoints(:,1), worldPoints(:,2), 'gx');
            %   hold on
            %   plot(newWorldPoints(:,1), newWorldPoints(:,2), 'ro');
            %   legend('Ground Truth', 'Estimates');
            %
            %  See also worldToImage, estimateFisheyeParameters,
            %      fisheyeIntrinsics, extrinsics, undistortFisheyeImage
            
            points = vision.internal.inputValidation.checkAndConvertPoints(...
                imagePoints, 'fisheyeIntrinsics', 'imagePoints');

            [R, t, pts, outputClass] = parseProjectionInputs(this, ...
                rotationMatrix, translationVector, points);

            % Compute the normalized vector on unit sphere, i.e, ray vector
            X = imageToNormalizedVector(this, pts);

            % Map to X-Y world plane
            if isempty(X)
                Y = zeros(0,2,'like',X);
            else
                tform = [R(1, :); R(2, :); t];
                U = X / tform;
                U(:, 1) = U(:, 1)./ U(:, 3);
                U(:, 2) = U(:, 2)./ U(:, 3);
                Y = U(:, 1:2);
            end
            worldPoints = cast(Y, outputClass);
        end
        
        %------------------------------------------------------------------
        function worldPoints = imageToNormalizedVector(this, imagePoints)
            %imageToNormalizedVector Determine the normalized 3D vector on
            %the unit sphere.
            %  worldPoints = imageToNormalizedWorld(intrinsics,imagePoints) 
            %  maps image points to the normalized 3D vector emanating from
            %  the single effective viewpoint on the unit sphere.
            %
            %  Inputs:
            %  -------
            %  intrinsics        - fisheyeIntrinsics object. 
            %
            %  imagePoints       - M-by-2 matrix containing [x, y] 
            %                      coordinates of image points. M is the
            %                      number of points.
            %
            %  Output:
            %  -------
            %  worldPoints       - M-by-3 matrix containing corresponding 
            %                      [X,Y,Z] coordinates on the unit sphere.
            
            points = vision.internal.inputValidation.checkAndConvertPoints(...
                imagePoints, 'fisheyeIntrinsics', 'imagePoints');
            
            if isa(points, 'single')
                points = double(points);
            end
            
            center = double(this.DistortionCenter);
            stretch = double(this.StretchMatrix);
            coeffs = double(this.MappingCoeffsInternal);

            % Convert image points to sensor coordinates
            points(:, 1) = points(:, 1) - center(1);
            points(:, 2) = points(:, 2) - center(2);
            points = stretch \ points';
            
            rho = sqrt(points(1, :).^2 + points(2, :).^2);
            f = polyval(coeffs(end:-1:1), rho);
            
            % Note, points could be invalid if f < 0
            worldPoints = [points; f]';
            nw = sqrt(sum(worldPoints.^2, 2));
            nw(nw == 0) = eps;
            worldPoints = worldPoints ./ nw;
            worldPoints = cast(worldPoints, class(imagePoints));
        end
        
    end
                
    methods(Access=private)
        %------------------------------------------------------------------
        function [R, t, pts, outputClass] = parseWorldToImageInputs(this,...
                rotationMatrix, translationVector, worldPoints, varargin)
            validateattributes(worldPoints, {'double', 'single'}, ...
                {'real', 'nonsparse', 'nonempty', '2d', 'ncols', 3}, ...
                'fisheyeIntrinsics', 'worldPoints');
            [R, t, pts, outputClass] = parseProjectionInputs(this, ...
                rotationMatrix, translationVector, worldPoints);            
        end

        %--------------------------------------------------------------
        function [R, t, pts, outputClass] = parseProjectionInputs(~, ...
                rotationMatrix, translationVector, points)

            vision.internal.inputValidation.validateRotationMatrix(...
                rotationMatrix, 'fisheyeIntrinsics', 'rotationMatrix');
            vision.internal.inputValidation.validateTranslationVector(...
                translationVector, 'fisheyeIntrinsics', 'translationVector');

            % if any of the inputs is double, internal math is done in
            % doubles.  Otherwise, internal math is  done in singles.
            if isa(rotationMatrix, 'double') || isa(translationVector, 'double')...
                || isa(points, 'double')
                R = double(rotationMatrix);
                tTemp = double(translationVector);                
                pts = double(points);
            else
                R = single(rotationMatrix);
                tTemp = single(translationVector);
                pts = single(points);
            end

            % Force t to be a row vector.
            t = tTemp(:)';

            % if imagePoints is double, then the output worldPoints is
            % double. Otherwise worldPoints is single.
            if isa(points, 'double')
                outputClass = 'double';
            else
                outputClass = 'single';
            end
        end        
    end
    
    methods (Hidden = true)
        %------------------------------------------------------------------
        % Remove distortion and project to a perspective camera
        %------------------------------------------------------------------
        function undistortedPoints = undistortPointsImpl(this, points, camIntrinsics)            
            worldPoints = imageToNormalizedVector(this, points);
            IND = find(worldPoints(:, 3) < 0);
            u = worldPoints(:, 1) ./ worldPoints(:, 3);
            v = worldPoints(:, 2) ./ worldPoints(:, 3);
            X = [u, v, ones(length(u), 1)] * camIntrinsics.IntrinsicMatrix;
            undistortedPoints = X(:, 1:2);
            if ~isempty(IND)
                undistortedPoints(IND, :) = NaN;
                warning(message('vision:calibrate:failToUndistortPoints'));
            end
        end
        
        %------------------------------------------------------------------
        % Apply distortion to a set of points and a given perspective
        % camera
        %------------------------------------------------------------------
        function distortedPoints = distortPoints(this, points, camIntrinsics)
            u = (points(:, 1) - camIntrinsics.PrincipalPoint(1)) / camIntrinsics.FocalLength(1);
            v = (points(:, 2) - camIntrinsics.PrincipalPoint(2)) / camIntrinsics.FocalLength(2);
            points3D = [u, v, ones(numel(u), 1)];
            distortedPoints = vision.internal.calibration.computeImageProjection(...
                points3D, this.MappingCoeffsInternal, ...
                this.StretchMatrix, this.DistortionCenter);
        end
        
        %------------------------------------------------------------------
        function [Jout, camIntrinsics] = undistortImageImpl(this, I, interp, ...
                outputView, focalLength, fillValues, method)
            % undistortImageImpl implements the core lens undistortion
            % algorithm for the undistortFisheyeImage.m function.
            if needToUpdate(this.UndistortMap, I, outputView, focalLength, method)
                [xBounds, yBounds, pp] = computeUndistortBounds(this, ...
                    [size(I, 1), size(I, 2)], outputView, focalLength);
                
                this.UndistortMap.update(I, ...
                    this.MappingCoeffsInternal, this.StretchMatrix, ...
                    this.DistortionCenter, outputView, ...
                    xBounds, yBounds, focalLength, pp, method);
            end
            
            J = transformImage(this.UndistortMap, I, interp, fillValues); 
            camIntrinsics = this.UndistortMap.Intrinsics;
            
            if strcmp(outputView, 'same')
                Jout = coder.nullcopy(zeros(size(I), 'like', I));
                Jout(:,:,:) = J(1:size(I, 1), 1:size(I, 2), 1:size(I,3));
            else
                Jout = J;
            end
        end

        %------------------------------------------------------------------
        function [xBounds, yBounds, principalPoint] = computeUndistortBounds(this, ...
                imageSize, outputView, focalLength)          
            if strcmp(outputView, 'same')
                xBounds = [1, imageSize(2)];
                yBounds = [1, imageSize(1)];
                principalPoint = imageSize([2, 1]) / 2 + 0.5;
            else                
                top = [(1:imageSize(2))', ones(imageSize(2), 1)];
                bottom = [(1:imageSize(2))', imageSize(1)*ones(imageSize(2), 1)];
                left = [ones(imageSize(1), 1), (1:imageSize(1))'];
                right = [imageSize(2)*ones(imageSize(1), 1), (1:imageSize(1))'];
                points = [top;bottom;left;right];
    
                worldPoints = imageToNormalizedVector(this, points);
                if any(worldPoints(:, 3) < 0)
                    error(message('vision:calibrate:failToUndistortFullImage'));
                end
                
                u = worldPoints(:, 1) ./ worldPoints(:, 3);
                v = worldPoints(:, 2) ./ worldPoints(:, 3);
                x = u * focalLength(1);
                y = v * focalLength(2);

                if strcmpi(outputView, 'full')
                    xmin = min(x);
                    ymin = min(y);
                    xmax = max(x);
                    ymax = max(y);
                else   
                    topInd = 1:imageSize(2);
                    bottomInd = imageSize(2)+1:2*imageSize(2);
                    leftInd = 2*imageSize(2)+1:2*imageSize(2)+imageSize(1);
                    rightInd = 2*imageSize(2)+imageSize(1)+1:2*imageSize(2)+2*imageSize(1);
                    topy = y(topInd);
                    bottomy = y(bottomInd);
                    leftx = x(leftInd);
                    rightx = x(rightInd);
        
                    xmin = max(leftx);
                    ymin = max(topy);
                    xmax = min(rightx);
                    ymax = min(bottomy);        
                end
                                
                newWidth = ceil(xmax - xmin);
                newHeight = ceil(ymax - ymin);
                
                % The undistorted image is too large to produce
                if (newWidth >= imageSize(1)*5 || newHeight >= imageSize(2)*5)
                    error(message('vision:calibrate:failToUndistortFullImage'));
                end
                % The undistorted image is not correct
                if (newWidth <= 0 || newHeight <= 0)
                    error(message('vision:calibrate:failToUndistortFullImage'));
                end
    
                xBounds = [1 newWidth];
                yBounds = [1 newHeight];
                principalPoint = 0.5 - [xmin, ymin];

            end
        end
    end
    
    %----------------------------------------------------------------------
    % Static methods
    %----------------------------------------------------------------------
    methods(Static, Hidden)
        
        %------------------------------------------------------------------
        function checkCoefficients(coefficients)
            validateattributes(coefficients, {'double', 'single'}, ...
                {'vector','real', 'nonsparse', 'finite', 'numel', 4}, ...
                mfilename, 'mappingCoeffs');            
        end
        
        %------------------------------------------------------------------
        function checkStretchMatrix(stretch)
            validateattributes(stretch, {'double', 'single'}, ...
                {'real', 'nonsparse', 'size', [2 2], 'finite'}, ...
                mfilename, 'stretchMatrix');
        end

        %------------------------------------------------------------------
        function checkDistortionCenter(center)
            validateattributes(center, {'double', 'single'}, ...
                {'real', 'nonsparse', 'vector', 'numel', 2, 'finite'}, ...
                mfilename, 'distortionCenter');
        end
        
        %------------------------------------------------------------------
        function checkImageSize(imageSize)
            if isempty(imageSize)
                return;
            end
            
            validateattributes(imageSize, {'double', 'single'}, ...
                {'vector','real', 'nonsparse','numel', 2, 'integer', 'positive'}, ...
                mfilename, 'imageSize');
        end        
                       
        %------------------------------------------------------------------
        function this = loadobj(that)
            this = fisheyeIntrinsics(...
                that.MappingCoefficients, ...
                that.ImageSize, ...
                that.DistortionCenter, ...
                that.StretchMatrix ...
                );
        end
        
    end
    
    %----------------------------------------------------------------------
    % saveobj is implemented to ensure compatibility across releases by
    % converting the class to a struct prior to saving it. It also contains
    % a version number, which can be used to customize the loading process.
    methods (Hidden)
       
        function that = saveobj(this)
            that.MappingCoefficients  = this.MappingCoefficients;
            that.StretchMatrix        = this.StretchMatrix;
            that.DistortionCenter     = this.DistortionCenter;
            that.ImageSize            = this.ImageSize;
            that.Version              = this.Version;
        end
        
    end    
    
end
