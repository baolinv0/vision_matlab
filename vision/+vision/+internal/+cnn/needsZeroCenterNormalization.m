function tf = needsZeroCenterNormalization(network)
tf = ismember(cellstr('zerocenter'), cellstr(network.Layers(1).Normalization));