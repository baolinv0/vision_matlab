function val = checkExecutionEnvironment(val, callername)
val = validatestring(val, {'auto', 'cpu', 'gpu'}, ...
    callername, 'ExecutionEnvironment');
end