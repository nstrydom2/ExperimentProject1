function [anin,anout1,avnin,avnout1,pdata] = loadData(fname, stf, finf, k, slice, afile, drop ...
    )
    % Preprocess data if necessary
    % Example: Normalize data, convert categorical labels to numeric, etc.
    % This step depends on the specifics of your data and model requirements

    % Note: Adjust the paths and preprocessing steps according to your actual data


    names=sheetnames(fname);
    for ifile=stf:finf  % stf is the start file name and finf is the ending file 
        t = readtable(fname,'sheet',names(ifile,1),'PreserveVariableNames',true);
        t([1],:)=[];  % remove row 1 of headers in vp
        sn=zeros(height(t),19);
        % save data here to be un hashed later
        snfai=zeros(height(t),19,length(names));
        snf21ai=zeros(height(t),3,length(names));
        %         rt= readtable(rtfname,'sheet',rtnames(ifile,1),'PreserveVariableNames',true,'Format','auto');
        for i=1:height(t)
            % idx=find_date_match(rt{:,2},t{i,1});
            %   if idx~=0
            sn(i,1)=t{i,2};       % med
            sn(i,2)=t{i,22};      % short term diff
            sn(i,17)=t{i,3};

            % mid from vp
            sn(i,3)=t{i,4};    % open  rt3   vp-t4  mid-rt3-open
            sn(i,4)=t{i,5};    % close rt4   vp-t5  mid -rt4 close
            sn(i,5)=t{i,6};    % high  rt5   vp-t6   mid -rt5 high
            sn(i,6)=t{i,7};    % low   rt6   vp-t7   mid rt6 low

            sn(i,7)=t{i,4};    % ask open     mid-rt3 open
            sn(i,8)=t{i,5};    % ask close    mid-rt4 close
            sn(i,9)=t{i,6};    % ask high     mid-rt5 high
            sn(i,10)=t{i,7};   % ask low      mid-rt6 low
            sn(i,11)=t{i,8};      % rsi
            sn(i,13)=t{i,14};
            sn(i,14)=t{i,15};
            sn(i,15)=t{i,16};
            sn(i,16)=t{i,17};     % emi
            % sn(i,17)=t{i,18};
            sn(i,18)=t{i,19};
            sn(i,19)=(t{i,20});
            sn23(i,2)=(t{i,22});  % short term line 3 day
            sn(i,2)=(t{i,22});    % new short term diff 3 day ai average
            %             else
            %                  fmt='error %11s day not found error=%2.0f\n';
            %                  fprintf(fmt,t{i,1},idx);
            %                  pause(10);
            %             end

        end
     
        sn(1,7)=0;
        sn(1,13)=0;
    
        sn(1,8)=0;
        snfai(:,:,ifile)=sn(:,:); % save in indexed file
    end   % end of file load to snfai(X,cx,x)
    %

    % make ai input file here
    %

    ain=zeros(height(t),4); % this is the number of features;
    for i=2:height(t)
        range=(2:i);
        %load 8 inputs for each market
        k1=0;
        for j=ifile:1:ifile %length(names)
            ain(i,k1+1)=snfai(i,16,ifile);      % sn16
            ain(i,k1+3)=snfai(i,1,ifile);       % med term diff
            ain(i,k1+2)=snfai(i,2,ifile);       % short term diff
            ain(i,k1+4)=snfai(i,17,ifile);      %   long term
