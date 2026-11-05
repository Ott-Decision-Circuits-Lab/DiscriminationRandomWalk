function GUIOdorSettings(varargin)
global BpodSystem
if ~isfield(BpodSystem.ProtocolFigures,'GUIOdorSettings')
    BpodSystem.ProtocolFigures.GUIOdorSettings = figure('Position', [200 200 400 400],'name','Odor settings','numbertitle','off', 'MenuBar', 'none', 'Resize', 'off');
else
    figure(BpodSystem.ProtocolFigures.GUIOdorSettings)
end
end