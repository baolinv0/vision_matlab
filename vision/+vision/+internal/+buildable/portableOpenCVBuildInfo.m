function portableOpenCVBuildInfo(buildInfo, context, fcnName)
% portableOpenCVBuildInfo:
% This functions performs following operations:
%   All platforms:
%       (1) headers: includes ALL opencv header files
%       (2) nonBuildFiles: includes ALL openCV libraries
%                        (win: dll, linux: so, mac: dylib) as nonBuildFiles
%       (3) linkObjects: includes ALL openCV libraries
%                        (win: lib, linux: so, mac: dylib) as linkObjects

% File extensions
% for windows: linkLibExt = '.lib', execLibExt = '.dll'
[~, linkLibExt, execLibExt] = context.getStdLibInfo();
group = 'BlockModules';

% Platform specific link and non-build files
arch            = computer('arch');
pathBinArch     = fullfile(matlabroot,'bin',arch,filesep);

%--------------------------------------------------------------------------
% Set OpenCV version
%--------------------------------------------------------------------------
ocv_version = '3.1.0';

warnIfNotCPPCompiler();
errorIfNotHierachicalPackType(buildInfo);

if isProdHWDeviceTypeARM(buildInfo)
    % no need to include libraries in the buildInfo. These libraries are
    % for MATLAB host only
    return;
end

switch arch
    case {'win32','win64'}
        % include all opencv .lib files
        linkLibPath = fullfile(matlabroot,'toolbox', ...
            'vision','builtins','src','ocvcg', 'opencv', arch, 'lib');

        ocv_ver_no_dots = strrep(ocv_version,'.','');

        % Non-build files
        % associate open cv 3p libraries in (matlabroot)\bin\win64
        nonBuildFilesNoExt = {};
        ocvNonBuildFilesNoExt = AddDefaultOpenCVLibraries(nonBuildFilesNoExt, ocv_ver_no_dots);
        ocvNonBuildFilesNoExt = AddHighGuiLibIfNeeded(ocvNonBuildFilesNoExt, fcnName, ocv_ver_no_dots);
        ocvNonBuildFilesNoExt = AddObjDetectLibIfNeeded(ocvNonBuildFilesNoExt, fcnName, ocv_ver_no_dots);
        ocvNonBuildFilesNoExt = AddFeaturesLibIfNeeded(ocvNonBuildFilesNoExt, fcnName, ocv_ver_no_dots);
        ocvNonBuildFilesNoExt = AddFlannLibIfNeeded(ocvNonBuildFilesNoExt, fcnName, ocv_ver_no_dots);
        ocvNonBuildFilesNoExt = AddCalib3DLibIfNeeded(ocvNonBuildFilesNoExt, fcnName, ocv_ver_no_dots);
        ocvNonBuildFilesNoExt = AddVideoLibIfNeeded(ocvNonBuildFilesNoExt, fcnName, ocv_ver_no_dots);
        ocvNonBuildFilesNoExt = AddVideoIOLibIfNeeded(ocvNonBuildFilesNoExt, fcnName, ocv_ver_no_dots);
        ocvNonBuildFilesNoExt = AddMLLibIfNeeded(ocvNonBuildFilesNoExt, fcnName, ocv_ver_no_dots);
        ocvNonBuildFilesNoExt = AddImgCodecsLibIfNeeded(ocvNonBuildFilesNoExt, fcnName, ocv_ver_no_dots);

        ocvLinkFilesNoExt = ocvNonBuildFilesNoExt;
        nonBuildFilesNoExt = [ocvNonBuildFilesNoExt, 'tbb'];
        nonBuildFiles = strcat(pathBinArch,nonBuildFilesNoExt, execLibExt);

        %linkFilesNoExt  = ocv_libs;%{libName}; %#ok<*EMCA>
        linkFiles       = strcat(ocvLinkFilesNoExt, linkLibExt);

    case {'glnxa64','maci64'}
        linkLibPath     = pathBinArch;

        ocv_major_ver = ocv_version(1:end-2);
        %
        ocvNonBuildFilesNoExt = {'libopencv_calib3d', ...
            'libopencv_core', ...
            'libopencv_cudaarithm', ...
            'libopencv_cudabgsegm', ...
            'libopencv_cudafeatures2d', ...
            'libopencv_cudafilters', ...
            'libopencv_cudaimgproc', ...
            'libopencv_cudalegacy', ...
            'libopencv_cudaobjdetect', ...
            'libopencv_cudaoptflow', ...
            'libopencv_cudastereo', ...
            'libopencv_cudawarping', ....
            'libopencv_cudev', ...
            'libopencv_features2d', ...
            'libopencv_flann', ...
            'libopencv_highgui', ...
            'libopencv_imgproc', ...
            'libopencv_imgcodecs', ...
            'libopencv_ml', ...
            'libopencv_objdetect', ...
            'libopencv_photo', ...
            'libopencv_shape', ...
            'libopencv_stitching', ...
            'libopencv_superres', ...
            'libopencv_stitching', ...
            'libopencv_video', ...
            'libopencv_videoio', ...
            'libopencv_videostab'};

        if strcmpi(arch,'glnxa64')
            % cudacodec is not available on maci platforms.
            ocvNonBuildFilesNoExt{end+1} = 'libopencv_cudacodec';
            nonBuildFiles = strcat(pathBinArch,ocvNonBuildFilesNoExt, strcat('.so.',ocv_major_ver));
            % since opencv source codes are built during codegen, we need
            % add link files
            linkFiles = strcat(ocvNonBuildFilesNoExt, strcat('.so.',ocv_major_ver));

            % boost [only used by pointTracker]
            nonBuildFiles = AddBoostLibsIfNeeded(nonBuildFiles, pathBinArch, fcnName);
            % tbb [used by all]
            nonBuildFiles = AddTbbLibs(nonBuildFiles, pathBinArch);
            % glnxa64 specific runtime libs
            nonBuildFiles = AddGLNXRTlibs(nonBuildFiles);
        else % maci64
            nonBuildFiles = strcat(pathBinArch,ocvNonBuildFilesNoExt, strcat('.',ocv_major_ver,'.dylib'));

            % since opencv source codes are built during codegen, we need
            % add link files
            linkFiles = strcat(ocvNonBuildFilesNoExt, strcat('.',ocv_major_ver,'.dylib'));

            % boost [only used by pointTracker]
            nonBuildFiles = AddBoostLibsIfNeeded(nonBuildFiles, pathBinArch, fcnName);
            % tbb (implicitly used by libopencv_core.2.4.dylib)
            nonBuildFiles{end+1} = strcat(pathBinArch,'libtbb.dylib');
        end

    otherwise
        % unsupported
        assert(false,[ arch ' operating system not supported']);
