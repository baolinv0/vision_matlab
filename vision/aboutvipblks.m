function aboutvipblks
%ABOUTVIPBLKS Displays version number of the Computer Vision  
%  System Toolbox and the copyright notice in a modal dialog box.

%  Copyright 2004-2005 The MathWorks, Inc.
 

a=ver('vision');
str1=a.Name;
str2=a.Version;
tmp=a.Date;b=tmp(end-3:end);
str3=['Copyright 2004-',b,' MathWorks, Inc.'];
str = sprintf([str1,' ',str2,'\n',str3]);
msgbox(str,'About the Computer Vision System Toolbox','modal');

% [EOF] aboutvision.m
