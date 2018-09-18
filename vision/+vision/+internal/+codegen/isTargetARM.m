function tf = isTargetARM()
% tf = isTargetARM
% Return true if the Code Generation Target is ARM Cortex

%   Copyright 2015 The MathWorks, Inc.

%#codegen

isARMTarget = ...
    coder.target('ARM Compatible->ARM Cortex');

tf = isARMTarget;
end