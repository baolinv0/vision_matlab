classdef extractFreakBuildable < coder.ExternalDependency %#codegen
    % extractFreakBuildable - encapsulate extractFeature (FREAK) implementation library
    
    % Copyright 2012-2016 The MathWorks, Inc.
    
    
    methods (Static)
        
        function name = getDescriptiveName(~)
            name = 'extractFreakBuildable';
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
            buildInfo.addSourceFiles({'extractFreakCore.cpp', ...
                                      'mwfreak.cpp', ...
                                      'cgCommon.cpp'});
            buildInfo.addIncludeFiles({'vision_defines.h', ...
                                       'mwfreak.hpp', ...
                                       'cgCommon.hpp', ...
                                       'extractFreakCore_api.hpp'}); % no need 'rtwtypes.h'   
                                   
            vision.internal.buildable.portableOpenCVBuildInfo(buildInfo, context, ...
                'extractFreak');          
        end

        %------------------------------------------------------------------
        % write all supported data-type specific function calls      
        function [outLocation, outScale, outMetric, outMisc, ...
                  outOrientation, outFeatures] = ...
                 extractFreak_uint8(Iu8T, inLocation, inScale, inMetric, ...
                 inMisc, nbOctave, orientationNormalized, scaleNormalized, patternScale)        
            
            coder.inline('always');
            coder.cinclude('extractFreakCore_api.hpp');

            ptrKeypoints = coder.opaque('void *', 'NULL');
            ptrDescriptors = coder.opaque('void *', 'NULL');
    
            % call function
            out_numel = int32(0);
            numel = int32(size(inLocation, 1));
            numInDims = int32(ndims(Iu8T));
            if coder.isColumnMajor
            nRows = int32(size(Iu8T, 2)); % original (before transpose)
            nCols = int32(size(Iu8T, 1)); % original (before transpose)
                
            out_numel(1)=coder.ceval('-col','extractFreak_compute',...
              coder.ref(Iu8T), ...
              nRows, nCols, numInDims, ...   
              coder.ref(inLocation), coder.ref(inScale), coder.ref(inMetric), coder.ref(inMisc), ...
              int32(numel), int32(nbOctave), logical(orientationNormalized), logical(scaleNormalized), single(patternScale), ...
              coder.ref(ptrKeypoints), coder.ref(ptrDescriptors));
            else
            nRows = int32(size(Iu8T, 1)); % original (before transpose)
            nCols = int32(size(Iu8T, 2)); % original (before transpose)
                
            out_numel(1)=coder.ceval('-row','extractFreak_computeRM',...
              coder.ref(Iu8T), ...
              nRows, nCols, numInDims, ...   
              coder.ref(inLocation), coder.ref(inScale), coder.ref(inMetric), coder.ref(inMisc), ...
              int32(numel), int32(nbOctave), logical(orientationNormalized), logical(scaleNormalized), single(patternScale), ...
              coder.ref(ptrKeypoints), coder.ref(ptrDescriptors));                
            end
            
            % copy output to mxArray
            % declare output as variable sized so that _mex file can return differet sized output.
            % allocate output
            % coder.internal.prefer_const(featureWidth);
            coder.varsize('outLocation',        [inf, 2]);
            coder.varsize('outScale',           [inf, 1]);
            coder.varsize('outMetric',          [inf, 1]);
            coder.varsize('outMisc',            [inf, 1]);
            coder.varsize('outOrientation',     [inf, 1]);
            coder.varsize('outFeatures',        [inf, 128],[1 1]);
            
            % create uninitialized memory using coder.nullcopy
            outLocation = coder.nullcopy(zeros(out_numel,2,'single'));
            outScale    = coder.nullcopy(zeros(out_numel,1,'single'));
            outMetric   = coder.nullcopy(zeros(out_numel,1,'single'));
            outMisc = coder.nullcopy(zeros(out_numel,1,'int32'));
            outOrientation = coder.nullcopy(zeros(out_numel,1,'single'));
            featureWidth = 64;
            outFeatures = coder.nullcopy(zeros(out_numel,featureWidth,'uint8'));            
            
            if coder.isColumnMajor
            coder.ceval('-col','extractFreak_assignOutput',...
              ptrKeypoints, ptrDescriptors, ...
              coder.ref(outLocation), coder.ref(outScale), ...
              coder.ref(outMetric), coder.ref(outMisc), ...
              coder.ref(outOrientation), coder.ref(outFeatures));
            else
            coder.ceval('-row','extractFreak_assignOutputRM',...
              ptrKeypoints, ptrDescriptors, ...
              coder.ref(outLocation), coder.ref(outScale), ...
              coder.ref(outMetric), coder.ref(outMisc), ...
              coder.ref(outOrientation), coder.ref(outFeatures));                
            end

        end       
    end   
end