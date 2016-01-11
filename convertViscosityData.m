function [rpm torque visc nm2 shearRate time] = readViscosityData(DATA_PATH, MOVING_STD_SIZE, MAKE_PLOTS)

%%% THINGS TO CHANGE
WRITEPLOTS = 1; % Make this 1 to save plots, 0 to not save plots.
RPM = 60; % This is the spindle speed to plot. Only spindle speeds equal to this variable get plotted.
xLimits = [0, 60];  % These are the horizontal limits of the plot (minutes)
yLimits = [0, 6]; % These are the vertical limits of the plot (cP)

%%% DON'T MESS WITH THINGS BELOW HERE!
close all;
fclose all;

% Size of fonts for plots
fSize = 16;

% Determine the absolute path to the folder containing these codes
% If you changed the name of the folder from 'read-viscometer-files',
% then you should change the argument to the function "getPath"
localRepository = getPath('read-viscometer-files');

% Determine the path to the data directory
data_directory = fullfile(localRepository, 'analysis', 'data', 'raw');

% Select a file from the list.
[fileName, filePath] = uigetfile(fullfile(data_directory, '*.txt'), '');

% Path to the data
dataPath = fullfile(filePath, fileName);

% Samples per second (the output
% file desn't indicate the data rate)
samplesPerSecond = 2;

% Open the file for reading
fid = fopen(dataPath, 'r');
endLine = 0;
numLines = 0;

% Read until the end of the file
while endLine ~=-1
    numLines = numLines + 1;
    endLine = fgetl(fid);
end

% Close the file and reopen it
fclose all;
fid = fopen(dataPath, 'r');

%Initialize the vectors to hold the data
rpm = zeros(numLines, 1);
torque = zeros(numLines, 1);
visc = zeros(numLines, 1);
nm2 = zeros(numLines, 1);
shearRate = zeros(numLines, 1);
time = zeros(numLines, 1);

% Read the data from each line in the
% file output by the viscometer.
for k = 1 : numLines - 2
    dataStr = fgetl(fid);
    rpmLoc = regexpi(dataStr, 'RPM=');
    rpm(k) = str2double(dataStr(rpmLoc + 4 : rpmLoc + 6));

    torqueLoc = regexpi(dataStr, '%=');
    torque(k) = str2double(dataStr(torqueLoc + 2 : torqueLoc + 6));

    viscLoc = regexpi(dataStr, 'mPas=');
    visc(k) = str2double(dataStr(viscLoc + 5 : viscLoc + 8));

    nm2Loc = regexpi(dataStr, 'N/M2=');
    nm2(k) = str2double(dataStr(nm2Loc + 5 : nm2Loc + 8));

    shearRateLoc = regexpi(dataStr, '1/SEC=');
    shearRate(k) = str2double(dataStr(shearRateLoc + 6 : shearRateLoc + 10));
    
    % Time in seconds
    time(k) = k / samplesPerSecond;
    
end

% Find the entries corresponding to the 
% specified spindle speed
viscValid = visc(rpm == RPM);

% Eliminate the NaNs, which occur when
% the viscometer is over-torqued, I think.
viscReal = viscValid(~isnan(viscValid));

% Calculate the mean viscosity
meanVisc = mean(viscReal);

% Calculate the movind-window standard deviation.
% MOVING_STD_SIZE is the window-size of the moving standard deviation.
stdVisc = movingstd(viscReal, MOVING_STD_SIZE, 'central');

% Convert the time variable to minutes.
tMinValid = time(~isnan(viscValid)) / 60;

[haxes, hline1, hline2] = plotyy(tMinValid, viscReal, tMinValid, stdVisc);
set(hline1, 'LineStyle', '--');
set(hline2, 'LineStyle', '-');
axes(haxes(1));
ylim([0 6]);
axes(haxes(2));
ylim([0 1]);

% Find the dot in the file name.
dotLoc = strfind(fileName, '.');

% Make the plot
plot(tMinValid, viscReal, '-k');
hold on
plot([0 max(tMinValid)], [meanVisc meanVisc], '--r')

% Plot labels
xlabel('Time (minutes)', 'FontSize', fSize);
ylabel('Viscosity (cP)', 'FontSize', fSize);
title(['Viscosity vs time, ' num2str(RPM) ' rpm, sample ' strrep(fileName(1:dotLoc-1), '_', '\_') ], 'FontSize', fSize);
legend('Raw', 'Mean');
set(gca, 'FontSize', fSize);
set(gcf, 'Color', 'white');
xlim(xLimits);
ylim(yLimits);
hold off

% Directory in which to plot the data
% This looks wrong? 
plotDir = fullfile(filePath, 'plots');

if MAKE_PLOTS
	if ~exist(plotDir, 'dir')
	    mkdir(plotDir);
	end
    print(1, '-depsc', fullfile(plotDir, [fileName(1:dotLoc-1) '_plot.eps']));
    print(1, '-dpng', '-r300',  fullfile(plotDir, [fileName(1:dotLoc-1) '_plot.png']));
end

end




