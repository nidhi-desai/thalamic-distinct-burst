function reboundBurstTC_FrequencyResponse()
%% Description
% This code runs simulations for Section 3.8 figure 10c.
% It simulates and calculates the fraction of inhibitory pulses which would 
% lead a TC cell to burst when applied at increasing frequencies.
% by Nidhi Desai

%% Initializing
output = array2table(zeros(0,10));
output.Properties.VariableNames = {'gT','Vshift','HyperpolarIapp','hyperpolarFreq',...
    'NumInputPulses','NumBurstsCaused','avgHyperVolReached','avgNumSpksPerBurst',...
    'avgLatencyOfBurst','prcntOfInputsThatCausedABurst'};
counter = 1;
folderName = 'Results';
cd (folderName);
fileName = 'FreqResponse';
exportToPPTX('new', fileName); 
exportToPPTX('saveandclose', fileName);

%% Setting parameters
Vshift_all = [0; -5; -10; -12; -14; -15; -16]; 
varyFreq = [1; 4; 6; 10; 15];
for u = 1:size(Vshift_all,1)
    for s = 2:size(varyFreq,1)
        close all; clc;
        gT_temp = 1; % 1.3; 
        Vshift_temp = Vshift_all(u); % max Vshift=-18 with Iapp=1
        % Try for hyperVols around -80 to -85 mV
        Iapp = %0.9; %0.75;  
        freq = varyFreq(s);
        [data, AppCurrentTime, hyperpolarStartTime] =...
            TC_burstSimulation_vary_gT_Vshift(gT_temp, Vshift_temp, Iapp, freq);
        h = figure; plot(data.time, data.Ed_V);

        %% Better way of detecting individual bursts
        [~,locs] = findpeaks(data.Ed_V(data.time>hyperpolarStartTime), data.time(data.time>hyperpolarStartTime), 'MinPeakHeight', 0);
        locs = double(locs); locs = [locs; 0];
        burstCounter = 0;
        hyperVol = [];
        numSpksPerBurst = [];
        latency = [];
        r = 1;
        localBurst = 1;
        tempLocsIndx = 1;
        HyperTimeBeforeB = [];
        firstBurstSpkTime = [];
        while r < size(locs,1)
            if (locs(r+1) - locs(r)) <= 30 && r < size(locs,1)-1
                tempLocsIndx = [tempLocsIndx; r+1];
                localBurst = localBurst + 1;
                r = r + 1;
            elseif (locs(r+1) - locs(r)) > 30 || r == size(locs,1)-1
                numSpksPerBurst = [numSpksPerBurst; localBurst];
                localBurst = 1;
                burstCounter = burstCounter + 1;
                currentBurstFirstSpkTime = locs(tempLocsIndx(1));
                tempIndx = data.time < currentBurstFirstSpkTime & ...
                    data.time > (currentBurstFirstSpkTime - 220);
                [~,locs2] = findpeaks(-data.Ed_V(tempIndx), data.time(tempIndx), 'MinPeakHeight', 65); %70);    
                lastHyperEndTimeBeforeBurst = locs2(end);
                HyperTimeBeforeB = [HyperTimeBeforeB; locs2(end)];
                firstBurstSpkTime = [firstBurstSpkTime; currentBurstFirstSpkTime];
                hyperVol = [hyperVol; double(data.Ed_V(data.time == lastHyperEndTimeBeforeBurst))];
                latency = [latency; currentBurstFirstSpkTime - lastHyperEndTimeBeforeBurst];   
                r = r + 1;
                tempLocsIndx = r;
            end
        end  

        %% Saving results
        output.gT(counter) = gT_temp;
        output.Vshift(counter) = Vshift_temp;
        output.HyperpolarIapp(counter) = Iapp;
        output.hyperpolarFreq(counter) = freq;
        output.NumInputPulses(counter) = size(AppCurrentTime,1);
        output.NumBurstsCaused(counter) = burstCounter;
        output.avgHyperVolReached(counter) = mean(hyperVol);
        output.avgNumSpksPerBurst(counter) = median(numSpksPerBurst);
        output.avgLatencyOfBurst(counter) = median(latency);
        output.prcntOfInputsThatCausedABurst(counter) = burstCounter*100/size(AppCurrentTime,1);
        
        
        %% % ------------------------------------------------------ %%%%%%%



        %% Save plots
        counter = counter + 1;
        title(strcat('gT= ', num2str(gT_temp),'; Vshift= ',...
            num2str(Vshift_temp), '; Iapp= ', num2str(Iapp), '; freq= ', num2str(freq)));
        exportToPPTX('open', fileName); 
        exportToPPTX('addslide');
        exportToPPTX('addpicture',h);
        exportToPPTX('saveandclose',fileName);
        close(h); 

    end
end

%% Plots with the results
varyFreq = [1; 4; 6; 10; 15];
indx1 = output.gT == 1;
figure; hold on;
for r = 1:size(varyFreq,1)
    indx2 = output.hyperpolarFreq == varyFreq(r);
    shift = -output.Vshift(indx1 & indx2);
    latency = output.avgLatencyOfBurst(indx1 & indx2);
    percnt = output.prcntOfInputsThatCausedABurst(indx1 & indx2)./100;
    plot(latency, percnt, '-o');
end
ylim([-0.1, 1.1]);
xlim([-2, 20]);
xticks([0, 5, 10, 12, 14, 15, 16, 18]);
legend({'freq=1','freq=4','freq=6','freq=10','freq=15'});
ylabel('fraction of hyperpolarizing inputs that caused a burst');
xlabel('Vshift');
title('frequency response results: gT = 1');

end
