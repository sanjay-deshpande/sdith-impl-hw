/*
 *Copyright (c) SandboxAQ. All rights reserved.
 *SPDX-License-Identifier: Apache-2.0   
*/


module gf251_mul_red
#(
//    parameter REG_IN = 1,
//    parameter REG_OUT = 1
)
(
    input i_clk, // for potential regs we may add later
    input i_start,
    input [15:0] i_a,
    output [7:0] o_c,
    output o_done
    );
  
reg [15:0] a_reg, a_reg_reg, a_reg_reg_reg, a_reg_reg_reg_reg;  
wire [15+8:0] a_mul_256;
wire [15+2:0] a_mul_4;
wire [15+1:0] a_mul_2;

wire [15+8+2:0] a_mul_262;

reg [9:0] a_s16;
wire [9+8:0] a_s16_mul_256;
wire [9+2:0] a_s16_mul_4;

reg [9+8:0] a_s16_mul_251;

wire [8:0] c_temp;

reg done[3:0];
always@(posedge i_clk) 
begin
    if (i_start) begin
         a_reg <= i_a;
    end
    done[0] <= i_start;
end

//assign a_reg = i_a;

assign a_mul_256 = {a_reg,8'h00};
assign a_mul_4 = {a_reg,2'b00};
assign a_mul_2 = {a_reg,1'b0};

//=====================

assign a_mul_262 = a_mul_256 + a_mul_4 + a_mul_2;

//assign a_s16 = a_mul_262[15+8+2:16];
//assign a_s16_mul_256 = {a_s16,8'h00};
//assign a_s16_mul_4 = {a_s16,2'b00};

always@(posedge i_clk) 
begin
    a_s16 <= a_mul_262[15+8+2:16];

    a_reg_reg <= a_reg;
    done[1] <= done[0];  
end
//===================

assign a_s16_mul_256 = {a_s16,8'h00};
assign a_s16_mul_4 = {a_s16,2'b00};
//assign a_s16_mul_251 = a_s16_mul_256 - a_s16_mul_4 - a_s16;

always@(posedge i_clk) 
begin
    a_s16_mul_251 <= a_s16_mul_256 - a_s16_mul_4 - a_s16;
    a_reg_reg_reg <= a_reg_reg;
     done[2] <= done[1];
     done[3] <= done[2];
     a_reg_reg_reg_reg <= a_reg_reg_reg;
end


assign c_temp = a_reg_reg_reg - a_s16_mul_251;


assign o_c = (c_temp[8] == 1)? c_temp + 251 : c_temp;

assign o_done = done[2];
 
endmodule

