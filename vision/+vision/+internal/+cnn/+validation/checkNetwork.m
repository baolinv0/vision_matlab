function checkNetwork(network, name, varargin)
cls = {'SeriesNetwork', 'nnet.cnn.layer.Layer'};
if numel(varargin) == 1
    cls{end+1} = varargin{1};
end
validateattributes(network,cls,{},name);
