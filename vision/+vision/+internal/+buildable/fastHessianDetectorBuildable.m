classdef fastHessianDetectorBuildable < coder.ExternalDependency %#codegen
    %FASTHESSIANDETECTORBUILDABLE - encapsulate fastHessianDetector implementation library
    
    % Copyright 2013 The MathWorks, Inc.    
    
    methods (Static)
        
        function name = getDescriptiveName(~)
            name = 'fastHessianDetectorBuildable';
        end
        
        function b = isSupportedContext(~)
            b = true; % supports non-host target
        end
        
        function updateBuildInfo(buildInfo, context)
            buildInfo.addIncludePaths({fullfile(matlabroot,'toolbox', ...
                'vision','builtins','src','ocv','include'), ...
                fullfile(matlabroot,'toolbox', ...
                'vision','builtins','src','ocvcg', 'opencv', 'include')} );
            buildInfo.addSourcePaths({fullfile(matlabroot,'toolbox', ...
                'vision','builtins','src','ocv')});
            buildInfo.addSourceFiles({'fastHessianDetectorCore.cpp', ...
                'surfCommon.cpp', ...                
                'mwsurf.cpp'});
            buildInfo.addIncludeFiles({'vision_defines.h', ...
                                       'fastHessianDetectorCore_api.hpp', ...
                                       'precomp_mw.hpp', ...
                                       'features2d_surf_mw.hpp', ...
                                       'surfCommon.hpp'}); % no need 'rtwtypes.h'
                                   
            vision.internal.buildable.portableOpenCVBuildInfo(buildInfo, context, ...
                'fastHessianDetector');
        end

        %------------------------------------------------------------------
        % write all supported data-type specific function calls       
        function [Location, Scale, Metric, SignOfLaplacian] = fastHessianDetector_uint8(Iu8, ...
                            nRows, nCols, numInDims, ...         
                            nOctaveLayers, nOctaves, hessianThreshold)
            
            coder.inline('always');
            coder.cinclude('fastHessianDetectorCore_api.hpp');
            
            ptrKeypoint = coder.opaque('void *', 'NULL');
    
            % call function
            outNumRows = int32(0);
            if coder.isColumnMajor
                outNumRows(1)=coder.ceval('-col','fastHessianDetector_uint8',...
                  coder.ref(Iu8), ...
                  nRows, nCols, numInDims, ...   
                  nOctaveLayers, nOctaves, hessianThreshold, ...
                  coder.ref(ptrKeypoint));
            else
                outNumRows(1)=coder.ceval('-row','fastHessianDetector_uint8',...
                  coder.ref(Iu8), ...
                  nRows, nCols, numInDims, ...   
                  nOctaveLayers, nOctaves, hessianThreshold, ...
                  coder.ref(ptrKeypoint));                
            end
            
            % copy output to mxArray
            % step-2: declare output as variable sized so that _mex file can return differet sized output.
            % allocate output
            coder.varsize('Location', [inf, 2]);
            coder.varsize('Scale', [inf, 1]);
            coder.varsize('Metric', [inf, 1]);
            coder.varsize('SignOfLaplacian', [inf, 1]);
            
            % create uninitialized memory
            Location = coder.nullcopy(zeros(double(outNumRows),2,'single'));
            Scale    = coder.nullcopy(zeros(double(outNumRows),1,'single'));
            Metric   = coder.nullcopy(zeros(double(outNumRows),1,'single'));
            SignOfLaplacian = coder.nullcopy(zeros(double(outNumRows),1,'int8'));
            
            if coder.isColumnMajor
                coder.ceval('-col','fastHessianDetector_keyPoints2field',...
                  ptrKeypoint, ...
                  coder.ref(Location), coder.ref(Scale), coder.ref(Metric), coder.ref(SignOfLaplacian));
            else
                coder.ceval('-row','fastHessianDetector_keyPoints2fieldRM',...
                  ptrKeypoint, ...
                  coder.ref(Location), coder.ref(Scale), coder.ref(Metric), coder.ref(SignOfLaplacian));
            end                
            
            coder.ceval('fastHessianDetector_deleteKeypoint',...
              ptrKeypoint);
        end       
    end   
end
