
I = imread('colorbar.jpg');
A = rgb2gray(I);
K=A;
H=A;%H用来放RGB
j=0;
[height,width,depth] = size(A);%height=480;width=640;

fid=fopen('colorbar.coe','wt');
fprintf(fid,'memory_initialization_radix=10;\n');
fprintf(fid,'memory_initialization_vector=\n');
 for h = 1:height
    for w = 1:width   
                H(h,w)=A(h,w);         
            fprintf(fid,'%d,\n ',H(h,w));
    end
 end
 fclose(fid);
 figure;
 imshow(K);
 title('变化后的图');
 figure;
 imshow(H);
