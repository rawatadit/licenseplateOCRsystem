clear;clc;
I = imread('Test\lp11.jpg');
figure, imshow(I);
pause(0.5);
%Crop the yellow object in the image
r = I(:,:,1);
g = I(:,:,2);
b = I(:,:,3);
threshold = 100;
y = r > threshold & g > threshold & b < threshold;
figure, imshow(y);

%Obtain the threshold for row and column size
y1 = y;
[m,n] = size(y);
s1=[1,m];
s2=[1,n];
for i=1:m
    s1(i) = sum(y(i,:));
end
p = max(s1);
threshrow = 0.50 * p;
for j=1:n
    s2(j) = sum(y(:,j));
end
q = max(s2);
threshcol = 0.53 * q;

%Mask the image with the obtained threshold
for i=1:m
    s1(i) = sum(y(i,:));
    if s1(i) < threshrow
        y(i,:) = 0;
    end
end

for j=1:n
    s2(j) = sum(y(:,j));
    if s2(j) < threshcol
        y(:,j) = 0;
    end
end

%Fill the ROI from the original image
y=imfill(y,'holes');
figure, imshow(y);

%Determine the co-ordinates for ROI
maxX=0;
maxY=0;
minX=1000;
minY=1000;
for i=1:m
    for j=1:n
        if(y(i,j)==1)
            if(maxY<i)
                maxY=i;
            end
            if(maxX<j)
                maxX=j;
            end
            if(minY>i)
                minY=i;
            end
            if(minX>j)
                minX=j;
            end
        end
    end
end

%Make a rectangular mask
 for i=minX:maxX
    for j=minY:maxY
        y(j,i)=1;        
    end
 end
 
%Get the ROI
I=rgb2gray(I);
y=uint8(y);
roi=I.*y;
figure, imshow(roi);

%Crop the line segmented image
width=maxX-minX;
height=maxY-minY;
new=imcrop(roi,[minX minY width height]);
figure, imshow(new);

%Convert the image to binary
thresh=100;
binaryImage=new>thresh;
binaryImage=not(binaryImage);
imwrite(binaryImage,'temp.jpg');
figure, imshow(binaryImage);

%Filter the small structures out of the image to get the characters
sedisk = strel('disk',10);
noSmallStructures = imopen(binaryImage, sedisk);
figure, imshow(noSmallStructures);

%Clear any unwanted borders
noSmallStructures = imclearborder(noSmallStructures, 4);

%Line segmentation
[qw,ew]=size(noSmallStructures);
startr=0;
endingr=qw;
for row=1:qw
    s1(row) = sum(noSmallStructures(row,:));
    if (s1(row)~=0) && (startr==0)
        startr=row;
    end
    if (s1(row)==0) && (startr>0) && (endingr==qw)
        endingr=row-1;
    end
end


% Crop the image row wise to get just the working set
nheight=(endingr-startr);
N=imcrop(noSmallStructures,[0 startr ew nheight]);
imwrite(N,'liines.jpg');
figure, imshow(N,'initialmagnification','fit');

%Character segmentation
startc=0;
endingc=ew;
totalCharacters=1;
for col=1:ew
    s2(col) = sum(N(:,col));
    if (s2(col)~=0) && (startc==0)
        fins(totalCharacters)=col;
        startc=col;
    end
    if (s2(col)==0) && (startc>0) && (endingc==ew)
        finc(totalCharacters)=col-1;
        totalCharacters=totalCharacters+1;
        startc=0;
        endingc=ew;
    end
end

for ch=1:totalCharacters-1
    chwidth=finc(ch)-fins(ch);
    tempImg=imcrop(N,[fins(ch) 1 chwidth nheight]);
    characterArray{ch}=imresize(tempImg,[42 24]);
end

%Clear all the unwanted variables from the memory
clearvars -except -regexp char*|total;

%Display all the characters obtained
for ch=1:totalCharacters-1
    subplot(4,4,ch);
    imshow(characterArray{ch});
    pause(0.5);
end

%OCR
if exist('templates.mat','file')~=2
    createTemplate();
end
word=[];
global templates
load templates
num_letras=size(templates,2);
for check=1:totalCharacters-1
    letter=read_letter(characterArray{check},num_letras);
    % Letter concatenation
    word=[word letter];
end
fprintf('%s\n',word);