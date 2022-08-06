% cd('C:\toolbox\Psychtoolbox')
% SetupPsychtoolbox
%%
%%%%%%%%%%%%%% Orientation Discrimination Task under Crowding %%%%%%%%%%%
% This code was written by Milad Qolami
clc;
clear;
close all;
% Inputs
SubjectID = input('Inter subject ID:');
DominantEye = input("Which Eye is dominant (either 'right' or 'left'? : ","s");
while ~any(strcmp(DominantEye,{'right','left'}))
    DominantEye = input("Which Eye is dominant (either 'right' or 'left'? : ","s");
end

BinocularCond = input("Which binocular condition? (either 'binocular' or 'monoocular'):","s")
while ~any(strcmp(BinocularCond,{'binocular','monoocular'}))
    BinocularCond = input("Which binocular condition? (either 'binocular' or 'monoocular'):","s")
end
%% Display setup module
% Define display parameters
scrnNum     = max(Screen('Screens'));
stereoMode  = 4; % Define the mode for stereodisply

% Windows-Hack: If mode 4 or 5 is requested, we select screen zero
% as target screen: This will open a window that spans multiple
% monitors on multi-display setups, which is usually what one wants
% for this mode.
if IsWin && (stereoMode==4 || stereoMode==5)
    scrnNum = 0;
end
% Dual display dual-window stereo requested?
if stereoMode == 10
    % Yes. Do we have at least two separate displays for both views?
    if length(Screen('Screens')) < 2
        error('Sorry, for stereoMode 10 you''ll need at least 2 separate display screens in non-mirrored mode.');
    end
    
    if ~IsWin
        % Assign left-eye view (the master window) to main display:
        scrnNum = 0;
    else
        % Assign left-eye view (the master window) to main display:
        scrnNum = 1;
    end
end
if stereoMode == 10
    % In dual-window, dual-display mode, we open the slave window on
    % the secondary screen:
    if IsWin
        slaveScreen = 2;
    else
        slaveScreen = 1;
    end
     % The 2nd window for output of the right-eye view should be
    % opened on 'slaveScreen':
    PsychImaging('AddTask', 'General', 'DualWindowStereo', slaveScreen);
end
p.ScreenDistance = 50; % in centimeter
p.ScreenHeight = 19; % in centimeter
p.ScreenGamma = 2; % from monitor calibration
p.maxLuminance = 100; % from monitor calibration
p.ScreenBackground = 0.5;



% Open the display window, set up lookup table, and hide the  mouse cursor
if exist('onCleanup', 'class'), oC_Obj = onCleanup(@()sca); end
% close any pre-existing PTB Screen window

% Prepare setup of imaging pipeline for onscreen window.

% Check that Psychtoolbox is properly installed, switch to unified KbName's
% across operating systems, and switch color range to normalized 0 - 1 range:
PsychDefaultSetup(2);
Screen('Preference', 'SkipSyncTests', 1);
PsychImaging( 'PrepareConfiguration'); % First step in starting  pipeline
PsychImaging( 'AddTask', 'General','FloatingPoint32BitIfPossible' );
% set up a 32-bit floatingpoint framebuffer

PsychImaging( 'AddTask', 'General','NormalizedHighresColorRange' );
% normalize the color range ([0, 1] corresponds to [min, max])

PsychImaging('AddTask', 'General', 'EnablePseudoGrayOutput' );
% enable high gray level resolution output with bitstealing

PsychImaging( 'AddTask' , 'FinalFormatting','DisplayColorCorrection' , 'SimpleGamma' );
% setup Gamma correction method using simple power  function for all color channels

[windowPtr p.ScreenRect] = PsychImaging( 'OpenWindow'  , scrnNum, p.ScreenBackground, [], [], [], stereoMode);

