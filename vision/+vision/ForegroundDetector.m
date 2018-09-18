classdef ForegroundDetector < matlab.System
%ForegroundDetector Detect foreground using Gaussian Mixture Models
% 
%   detector = vision.ForegroundDetector returns a foreground detector System 
%   object, detector, that computes foreground mask using Gaussian Mixture
%   Models (GMM) given a series of either grayscale or color video frames.
% 
%   detector = vision.ForegroundDetector('PropertyName', PropertyValue, ...) 
%   returns a foreground detector System object, H, with each specified 
%   property set to the specified value.
% 
%   Step method syntax:
% 
%   foregroundMask = step(detector, I) computes the foreground mask for input 
%   image I, and returns a logical mask where true represents foreground
%   pixels. Image I can be grayscale or color. This form of the step 
%   function call is allowed when AdaptLearningRate is true (default).
%
%   foregroundMask = step(detector, I, learningRate) computes the foreground 
%   mask for input image I using the LearningRate provided by the user. This
%   form of the step function call is allowed when AdaptLearningRate is 
%   false.
% 
%   System objects may be called directly like a function instead of using
%   the step method. For example, y = step(obj, x) and y = obj(x) are
%   equivalent.
%
%   ForegroundDetector methods:
% 
%   step     - See above description for use of this method
%   reset    - Resets the GMM model to its initial state
%   release  - Allow property value and input characteristics changes
%   clone    - Create foreground detection object with same property values
%   isLocked - Locked status (logical)
% 
%   ForegroundDetector properties:
% 
%   AdaptLearningRate          - Enables the adapting of LearningRate as 
%                                1/(current frame number) during the
%                                training period specified by 
%                                NumTrainingFrames
%   NumTrainingFrames          - Number of initial video frames used for 
%                                training the background model
%   LearningRate               - Learning rate used for parameter updates
%   MinimumBackgroundRatio     - Threshold to determine the gaussian modes
%                                in the mixture model that constitute the
%                                background process
%   NumGaussians               - Number of distributions that make up the
%                                foreground-background mixture model
%   InitialVariance            - Initial variance to initialize all
%                                distributions that compose the
%                                foreground-background mixture model
% 
%   Example: Detect moving cars in video
%   ------------------------------------
%   reader = vision.VideoFileReader('visiontraffic.avi', ...
%     'VideoOutputDataType', 'uint8');
%
%   detector = vision.ForegroundDetector();
%
%   blobAnalyzer = vision.BlobAnalysis(...
%       'CentroidOutputPort', false, 'AreaOutputPort', false, ...
%       'BoundingBoxOutputPort', true, 'MinimumBlobArea', 250);
% 
%   player = vision.DeployableVideoPlayer();
%
%   while ~isDone(reader)
%     frame  = step(reader);
%     fgMask = step(detector, frame);
%     bbox   = step(blobAnalyzer, fgMask);
%
%     % draw bounding boxes around cars
%     out = insertShape(frame, 'Rectangle', bbox, 'Color', 'Yellow');
%     step(player, out); % view results in the video player
%   end
%
%   release(player);
%   release(reader);
%
% See also: vision.BlobAnalysis, regionprops, vision.KalmanFilter, imopen,
% imclose
    
%   Copyright 2010-2016 The MathWorks, Inc.

%   References:
%      P. Kaewtrakulpong, R. Bowden, "An Improved Adaptive Background 
%      Mixture Model for Realtime Tracking with Shadow Detection". In Proc. 
%      2nd European Workshop on Advanced Video Based Surveillance Systems, 
%      AVBS01, VIDEO BASED SURVEILLANCE SYSTEMS: Computer Vision and 
%      Distributed Processing (September 2001)
%
%      Stauffer, C. and Grimson, W.E.L, "Adaptive Background Mixture Models 
%      for Real-Time Tracking". Computer Vision and Pattern Recognition, 
%      IEEE Computer Society Conference on, Vol. 2 (06 August 1999), 
%      pp. 2246-252 Vol. 2.
%
%--------------------- Pseudocode for the algorithm -----------------------
%
% initialize per-pixel model
% 
% for each frame
% {     
%     update LearningRate if required
%     for each pixel (x)
%     {
%         for each Gaussian mode in the mixture (k)
%         {
%             if (x belongs to mode k)
%             {
%                update parameters for mode k (mean, variance and weight)
%             }
%         }
%         if (x did not belong to any mode)
%         {
%            replace lowest rank mode with a new one with x as mean
%         }
%         else
%         {
%            compute rank for each mode for the pixel
%            re-sort modes based on rank
%         }
%         test and decide if pixel x is foreground
%     }
% }
%
%--------------------------------------------------------------------------