%
            % ain(i,k1+5)=snfai(i-1,16,ifile)-snfai(i,16,ifile); % sn16 s
            % ain(i,k1+6)=(snfai(i,1,ifile)-min(snfai(range,1,ifile)))-(snfai(i-1,1,ifile)-min(snfai(range,1,ifile)));       % med s
            % ain(i,k1+7)=snfai(i,2,ifile)-snfai(i-1,2,ifile);       % short s
            % ain(i,k1+8)=snfai(i,17,ifile)-snfai(i-1,17,ifile); % long s
            %
            k1=k1+4; % 
        end
    end
    %
    % make output file for ai to be the same day as i-1
    %
    aout=zeros(height(t),1);
    clear cout;
    for i=2:height(t)-1
        aout(i+1,1)=snfai(i+1,4,ifile);% tomarrows close price pit in i for taining
        aout(i,1)=snfai(i,4,ifile);
        if aout(i,1)>aout(i+1,1)
            cout(i,1)={'SHORT'};  % cout for classifcation
        else
            cout(i,1)={'LONG'};
        end
    end
    cout(1,1)={'SHORT'};
    cin=ain;
    cout=cellstr(cout);
    dout=categorical(cout);

    %slice=hi(ii,11)
 

    %afile=hi(ii,13);
        %
        % days =(hi(i,4)
        % k = craw,  ii=hash number sliceis thge # observations
        % normilize data from 1 to to k+1 (801)
        % for this test hi(ii,4)=days=20 slice=40 data will be 801
        %
        days=0;
     %   drop=hi(ii,4)/10; % this is not drop factor between layers
        obs=slice;
        %[rows inputSize]=size(t);
        inputSize = 4;
        muX=zeros(inputSize);  % input size is the numner of columes or inmputs
        SigmaX=zeros(inputSize);
        %k=k1;
%k
muX = arrayfun(@(j) mean(ain(k-580:k+1,j)), 1:inputSize);
        sigmaX = arrayfun(@(j) std(ain(k-580:k+1,j)), 1:inputSize);     
        %
        % the -1 is to keep the ladidation set the same size
        % slice is the observations size = # of observations
        %
        for i=k-580:k+1 % k-800:k+1
            ain(i,:) = arrayfun(@(j) (ain(i,j)-muX(j))./sigmaX(j), 1:inputSize);
        end
        ain1=ain(:,:); % input file 1
        %
        % set up training input data
        %
        j=0;
        %
        ic=520;  % total dat used for patten reqcontion + 1 observation or slice
       
        for i=1:27  % slice is the number observations
           
            temp=ain1(k-ic-19:k-ic,:); %for debug
            tempi=ain1(k-ic-19:k-ic,:).';
            anin(i,1)={tempi}; % here is the input data
            ic=ic-20;
        end
       
        %
        % set up training output  data from aout
        %
        j=0;
        ic=520;
     
        for i=1:27           
            tempnin=dout(k-ic-19:k-ic).';
            anout1(i,1)={tempnin}; % here is the output data
            ic=ic-20;
        end
        %
        % set up validation input avnin and avniout1 with +1 days
        %
        %  (change validation to be one day behind) for the first test
        %
        j=0;
        ic=560;
       
        for i=1:2           
%             if i==slice  %put in validation data excdept for last one
                tempxx=ain1(k-19-ic:k-ic,:);
                tempvin=ain1(k-19-ic:k-ic,:).';
                avnin(i,1)={tempvin}; % here is the input validation data
%             else
%                 tempvin=ain1(k-18-ic:k-ic+1,:).';
%                 avnin(i,1)={tempvin}; % here is lidation data
%             end
            ic=ic-20;
        end
        %
        % set up validation output  data from aout
        %
        j=0;
        ic=560;
        slicea=slice-30;
        for i=1:2         
%             if i==slice
                tempv=dout(k-19-ic:k-ic).';
                avnout1(i,1)={tempv}; % here is the output validation data
%             else
%                 tempv=dout(k-18-ic:k-ic+1,:).';
%                 avnout1(i,1)={tempv}; % here is the input validation data
%             end
            ic=ic-20;
        end
        %
        % set up test data
        %
 j=0;
        %
        ic=520;  % input test features       
        for i=1:27  % slice is the number observations          
            temp=ain1(k-ic-19+1:k-ic+1,:); %for debug
            tempi=ain1(k-ic-19+1:k-ic+1,:).';
            pdata(i,1)={tempi}; % here is the input data
            ic=ic-20;
        end
end
