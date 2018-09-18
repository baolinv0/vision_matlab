%opticalFlowLKDoG Estimate optical flow using modified Lucas-Kanade algorithm.
%   obj = opticalFlowLKDoG returns an optical flow object, obj, that
%   estimates the direction and speed of object motion from previous video
%   frame to the current one using Lucas-Kanade algorithm with derivative
%   of Gaussian filter for temporal smoothing.
%
%   obj = opticalFlowLKDoG(Name, Value) specifies additional name-value pairs
%   described below:
%
%   'NumFrames'  Number of frames to buffer for temporal smoothing. It's 
%                a positive integer-valued scalar. The higher the number,
%                the less abrupt movements impact the optical flow
%                calculation.
%
%                Default: 3
%
%   'ImageFilterSigma' Standard deviation for image smoothing filter. It's 
%                      a positive scalar.
%
%                      Default: 1.5
%
%   'GradientFilterSigma' Standard deviation for gradient smoothing filter.
%                         It's a positive scalar.
%
%                         Default: 1
%
%   'NoiseThreshold' Threshold for noise reduction. It's a positive scalar.
%                    The higher the number, the less small movements impact
%                    the optical flow calculation.
%
%                    Default: 0.0039
%
%   opticalFlowLKDoG properties:
%      NumFrames           - Number of frames to buffer for temporal smoothing
%      ImageFilterSigma    - Standard deviation for image smoothing filter
%      GradientFilterSigma - Standard deviation for gradient smoothing filter
%      NoiseThreshold      - Threshold for noise reduction
%
%   opticalFlowLKDoG methods:
%      estimateFlow - Estimates the optical flow
%      reset        - Resets the internal state of the object
%
%   Example - Compute and display optical flow  
%   ------------------------------------------
%     vidReader = VideoReader('visiontraffic.avi', 'CurrentTime', 11);
%     opticFlow = opticalFlowLKDoG('NoiseThreshold', 0.0005);
%     while hasFrame(vidReader)
%       frameRGB = readFrame(vidReader);
%       frameGray = rgb2gray(frameRGB);
%       % Compute optical flow
%       flow = estimateFlow(opticFlow, frameGray); 
%       % Display video frame with flow vectors
%       imshow(frameRGB) 
%       hold on
%       plot(flow, 'DecimationFactor', [5 5], 'ScaleFactor', 35)
%       drawnow
%       hold off
%     end
%
%   See also opticalFlowHS, opticalFlowLK, opticalFlowFarneback, 
%            opticalFlow, opticalFlow>plot.

%   Copyright 2014 MathWorks, Inc.
%
% References: 
%    Barron, J.L., D.J. Fleet, S.S. Beauchemin, and T.A.
%    Burkitt. "Performance of optical flow techniques". CVPR, 1992.

