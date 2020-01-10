module image_write
#(parameter width_of_image 	= 768,							
height_of_image = 512,							
INFILE  = "/home/2018csb1127/Desktop/cs203/output.bmp",						
BMP_HEADER_NUM = 54)
(input HCLK,												
input HRESETn,											
input hsync,														
input [7:0]pixel_final_R0,					
input [7:0]pixel_final_G0,			
input [7:0]pixel_final_B0,			
input [7:0]pixel_final_R1,			
input [7:0]pixel_final_G1,			
input [7:0]pixel_final_B1,			
output 	reg	 Write_Done);	
integer BMP_header[0 : BMP_HEADER_NUM - 1];	
reg [7:0]final_bmp[0 : width_of_image*height_of_image*3 - 1];	
reg [18:0] datacount;					
wire done;													
integer i;
integer k, l, m;
integer fd; 
initial begin
BMP_header[0] = 66;BMP_header[28] =24;
BMP_header[1] = 77;BMP_header[29] = 0;
BMP_header[2] = 54;BMP_header[30] = 0;
BMP_header[3] =  0;BMP_header[31] = 0;
BMP_header[4] = 18;BMP_header[32] = 0;
BMP_header[5] =  0;BMP_header[33] = 0;
BMP_header[6] =  0;BMP_header[34] = 0;
BMP_header[7] =  0;BMP_header[35] = 0;
BMP_header[8] =  0;BMP_header[36] = 0;
BMP_header[9] =  0;BMP_header[37] = 0;
BMP_header[10] = 54;BMP_header[38] = 0;
BMP_header[11] =  0;BMP_header[39] = 0;
BMP_header[12] =  0;BMP_header[40] = 0;
BMP_header[13] =  0;BMP_header[41] = 0;
BMP_header[14] = 40;BMP_header[42] = 0;
BMP_header[15] =  0;BMP_header[43] = 0;
BMP_header[16] =  0;BMP_header[44] = 0;
BMP_header[17] =  0;BMP_header[45] = 0;
BMP_header[18] =  0;BMP_header[46] = 0;
BMP_header[19] =  3;BMP_header[47] = 0;
BMP_header[20] =  0;BMP_header[48] = 0;
BMP_header[21] =  0;BMP_header[49] = 0;
BMP_header[22] =  0;BMP_header[50] = 0;
BMP_header[23] =  2;BMP_header[51] = 0;	
BMP_header[24] =  0;BMP_header[52] = 0;
BMP_header[25] =  0;BMP_header[53] = 0;
BMP_header[26] =  1;
BMP_header[27] =  0;
end
always@(posedge HCLK, negedge HRESETn) begin
if(!HRESETn) begin
l <= 0;
m <= 0;
end else begin
if(hsync) begin
if(m == width_of_image/2-1) begin
m <= 0;
l <= l + 1; 
end else begin
m <= m + 1;
end
end
end
end
always@(posedge HCLK, negedge HRESETn) begin
if(!HRESETn) begin
for(k=0;k<width_of_image*height_of_image*3;k=k+1) begin
final_bmp[k] <= 0;
end
end else begin
if(hsync) begin
final_bmp[width_of_image*3*(height_of_image-l-1)+6*m+2] <= pixel_final_R0;
final_bmp[width_of_image*3*(height_of_image-l-1)+6*m+1] <= pixel_final_G0;
final_bmp[width_of_image*3*(height_of_image-l-1)+6*m  ] <= pixel_final_B0;
final_bmp[width_of_image*3*(height_of_image-l-1)+6*m+5] <= pixel_final_R1;
final_bmp[width_of_image*3*(height_of_image-l-1)+6*m+4] <= pixel_final_G1;
final_bmp[width_of_image*3*(height_of_image-l-1)+6*m+3] <= pixel_final_B1;
end
end
end
always@(posedge HCLK, negedge HRESETn)
begin
if(~HRESETn) begin
datacount <= 0;
end
else begin
if(hsync)
datacount <= datacount + 1;
end
end
assign done = (datacount ==196607)? 1'b1: 1'b0; 
always@(posedge HCLK, negedge HRESETn)
begin
if(~HRESETn) begin
Write_Done<=0;
end
else begin
Write_Done<=done;
end 
end 
initial begin
fd=$fopen(INFILE,"wb+");
end
always@(Write_Done) begin 
if(Write_Done == 1'b1) begin
for(i=0;i<BMP_HEADER_NUM;i=i+1) begin
$fwrite(fd, "%c", BMP_header[i][7:0]); 
end
for(i=0; i<width_of_image*height_of_image*3; i=i+6) begin
$fwrite(fd,"%c",final_bmp[i][7:0]);
$fwrite(fd,"%c",final_bmp[i+1][7:0]);
$fwrite(fd,"%c",final_bmp[i+2][7:0]);
$fwrite(fd,"%c",final_bmp[i+3][7:0]);
$fwrite(fd,"%c",final_bmp[i+4][7:0]);
$fwrite(fd,"%c",final_bmp[i+5][7:0]);
end
end
end
endmodule
