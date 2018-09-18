%opticalFlowLK Estimate optical flow using Lucas-Kanade algorithm.
%   obj = opticalFlowLK returns an optical flow object, obj, that estimates
%   the direction and speed of object motion from previous video frame to
%   the current one using Lucas-Kanade algorithm with difference filter 
%   [-1 1] for temporal smoothing.
%
%   obj = opticalFlowLK(Name, Value) specifies additional name-value pairs
%   described below:
%
%   'NoiseThreshold' Threshold for noise reduction. It's a positive scalar.
%                    The higher the number, the less small movements impact
%                    the optical flow calculation.
%
%                    Default: 0.0039
%
%   opticalFlowLK properties:
%      NoiseThreshold   - Threshold for noise reduction
%
%   opticalFlowLK methods:
%      estimateFlow - Estimates the optical flow
%      reset        - Resets the internal state of the object
%
%
%   Example - Compute and display optical flow  
%   ------------------------------------------
%     vidReader = VideoReader('visiontraffic.avi', 'CurrentTime', 11);
%     opticFlow = opticalFlowLK('NoiseThreshold', 0.009);
%     while hasFrame(vidReader)
%       frameRGB = readFrame(vidReader);
%       frameGray = rgb2gray(frameRGB);
%       % Compute optical flow
%       flow = estimateFlow(opticFlow, frameGray); 
%       % Display video frame with flow vectors
%       imshow(frameRGB) 
%       hold on
%       plot(flow, 'DecimationFactor', [5 5], 'ScaleFactor', 10)
%       drawnow
%       hold off 
%     end
%
%   See also opticalFlowHS, opticalFlowLKDoG, opticalFlowFarneback, 
%            opticalFlow, opticalFlow>plot.

%   Copyright 2014 MathWorks, Inc.
%
% References: 
%    Barron, J.L., D.J. Fleet, S.S. Beauchemin, and T.A.
%    Burkitt. "Performance of optical flow techniques". CVPR, 1992.

