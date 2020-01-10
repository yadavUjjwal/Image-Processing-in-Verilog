# Image-Processing-in-Verilog
`include "parameter.v" 						
module image_read
#(parameter width_of_image 	= 768, 					
height_of_image 	= 512, 						
INFILE  = "/home/2018csb1127/Desktop/cs203/kodim23.hex", 
START_UP_DELAY = 100, 				
HSYNC_DELAY = 160,					
increment= 100,								
THRESHOLD= 90,							
SIGN=1	)								
(input HCLK,														
input HRESETn,									
output VSYNC,								
output reg HSYNC,								
output reg [7:0]  D_R0,				
output reg [7:0]  D_G0,				
output reg [7:0]  D_B0,				
output reg [7:0]  D_R1,				
output reg [7:0]  D_G1,				
output reg [7:0]  D_B1,				
output	ctrl_done);		
	
parameter sizeOfWidth = 8;					
parameter sizeOfLengthReal = 1179648; 		
localparam		ST_IDLE 	= 2'b00,		
ST_VSYNC	= 2'b01,			 
ST_HSYNC	= 2'b10,			
ST_DATA		= 2'b11;	
reg [1:0] cstate, 					
nstate;							
reg start;									
reg HRESETn_d;								
reg 		ctrl_vsync_run; 				
reg [8:0]	ctrl_vsync_cnt;			
reg 		ctrl_hsync_run;				
reg [8:0]	ctrl_hsync_cnt;			
reg 		ctrl_data_run;					
reg [31 : 0]  in_memory    [0 : sizeOfLengthReal/4]; 	
reg [7 : 0]   total_memory [0 : sizeOfLengthReal-1];	
integer temp_BMP   [0 : width_of_image*height_of_image*3 - 1];			
integer org_R  [0 : width_of_image*height_of_image - 1]; 	
integer org_G  [0 : width_of_image*height_of_image - 1];	
integer org_B  [0 : width_of_image*height_of_image - 1];	
integer i, j;
integer tempR0,tempR1,tempG0,tempG1,tempB0,tempB1;
integer r,r1,r2,r3,r4,r5,r6,r7,r8,r9,temp_sum,check1,check2,check3,check4;
integer value,value1,value2,value4;
reg [ 9:0] row; 
reg [10:0] col; 
reg [18:0] datacount; 

initial begin
$readmemh(INFILE,total_memory,0,sizeOfLengthReal-1); 
end
always@(start) begin
if(start == 1'b1) begin
for(i=0; i<width_of_image*height_of_image*3 ; i=i+1) begin
temp_BMP[i] = total_memory[i+0][7:0]; 
end
for(i=0; i<height_of_image; i=i+1) begin
for(j=0; j<width_of_image; j=j+1) begin
org_R[width_of_image*i+j] = temp_BMP[width_of_image*3*(height_of_image-i-1)+3*j+0]; 
org_G[width_of_image*i+j] = temp_BMP[width_of_image*3*(height_of_image-i-1)+3*j+1];
org_B[width_of_image*i+j] = temp_BMP[width_of_image*3*(height_of_image-i-1)+3*j+2];
end
end
end
end
always@(posedge HCLK, negedge HRESETn)
begin
if(!HRESETn) begin
start <= 0;
HRESETn_d <= 0;
end
else begin											
if(HRESETn == 1'b1 && HRESETn_d == 1'b0)			
start <= 1'b1;
else
start <= 1'b0;
end
end
always@(posedge HCLK, negedge HRESETn)
begin
if(~HRESETn) begin
cstate <= ST_IDLE;
end
else begin
cstate <= nstate;
end
end
always @(*) begin
case(cstate)
ST_IDLE: begin
if(start)
nstate = ST_VSYNC;
else
nstate = ST_IDLE;
end			
ST_VSYNC: begin
if(ctrl_vsync_cnt == START_UP_DELAY) 
nstate = ST_HSYNC;
else
nstate = ST_VSYNC;
end
ST_HSYNC: begin
if(ctrl_hsync_cnt == HSYNC_DELAY) 
nstate = ST_DATA;
else
nstate = ST_HSYNC;
end		
ST_DATA: begin
if(ctrl_done)
nstate = ST_IDLE;
else begin
if(col == width_of_image - 2)
nstate = ST_HSYNC;
else
nstate = ST_DATA;
end
end
endcase
end
always @(*) begin
ctrl_vsync_run = 0;
ctrl_hsync_run = 0;
ctrl_data_run  = 0;
case(cstate)
ST_VSYNC: 	begin ctrl_vsync_run = 1; end 	
ST_HSYNC: 	begin ctrl_hsync_run = 1; end	
ST_DATA: 	begin ctrl_data_run  = 1; end	
endcase
end
always@(posedge HCLK, negedge HRESETn)
begin
if(~HRESETn) begin
ctrl_vsync_cnt <= 0;
ctrl_hsync_cnt <= 0;
end
else begin
if(ctrl_vsync_run)
ctrl_vsync_cnt <= ctrl_vsync_cnt + 1;
else 
ctrl_vsync_cnt <= 0;

if(ctrl_hsync_run)
ctrl_hsync_cnt <= ctrl_hsync_cnt + 1;			
else
ctrl_hsync_cnt <= 0;
end
end
always@(posedge HCLK, negedge HRESETn)
begin
if(~HRESETn) begin
row <= 0;
col <= 0;
end
else begin
if(ctrl_data_run) begin
if(col == width_of_image - 2) begin
row <= row + 1;
end
if(col == width_of_image - 2) 
col <= 0;
else 
col <= col + 2;
end
end
end
always@(posedge HCLK, negedge HRESETn)
begin
if(~HRESETn) begin
datacount <= 0;
end
else begin
if(ctrl_data_run)
datacount <= datacount + 1;
end
end
assign VSYNC = ctrl_vsync_run;
assign ctrl_done = (datacount == 196607)? 1'b1: 1'b0; 
always @(*) begin

HSYNC   = 1'b0;
D_R0 = 0;
D_G0 = 0;
D_B0 = 0;                                       
D_R1 = 0;
D_G1 = 0;
D_B1 = 0;                                         
if(ctrl_data_run) begin

HSYNC   = 1'b1;
`ifdef BRIGHTNESS_OPERATION	
if(SIGN == 1) begin
tempR0=org_R[width_of_image*row+col]+increment;
if(tempR0>255)
D_R0=255;
else
D_R0=org_R[width_of_image*row+col]+increment;
tempR1=org_R[width_of_image*row+col+1]+increment;
if(tempR1>255)
D_R1=255;
else
D_R1=org_R[width_of_image*row+col+1]+increment;	
tempG0=org_G[width_of_image*row+col]+increment;
if(tempG0>255)
D_G0=255;
else
D_G0=org_G[width_of_image*row+col]+increment;
tempG1=org_G[width_of_image*row+col+1]+increment;
if(tempG1>255)
D_G1=255;
else
D_G1=org_G[width_of_image*row+col+1]+increment;		
tempB0=org_B[width_of_image*row+col]+increment;
if(tempB0>255)
D_B0=255;
else
D_B0=org_B[width_of_image*row+col]+increment;
tempB1=org_B[width_of_image*row+col+1]+increment;
if(tempB1>255)
D_B1=255;
else
D_B1=org_B[width_of_image*row+col+1]+increment;
end
else begin
tempR0=org_R[width_of_image*row+col]-increment;
if(tempR0<0)
D_R0=0;
else
D_R0=org_R[width_of_image*row+col]-increment;
tempR1=org_R[width_of_image*row+col+1]-increment;
if(tempR1<0)
D_R1=0;
else
D_R1=org_R[width_of_image*row+col+1]-increment;	
tempG0=org_G[width_of_image*row+col]-increment;
if(tempG0<0)
D_G0=0;
else
D_G0=org_G[width_of_image*row+col]-increment;
tempG1=org_G[width_of_image*row+col+1]-increment;
if(tempG1<0)
D_G1=0;
else
D_G1=org_G[width_of_image*row+col+1]-increment;		
tempB0=org_B[width_of_image*row+col]-increment;
if(tempB0<0)
D_B0=0;
else
D_B0=org_B[width_of_image*row+col]-increment;
tempB1=org_B[width_of_image*row+col+1]-increment;
if(tempB1<0)
D_B1=0;
else
D_B1=org_B[width_of_image*row+col+1]-increment;
end
`endif


`ifdef SMOOTHING_OPERATION
r=width_of_image*row + col;
if(r%width_of_image==0)
check1=1;
else
check1=0;
if((r+1)%width_of_image==0)
check2=1;
else
check2=0;
if(r>=0 && r<=width_of_image-1)
check3=1;
else
check3=0;
if((height_of_image*width_of_image-r)>=1 && (height_of_image*width_of_image-r)<=width_of_image)
check4=1;
else
check4=0;
if(check1==0 &&check2==0 &&check3==0 &&check4==0)begin
r1=org_R[r-width_of_image-1];
r2=org_R[r-width_of_image];
r3=org_R[r-width_of_image+1];
r4=org_R[r-1];
r5=org_R[r];
r6=org_R[r+1];
r7=org_R[r+width_of_image-1];
r8=org_R[r+width_of_image];
r9=org_R[r+width_of_image+1];
end
temp_sum=(r1+r2+r3+r4+r5+r6+r7+r8+r9)/9;
D_R0=temp_sum;
r=width_of_image*row + col;
if(check1==0 &&check2==0 &&check3==0 &&check4==0)begin
r1=org_G[r-width_of_image-1];
r2=org_G[r-width_of_image];
r3=org_G[r-width_of_image+1];
r4=org_G[r-1];
r5=org_G[r];
r6=org_G[r+1];
r7=org_G[r+width_of_image-1];
r8=org_G[r+width_of_image];
r9=org_G[r+width_of_image+1];
end
temp_sum=(r1+r2+r3+r4+r5+r6+r7+r8+r9)/9;
D_G0=temp_sum;
r=width_of_image*row + col;
if(check1==0 &&check2==0 &&check3==0 &&check4==0)begin
r1=org_B[r-width_of_image-1];
r2=org_B[r-width_of_image];
r3=org_B[r-width_of_image+1];
r4=org_B[r-1];
r5=org_B[r];
r6=org_B[r+1];
r7=org_B[r+width_of_image-1];
r8=org_B[r+width_of_image];
r9=org_B[r+width_of_image+1];
end
temp_sum=(r1+r2+r3+r4+r5+r6+r7+r8+r9)/9;
D_B0=temp_sum;

