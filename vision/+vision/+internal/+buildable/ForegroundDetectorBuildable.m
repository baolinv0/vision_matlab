classdef ForegroundDetectorBuildable < coder.ExternalDependency %#codegen
% ForegroundDetectorBuildable - encapsulate ForegroundDetector implementation library
%   This function is used by ForegroundDetector function
    
% Copyright 2012 The MathWorks, Inc.


    methods (Static)
        
        function name = getDescriptiveName(~)
            name = 'vision.ForegroundDetector';
        end

        function b = isSupportedContext(context)
            b = context.isMatlabHostTarget();
        end
        
        function updateBuildInfo(buildInfo, context)
            vision.internal.buildable.cvstBuildInfo(buildInfo, context, ...
                                                      'foregroundDetector', ...
                                                      {'use_tbb'}); %#ok<EMCA>
        end

        %------------------------------------------------------------------
        % write all supported data-type specific function calls      
        %------------------------------------------------------------------

        function ptrObj = ForegroundDetector_construct(imageType, statType)        
            
            coder.inline('always');
            coder.cinclude('rtwtypes.h');
            coder.cinclude('cvstCG_foregroundDetector.h');
            
            ptrObj = coder.opaque('void *', 'NULL');

            fcnName = ['foregroundDetector_construct_'  imageType '_'  statType];            
            coder.ceval('-layout:any',fcnName, coder.ref(ptrObj));      
        end        

        function ForegroundDetector_initialize(...
            ptrObj, ...
            imageType, ...
            statType, ...
            I, ...
            numGaussians, initialVariance, initialWeight, varianceThreshold, minBGRatio)
            coder.inline('always');
            coder.cinclude('cvstCG_foregroundDetector.h');
            
            numDim = int32(ndims(I));            
            dims = int32(size(I));

            fcnName = ['foregroundDetector_initialize_' imageType '_'  statType];
            coder.ceval('-layout:any',fcnName,...
                        ptrObj, ...
                        numDim, ...
                        dims, ...
                        int32(numGaussians), ...                    
                        initialVariance, ...
                        initialWeight, ...
                        varianceThreshold, ...
                        minBGRatio);	
            
        end

        function outMask = ForegroundDetector_step(ptrObj, imageType, statType, I, learningRate) 
            
            coder.inline('always');
            coder.cinclude('cvstCG_foregroundDetector.h');
            
            outMask = coder.nullcopy(false(size(I,1),size(I,2)));
            
            if coder.isColumnMajor
                fcnName = ['foregroundDetector_step_'  imageType '_'  statType];
            else
                fcnName = ['foregroundDetector_step_rowMaj_'  imageType '_'  statType];
            end
            
            coder.ceval('-layout:any',fcnName, ...
                        ptrObj, ...
                        coder.rref(I), ...
                        coder.wref(outMask), ...
                        learningRate);            
        end
        
        function ForegroundDetector_release(ptrObj, imageType, statType)

            coder.inline('always');
            coder.cinclude('cvstCG_foregroundDetector.h');
            
            fcnName = ['foregroundDetector_release_' imageType '_' statType];

            coder.ceval('-layout:any',fcnName, ...
                        ptrObj);
            

        end

        function ForegroundDetector_reset(ptrObj, imageType, statType)
                    
            coder.inline('always');
            coder.cinclude('cvstCG_foregroundDetector.h');

            fcnName = ['foregroundDetector_reset_' imageType '_'  statType];
            coder.ceval('-layout:any',fcnName, ...
                        ptrObj);
        end

        function ForegroundDetector_delete(ptrObj, imageType, statType)           

            coder.inline('always');
            coder.cinclude('cvstCG_foregroundDetector.h');
            
            fcnName = ['foregroundDetector_deleteObj_'  imageType '_'  statType];
            coder.ceval('-layout:any',fcnName, ...
                        ptrObj);

        end

    end  
    
end
