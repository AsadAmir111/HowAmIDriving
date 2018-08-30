function [newTime2,newOutput] = func1(fileName,dbcName)
    close all;
    myData = load(fileName);
    myDBC = canDatabase(dbcName);
    
    Time = myData.myStruct(:,5);
    Address = myData.myStruct(:,2);
    Data = myData.myStruct(:,3);
    Time = table2array(Time);
    Address = table2array(Address);
    Data = table2array(Data);

    Address = strrep(Address(:),'0x','');
    Data = strrep(Data(:),'0x','');

    popECU = uicontrol('Style','popupmenu','String',{myDBC.MessageInfo(:).Name},...
        'Position',[70 380 150 30],'Callback','uiresume(gcbf)');
    uiwait(gcf);
    ind1 = popECU.Value;
    ID = myDBC.MessageInfo(ind1).ID;
    ID = dec2hex(ID);

    [addsize,~] = size(Address);
    Address1 = zeros(addsize,1);
    for i = 1:1:addsize;
        Address1(i) = strcmpi(Address(i),ID);
    end
    index1 = find(Address1);
    newTime = Time(index1(:,1));
    newData1 = Data(index1(:,1));

    newData = hex2dec(newData1);
    [y,~] = size(newData);
    Output = zeros(y,1);

    popSC = uicontrol('Style','popupmenu','String',{myDBC.MessageInfo(ind1).SignalInfo(:).Name},...
        'Position',[300 380 150 30],'Callback','uiresume(gcbf)');
    uiwait(gcf);
    ind2 = popSC.Value;

    lenSignal = myDBC.MessageInfo(ind1).Length;
    nbits = lenSignal * 8;
    startBit = myDBC.MessageInfo(ind1).SignalInfo(ind2).StartBit;

    MSB = startBit + 8 + 8 * floor(((nbits/2)-startBit)/8) * 2;
    signalSize = myDBC.MessageInfo(ind1).SignalInfo(ind2).SignalSize - 1;
    mySign = 1;
    myNum = 0;
    
    for i = 1:y
        Binary = bitget(newData(i),MSB-signalSize:1:MSB);
        if myDBC.MessageInfo(ind1).SignalInfo(ind2).Signed == 1
            if Binary(3) == 1
                mySign = -1;
                myNum = 1;
            else
                mySign = 1;
                myNum = 0;
            end
        end
        Output(i) = bi2de(Binary) * mySign + myNum;
    end
    
    Factor = myDBC.MessageInfo(ind1).SignalInfo(ind2).Factor;
    Offset = myDBC.MessageInfo(ind1).SignalInfo(ind2).Offset;
    Output = Factor .* Output;
    Output = Offset + Output(:,:);
    
    Min = myDBC.MessageInfo(ind1).SignalInfo(ind2).Minimum;

    Max = myDBC.MessageInfo(ind1).SignalInfo(ind2).Maximum;

    Output1 = Output >= Min & Output <= Max;
    index2 = find(Output1);
    newOutput = Output(index2(:,1));
    newTime2 = newTime(index2(:,1));

    movFiles = input('Enter the name of the video: \n');
    [myVid,finalVideo] = vidSync(movFiles);
    
    minOut = min(newOutput);
    maxOut = max(newOutput);
    Range = maxOut - minOut;
    Percentage = Range * 0.05;    
    yMin = floor(minOut - Percentage);
    yMax = ceil(maxOut + Percentage);
    
%     [xSize,~] = size(newTime2);
%     xlimit = newTime2(xSize);

    smoothOutput = smooth(newOutput);
    plot(newTime2,smoothOutput);
    hold on;
    p = plot([0,0],[yMin,yMax],'r');
    x1 = 0;
    x2 = 60;
    axis([x1 x2 yMin yMax]);
    
%%%% ginput    
%     while 1
%         [x,~] = ginput(1);       
%         if (x1+jump+x2+jump)/2 < x && ((x1+jump+x2+jump)*3)/4 < xlimit
%             tempx = tempx+10;
%             x1 = x1+jump;
%             x2 = x2+jump;
%         elseif (x1-jump+x2-jump)/2 > x && (x1-jump+x2-jump)/4 > 0
%             tempx = tempx-10;
%             x1 = x1-jump;
%             x2 = x2-jump;
%         end
%         axis([x1 x2 yMin yMax]);        
%     end

    frameRate = myVid.FrameRate;
    jump = 1;
    
    videoFReader = vision.VideoFileReader(finalVideo);
    videoPlayer = vision.VideoPlayer;
    videoPlayer.Position = [470 230 500 400];    
    
%     for i = 0:1/frameRate:xlimit
%         if jump > 60*frameRate
%             x1 = x1 + 60;
%             x2 = x2 + 60;            
%             axis([x1 x2 yMin yMax]);
%             jump = 0;
%         end
%         p.XData = [i,i];
%         p.YData = [yMin,yMax];
%         drawnow
%         pause(0.01);
%         jump = jump + 1;
%     end
    
    i = 0;
    while ~isDone(videoFReader)
        frame = step(videoFReader);
        step(videoPlayer,frame);
        if jump > 60*frameRate
            x1 = x1 + 60;
            x2 = x2 + 60;            
            axis([x1 x2 yMin yMax]);
            jump = 0;
        end
        p.XData = [i,i];
        p.YData = [yMin,yMax];
        drawnow
%         pause(0.01);
        jump = jump + 1;
        i = i + 1/frameRate;
    end
end