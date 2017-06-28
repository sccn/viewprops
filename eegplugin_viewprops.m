function eegplugin_viewprops( fig, try_strings, catch_strings )
%EEGLABPLUGIN_POP_PROP_EXTENDED Summary of this function goes here
%   Detailed explanation goes here
vers = '1.0';
if nargin < 3
    error('eegplugin_viewprops requires 3 arguments');
end

plotmenu = findobj(fig, 'tag', 'plot');
uimenu( plotmenu, 'label', 'View extended channel properties', ...
    'callback', 'pop_viewprops(EEG, 1);');
uimenu( plotmenu, 'label', 'View extended component properties', ...
    'callback', 'pop_viewprops(EEG, 0);');
end

