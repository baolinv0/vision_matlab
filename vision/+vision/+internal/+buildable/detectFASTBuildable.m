classdef detectFASTBuildable < coder.ExternalDependency %#codegen
    % detectFASTBuildable - used by detectFASTFeatures
    
    % Copyright 2012 The MathWorks, Inc.
    
    
    methods (Static)
        
        function name = getDescriptiveName(~)
            name = 'detectFASTBuildable';
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
            buildInfo.addSourceFiles({'detectFASTCore.cpp', ...
                'cgCommon.cpp'});
            buildInfo.addIncludeFiles({'vision_defines.h', ...
                                       'detectFASTCore_api.hpp', ...
                                       'cgCommon.hpp'}); % no need 'rtwtypes.h'   
                                   
            vision.internal.buildable.portableOpenCVBuildInfo(buildInfo, context, ...
                'detectFAST');            
        end

        %------------------------------------------------------------------
        % write all supported data-type specific function calls      
        function [outLocation, outMetric] = detectFAST_uint8(Iu8, minContrast)        
            
            coder.inline('always');
            coder.cinclude('detectFASTCore_api.hpp');
                        
            ptrKeypoints = coder.opaque('void *', 'NULL');
    
            % call function
            out_numel = int32(0);
            nRows = int32(size(Iu8, 1));
            nCols = int32(size(Iu8, 2));
            isRGB = ~ismatrix(Iu8);
            if coder.isColumnMajor
                out_numel(1)=coder.ceval('-col', 'detectFAST_compute',...
                  coder.ref(Iu8), ...
                  nRows, nCols, isRGB, ... 
                  minContrast, ...
                  coder.ref(ptrKeypoints));
            else
                out_numel(1)=coder.ceval('-row', 'detectFAST_computeRM',...
                  coder.ref(Iu8), ...
                  nRows, nCols, isRGB, ... 
                  minContrast, ...
                  coder.ref(ptrKeypoints));                
            end
            
            % copy output to mxArray
            % declare output as variable sized so that _mex file can return differet sized output.
            % allocate output
            % coder.internal.prefer_const(featureWidth);
            coder.varsize('outLocation',        [inf, 2]);
            coder.varsize('outMetric',          [inf, 1]);
            
            % create uninitialized memory using coder.nullcopy
            outLocation = coder.nullcopy(zeros(out_numel,2,'single'));
            outMetric   = coder.nullcopy(zeros(out_numel,1,'single'));           
            
            if coder.isColumnMajor
                coder.ceval('-col', 'detectFAST_assignOutput',...
                  ptrKeypoints, ...
                  coder.ref(outLocation), ...
                  coder.ref(outMetric));
            else
                coder.ceval('-row', 'detectFAST_assignOutputRM',...
                  ptrKeypoints, ...
                  coder.ref(outLocation), ...
                  coder.ref(outMetric));                
            end

        end       
    end   
end