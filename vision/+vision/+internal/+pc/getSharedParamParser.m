% Return shared inputParser
function parser = getSharedParamParser(filename)

% Parse the PV-pairs
defaults = struct('MarkerSize', 6, 'VerticalAxis', 'Z', ...
    'VerticalAxisDir', 'Up');

% Setup parser
parser = inputParser;
parser.CaseSensitive = false;
parser.FunctionName  = filename;

parser.addParameter('MarkerSize', defaults.MarkerSize, ...
    @(x)vision.internal.pc.validateMarkerSize(filename, x));

parser.addParameter('VerticalAxis', defaults.VerticalAxis, ...
    @(x)vision.internal.pc.validateVerticalAxis(filename, x));

parser.addParameter('VerticalAxisDir', defaults.VerticalAxisDir, ...
    @(x)vision.internal.pc.validateVerticalAxisDir(filename, x));

  