r=width_of_image*row + col+1;
if(r%width_of_image==0)
check1=1;
else
check1=0;
if((r+1)%width_of_image==0)
check2=1;
else
check2=0;
if(r>=0 && r<=width_of_image-1)
check3=1;
else
check3=0;
if((height_of_image*width_of_image-r)>=1 && (height_of_image*width_of_image-r)<=width_of_image)
check4=1;
else
check4=0;
if(check1==0 &&check2==0 &&check3==0 &&check4==0)begin
r1=org_R[r-width_of_image-1];
r2=org_R[r-width_of_image];
r3=org_R[r-width_of_image+1];
r4=org_R[r-1];
r5=org_R[r];
r6=org_R[r+1];
r7=org_R[r+width_of_image-1];
r8=org_R[r+width_of_image];
r9=org_R[r+width_of_image+1];
end
temp_sum=(r1+r2+r3+r4+r5+r6+r7+r8+r9)/9;
D_R1=temp_sum;
r=width_of_image*row + col+1;
if(check1==0 &&check2==0 &&check3==0 &&check4==0)begin
r1=org_G[r-width_of_image-1];
r2=org_G[r-width_of_image];
r3=org_G[r-width_of_image+1];
r4=org_G[r-1];
r5=org_G[r];
r6=org_G[r+1];
r7=org_G[r+width_of_image-1];
r8=org_G[r+width_of_image];
r9=org_G[r+width_of_image+1];
end
temp_sum=(r1+r2+r3+r4+r5+r6+r7+r8+r9)/9;
D_G1=temp_sum;
r=width_of_image*row + col+1;
if(check1==0 &&check2==0 &&check3==0 &&check4==0)begin
r1=org_B[r-width_of_image-1];
r2=org_B[r-width_of_image];
r3=org_B[r-width_of_image+1];
r4=org_B[r-1];
r5=org_B[r];
r6=org_B[r+1];
r7=org_B[r+width_of_image-1];
r8=org_B[r+width_of_image];
r9=org_B[r+width_of_image+1];
end
temp_sum=(r1+r2+r3+r4+r5+r6+r7+r8+r9)/9;
D_B1=temp_sum;

`endif

`ifdef INVERT_OPERATION	
value2=(org_B[width_of_image*row+col]+org_R[width_of_image*row+col]+org_G[width_of_image* row+col])/3;
D_R0=255-value2;
D_G0=255-value2;
D_B0=255-value2;
value4 = (org_B[width_of_image*row+col+1]+org_R[width_of_image*row+col+1]+org_G[width_of_image*row+col+1])/3;
D_R1=255-value4;
D_G1=255-value4;
D_B1=255-value4;		
`endif
end
end

endmodule