if ismember(stereoMode, [4, 5])
    % This uncommented bit of code would allow to exercise the
    % SetStereoSideBySideParameters() function, which allows to change
    % presentation parameters for dual-display / side-by-side stereo modes 4
    % and 5:
    % "Shrink display a bit to the center": SetStereoSideBySideParameters(windowPtr, [0.25, 0.25], [0.75, 0.5], [1, 0.25], [0.75, 0.5]);
    % Restore defaults: SetStereoSideBySideParameters(windowPtr, [0, 0], [1, 1], [1, 0], [1, 1]);
end

[screenXpixels, screenYpixels] = Screen('WindowSize', windowPtr); % size of open window

[xCenter, yCenter]  = RectCenter(p.ScreenRect); % center of the open window

PsychColorCorrection( 'SetEncodingGamma', windowPtr,1/ p.ScreenGamma);
% set Gamma for all color channels

HideCursor; % Hide the mouse cursor
ShowCursor

% Get frame rate and set screen font
p.ScreenFrameRate = FrameRate(windowPtr);
% get current frame rate
Screen( 'TextFont', windowPtr, 'Times' );
% set the font for the screen to Times
Screen( 'TextSize', windowPtr, 24); % set the font size
                                    % for the screen to 24
%% Experiment module 

% Specify general experiment parameters
nTrials         = 20;   
p.randSeed      = ClockRandSeed;     

% Specify the stimulus
p.stimSize      = 1;  % In visual angle
p.stimDistance  = 3; 
p.eccentricity  = 2; 
p.stimDuration  = 0.250; 
p.ISI           = 0.5;    % duration between response and next trial onset
p.contrast      = 1;   
p.tf            = 4;   % Drifting temporal frequency in Hz
p.sf            = 4;   % Spatial frequency in cycles/degree
numCrowd        = 4; % number of crowding stimuli

% Compute stimulus parameters
ppd     = pi/180 * p.ScreenDistance / p.ScreenHeight * p.ScreenRect(4);     % pixels per degree
nFrames = round(p.stimDuration * p.ScreenFrameRate);    % # stimulus frames
m       = 2 * round(p.stimSize * ppd / 2);    % horizontal and vertical stimulus size in pixels                                         
d       = 2 * round(p.stimDistance * ppd / 2); % stimulus distance in pixel
e       = 2 * round(p.eccentricity * ppd / 2);  % stimulus eccentricity in pixel
sf      = p.sf / ppd;    % cycles per pixel
phasePerFrame = 360 * p.tf / p.ScreenFrameRate;     % phase drift per frame

% Creating Eccentricity matrix 
E = [e 0;0 -e;-e 0;0 e];

fixRect = CenterRect([0 0 1 1] * 8, p.ScreenRect);   % 8 x 8 fixation
% Initialize a table to set up experimental conditions
p.recLabel = {'trialIndex' 'stimOrientation' 'crowdOrientation' 'stimuliPosition' 'respCorrect' 'respTime' };

rec                                 = nan(nTrials, length(p.recLabel));     % matrix rec is nTrials x 5 of NaN
rec(:, 1)                           = 1 : nTrials;    % Label the trial type numbers from 1 to nTrials
rec(1 : nTrials/2, 2)               = 45;     % Half of the trials set to +1 for 45 orientatin of targer
rec(nTrials/2 +1 : end, 2)          = 135;     % Half of the trials set to +1 for 45 orientatin of targer
rec(:,3)                            = rec(:,2);              % The same labels are used ro crowding stimulation
rec(1 : nTrials/4, 4)               = 1;      % 1/4 of the trials set to 1 for right visual field presentation
rec(nTrials/4 + 1 : nTrials/2, 4)   = 2;      % 1/4 of the trials set to 2 for down visual field presentation
rec(nTrials/2 + 1 : 3*nTrials/4, 4) = 3;      % 1/4 of the trials set to 3 for left visual field presentation
rec(3*nTrials/4 + 1 : end, 4)       = 4;      % 1/4 of the trials set to 4 for up visual field presentation
rec(:, 2)                           = Shuffle(rec(:, 2));     % randomize orientation of target over trials
rec(:, 3)                           = Shuffle(rec(:, 2));     % randomize orientation of target over trials
rec(:, 4)                           = Shuffle(rec(:, 4));     % randomize orientation of target over trials


