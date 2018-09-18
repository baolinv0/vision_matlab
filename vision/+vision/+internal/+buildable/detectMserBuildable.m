classdef detectMserBuildable < coder.ExternalDependency %#codegen
    % detectMserBuildable - used by detectMserFeatures
    
    % Copyright 2012 The MathWorks, Inc.
    
    
    methods (Static)
        
        function name = getDescriptiveName(~)
            name = 'detectMserBuildable';
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
            buildInfo.addSourceFiles({'detectMserCore.cpp', 'cgCommon.cpp'});
            buildInfo.addIncludeFiles({'vision_defines.h', ...
                                       'cgCommon.hpp', ...
                                       'detectMserCore_api.hpp'}); % no need 'rtwtypes.h'   
                                   
            vision.internal.buildable.portableOpenCVBuildInfo(buildInfo, context, ...
                'detectMser');             
        end
        
        %------------------------------------------------------------------
        % write all supported data-type specific function calls
        function [outPixelList, outLengts] = detectMser_uint8(Iu8, params)
            
            coder.inline('always');
            coder.cinclude('detectMserCore_api.hpp');
            
            ptrRegions = coder.opaque('void *', 'NULL');
            
            % call function
            numTotalPts = int32(0);
            numRegions = int32(0);
            nRows = int32(size(Iu8, 1));
            nCols = int32(size(Iu8, 2));
            isRGB = ~ismatrix(Iu8);
            
            if isempty(Iu8)                
                outPixelList = zeros(numTotalPts,2,'int32');
                outLengts    = zeros(numRegions,1,'int32');
            else
                if coder.isColumnMajor
                    coder.ceval('-col', 'detectMser_compute',...
                        coder.ref(Iu8), ...
                        nRows, nCols, isRGB, ...
                        params.delta, ... % int
                        params.minArea, ... % int
                        params.maxArea, ... % int
                        params.maxVariation, ... % float
                        params.minDiversity, ... % float
                        params.maxEvolution, ... % int
                        params.areaThreshold, ... % double
                        params.minMargin, ... % double
                        params.edgeBlurSize, ... % int
                        coder.ref(numTotalPts), ...
                        coder.ref(numRegions), ...
                        coder.ref(ptrRegions));
                else
                    coder.ceval('-row', 'detectMser_computeRM',...
                        coder.ref(Iu8), ...
                        nRows, nCols, isRGB, ...
                        params.delta, ... % int
                        params.minArea, ... % int
                        params.maxArea, ... % int
                        params.maxVariation, ... % float
                        params.minDiversity, ... % float
                        params.maxEvolution, ... % int
                        params.areaThreshold, ... % double
                        params.minMargin, ... % double
                        params.edgeBlurSize, ... % int
                        coder.ref(numTotalPts), ...
                        coder.ref(numRegions), ...
                        coder.ref(ptrRegions));
                end
                % copy output to mxArray
                % declare output as variable sized so that _mex file can return differet sized output.
                % allocate output
                % coder.internal.prefer_const(featureWidth);
                coder.varsize('outPixelList', [inf, 2]);
                coder.varsize('outLengts',    [inf, 1]);
                
                % create uninitialized memory using coder.nullcopy
                outPixelList = coder.nullcopy(zeros(numTotalPts,2,'int32'));
                outLengts    = coder.nullcopy(zeros(numRegions,1,'int32'));
                if coder.isColumnMajor
                    coder.ceval('-col', 'detectMser_assignOutput',...
                        ptrRegions, ...
                        numTotalPts, ...
                        coder.ref(outPixelList), ...
                        coder.ref(outLengts));    
                else
                    coder.ceval('-row', 'detectMser_assignOutputRM',...
                        ptrRegions, ...
                        numTotalPts, ...
                        coder.ref(outPixelList), ...
                        coder.ref(outLengts));                     
                end
            end
            
        end
    end
end