end

nonBuildFiles = AddCUDALibs(nonBuildFiles, pathBinArch);

linkPriority    = '';
linkPrecompiled = true;
linkLinkonly    = true;
buildInfo.addLinkObjects(linkFiles,linkLibPath,linkPriority,...
    linkPrecompiled,linkLinkonly,group);

buildInfo.addNonBuildFiles(nonBuildFiles,'',group);

%==========================================================================
function nonBuildFiles = AddBoostLibsIfNeeded(nonBuildFiles, pathBinArch, fcnName)
% boost: used by only pointTracker
if strcmp(fcnName, 'pointTracker')
    arch = computer('arch');
    if strcmpi(arch, 'glnxa64')
        boostFileSys = getBoostLibName(pathBinArch, 'libboost_filesystem.so.*');
        boostSys = getBoostLibName(pathBinArch, 'libboost_system.so.*');
        nonBuildFiles{end+1} = strcat(pathBinArch, boostFileSys);
        nonBuildFiles{end+1} = strcat(pathBinArch, boostSys);
    else % must be maci64
        nonBuildFiles{end+1} = strcat(pathBinArch,'libboost_filesystem.dylib');
        nonBuildFiles{end+1} = strcat(pathBinArch,'libboost_system.dylib');
    end
end

%==========================================================================
function nonBuildFiles = AddTbbLibs(nonBuildFiles, pathBinArch)
% tbb: used by all
nonBuildFiles{end+1} = strcat(pathBinArch,'libtbb.so.2');

%==========================================================================
function nonBuildFiles = AddCUDALibs(nonBuildFiles, pathBinArch)
% CUDA: required by all OpenCV libs when OpenCV is built WITH_CUDA=ON.
cudaLibs = {'cudart', 'nppc', 'nppi', 'npps','cufft'};

