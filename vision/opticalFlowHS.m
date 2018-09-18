%opticalFlowHS Estimate optical flow using Horn-Schunck algorithm.
%   obj = opticalFlowHS returns an optical flow object, obj, that estimates
%   the direction and speed of object motion from previous video frame to
%   the current one using Horn-Schunck algorithm.
%
%   obj = opticalFlowHS(Name, Value) specifies additional name-value pairs
%   described below:
%
%   'Smoothness'    Expected smoothness of optical flow. It's a positive
%                   scalar. Use higher value if the relative motion between
%                   two consecutive frames are higher. Typical value is
%                   around 1.
%
%                   Default: 1
%
%   'MaxIteration'  Maximum number of iterations to perform in the optical
%                   flow iterative solution. It's a positive integer-valued
%                   scalar. Use higher value to estimate flow of objects
%                   with lower velocity.
%
%                   Default: 10
%
%   'VelocityDifference'   Minimum absolute velocity difference to stop  
%                          iterative computation. It's a non-negative scalar.
%                          The value depends on input data type. Use
%                          smaller value to estimate flow of objects with
%                          lower velocity. 
%
%                          Default: 0
%
%   Notes
%   -----
%   Iterative computation stops when 'MaxIteration' is reached or
%   'VelocityDifference' is attained.
%   * To use only 'MaxIteration', set 'VelocityDifference' to 0.
%   * To use only 'VelocityDifference', set 'MaxIteration' to Inf.
%
%   opticalFlowHS properties:
%      Smoothness         - Smoothness of optical flow
%      MaxIteration       - Maximum number of iterations for iterative solution
%      VelocityDifference - Minimum absolute velocity difference for iterative solution
%
%   opticalFlowHS methods:
%      estimateFlow - Estimates the optical flow
%      reset        - Resets the internal state of the object
%
%   Example - Compute and display optical flow  
%   ------------------------------------------
%     vidReader = VideoReader('visiontraffic.avi', 'CurrentTime', 11);
%     opticFlow = opticalFlowHS;
%     while hasFrame(vidReader)
%       frameRGB = readFrame(vidReader);
%       frameGray = rgb2gray(frameRGB);
%       % Compute optical flow
%       flow = estimateFlow(opticFlow, frameGray); 
%       % Display video frame with flow vectors
%       imshow(frameRGB) 
%       hold on
%       plot(flow, 'DecimationFactor', [5 5], 'ScaleFactor', 60)
%       drawnow
%       hold off 
%     end
%
%   See also opticalFlowLK, opticalFlowLKDoG, opticalFlowFarneback, 
%            opticalFlow, opticalFlow>plot.

%   Copyright 2014 MathWorks, Inc.
%
% References: 
%    Barron, J.L., D.J. Fleet, S.S. Beauchemin, and T.A.
%    Burkitt. "Performance of optical flow techniques". CVPR, 1992.

