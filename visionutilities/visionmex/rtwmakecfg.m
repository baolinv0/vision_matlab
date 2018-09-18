function makeInfo=rtwmakecfg()
%RTWMAKECFG Add include and source directories to RTW make files.
%  makeInfo=RTWMAKECFG returns a structured array containing
%  following fields:
%
%     makeInfo.includePath - cell array containing additional include
%                            directories. Those directories will be
%                            expanded into include instructions of rtw
%                            generated make files.
%
%     makeInfo.sourcePath  - cell array containing additional source
%                            directories. Those directories will be
%                            expanded into rules of rtw generated make
%                            files.

% Copyright 1995-2008 The MathWorks, Inc.

makeInfo.includePath = { ...
    fullfile(matlabroot,'toolbox','vision','include'), ...
    fullfile(matlabroot, 'toolbox','shared','dsp','vision','matlab','include') };

makeInfo.sourcePath = {};
