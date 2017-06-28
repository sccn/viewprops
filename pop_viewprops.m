% POP_VIEWPROPS See  common properties of many EEG channel or component
%   Creates a figure containing a scalp topography or channel location for
%   each selected component or channel. Pressing the button above the scalp
%   topopgraphies will open pop_prop_extended for that component or
%   channel. If pop_viewprops is called with only the first two arguments, 
%   a GUI opens to select the rest. If only one argument is given, typecomp
%   will be set to channels (1) and the GUI will open.
%
%   Inputs
%       EEG: EEGLAB EEG structure
%       typecomp: 0 for component, 1 for channel
%       chanorcomp:  channel or component index to plot
%       spec_opt:  cell array of options which are passed to spectopo()
%       erp_opt:  cell array of options which are passed to erpimage()
%       scroll_event:  0 to hide events in scroll plot, 1 to show them
%       fig: figure handle for the figure to use.
%
%   See also: pop_prop_extended()
%
%   Adapted from pop_selectcomps Luca Pion-Tonachini (2017)

% Copyright (C) 2001 Arnaud Delorme, Salk Institute, arno@salk.edu
%
% This program is free software; you can redistribute it and/or modify
% it under the terms of the GNU General Public License as published by
% the Free Software Foundation; either version 2 of the License, or
% (at your option) any later version.
%
% This program is distributed in the hope that it will be useful,
% but WITHOUT ANY WARRANTY; without even the implied warranty of
% MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
% GNU General Public License for more details.
%
% You should have received a copy of the GNU General Public License
% along with this program; if not, write to the Free Software
% Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA

% 01-25-02 reformated help & license -ad 

function pop_viewprops( EEG, typecomp, chanorcomp, spec_opt, erp_opt, scroll_event, fig)

COLACC = [0.75 1 0.75];
PLOTPERFIG = 35;

if nargin < 1
	help pop_viewprops;
	return;
end;

if nargin < 2
	typecomp = 1; % default
end;	