arch = computer('arch');
switch arch
    case 'win32'
        % CUDA not enabled on win32
        cudaLibs = [];
    case 'win64'
        cudaLibs = strcat(cudaLibs, '64_*.dll');
    case 'glnxa64'
        cudaLibs = strcat('lib', cudaLibs, '.so.*.*');
    case 'maci64'
        cudaLibs = strcat('lib', cudaLibs, '.*.*.dylib');

    otherwise
        assert(false,[ arch ' operating system not supported']);
end

if ~strcmpi(arch,'win32')
    cudaLibs = lookupInBinDir(pathBinArch, cudaLibs);
    cudaLibs = strcat(pathBinArch,cudaLibs);
    for i = 1:numel(cudaLibs)
        nonBuildFiles{end+1} = cudaLibs{i}; %#ok<AGROW>
    end
end

%==========================================================================
function out = lookupInBinDir(pathBinArch, libs)

numLibs = numel(libs);

out = cell(1,numLibs);

for i = 1:numLibs
    info = dir(fullfile(pathBinArch, libs{i}));
    out{i} = info(1).name;
end

%==========================================================================
function nonBuildFiles = AddGLNXRTlibs(nonBuildFiles)
% glnxa64 specific runtime libs
arch = computer('arch');
sysosPath = fullfile(matlabroot,'sys','os',arch,filesep);
nonBuildFiles{end+1} = strcat(sysosPath,'libstdc++.so.6');
nonBuildFiles{end+1} = strcat(sysosPath,'libgcc_s.so.1');

%==========================================================================
function nonBuildFilesNoExt = AddDefaultOpenCVLibraries(nonBuildFilesNoExt, ocv_ver_no_dots)

    nonBuildFilesNoExt{end+1} = strcat('opencv_core', ocv_ver_no_dots);
    nonBuildFilesNoExt{end+1} = strcat('opencv_imgproc', ocv_ver_no_dots);

%==========================================================================
function nonBuildFilesNoExt = AddHighGuiLibIfNeeded(nonBuildFilesNoExt, fcnName, ocv_ver_no_dots)

if strcmp(fcnName, 'cascadeClassifier') || ...
        strcmp(fcnName, 'HOGDescriptor') || ...
        strcmp(fcnName, 'extractSurf') || ...  % dependency via nonfree
        strcmp(fcnName, 'fastHessianDetector') % dependency via nonfree
    nonBuildFilesNoExt{end+1} = strcat('opencv_highgui', ocv_ver_no_dots);
end

%==========================================================================
function nonBuildFilesNoExt = AddObjDetectLibIfNeeded(nonBuildFilesNoExt, fcnName, ocv_ver_no_dots)

if strcmp(fcnName, 'cascadeClassifier') || ...
        strcmp(fcnName, 'HOGDescriptor') || ...
        strcmp(fcnName, 'extractSurf') || ...  % dependency via nonfree
        strcmp(fcnName, 'fastHessianDetector') % dependency via nonfree
    nonBuildFilesNoExt{end+1} = strcat('opencv_objdetect', ocv_ver_no_dots);
end

%==========================================================================
function nonBuildFilesNoExt = AddFeaturesLibIfNeeded(nonBuildFilesNoExt, fcnName, ocv_ver_no_dots)

if strcmp(fcnName, 'detectFAST') || ...
        strcmp(fcnName, 'detectMser') || ...
        strcmp(fcnName, 'extractFreak') || ...
        strcmp(fcnName, 'disparityBM') || ...
        strcmp(fcnName, 'disparitySGBM') || ...
        strcmp(fcnName, 'extractSurf') || ...
        strcmp(fcnName, 'fastHessianDetector') || ...
        strcmp(fcnName, 'detectBRISK') || ...
        strcmp(fcnName, 'extractBRISK')
    nonBuildFilesNoExt{end+1} = strcat('opencv_features2d', ocv_ver_no_dots);
end

%==========================================================================
function nonBuildFilesNoExt = AddFlannLibIfNeeded(nonBuildFilesNoExt, fcnName, ocv_ver_no_dots)

if strcmp(fcnName, 'detectFAST') || ...
        strcmp(fcnName, 'detectMser') || ...
        strcmp(fcnName, 'extractFreak') || ...
        strcmp(fcnName, 'disparityBM') || ...
        strcmp(fcnName, 'disparitySGBM') || ...
        strcmp(fcnName, 'extractSurf') || ...
        strcmp(fcnName, 'fastHessianDetector') || ...
        strcmp(fcnName, 'detectBRISK') || ...
        strcmp(fcnName, 'extractBRISK') || ...
        strcmp(fcnName, 'matchFeatures')
    nonBuildFilesNoExt{end+1} = strcat('opencv_flann', ocv_ver_no_dots);
