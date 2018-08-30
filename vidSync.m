function [myVid,finalVideo] = vidSync(movFiles)
    workingDir = cd;
    myFile = strrep(movFiles,'.mp4','');
    myVid = VideoReader(movFiles);

    % Getting al of the frames from the video
    if ~isdir(myFile)
        mkdir(workingDir,myFile);
        count = 1;
        while hasFrame(myVid)
           img = readFrame(myVid);
           filename = strcat(num2str(sprintf('%05d',count)),'.jpg');
           fullname = fullfile(workingDir,myFile,filename);
           imwrite(img,fullname)
           count = count+1;
        end
    else
        disp('File already exists...');
    end

    checkName = strcat(myFile,'(%d).avi');
    I = 1;
    finalVideo = strcat(myFile,sprintf('(%d).avi',I));

    % Remaking the video from the frames
    if ~exist(sprintf(checkName,I),'file')
        imageNames = dir(fullfile(workingDir,myFile,'*.jpg'));
        imageNames = {imageNames.name}';
        fullPath = fullfile(workingDir,finalVideo);
        outputVideo = VideoWriter(fullPath);
        outputVideo.FrameRate = myVid.FrameRate;
        disp('FrameRate');
        disp(myVid.FrameRate);
        open(outputVideo)
        for i = 1:length(imageNames)
           img = imread(fullfile(workingDir,myFile,imageNames{i}));
           writeVideo(outputVideo,img)
        end
        close(outputVideo);
    else
        disp('Video already exists...');
    end
% Playing the video
%     videoFReader = vision.VideoFileReader(finalVideo);
%     videoPlayer = vision.VideoPlayer;
%     videoPlayer.Position = [470 230 500 400];
%     while ~isDone(videoFReader)
%         frame = step(videoFReader);
%         step(videoPlayer,frame);
%     end
end


