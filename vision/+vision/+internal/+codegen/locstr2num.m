function out = locstr2num(value)
% Local version of STR2NUM to capture output into struct. This enables use
% with eml_const.

%#codegen

[out.Value, out.IsValid] = str2num(value);