% Generate the stimulus texture
text =  CreateProceduralSmoothedApertureSineGrating(windowPtr,...
    m, m, [.5 .5 .5 .5],50,.5,[],[],[]);
params = [0 sf p.contrast 0];  % Dfining parameters for the grating
switch BinocularCond
    case 'monoocular'
        switch DominantEye
            case 'right'
                onset = GetSecs;
                for orient_i = 1:10
                    orient_vect = [repmat(rec(orient_i,3),numCrowd,1);rec(orient_i,2)]
                    % Applying eccentircity 
                    StimPosition = [xCenter yCenter] + E(rec(orient_i,4),:);
                    p.targetLocs   = [StimPosition(1)-m/2  StimPosition(2)-m/2 StimPosition(1)+m/2 StimPosition(2)+m/2];
                    p.crowdingLocs = VisualCrowder(StimPosition,numCrowd, d ,m);
                    % Select left-eye image buffer for drawing:
                    Screen('SelectStereoDrawBuffer', windowPtr, 0);
                    % Draw left stim:
                    Screen('FillRect',windowPtr,[0 0 0],fixRect);

                    % Select right-eye image buffer for drawing:
                    Screen('SelectStereoDrawBuffer', windowPtr, 1);
                    Screen('DrawTextures', windowPtr, text, [], [p.crowdingLocs p.targetLocs'],orient_vect, [], [],...
                        [], [], [], params');
                    Screen('FillRect',windowPtr,[0 0 0],fixRect);
                    Screen('DrawingFinished', windowPtr);
                    % Flip stim to display and take timestamp of stimulus-onset after
                    % displaying the new stimulus and record it in vector t:
                    onset = Screen('Flip', windowPtr,onset + p.ISI);
                end
            case 'left'
                % Select left-eye image buffer for drawing:
                Screen('SelectStereoDrawBuffer', windowPtr, 0);
                % Draw left stim:
                Screen('DrawTextures', windowPtr, text, [], [p.crowdingLocs p.targetLocs'], 45, [], [],...
                    [], [], [], params');
                Screen('FillRect',windowPtr,[0 0 0],fixRect);
                % Select right-eye image buffer for drawing:
                Screen('SelectStereoDrawBuffer', windowPtr, 1);
                Screen('FillRect',windowPtr,[0 0 0],fixRect);
                Screen('DrawingFinished', windowPtr);
                onset = Screen('Flip', windowPtr);
        end
    case 'binocular'
        switch DominantEye
            case 'right'
                % Select left-eye image buffer for drawing:
                Screen('SelectStereoDrawBuffer', windowPtr, 0);

                % Draw left stim:
                Screen('DrawTextures', windowPtr, text, [], [p.crowdingLocs], 45, [], [],...
                    [], [], [], params');
                Screen('FillRect',windowPtr,[0 0 0],fixRect)

                % Select right-eye image buffer for drawing:
                Screen('SelectStereoDrawBuffer', windowPtr, 1);
                Screen('DrawTextures', windowPtr, text, [], [p.targetLocs'],135, [], [],...
                    [], [], [], params');
                Screen('FillRect',windowPtr,[0 0 0],fixRect)
                Screen('DrawingFinished', windowPtr);
                onset = Screen('Flip', windowPtr);
            case 'left'
                % Select left-eye image buffer for drawing:
                Screen('SelectStereoDrawBuffer', windowPtr, 0);

                % Draw left stim:
                Screen('DrawTextures', windowPtr, text, [], [p.targetLocs'], 45, [], [],...
                    [], [], [], params');
                Screen('FillRect',windowPtr,[0 0 0],fixRect)

                % Select right-eye image buffer for drawing:
                Screen('SelectStereoDrawBuffer', windowPtr, 1);
                Screen('DrawTextures', windowPtr, text, [], [p.crowdingLocs],135, [], [],...
                    [], [], [], params');
                Screen('FillRect',windowPtr,[0 0 0],fixRect)
                Screen('DrawingFinished', windowPtr);
                onset = Screen('Flip', windowPtr);
        end
end

% % Generate the stimulus texture
% text =  CreateProceduralSmoothedApertureSineGrating(windowPtr,...
%     m, m, [.5 .5 .5 .5],50,.5,[],[],[]);
% params = [0 sf p.contrast 0];  % Dfining parameters for the grating

KbName('UnifyKeyNames'); % set up keyboard functions to use
                         % the same labels on different computer platforms

% Initialize a table to set up experimental conditions
p.recLabel = {'trialIndex' 'stimOrientation' 'crowdOrientation' 'respCorrect' 'respTime' };

rec = nan(nTrials, length(p.recLabel));     % matrix rec is nTrials x 4 of NaN
rec(:, 1) = 1 : nTrials;    % label the trial type numbers from 1 to nTrials
rec(:, 2) = -135;     % -1 for 135 orientation of target
rec(1 : nTrials/2, 2) = 45 ;     % half of the trials set to +1 for 45 orientatin of targer
rec(:,3) = -1;      % -1 for 135 orientation of crowding stimuli
rec(1 : nTrials/2, 3) = 1 ;     % half of the trials set to +1 for 45 orientatin of targer
rec(:, 2) = Shuffle(rec(:, 2));     % randomize orientation of target over trials
rec(:, 3) = Shuffle(rec(:, 2));     % randomize orientation of crowding stimuli over trials

% Prioritize display to optimize display timing
% Priority(MaxPriority(windowPtr));

% Start experiment with instructions
% str = sprintf('Left/Right arrow keys for Orientation.\n\n Press SPACE to start.'  );
% DrawFormattedText(windowPtr, str, 'center', 'center', 1);
% Screen( 'Flip', windowPtr);
% KbWait;
% RestrictKeysForKbCheck([39,37,32,27]);
% 
% Screen( 'FillOval', windowPtr, 0, fixRect);      % create fixation box as black (0)
% Secs = Screen('Flip', windowPtr); 
% p.start = datestr(now);    % record start time

% % Run nTrials trials
% for i = 1 : nTrials

% Select left-eye image buffer for drawing:
% Screen('SelectStereoDrawBuffer', windowPtr, 0);
% 
% Draw left stim:
% Screen('DrawTextures', windowPtr, text, [], [p.stimLocCrowd], 45, [], [],...
%     [], [], [], params');
% Screen('FillRect',windowPtr,[0 0 0],fixRect)
% 
% Select right-eye image buffer for drawing:
% Screen('SelectStereoDrawBuffer', windowPtr, 1);
% Screen('DrawTextures', windowPtr, text, [], [p.stimLocTarget],135, [], [],...
%     [], [], [], params');
% Screen('FillRect',windowPtr,[0 0 0],fixRect)
% 
% 
%  Tell PTB drawing is finished for this frame:
% Screen('DrawingFinished', windowPtr);
% Flip stim to display and take timestamp of stimulus-onset after
% displaying the new stimulus and record it in vector t:
% onset = Screen('Flip', windowPtr);


%     Screen('FillOval', windowPtr, 1, fixRect);
%     Screen('Flip', windowPtr);
%     KbWait;
%     [keyIsDown, time_secs1, keyCode, deltaSecs] = KbCheck;


%     if strcmp(KbName(keyCode), 'esc'), break; end
%     % stop the trial sequence if keypress = <esc>
% 
%     respCorrect = strcmp(keyCode, 'right') == (rec(i, 2) == 1) | strcmp(keyCode, 'left') == (rec(i, 2) == -1) ;
%     % compute if correct or incorrect
% 
%     rec(i, 3 : 4) = [respCorrect time_secs1-t0];
%     % record correctness and RT in rec
% 
%     if rec(i, 3), Beeper; end % beep if correct
% 
% end

p.finish = datestr(now); % record finish time

% % Save Results
% save SubjectID.mat rec p; % save the results
% sca;


% %% System Reinstatement Module
% Priority(0); % restore priority
% sca; % close display window and textures, and restore the original color lookup table

