% Utility function for deriving UI strings from message catalog
function s = getMessage(id, varargin)
  s = getString(message(id,varargin{:}));
end