%#codegen
%#ok<*EMCLS>
%#ok<*EMCA>
    properties(Nontunable)
        %NumGaussians Number of Gaussian modes
        %   Set this property to a positive integer. Typically this value is
        %   3, 4 or 5. Set this value to 3 or greater to be able to model
        %   multiple background modes.
        %
        %   Default: 5
        NumGaussians = 5;   
        %MinimumBackgroundRatio Threshold to determine background model
        %   This property is the minimum of the apriori probabilities for 
        %   pixels to be background. If this value is too small, multimodal 
        %   backgrounds can not be handled. 
        %
        %   Default: 0.7
        MinimumBackgroundRatio = 0.7;         
        %InitialVariance Initial mixture model variance
        %   Specify the initial variance as a numeric scalar or 'Auto'.
        %   When 'Auto' is specified, the initial variance is set based on
        %   the input image data type:
        %  
        %   Image Data Type   Initial Variance
        %   ----------------  ---------------
        %   double/single     (30/255)^2
        %   uint8             30^2
        %
        %   If input is color, this value applies to all color channels.
        %
        %   Default: 'Auto'
        InitialVariance = 'Auto';
    end
    
    properties (Nontunable, Logical) 
        %AdaptLearningRate Adapt learning rate
        %   Set this property to true to adapt the LearningRate as 1/(current 
        %   frame number) during the training period specified by 
        %   NumTrainingFrames. Set this property to false to specify learning 
        %   rate as input at each time step.
        %
        %   Default: true
        AdaptLearningRate = true;
    end
    
    properties (Nontunable)
        %NumTrainingFrames Number of initial training frames
        %   Set this property to the number of training frames at the start of 
        %   the video sequence. This property is not available when 
        %   AdaptLearningRate is false.
        %
        %   Default: 150
        NumTrainingFrames = 150;    
    end
    
    properties
        %LearningRate Learning rate for parameter updates
        %   This property controls how quickly the model adapts to changing 
        %   conditions. Set this property appropriately to ensure algorithm 
        %   stability. When AdaptLearningRate is true, the LearningRate 
        %   property takes effect only after the training period specified by
        %   NumTrainingFrames is over. This property is not available when 
        %   AdaptLearningRate is false. This property is tunable.
        %
        %   Default: 0.005
        LearningRate = 0.005;
    end
           
    properties(Constant, Hidden, Nontunable)
        VarianceThreshold = 2.5*2.5;
        InitialWeight = 0.05;
    end

    properties(Access=private)
        Time;
        Weights; 
        Variances;
        Means;
    end

    properties(Access=private, Nontunable)
        ClassToUse;
        FrameSize;
        NumChannels;
        pInitialVariance;
    end

    properties(Access=private, Hidden, Nontunable)
        ImageClass=coder.internal.const('double'); %only for codegen
        StatClass =coder.internal.const('double');
    end
    
    properties(Access=private, Hidden, Logical)
        hasConstructed = false; %only for codegen
    end

    methods(Access=private)        
        %Initialize all states
        function initializeStates(obj, classToUse)
            obj.Time = 0;     
            numPixels = prod(obj.FrameSize);       
            obj.Weights = zeros([obj.NumGaussians numPixels], classToUse);     
            obj.Variances = obj.pInitialVariance *...
                ones([obj.NumChannels, obj.NumGaussians, numPixels], ...
                     classToUse);
            
            obj.Means = zeros([obj.NumChannels, obj.NumGaussians, numPixels], ...
                              classToUse);
        end

        function initializeParameters(obj, I)
            inputSize = size(I);
            obj.FrameSize = inputSize(1:2);
            if length(inputSize)<3
                obj.NumChannels = 1;
            else
                obj.NumChannels = inputSize(3);
            end        
            
            initInitialVariance(obj, I);
            
        end
        
        function initInitialVariance(obj, I)
            if strcmpi(obj.InitialVariance,'Auto')
                if isfloat(I)
                    obj.pInitialVariance = (30/255)^2;
                else
                    obj.pInitialVariance = 30^2;
                end
            else
                obj.pInitialVariance = obj.InitialVariance;
            end
        end
    end
    
    properties (Transient,Access = private)   
        pForegroundDetector = [];
    end
    
    methods
        function obj = ForegroundDetector(varargin)
            coder.allowpcode('plain');
            setProperties(obj, nargin, varargin{:});
            if isempty(coder.target)
                obj.pForegroundDetector = vision.internal.ForegroundDetector();     
            else
                obj.hasConstructed = false;

            end
        end

        function set.AdaptLearningRate(obj, value)        
            validateattributes( value, { 'logical' }, ...
                                { 'finite', 'scalar', 'nonsparse', 'real' },...
                                'ForegroundDetector', 'AdaptLearningRate');
            obj.AdaptLearningRate = value;
        end
        
        function set.NumTrainingFrames(obj, value)       
            validateattributes( value, { 'numeric' }, ...
                                { 'scalar', 'real', 'integer', 'positive', 'nonsparse' },...
                                'ForegroundDetector', 'NumTrainingFrames');
            
            obj.NumTrainingFrames = value;
        end

        function set.LearningRate(obj, value)
            validateattributes( value, { 'double', 'single' }, ...
                                { 'finite', 'scalar', '>', 0, '<=', 1, 'nonsparse', 'real' }, ...
                                'ForegroundDetector', 'LearningRate');
            
            obj.LearningRate = value;
        end
        
        function set.MinimumBackgroundRatio(obj, value)
            validateattributes( value, { 'numeric' }, ...
                                { 'finite', 'scalar', '>=', 0, '<=', 1, 'nonsparse', 'real' }, ...
                                'ForegroundDetector', 'MinimumBackgroundRatio');
            
            obj.MinimumBackgroundRatio = value;
        end
        
        function set.NumGaussians(obj, value)       
            validateattributes( value, { 'numeric' }, ...
                                { 'real', 'integer', 'scalar', '>', 0, 'nonsparse' }, ...
                                'ForegroundDetector', 'NumGaussians');

            obj.NumGaussians = value;
        end
        
        function set.InitialVariance(obj, value)                                             
            if ischar(value)   
                % Values from the system block dialog are strings. Check if
                % this is a numeric or a string.                
                [numericValue, isValidNumeric] = vision.internal.codegen.str2num(value);
                
                if isValidNumeric
                    % validate as a numeric
                    validateInitialVariance(numericValue);                                        
                    obj.InitialVariance = numericValue;
                else
                    % valiate as a string
                    str = validatestring(value, {'Auto'},  'ForegroundDetector', 'InitialVariance');                
                    obj.InitialVariance = str;                   
                end                            
            else
                validateInitialVariance(value);                
                obj.InitialVariance = value;
            end                
            
        end
        
    end

    methods(Access=protected)
        function fgMask = stepImpl(obj, I, varargin)
            obj.Time = obj.Time+1;

            % compute learningRate
            if isempty(varargin) %AdaptLearningRate == true
                if obj.Time < obj.NumTrainingFrames
                    learningRate = 1/obj.Time;
                else
                    learningRate = obj.LearningRate;
                end
            else
                learningRate = varargin{1};
                coder.internal.errorIf(learningRate <= 0 || learningRate > 1 || isnan(learningRate),...
                                       'vision:ForegroundDetector:invalidLearningRate');                                   
            end
            
            if isempty(coder.target) 
                % call optimized routine
                fgMask = obj.pForegroundDetector.step(I, learningRate);
            else
                if coder.internal.isTargetMATLABHost 
                    fgMask = ...
                        vision.internal.buildable.ForegroundDetectorBuildable.ForegroundDetector_step(...
                            obj.pForegroundDetector, ...
                            obj.ImageClass, ...
                            obj.StatClass, ...
                            I, cast(learningRate,obj.ClassToUse)); 
                elseif vision.internal.codegen.isTargetARM 
                    fgMask = ...
                        vision.internal.buildable.ForegroundDetectorBuildableARM.ForegroundDetector_step(...
                            obj.pForegroundDetector, ...
                            obj.ImageClass, ...
                            obj.StatClass, ...
                            I, cast(learningRate,obj.ClassToUse));                     
                else
                    [fgMask, obj.Weights, obj.Means, obj.Variances] = ...
                        vision.internal.detectForeground(I, learningRate, ...
                                                         obj.Weights, obj.Means, obj.Variances, ...
                                                         obj.ClassToUse, ...
                                                         obj.NumGaussians, obj.VarianceThreshold, ...
                                                         obj.MinimumBackgroundRatio, ...
                                                         obj.InitialWeight, obj.pInitialVariance);
                end	
            end
        end
        
        function setupImpl(obj, I, varargin)
            
            setupTypes(obj,I);            
            initializeParameters(obj, I);                                    
         
            if isempty(coder.target) 
                obj.pForegroundDetector.initialize(I, obj.NumGaussians, ...
                                                   obj.pInitialVariance, ...
                                                   obj.InitialWeight, ...  
                                                   obj.VarianceThreshold,...
                                                   obj.MinimumBackgroundRatio);
            else
                if coder.internal.isTargetMATLABHost 
                    obj.pForegroundDetector = ...
                        vision.internal.buildable.ForegroundDetectorBuildable.ForegroundDetector_construct(...
                            obj.ImageClass, obj.StatClass);
                    obj.hasConstructed = true;
                    vision.internal.buildable.ForegroundDetectorBuildable.ForegroundDetector_initialize(...
                        obj.pForegroundDetector, ...
                        obj.ImageClass, ...
                        obj.StatClass, ...
                        I, ...
                        obj.NumGaussians, ...
                        cast(obj.pInitialVariance,obj.ClassToUse), ...
                        cast(obj.InitialWeight,obj.ClassToUse), ...  
                        cast(obj.VarianceThreshold,obj.ClassToUse),...
                        cast(obj.MinimumBackgroundRatio,obj.ClassToUse));
                elseif vision.internal.codegen.isTargetARM    
                    obj.pForegroundDetector = ...
                        vision.internal.buildable.ForegroundDetectorBuildableARM.ForegroundDetector_construct(...
                            obj.ImageClass, obj.StatClass);
                    obj.hasConstructed = true;
                    vision.internal.buildable.ForegroundDetectorBuildableARM.ForegroundDetector_initialize(...
                        obj.pForegroundDetector, ...
                        obj.ImageClass, ...
                        obj.StatClass, ...
                        I, ...
                        obj.NumGaussians, ...
                        cast(obj.pInitialVariance,obj.ClassToUse), ...
                        cast(obj.InitialWeight,obj.ClassToUse), ...  
                        cast(obj.VarianceThreshold,obj.ClassToUse),...
                        cast(obj.MinimumBackgroundRatio,obj.ClassToUse));                    
                end
            end
        end
        
        function flag = isInputSizeLockedImpl(~,~)
            flag = true;
        end

        function flag = isInputComplexityLockedImpl(~,~)
            flag = true;
        end
        
        function flag = isOutputComplexityLockedImpl(~,~)
            flag = true;
        end
        
        function  resetImpl(obj)
            initializeStates(obj, obj.ClassToUse);        
            if isempty(coder.target) 
                obj.pForegroundDetector.reset();
            else
                if coder.internal.isTargetMATLABHost
                    if obj.hasConstructed  
                        vision.internal.buildable.ForegroundDetectorBuildable.ForegroundDetector_reset(...
                            obj.pForegroundDetector, obj.ImageClass, obj.StatClass);
                    end 
                elseif vision.internal.codegen.isTargetARM  
                    if obj.hasConstructed  
                        vision.internal.buildable.ForegroundDetectorBuildableARM.ForegroundDetector_reset(...
                            obj.pForegroundDetector, obj.ImageClass, obj.StatClass);
                    end                     
                end
            end
        end
        
        function releaseImpl(obj)
            if isempty(coder.target) 
                obj.pForegroundDetector.release();
            else                
                if coder.internal.isTargetMATLABHost
                    if obj.hasConstructed                         
                        vision.internal.buildable.ForegroundDetectorBuildable.ForegroundDetector_release(...
                            obj.pForegroundDetector, obj.ImageClass, obj.StatClass)
                        vision.internal.buildable.ForegroundDetectorBuildable.ForegroundDetector_delete(...
                            obj.pForegroundDetector, obj.ImageClass, obj.StatClass);
                        obj.hasConstructed = false;
                    end
                elseif vision.internal.codegen.isTargetARM
                    if obj.hasConstructed
                        vision.internal.buildable.ForegroundDetectorBuildableARM.ForegroundDetector_release(...
                            obj.pForegroundDetector, obj.ImageClass, obj.StatClass)
                        vision.internal.buildable.ForegroundDetectorBuildableARM.ForegroundDetector_delete(...
                            obj.pForegroundDetector, obj.ImageClass, obj.StatClass);
                        obj.hasConstructed = false;
                    end                    
                end
            end
        end
        
        function s = saveObjectImpl(obj)
        % save object properties     
            s.InitialVariance = obj.InitialVariance;
            s.LearningRate = obj.LearningRate;
            s.NumTrainingFrames = obj.NumTrainingFrames;
            s.NumGaussians = obj.NumGaussians;
            s.MinimumBackgroundRatio = obj.MinimumBackgroundRatio;
            s.AdaptLearningRate = obj.AdaptLearningRate;            
            if obj.isLocked                
                s.Time = obj.Time;
                s.ClassToUse = obj.ClassToUse;
                s.ImageClass = obj.ImageClass;
                s.StatClass = obj.StatClass;
                s.FrameSize = obj.FrameSize;
                s.NumChannels = obj.NumChannels;   
                s.pInitialVariance = obj.pInitialVariance;
                if isempty(coder.target)
                    [s.Weights, s.Means, s.Variances, s.NumActiveGaussians]  =...
                        getStates(obj.pForegroundDetector);                 
                end
            end                                     
        end
        
        function loadObjectImpl(obj, s, wasLocked)
        % load object properties                
            obj.LearningRate = s.LearningRate;
            obj.InitialVariance = s.InitialVariance;
            obj.NumGaussians = s.NumGaussians;
            obj.MinimumBackgroundRatio = s.MinimumBackgroundRatio;
            obj.NumTrainingFrames = s.NumTrainingFrames;
            obj.AdaptLearningRate = s.AdaptLearningRate;
            
            if wasLocked
                obj.ClassToUse = s.ClassToUse;
                obj.ImageClass = s.ImageClass;
                obj.StatClass = s.StatClass;
                obj.FrameSize = s.FrameSize;
                obj.NumChannels = s.NumChannels; 
                obj.Time = s.Time;
                
                if isfield(s,'pInitialVariance')                
                    obj.pInitialVariance = s.pInitialVariance;
                else
                    % saved in an older release, set to InitialVariance.
                    obj.pInitialVariance = s.InitialVariance;
                end
                
                if isempty(coder.target)
                    % set private properties that were not saved
                    obj.pForegroundDetector.initialize(ones([obj.FrameSize obj.NumChannels],obj.ClassToUse),...
                                                       obj.NumGaussians,...
                                                       obj.pInitialVariance,...
                                                       obj.InitialWeight,...
                                                       obj.VarianceThreshold,...
                                                       obj.MinimumBackgroundRatio);
                    obj.pForegroundDetector.setStates(s.Weights, s.Means, s.Variances, s.NumActiveGaussians);
                    
                end
            end               
        end
        
        function validateInputsImpl(obj, I, varargin)    
            validateattributes(I, {'double','single','uint8'},...
                               {'real','nonsparse'},'vision.ForegroundDetector.step','', 2);  
            
            if ~obj.AdaptLearningRate                
                validateattributes(varargin{1}, {'double','single'},...
                                   {'scalar','real','nonsparse'},...
                                   'vision.ForegroundDetector.step','',3);            
            end
        end

        function num = getNumInputsImpl(obj)
            if obj.AdaptLearningRate
                num = 1;
            else
                num = 2;
            end
        end

        function num = getNumOutputsImpl(~) 
            num = 1;
        end

        function flag = isInactivePropertyImpl(obj, prop)
            props = {'VarianceThreshold', 'InitialWeight'}; 
            
            if ~obj.AdaptLearningRate
                props{end+1} = 'NumTrainingFrames'; 
                props{end+1} = 'LearningRate'; 
            end
            flag = ismember(prop, props);
        end

        function setupTypes(obj,I)
            if (isa(I,'double'))
                obj.ClassToUse = 'double';
                obj.ImageClass = coder.internal.const('double');
                obj.StatClass =  coder.internal.const('double');
            else
                obj.ClassToUse = 'single';
                obj.StatClass = coder.internal.const('float');
                if (isa(I,'uint8'))
                    obj.ImageClass = coder.internal.const('uint8'); 
                else
                    obj.ImageClass = coder.internal.const('float');
                end
            end
        end
    end  
    
end

% -------------------------------------------------------------------------
function validateInitialVariance(value)
validateattributes( value, { 'numeric' }, ...
    { 'finite', 'scalar', '>=', 0, 'nonsparse', 'real' }, ...
    'ForegroundDetector', 'InitialVariance');
end