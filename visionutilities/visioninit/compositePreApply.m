function [status,errMsg] = compositePreApply(this, dialog, string1, string2)

% Copyright 2004 The MathWorks, Inc.

oldVal = dialog.getWidgetValue('firstCoeffFracLength');
dialog.setWidgetValue('firstCoeffFracLength',this.FracLengthCache);

[status, errMsg] = dspDDGPreApplyWithFracLengthUpdate(this, dialog, string1, string2);

dialog.setWidgetValue('firstCoeffFracLength',oldVal);