classdef opticalFlowLKDoG < handle & vision.internal.EnforceScalarHandle
%#codegen
%#ok<*EMCLS>
%#ok<*EMCA>
%#ok<*MCSUP>
  
  %------------------------------------------------------------------------
  % Public properties which can only be set in the constructor
  %------------------------------------------------------------------------
  properties(SetAccess=public)
     %NumFrames Number of frames to buffer for temporal smoothing
     NumFrames           = 3; % includes current frame 
                              % note that pDelayBuffer does not store current frame
                             
     %ImageFilterSigma Standard deviation for image smoothing filter
     ImageFilterSigma    = 1.5;
     %GradientFilterSigma Standard deviation for gradient smoothing filter
     GradientFilterSigma = 1;
     %NoiseThreshold Threshold for noise reduction
     NoiseThreshold      = 0.0039;
  end
  
  %------------------------------------------------------------------------
  % Hidden properties used by the object
  %------------------------------------------------------------------------
  properties(Hidden, Access=private)
    pInRows = 0;
    pInCols = 0;
    
    pPreviousNumFrames;
    p_sGradKernelLen;
    p_tGradKernelLen;
    p_sKernelLen;
    p_wKernelLen;
    
    % This class maintains its own delay buffer.
    % This buffer stores previous (NumFrames-1) frames.
    % Example: if NumFrames=4, at t=0 
    %   pDelayBuffer 
    %   = [image at t=-1 (most recent); image at t=-2; image at t=-3 (oldest)]   
    pDelayBuffer; % it stores only previous frames. it does not store current frame
    pFirstCall;
    
    pMostRecentDFrameIdx = uint32(0);
    pImageClassID = 0;
    
    %% All temporary memories
	pGradCC; 
    pGradRC; 
    pGradRR; 
    pGradCT; 
    pGradRT;

    p_tGradKernel; 
    p_sGradKernel; 
    p_tKernel; 
    p_sKernel; 
    p_wKernel; 
  end
  
  methods

    %----------------------------------------------------------------------
    % Constructor
    %----------------------------------------------------------------------
    function obj = opticalFlowLKDoG(varargin)
        
      % Parse the inputs.
      if isempty(coder.target)  % Simulation
       [tmpNumFrames, tmpImageFilterSigma, ...
        tmpGradientFilterSigma, tmpNoiseThreshold] ...
        = parseInputsSimulation(obj, varargin{:});
      else                      % Code generation
       [tmpNumFrames, tmpImageFilterSigma, ...
        tmpGradientFilterSigma, tmpNoiseThreshold] ...
        = parseInputsCodegen(obj, varargin{:});
      end

      obj.NumFrames = tmpNumFrames;
      % NumFrames includes current Frame; but note that current
      % frame is not stored in pDelayBuffer. That's why we are using pPreviousNumFrames
      obj.pPreviousNumFrames  = obj.NumFrames-1;
      obj.ImageFilterSigma    = tmpImageFilterSigma; % sigmaS
      obj.GradientFilterSigma = tmpGradientFilterSigma; % sigmaW
      obj.NoiseThreshold      = tmpNoiseThreshold;
      
      obj.p_tGradKernel = CreateTemporalGradientKernel(obj); 
      obj.p_sGradKernel = CreateSpacialGradientKernel(obj); 
      obj.p_tKernel = CreateTemporalKernel(obj); 
      obj.p_sKernel = CreateSpacialKernel(obj); 
      obj.p_wKernel = CreateWeightingKernel(obj);       
 
      sigmaS = obj.ImageFilterSigma;
      sigmaW = obj.GradientFilterSigma;
      sigmaS_der = sqrt(2.0*sigmaS);
      obj.p_sGradKernelLen = getKernelWidthFromSigma(obj, sigmaS_der);

      [~, obj.p_tGradKernelLen] = getTemporalWidth_WidthDerFromNumFrame(obj);
      obj.p_sKernelLen = getKernelWidthFromSigma(obj, sigmaS); 
      obj.p_wKernelLen = getKernelWidthFromSigma(obj, sigmaW);  
      
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
        %   - For the very first frame, the previous frames are set to black.
        
     checkImage(ImageA);
     if (~isSimMode())
         % compile time error if ImageA is not fixed sized
         eml_invariant(eml_is_const(size(ImageA)), ...
                      eml_message('vision:OpticalFlow:imageVarSize'));
     end
              
     if (obj.pFirstCall) 
         obj.pInRows = size(ImageA,1);
         obj.pInCols = size(ImageA,2);
         
         obj.pImageClassID = getClassID(ImageA);
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
     
     % Set up buffer for holding previous video frames
     if (obj.pFirstCall) 
       % initialize pDelayBuffer, pMostRecentDFrameIdx
       setupDelayBuffer(obj, tmpImageA);
       obj.pFirstCall = false;
     else
       coder.assertDefined(obj.pDelayBuffer);       
     end         
     allIdx = computeAllIndicesForLKDG(obj);  

     % Temporary memory: GRAD{CC,RC,RR,CT,RT}_IDX
     obj.pGradCC = zeros(obj.pInRows, obj.pInCols, otherDT);
     obj.pGradRC = zeros(obj.pInRows, obj.pInCols, otherDT);
     obj.pGradRR = zeros(obj.pInRows, obj.pInCols, otherDT);
     obj.pGradCT = zeros(obj.pInRows, obj.pInCols, otherDT);
     obj.pGradRT = zeros(obj.pInRows, obj.pInCols, otherDT);
      
     noiseThreshold = cast(obj.NoiseThreshold, otherDT);
     pp_tGradKernel = cast(obj.p_tGradKernel, otherDT);
     pp_sGradKernel = cast(obj.p_sGradKernel, otherDT);
     pp_tKernel = cast(obj.p_tKernel, otherDT);
     pp_sKernel = cast(obj.p_sKernel, otherDT);
     pp_wKernel = cast(obj.p_wKernel, otherDT);      
      
     discardIllConditionedEstimates = true;
     %out = zeros(obj.pInRows, obj.pInCols, otherDT);
     if isSimMode()
         [outVelReal, outVelImag] = visionOpticalFlowLKDoG( ...
         			tmpImageA, obj.pDelayBuffer, allIdx, ...
					obj.pGradCC, obj.pGradRC, obj.pGradRR, obj.pGradCT, obj.pGradRT, ...
					noiseThreshold, ...
					pp_tGradKernel, pp_sGradKernel, pp_tKernel, ...
                    pp_sKernel, pp_wKernel, ...
                    ~discardIllConditionedEstimates ...
         );
     else
        [outVelReal, outVelImag] = vision.internal.buildable.opticalFlowLKDoGBuildable.opticalFlowLKDoG_compute( ...
         			tmpImageA, obj.pDelayBuffer, allIdx, ...
					obj.pGradCC, obj.pGradRC, obj.pGradRR, obj.pGradCT, obj.pGradRT, ...
					noiseThreshold, ...
					pp_tGradKernel, pp_sGradKernel, pp_tKernel, ...
                    pp_sKernel, pp_wKernel, ...
                    discardIllConditionedEstimates ...
         );
     end
     outFlow = opticalFlow(outVelReal, outVelImag);
     updateDelayBuffer(obj, tmpImageA);
    end
    
    %------------------------------------------------------------------
    function set.NumFrames(this, numFrames)
        checkNumFrames(numFrames);
        this.NumFrames = double(numFrames);
    end
    %------------------------------------------------------------------
    function set.ImageFilterSigma(this, imageFilterSigma)
        checkSigma(imageFilterSigma, 'ImageFilterSigma');
        this.ImageFilterSigma = double(imageFilterSigma);
    end
    %------------------------------------------------------------------
    function set.GradientFilterSigma(this, gradientFilterSigma)
        checkSigma(gradientFilterSigma, 'GradientFilterSigma');
        this.GradientFilterSigma = double(gradientFilterSigma);
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
        %   the previous frames to black.
        
        obj.pFirstCall = true;

    end
    
  end
  
  methods(Access=private)
    %----------------------------------------------------------------------
    % Parse inputs for simulation
    %----------------------------------------------------------------------
    function [tmpNumFrames, tmpImageFilterSigma, ...
            tmpGradientFilterSigma, tmpNoiseThreshold] ...
        = parseInputsSimulation(obj, varargin)
      
      % Instantiate an input parser
      parser = inputParser;
      parser.FunctionName = mfilename;
      
      % Specify the optional parameters
      parser.addParameter('NumFrames',         obj.NumFrames);
      parser.addParameter('ImageFilterSigma', obj.ImageFilterSigma);
      parser.addParameter('GradientFilterSigma', obj.GradientFilterSigma);
      
      parser.addParameter('NoiseThreshold', obj.NoiseThreshold);
       
      % Parse parameters
      parse(parser, varargin{:});
      r = parser.Results;
      
      tmpNumFrames         =  r.NumFrames;
      tmpImageFilterSigma     =  r.ImageFilterSigma;
      tmpGradientFilterSigma  =  r.GradientFilterSigma;
      tmpNoiseThreshold     =  r.NoiseThreshold;
      
    end
    
    %----------------------------------------------------------------------
    % Parse inputs for code generation
    %----------------------------------------------------------------------
    function [tmpNumFrames, tmpImageFilterSigma, ...
            tmpGradientFilterSigma, tmpNoiseThreshold] ...
        = parseInputsCodegen(obj, varargin)

      defaultsNoVal = struct( ...
        'NumFrames',            uint32(0), ...
        'ImageFilterSigma',     uint32(0), ...
        'GradientFilterSigma',     uint32(0), ...
        'NoiseThreshold', uint32(0));
      
      properties = struct( ...
        'CaseSensitivity', false, ...
        'StructExpand',    true, ...
        'PartialMatching', false);
      
     optarg = eml_parse_parameter_inputs(defaultsNoVal, properties, varargin{:});
    
      tmpNumFrames = eml_get_parameter_value(optarg.NumFrames, ...
        obj.NumFrames, varargin{:});
      tmpImageFilterSigma = eml_get_parameter_value(optarg.ImageFilterSigma, ...
        obj.ImageFilterSigma, varargin{:});
      tmpGradientFilterSigma = eml_get_parameter_value(optarg.GradientFilterSigma, ...
        obj.GradientFilterSigma, varargin{:});    
      tmpNoiseThreshold = eml_get_parameter_value(optarg.NoiseThreshold, ...
        obj.NoiseThreshold, varargin{:});
    end
    
    % Compute all indices for Method = 'Lucas-Kanade' and 
    % GradientFilter = 'Derivative of Gaussian'
    function allIdx = computeAllIndicesForLKDG(obj)
        allIdx = zeros([obj.NumFrames-1 1], 'uint32');
        jj=1;
        for ii=obj.pMostRecentDFrameIdx:(obj.NumFrames-1)
            allIdx(jj) = ii;
            jj = jj+1;
        end
        for ii=1:obj.pMostRecentDFrameIdx-1
            allIdx(jj) = ii;
            jj = jj+1;
        end     
    end
    
    function s = getDelayBufferSize(obj, in)
      inSize = size(in);
      numFrames = getNumFramesInBuffer(obj);
      s = [inSize, numFrames];
    end
    
    function setupDelayBuffer(obj, in)
      inDataType = class(in);
      inSize = size(in);
      numFrames = getNumFramesInBuffer(obj);

      obj.pDelayBuffer = zeros([inSize, numFrames], inDataType);
      obj.pMostRecentDFrameIdx = uint32(1);
    end   
  
    function updateDelayBuffer(obj, in)
      oldestFrameIdx = getOldestFrameIdx(obj);
      obj.pDelayBuffer(:,:,oldestFrameIdx) = in;
      obj.pMostRecentDFrameIdx(:) = oldestFrameIdx;
    end
    
    function idx = getOldestFrameIdx(obj)
      idx = obj.pMostRecentDFrameIdx-uint32(1);
      if (idx < uint32(1)) % 1 based indexing
          idx(:) = getNumFramesInBuffer(obj);
      end
    end
    
    % Compute the number of frames in the buffer
    function numFrames = getNumFramesInBuffer(obj)
        numFrames = obj.NumFrames - 1;

    end
    
    %======================================================================
    %
    %            Temporal Gradient Filter
    %
    %======================================================================    
    function sigmaT = getSigmaT(obj)
    %{
        sigmaTmin  sigmaTmax   numFrames(idx)
        0.0139     0.124       3(0); => if (0.0139 < sigmaT3 <= 0.124), width_derGauss = 3;
        0.124      0.347       5(1);  => if (0.124 < sigmaT3 <= 0.347), width_derGauss = 5;
        0.347      0.680       7(2); => 3 width_derGauss
        0.680      1.124       9(3); => 3 width_derGauss
        1.124      1.680       11(4); => 3 width_derGauss
        1.680      2.166       13(5); => if (0.168 < sigmaT3 <= 2.166), width_derGauss = 13;
        %===== =   ======      ==
        2.166      2.499       15(6); => if (2.166 < sigmaT3 <= 2.499), width_Gauss = 15;
        2.499      2.833       17(7);
        2.833      3.166       19(8);
        3.166      3.499       21(9);
        3.499      3.833       23(10);
        3.833      4.166       25(11);
        4.166      4.499       27(12);
        4.499      4.833       29(13);
        4.833      5.166       31(14)  => if (4.833 < sigmaT3 <= 5.166), width_Gauss = 31;
    %}
     
    numFrames = obj.NumFrames; % NumFrames includes current frame
    sigmaT_range = [0.0139,0.124,0.347,0.680,1.124,1.680, ...
                    2.166, 2.499,2.833,3.166,3.499,3.833,4.166,4.499,4.833,5.166];
    idx = (numFrames-3)/2 + 1; % (+1 for 1 based) numFrames must be odd and >=3
    TuningFactor = 0.5; % it may come as input parameter in future
    sigmaT = sigmaT_range(idx) + (sigmaT_range(idx+1)- sigmaT_range(idx))*TuningFactor;
    
    end
    
    function width = getKernelWidthFromSigma(~, sigma)

       width = floor(6*sigma +1);
       if mod(width,2)==0 % iseven(width) % (!(width & 0x1)) 
        width = width +1 ; %width must be odd numbered 
       end

    end
    
   function gradKernel = getGradientKernel(~, kernelLen, sigma)

       gradKernel = zeros(kernelLen, 1);
       halfWidth = floor(kernelLen/2.0);% kernelLen is odd
       sigmaSquareTimes2 = 2 * sigma * sigma;
       coeff = 1.0 / (sqrt(2.0 * pi) * sigma * sigma * sigma);
       k = 1;
       for x=-halfWidth:halfWidth
             gradKernel(k) = - coeff * x * exp(-x*x / sigmaSquareTimes2 );
             k = k+1;
       end
   end

   function kernel = getKernel(~, kernelLen, sigma)

       kernel = zeros(kernelLen, 1);
       halfWidth = floor(kernelLen/2.0);% kernelLen is odd
       sigmaSquareTimes2 = 2* sigma * sigma;
       coeff = 1.0 / (sqrt(2.0 * pi) * sigma);
       k = 1;
       for x=-halfWidth:halfWidth
             kernel(k) = coeff *  exp(-x*x / sigmaSquareTimes2);
             k = k+1;
       end
   end
   
    function [width_G, width_derG] = getTemporalWidth_WidthDerFromNumFrame(obj)
        numFrames = obj.NumFrames;
        
        sigmaT = getSigmaT(obj);
        if (numFrames <= 13) % 3 <= numFrames <= 13
           % here always width_derG >= width_G 
            width_derG = numFrames;
            width_G = getKernelWidthFromSigma(obj, sigmaT);
            % the following should never happen
            if (width_G > width_derG)  
                width_G = width_derG;
            end

        else % 15 <= numFrames <= 31
           % here always width_G >= width_derG 
            width_G = numFrames;

            sigmaT_der = sqrt(2.0*sigmaT);
            width_derG = getKernelWidthFromSigma(obj, sigmaT_der);
            % the following should never happen
            if (width_derG > width_G)  
                width_derG = width_G;
            end
        end
    end
    function kernel = CreateTemporalGradientKernel(obj)
        sigmaT = getSigmaT(obj);
        sigmaT_der = sqrt(2.0*sigmaT);
        [~, kernelLen] = getTemporalWidth_WidthDerFromNumFrame(obj);
        kernel = getGradientKernel(obj, kernelLen, sigmaT_der);
        
    end 
    
    function kernel = CreateTemporalKernel(obj)
        sigmaT = getSigmaT(obj);
        [~, kernelLen] = getTemporalWidth_WidthDerFromNumFrame(obj);
        kernel = getKernel(obj, kernelLen, sigmaT);
        
    end 
    
    %======================================================================
    %
    %            Spatial Gradient Filter            
    %
    %======================================================================
    %{
    function kernelLen = getSpacialGradientKernelLength(sigmaS)
        sigmaS_der = sqrt(2.0*sigmaS);
        kernelLen = getKernelWidthFromSigma(sigmaS_der);        
    end
    %}
    function kernel = CreateSpacialGradientKernel(obj)
        sigmaS = obj.ImageFilterSigma;
        sigmaS_der = sqrt(2.0*sigmaS);
        kernelLen = getKernelWidthFromSigma(obj, sigmaS_der);
        kernel = getGradientKernel(obj, kernelLen, sigmaS_der);
    end    
    function kernel = CreateSpacialKernel(obj)
        sigmaS = obj.ImageFilterSigma;
        kernelLen = getKernelWidthFromSigma(obj, sigmaS);
        kernel = getKernel(obj, kernelLen, sigmaS);
    end     
    %======================================================================
    %
    %            Weighting Filter            
    %
    %======================================================================    
    function kernel = CreateWeightingKernel(obj)
        sigmaW = obj.GradientFilterSigma;
        kernelLen = getKernelWidthFromSigma(obj, sigmaW);
        kernel = getKernel(obj, kernelLen, sigmaW);
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
function checkNumFrames(NumFrames)

validateattributes(NumFrames, {'numeric'}, ...
    {'nonempty', 'integer', 'odd', 'nonsparse', 'nonnan', 'real', ...
     'finite', 'scalar', '>=', 1}, ...
    mfilename, 'NumFrames');

end

%==========================================================================
function checkSigma(Sigma, ParamName)

validateattributes(Sigma, {'numeric'}, {'nonempty', 'nonnan', ...
    'finite', 'nonsparse', 'real', 'scalar', '>', 0}, ...
    mfilename, ParamName);

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