if nargin < 3
	promptstr    = { fastif(typecomp,'Channel indices to plot:','Component indices to plot:') ...
                     'Spectral options (see spectopo() help):','Erpimage options (see erpimage() help):' ...
                     [' Draw events over scrolling ' fastif(typecomp,'channel','component') ' activity']};
    if typecomp
        inistr       = { ['1:' int2str(length(EEG.chanlocs))] '''freqrange'', [2 80]' '' 1};
    else
        inistr       = { ['1:' int2str(size(EEG.icawinv, 2))] '''freqrange'', [2 80]' '' 1};
    end
    stylestr     = {'edit', 'edit', 'edit', 'checkbox'};
    try
        result       = inputdlg3( 'prompt', promptstr,'style', stylestr, ...
            'default',  inistr, 'title', 'View many chan or comp. properties -- pop_viewprops');
    catch
        result = [];
    end
	if size( result, 1 ) == 0
        return; end
   
	chanorcomp   = eval( [ '[' result{1} ']' ] );
    spec_opt     = eval( [ '{' result{2} '}' ] );
    erp_opt     = eval( [ '{' result{3} '}' ] );
    scroll_event     = result{4};

    if length(chanorcomp) > PLOTPERFIG
        ButtonName=questdlg2(strvcat(['More than ' int2str(PLOTPERFIG) fastif(typecomp,' channels',' components') ' so'],...
            'this function will pop-up several windows'), 'Confirmation', 'Cancel', 'OK','OK');
        if ~isempty( strcmpi(ButtonName, 'cancel')), return; end;
    end;

end;
fprintf('Drawing figure...\n');
currentfigtag = ['selcomp' num2str(rand)]; % generate a random figure tag

if length(chanorcomp) > PLOTPERFIG
    for index = 1:PLOTPERFIG:length(chanorcomp)
        pop_viewprops(EEG, chanorcomp(index:min(length(chanorcomp),index+PLOTPERFIG-1)));
    end;
    return;
end;

try
    icadefs; 
catch
	BACKCOLOR = [0.8 0.8 0.8];
end;

% set up the figure
% -----------------
column =ceil(sqrt( length(chanorcomp) ))+1;
rows = ceil(length(chanorcomp)/column);
if ~exist('fig','var')
	figure('name', [ 'View ' fastif(typecomp,'channels','components') ' properties - pop_viewprops() (dataset: ' EEG.setname ')'], 'tag', currentfigtag, ...
		   'numbertitle', 'off', 'color', BACKCOLOR);
	set(gcf,'MenuBar', 'none');
	pos = get(gcf,'Position');
	set(gcf,'Position', [pos(1) 20 800/7*column 600/5*rows]);
    incx = 120;
    incy = 110;
    sizewx = 100/column;
    if rows > 2
        sizewy = 90/rows;
	else 
        sizewy = 80/rows;
    end;
    pos = get(gca,'position'); % plot relative to current axes
	q = [pos(1) pos(2) 0 0];
	s = [pos(3) pos(4) pos(3) pos(4)]./100;
	axis off;
end;

% figure rows and columns
% -----------------------  
if ~typecomp && EEG.nbchan > 64
    disp('More than 64 electrodes: electrode locations not shown');
    plotelec = 0;
else
    plotelec = 1;
end;
count = 1;
for ri = chanorcomp
	if exist('fig','var')
		button = findobj('parent', fig, 'tag', ['comp' num2str(ri)]);
		if isempty(button) 
			error( 'pop_viewprops(): figure does not contain the component button');
		end;	
	else
		button = [];
	end;		
		 
	if isempty( button )
		% compute coordinates
		% -------------------
		X = mod(count-1, column)/column * incx-10;  
        Y = (rows-floor((count-1)/column))/rows * incy - sizewy*1.3;  

		% plot the head
		% -------------
        if ~strcmp(get(gcf, 'tag'), currentfigtag);
            figure(findobj('tag', currentfigtag));
        end;
		ha = axes('Units','Normalized', 'Position',[X Y sizewx sizewy].*s+q);
        if typecomp
            topoplot( ri, EEG.chanlocs, 'chaninfo', EEG.chaninfo, ...
                     'electrodes','off', 'style', 'blank', 'emarkersize1chan', 12);
        else
            if plotelec
                topoplot( EEG.icawinv(:,ri), EEG.chanlocs, 'verbose', ...
                          'off', 'style' , 'fill', 'chaninfo', EEG.chaninfo, 'numcontour', 8);
            else
                topoplot( EEG.icawinv(:,ri), EEG.chanlocs, 'verbose', ...
                          'off', 'style' , 'fill','electrodes','off', 'chaninfo', EEG.chaninfo, 'numcontour', 8);
            end;
        end
		axis square;

		% plot the button
		% ---------------
         if ~strcmp(get(gcf, 'tag'), currentfigtag);
             figure(findobj('tag', currentfigtag));
         end
		button = uicontrol(gcf, 'Style', 'pushbutton', 'Units','Normalized', 'Position',...
                           [X Y+sizewy sizewx sizewy*0.25].*s+q, 'tag', ['comp' num2str(ri)]);
        if ~exist('spec_opt', 'var') || ~iscell(spec_opt)
            spec_opt = {}; end
        if ~exist('erp_opt', 'var') || ~iscell(erp_opt)
            erp_opt = {}; end
        if ~exist('scroll_event', 'var')
            scroll_event = 1; end
		set( button, 'callback', {@pop_prop_extended, EEG, typecomp, ri, NaN, spec_opt, erp_opt, scroll_event} );
	end;
    if typecomp
        set( button, 'backgroundcolor', COLACC, 'string', EEG.chanlocs(ri).labels); 	
    else
        set( button, 'backgroundcolor', COLACC, 'string', int2str(ri)); 	
    end
	drawnow;
	count = count +1;
end;

return;		


% inputdlg3() - A comprehensive gui automatic builder. This function takes
%               text, type of GUI and default value and builds
%               automatically a simple graphic interface.
%
% Usage:
%   >> [outparam outstruct] = inputdlg3( 'key1', 'val1', 'key2', 'val2', ... );
% 
% Inputs:
%   'prompt'     - cell array of text
%   'style'      - cell array of style for each GUI. Default is edit.
%   'default'    - cell array of default values. Default is empty.
%   'tags'       - cell array of tag text. Default is no tags.
%   'tooltip'    - cell array of tooltip texts. Default is no tooltip.
%
% Output:
%   outparam   - list of outputs. The function scans all lines and
%                add up an output for each interactive uicontrol, i.e
%                edit box, radio button, checkbox and listbox.
%   userdat    - 'userdata' value of the figure.
%   strhalt    - the function returns when the 'userdata' field of the
%                button with the tag 'ok' is modified. This returns the
%                new value of this field.
%   outstruct  - returns outputs as a structure (only tagged ui controls
%                are considered). The field name of the structure is
%                the tag of the ui and contain the ui value or string.
%
% Note: the function also adds three buttons at the bottom of each 
%       interactive windows: 'CANCEL', 'HELP' (if callback command
%       is provided) and 'OK'.
%
% Example:
%   res = inputdlg3('prompt', { 'What is your name' 'What is your age' } );
%   res = inputdlg3('prompt', { 'Chose a value below' 'Value1|value2|value3' ...
%                   'uncheck the box' }, ...
%                   'style',  { 'text' 'popupmenu' 'checkbox' }, ...
%                   'default',{ 0 2 1 });
%
% Author: Arnaud Delorme, Tim Mullen, Christian Kothe, SCCN, INC, UCSD
%
% See also: supergui(), eeglab()

% Copyright (C) Arnaud Delorme, SCCN, INC, UCSD, 2010, arno@ucsd.edu
%
% This program is free software; you can redistribute it and/or modify
% it under the terms of the GNU General Public License as published by
% the Free Software Foundation; either version 2 of the License, or
% (at your option) any later version.
%
% This program is distributed in the hope that it will be useful,
% but WITHOUT ANY WARRANTY; without even the implied warranty of
% MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
% GNU General Public License for more details.
%
% You should have received a copy of the GNU General Public License
% along with this program; if not, write to the Free Software
% Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA

function [result, userdat, strhalt, resstruct] = inputdlg3( varargin);

if nargin < 2
   help inputdlg3;
   return;
end;	

% check input values
% ------------------
[opt addopts] = finputcheck(varargin, { 'prompt'  'cell'  []   {};
                                        'style'   'cell'  []   {};
                                        'default' 'cell'  []   {};
                                        'tag'     'cell'  []   {};
                                        'tooltip','cell'  []   {}}, 'inputdlg3', 'ignore');
if isempty(opt.prompt),  error('The ''prompt'' parameter must be non empty'); end;
if isempty(opt.style),   opt.style = cell(1,length(opt.prompt)); opt.style(:) = {'edit'}; end;
if isempty(opt.default), opt.default = cell(1,length(opt.prompt)); opt.default(:) = {0}; end;
if isempty(opt.tag),     opt.tag = cell(1,length(opt.prompt)); opt.tag(:) = {''}; end;

% creating GUI list input
% -----------------------
uilist = {};
uigeometry = {};
outputind  = ones(1,length(opt.prompt));
for index = 1:length(opt.prompt)
    if strcmpi(opt.style{index}, 'edit')
        uilist{end+1} = { 'style' 'text' 'string' opt.prompt{index} };
        uilist{end+1} = { 'style' 'edit' 'string' opt.default{index} 'tag' opt.tag{index} 'tooltip' opt.tag{index}};
        uigeometry{index} = [2 1];
    else
        uilist{end+1} = { 'style' opt.style{index} 'string' opt.prompt{index} 'value' opt.default{index} 'tag' opt.tag{index} 'tooltip' opt.tag{index}};
        uigeometry{index} = [1];
    end;
    if strcmpi(opt.style{index}, 'text')
        outputind(index) = 0;
    end;
end;

[tmpresult, userdat, strhalt, resstruct] = inputgui('uilist', uilist,'geometry', uigeometry, addopts{:});
result = cell(1,length(opt.prompt));
result(find(outputind)) = tmpresult;
