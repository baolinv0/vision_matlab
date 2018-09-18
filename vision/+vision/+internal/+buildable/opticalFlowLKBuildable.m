classdef opticalFlowLKBuildable < coder.ExternalDependency %#codegen
    % opticalFlowLKBuildable - encapsulate opticalFlowLK implementation library
    
    % Copyright 2012 The MathWorks, Inc.
    
    
    methods (Static)
        
        function name = getDescriptiveName(~)
            name = 'opticalFlowLKBuildable';
        end
        
        function b = isSupportedContext(context)
            b = context.isMatlabHostTarget();
        end
        
        function updateBuildInfo(buildInfo, ~)
            buildInfo.addIncludePaths({fullfile(matlabroot,'toolbox', ...
                'vision','builtins','src','vision','include')} );
            buildInfo.addSourcePaths({fullfile(matlabroot,'toolbox', ...
                'vision','builtins','src','vision')});
            buildInfo.addSourceFiles({'opticalFlowLKCore.cpp'});
            buildInfo.addIncludeFiles({'vision_defines.h', ...
                                       'opticalFlowLKCore_api.hpp', ...
                                       'opticalFlowLK.hpp'});                                      
        end

        %------------------------------------------------------------------
        % write all supported data-type specific function calls      
        function [outVelReal, outVelImag] = ...
                 opticalFlowLK_compute( ...
         			tmpImageA, ImageB, ...
					pGradCC, pGradRC, pGradRR, pGradCT, pGradRT, ...
				    NoiseThreshold ...
                  )        
            
            coder.inline('always');
            % add '#include "opticalFlowLKCore_api.hpp"' in <myfcn>.c
            coder.cinclude('opticalFlowLKCore_api.hpp');
    
            % call function
            outVelReal = zeros(size(tmpImageA), 'like', pGradCC);
            outVelImag = zeros(size(tmpImageA), 'like', pGradCC);
            
            pInRows = int32(size(tmpImageA,1));
            pInCols = int32(size(tmpImageA,2));
            fcnName = ['MWCV_OpticalFlow_LK_' class(tmpImageA)];
            coder.ceval(fcnName,...
              coder.ref(tmpImageA), ...
              coder.ref(ImageB), ...
              coder.ref(outVelReal), ...
              coder.ref(outVelImag), ...
  			  coder.ref(pGradCC), coder.ref(pGradRC), coder.ref(pGradRR), coder.ref(pGradCT), coder.ref(pGradRT), ...
			  coder.ref(NoiseThreshold), ...
              pInRows, pInCols ...
                  );
        end       
    end   
end