classdef opticalFlowLK < handle & vision.internal.EnforceScalarHandle
%#codegen
%#ok<*EMCLS>
%#ok<*EMCA>
%#ok<*MCSUP>
  
  %------------------------------------------------------------------------
  % Public properties which can only be set in the constructor
  %------------------------------------------------------------------------
  properties(SetAccess=public)
    %NoiseThreshold Threshold for noise reduction
    NoiseThreshold = 0.0039;% eigTh
  end
  
  %------------------------------------------------------------------------
  % Hidden properties used by the object
  %------------------------------------------------------------------------
  properties(Hidden, Access=private)
    pInRows = 0;
    pInCols = 0;
    pImageClassID = 0;
    
    pPreviousFrameBuffer;
    pFirstCall;
    
    %% All intermediate buffers
 	pGradCC; 
    pGradRC; 
    pGradRR; 
    pGradCT; 
    pGradRT;
  end
  
  methods

    %----------------------------------------------------------------------
    % Constructor
    %----------------------------------------------------------------------
    function obj = opticalFlowLK(varargin)
        
      % Parse the inputs.
      if nargin>0
          condition = (nargin>0) && (~strcmpi(varargin{1},'NoiseThreshold'));
          coder.internal.errorIf(condition, 'vision:OpticalFlow:paramNoiseTh');

          tmpNoiseThreshold = varargin{2};
          obj.NoiseThreshold = tmpNoiseThreshold;
      end
      obj.pFirstCall = true;
    end
    
    %----------------------------------------------------------------------
    % Predict method
    %----------------------------------------------------------------------
    function outFlow = estimateFlow(obj, ImageA) %, varargin)
        % estimateFlow Estimates the optical flow
        %   flow = estimateFlow(obj, I) estimates the optical flow between 
        %   the current frame I and the previous frame. 
        %    
        %   Notes
        %   -----
        %   - output flow is an object of class <a href="matlab:help('opticalFlow')">opticalFlow</a> that stores
        %     velocity matrices.
        %   - Class of input, I, can be double, single, uint8, int16, or logical.
        %   - For the very first frame, the previous frame is set to black.
        
     checkImage(ImageA);
     if (~isSimMode())
         % compile time error if ImageA is not fixed sized
         eml_invariant(eml_is_const(size(ImageA)), ...
                      eml_message('vision:OpticalFlow:imageVarSize'));
     end
     
     if (obj.pFirstCall) 
         obj.pInRows = coder.const(size(ImageA,1));
         obj.pInCols = coder.const(size(ImageA,2)); 
         
         obj.pImageClassID = coder.const(getClassID(ImageA));
     else
         inRows_ = size(ImageA,1);
         inCols_ = size(ImageA,2);
         condition = (obj.pInRows ~= inRows_) || (obj.pInCols ~= inCols_);
         coder.internal.errorIf(condition, 'vision:OpticalFlow:inputSizeChange');
         
         condition = obj.pImageClassID ~= getClassID(ImageA);
         coder.internal.errorIf(condition, 'vision:OpticalFlow:inputDataTypeChange'); 
     end     
    
     if isa(ImageA, 'double') 
         otherDT = coder.const('double');
         tmpImageA = ImageA;
     else
         otherDT = coder.const('single');
         if isa(ImageA, 'uint8') 
             tmpImageA = ImageA;
         else
             tmpImageA = im2single(ImageA);
         end
     end  
     
     if((obj.pInRows==0) || (obj.pInCols==0))
         velComponent = zeros(size(tmpImageA), otherDT);
         outFlow = opticalFlow(velComponent, velComponent);
         return;
     end

     if (obj.pFirstCall) 
        obj.pPreviousFrameBuffer = zeros(size(tmpImageA), 'like', tmpImageA);
        obj.pFirstCall = false;
     else
        coder.assertDefined(obj.pPreviousFrameBuffer);        
     end
     ImageB = obj.pPreviousFrameBuffer;        
    
      % Temporary memory: GRAD{CC,RC,RR,CT,RT}_IDX
      obj.pGradCC = zeros(size(ImageA), otherDT);
      obj.pGradRC = zeros(size(ImageA), otherDT);
      obj.pGradRR = zeros(size(ImageA), otherDT);
      obj.pGradCT = zeros(size(ImageA), otherDT);
      obj.pGradRT = zeros(size(ImageA), otherDT);
      
      noiseThreshold = cast(obj.NoiseThreshold, otherDT);
      
     if isSimMode()
      [outVelReal, outVelImag] = visionOpticalFlowLK( ...
         			tmpImageA, ImageB, ...
					obj.pGradCC, obj.pGradRC, obj.pGradRR, obj.pGradCT, obj.pGradRT, ...
					noiseThreshold ...
         );
     else
      [outVelReal, outVelImag] = vision.internal.buildable.opticalFlowLKBuildable.opticalFlowLK_compute( ...
         			tmpImageA, ImageB, ...
					obj.pGradCC, obj.pGradRC, obj.pGradRR, obj.pGradCT, obj.pGradRT, ...
					noiseThreshold ... 
         );
     end
     
     outFlow = opticalFlow(outVelReal, outVelImag);
     % Update delay buffer  
     obj.pPreviousFrameBuffer = tmpImageA;
    end
    
    %------------------------------------------------------------------
    function set.NoiseThreshold(this, noiseThreshold)
        checkNoiseThreshold(noiseThreshold);
        this.NoiseThreshold = double(noiseThreshold);
    end
    
    %----------------------------------------------------------------------
    % Correct method
    %----------------------------------------------------------------------
    function reset(obj)
        % reset Reset the internal state of the object
        %
        %   reset(flow) resets the internal state of the object. It sets 
        %   the previous frame to black.
        
        obj.pFirstCall = true;
    end    
      
  end

end
               
%========================================================================== 
function flag = isSimMode()

flag = isempty(coder.target);
end

%==========================================================================
function checkImage(I)
% Validate input image

validateattributes(I,{'uint8', 'int16', 'double', 'single', 'logical'}, ...
    {'real','nonsparse', '2d'}, mfilename, 'ImageA', 1)

end

%==========================================================================
function checkNoiseThreshold(NoiseThreshold)

validateattributes(NoiseThreshold, {'numeric'}, {'nonempty', 'nonnan', ...
    'finite', 'nonsparse', 'real', 'scalar', '>', 0}, ...
    mfilename, 'NoiseThreshold');

end

%==========================================================================
function id = getClassID(img)
    id = 0;
    if isa(img,'double')
        id = 0;
    elseif isa(img,'single')
        id = 1;
    elseif isa(img,'uint8')
        id = 2;
    elseif isa(img,'int16')
        id = 3;
    elseif isa(img,'logical')
        id = 4;
    end
end
