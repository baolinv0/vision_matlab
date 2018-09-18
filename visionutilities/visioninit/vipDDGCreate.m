function obj = vipDDGCreate(h,classInfo)

% Copyright 2004-2005 The MathWorks, Inc.

if strcmp(classInfo{1},'blockproc')
   obj = vipdialog.(classInfo{1})(h);
else
    if length(classInfo) < 2
        classInfo{2} = 'vipfixptddg';
    end
    obj = dvDDGCreate(h,classInfo);
end   