classdef opticalFlowHS < handle & vision.internal.EnforceScalarHandle
%#codegen
%#ok<*EMCLS>
%#ok<*EMCA>
%#ok<*MCSUP>
  
  %------------------------------------------------------------------------
  % Public properties which can only be set in the constructor
  %------------------------------------------------------------------------
  properties(SetAccess=public)
    %Smoothness Smoothness of optical flow
    Smoothness = 1;
    %MaxIteration Maximum number of iterations for iterative solution
    MaxIteration = int32(10);
    %VelocityDifference Minimum absolute velocity difference for iterative solution
    VelocityDifference = 0;    
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
    pBuffCprev; 
    pBuffCnext; 
    pBuffRprev; 
    pBuffRnext; 
	pGradCC; 
    pGradRC; 
    pGradRR; 
    pGradCT; 
    pGradRT;
    pAlpha;
    pVelBufCcurr; 
    pVelBufCprev; 
    pVelBufRcurr; 
    pVelBufRprev;
  end
  
  methods

    %----------------------------------------------------------------------
    % Constructor
    %----------------------------------------------------------------------
    function obj = opticalFlowHS(varargin)
        
      % Parse the inputs.
      if isSimMode()
       [tmpSmoothness, tmpMaxIteration, tmpVelocityDifference] ...
        = parseInputsSimulation(obj, varargin{:});
      else % Code generation
        [tmpSmoothness, tmpMaxIteration, tmpVelocityDifference] ...
        = parseInputsCodegen(obj, varargin{:});
      end
      
      obj.Smoothness = tmpSmoothness;
      obj.MaxIteration = tmpMaxIteration;
      obj.VelocityDifference = tmpVelocityDifference;
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
      
      % Temporary memory: ALPHA_IDX
      obj.pAlpha = zeros(size(ImageA), otherDT);
      
      % Temporary memory: MEM{C0,C1,R0,R1}_IDX
      obj.pBuffCprev = zeros(obj.pInRows, 1, otherDT);
      obj.pBuffCnext = zeros(obj.pInRows, 1, otherDT);
      obj.pBuffRprev = zeros(obj.pInCols, 1, otherDT);
      obj.pBuffRnext = zeros(obj.pInCols, 1, otherDT);
      
      % Temporary memory: GRAD{CC,RC,RR,CT,RT}_IDX
      obj.pGradCC = zeros(size(ImageA), otherDT);
      obj.pGradRC = zeros(size(ImageA), otherDT);
      obj.pGradRR = zeros(size(ImageA), otherDT);
      obj.pGradCT = zeros(size(ImageA), otherDT);
      obj.pGradRT = zeros(size(ImageA), otherDT);

      % Temporary memory: VELBUFF{C0,C1,R0,R1}_IDX
      obj.pVelBufCcurr = zeros(obj.pInRows, 1, otherDT);
      obj.pVelBufCprev = zeros(obj.pInRows, 1, otherDT);
      obj.pVelBufRcurr = zeros(obj.pInRows, 1, otherDT);
      obj.pVelBufRprev = zeros(obj.pInRows, 1, otherDT);
      
      useMaxIter = (obj.MaxIteration < intmax('int32'));
      useMaxAllowableAbsDiffVel = (obj.VelocityDifference > 0);
      smoothness = cast(obj.Smoothness, otherDT);
      velocityDifference = cast(obj.VelocityDifference, otherDT);

     if isSimMode()
      [outVelReal, outVelImag] = visionOpticalFlowHS( ...
         			tmpImageA, ImageB, ...
					obj.pBuffCprev, obj.pBuffCnext, obj.pBuffRprev, obj.pBuffRnext, ...
					obj.pGradCC, obj.pGradRC, obj.pGradRR, obj.pGradCT, obj.pGradRT, ...
					obj.pAlpha, ...
					obj.pVelBufCcurr, obj.pVelBufCprev, obj.pVelBufRcurr, obj.pVelBufRprev, ...
					smoothness, ... % Smoothness is Lambda
					useMaxIter, useMaxAllowableAbsDiffVel, ... 
					obj.MaxIteration, velocityDifference ...
         );
     else
      [outVelReal, outVelImag] = vision.internal.buildable.opticalFlowHSBuildable.opticalFlowHS_compute( ...
         			tmpImageA, ImageB, ...
					obj.pBuffCprev, obj.pBuffCnext, obj.pBuffRprev, obj.pBuffRnext, ...
					obj.pGradCC, obj.pGradRC, obj.pGradRR, obj.pGradCT, obj.pGradRT, ...
					obj.pAlpha, ...
					obj.pVelBufCcurr, obj.pVelBufCprev, obj.pVelBufRcurr, obj.pVelBufRprev, ...
					smoothness, ... % Smoothness is Lambda
					useMaxIter, useMaxAllowableAbsDiffVel, ... 
					obj.MaxIteration, velocityDifference ... 
         );
     end
     
     outFlow = opticalFlow(outVelReal, outVelImag);
     % Update delay buffer  
     obj.pPreviousFrameBuffer = tmpImageA;
    end
    
    %------------------------------------------------------------------
    function set.Smoothness(this, smoothness)
        checkSmoothness(smoothness);
        this.Smoothness = double(smoothness);
    end
        
    %------------------------------------------------------------------
    function set.MaxIteration(this, maxIteration)
        checkMaxIteration(maxIteration);
        this.MaxIteration = int32(maxIteration);
    end
    
    %------------------------------------------------------------------
    function set.VelocityDifference(this, velocityDifference)
        checkVelocityDifference(velocityDifference);
        this.VelocityDifference = double(velocityDifference);
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
  
  methods(Access=private)
    %----------------------------------------------------------------------
    % Parse inputs for simulation
    %----------------------------------------------------------------------
    function [tmpSmoothness, tmpMaxIteration, tmpVelocityDifference] ...
        = parseInputsSimulation(obj, varargin)
      
      % Instantiate an input parser
      parser = inputParser;
      parser.FunctionName = mfilename;
      
      % Specify the optional parameters
      parser.addParameter('Smoothness',          obj.Smoothness);
      parser.addParameter('MaxIteration',       obj.MaxIteration);
      parser.addParameter('VelocityDifference', obj.VelocityDifference);
      
      % Parse parameters
      parse(parser, varargin{:});
      r = parser.Results;
      
      tmpSmoothness         = r.Smoothness;
      tmpMaxIteration       = r.MaxIteration;
      tmpVelocityDifference = r.VelocityDifference;     

    end
    
    %----------------------------------------------------------------------
    % Parse inputs for code generation
    %----------------------------------------------------------------------
    function [tmpSmoothness, tmpMaxIteration, tmpVelocityDifference] ...
        = parseInputsCodegen(obj, varargin)

      defaultsNoVal = struct( ...
        'Smoothness',            uint32(0), ...
        'MaxIteration',     uint32(0), ...
        'VelocityDifference', uint32(0));
      
      properties = struct( ...
        'CaseSensitivity', false, ...
        'StructExpand',    true, ...
        'PartialMatching', false);
      
     optarg = eml_parse_parameter_inputs(defaultsNoVal, properties, varargin{:});
    
      tmpSmoothness = eml_get_parameter_value(optarg.Smoothness, ...
        obj.Smoothness, varargin{:});
      tmpMaxIteration = eml_get_parameter_value(optarg.MaxIteration, ...
        obj.MaxIteration, varargin{:});
      tmpVelocityDifference = eml_get_parameter_value(optarg.VelocityDifference, ...
        obj.VelocityDifference, varargin{:});    

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
function checkSmoothness(Smoothness)

validateattributes(Smoothness, {'numeric'}, {'nonempty', 'nonnan', ...
    'finite', 'nonsparse', 'real', 'scalar', '>', 0}, ...
    mfilename, 'Smoothness');

end

%==========================================================================
function checkMaxIteration(MaxIteration)

% allow inf
is_inf = isnumeric(MaxIteration) && ...
        (numel(MaxIteration)==1) && isinf(MaxIteration);
if ~is_inf
 validateattributes(MaxIteration, {'numeric'}, ...
    {'nonempty', 'real', 'integer', 'nonnan', 'nonsparse', 'scalar', '>=', 1}, ...
    mfilename, 'MaxIteration');
end

end

%==========================================================================
function checkVelocityDifference(VelocityDifference)

validateattributes(VelocityDifference, {'numeric'}, {'nonempty', 'nonnan', ...
    'finite', 'nonsparse', 'real', 'scalar', '>=', 0}, ...
    mfilename, 'VelocityDifference');

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