end

%==========================================================================
function nonBuildFilesNoExt = AddCalib3DLibIfNeeded(nonBuildFilesNoExt, fcnName, ocv_ver_no_dots)

if strcmp(fcnName, 'disparityBM') || ...
        strcmp(fcnName, 'disparitySGBM') || ...
        strcmp(fcnName, 'extractSurf') || ...  % dependency via nonfree
        strcmp(fcnName, 'fastHessianDetector') % dependency via nonfree
    nonBuildFilesNoExt{end+1} = strcat('opencv_calib3d', ocv_ver_no_dots);
end

%==========================================================================
function nonBuildFilesNoExt = AddVideoIOLibIfNeeded(nonBuildFilesNoExt, fcnName, ocv_ver_no_dots)

if strcmp(fcnName, 'HOGDescriptor')
    nonBuildFilesNoExt{end+1} = strcat('opencv_videoio', ocv_ver_no_dots);
end

%==========================================================================
function nonBuildFilesNoExt = AddMLLibIfNeeded(nonBuildFilesNoExt, fcnName, ocv_ver_no_dots)

if strcmp(fcnName, 'HOGDescriptor')
    nonBuildFilesNoExt{end+1} = strcat('opencv_ml', ocv_ver_no_dots);
end

%==========================================================================
function nonBuildFilesNoExt = AddImgCodecsLibIfNeeded(nonBuildFilesNoExt, fcnName, ocv_ver_no_dots)

if strcmp(fcnName, 'HOGDescriptor')
    nonBuildFilesNoExt{end+1} = strcat('opencv_imgcodecs', ocv_ver_no_dots);
end

%==========================================================================
function nonBuildFilesNoExt = AddVideoLibIfNeeded(nonBuildFilesNoExt, fcnName, ocv_ver_no_dots)

if strcmp(fcnName, 'pointTracker') || ...
        strcmp(fcnName, 'opticalFlowFarneback') || ...
        strcmp(fcnName, 'extractSurf') || ...  % dependency via nonfree
        strcmp(fcnName, 'fastHessianDetector') % dependency via nonfree
    nonBuildFilesNoExt{end+1} = strcat('opencv_video', ocv_ver_no_dots);
end

%==========================================================================
function libName = getBoostLibName(pathBinArch, libName)
dirInfo = dir(fullfile(pathBinArch, libName));
libName = dirInfo(1).name;

%==========================================================================
function warnIfNotCPPCompiler()
compilerForMex = mex.getCompilerConfigurations('C++','selected');
if isempty(compilerForMex)
    isCPPComp = false;
else
    if isprop(compilerForMex,'Language')
        isCPPComp = strcmpi(compilerForMex.Language, 'c++');
    else
        isCPPComp = false;
    end
end

if (~isCPPComp)
    warning(message('vision:internal:useCPPCompiler'));
end

%==========================================================================
function errorIfNotHierachicalPackType(buildInfo)

if buildInfo.Settings.DisablePackNGo
    return;
else
     matDir = getLocalBuildDir(buildInfo);
     if isdir(matDir)
        matFilePath = fullfile(matDir, 'codeInfo.mat');
        if exist(matFilePath, 'file')
            x = load(matFilePath);
            y = x.configInfo;
            if isprop(y,'PostCodeGenCommand')
                str = get(y,'PostCodeGenCommand');
                if ~isempty(str)
                    if ~contains(lower(str), 'packngo')
                        if contains(lower(str), 'hierarchical')
                            error(message('vision:internal:useHierarchical'));
                        end
                    end
                end
            end
        end
    end
end

%==========================================================================
function isARM = isProdHWDeviceTypeARM(buildInfo)

 isARM = false;
 matDir = getLocalBuildDir(buildInfo);
 if isdir(matDir)
    matFilePath = fullfile(matDir, 'codeInfo.mat');
    if exist(matFilePath, 'file')
        x = load(matFilePath);
        y = x.configInfo;
        if isprop(y,'HardwareImplementation')
            hi = y.HardwareImplementation;
            if isprop(hi,'ProdHWDeviceType')
                phd = hi.ProdHWDeviceType;
                if ~isempty(phd)
                    if strcmpi(phd,'arm compatible->arm cortex')
                        isARM = true;
                    end
                end
            end
        end
    end
 end
