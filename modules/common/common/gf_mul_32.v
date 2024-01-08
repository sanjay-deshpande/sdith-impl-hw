/*
 *Copyright (c) SandboxAQ. All rights reserved.
 *SPDX-License-Identifier: Apache-2.0   
*/


module gf_mul_32
#(
    parameter REG_IN = 1,
    parameter REG_OUT = 1
)
(
    input i_clk,
    input i_start,
    input [31:0] i_x,
    input [31:0] i_y,
    output [31:0] o_o,
    output o_done
    );

parameter SDITH_IRRED_CST_GF2P32 = 32'h2000; 

wire [15:0] xx_0;
wire [15:0] xx_1;
wire [15:0] yy_0;
wire [15:0] yy_1;

wire [15:0] x0y0;
wire [15:0] x1y0;
wire [15:0] x0y1;
wire [15:0] x1y1;

wire done_x0y0;
wire done_x0y1;
wire done_x1y0;
wire done_x1y1;

assign xx_0 = i_x[15:0];
assign xx_1 = i_x[31:16];

assign yy_0 = i_y[15:0];
assign yy_1 = i_y[31:16];

gf_mul_16 
GF_MUL_X0Y0
  (
    .i_clk(i_clk),
    .i_start(i_start),
    .i_x(xx_0),
    .i_y(yy_0),
    .o_o(x0y0),
    .o_done(done_x0y0)
  );

wire [15:0] x0y0_reg;
pipeline_reg_gen #(.WIDTH(16), .REG_STAGES(2)) // update reg stages number accordingly
XOYO_REG
(
    .i_clk(i_clk),
    .i_data_in(x0y0),
    .o_data_out(x0y0_reg)
);

wire done_x0y0_reg;
pipeline_reg_gen #(.WIDTH(8), .REG_STAGES(2))
DONE_XOYO_REG
(
    .i_clk(i_clk),
    .i_data_in(done_x0y0),
    .o_data_out(done_x0y0_reg)
);


gf_mul_16 
GF_MUL_X0Y1
  (
    .i_clk(i_clk),
    .i_start(i_start),
    .i_x(xx_0),
    .i_y(yy_1),
    .o_o(x0y1),
    .o_done(done_x0y1)
  );

gf_mul_16 
GF_MUL_X1Y0
  (
    .i_clk(i_clk),
    .i_start(i_start),
    .i_x(xx_1),
    .i_y(yy_0),
    .o_o(x1y0),
    .o_done(done_x1y0)
  );

gf_mul_16 
GF_MUL_X1Y1
  (
    .i_clk(i_clk),
    .i_start(i_start),
    .i_x(xx_1),
    .i_y(yy_1),
    .o_o(x1y1),
    .o_done(done_x1y1)
  );

wire [15:0] x1y1_reg;
pipeline_reg_gen #(.WIDTH(16), .REG_STAGES(2))
X1Y1_REG
(
    .i_clk(i_clk),
    .i_data_in(x1y1),
    .o_data_out(x1y1_reg)
);

wire done_x1y1_reg;
pipeline_reg_gen #(.WIDTH(16), .REG_STAGES(2))
DONE_X1Y1_REG
(
    .i_clk(i_clk),
    .i_data_in(done_x1y1),
    .o_data_out(done_x1y1_reg)
);



wire [15:0] x0y1_plus_x1y0;
wire done_x0y1_plus_x1y0;

gf_add 
  #(
    .WIDTH(16),
    .REG_IN(1),
    .REG_OUT(1)
  )
GF_X0Y1_ADD_X1Y0 
(
    .i_clk(i_clk), 
    .i_start(done_x0y1), 
    .in_1(x0y1), 
    .in_2(x1y0),
    .o_done(done_x0y1_plus_x1y0), 
    .out(x0y1_plus_x1y0) 
);



wire [15:0] x1y1_const;
wire done_x1y1_const;
    gf_mul_16 
GF_MUL_X1Y1_CONST
  (
    .i_clk(i_clk),
    .i_start(done_x1y1),
    .i_x(x1y1),
    .i_y(SDITH_IRRED_CST_GF2P32),
    .o_o(x1y1_const), //a2
    .o_done(done_x1y1_const)
  );



// need to add final additions

wire done_a0;
wire [15:0] a0;

gf_add 
  #(
    .WIDTH(16),
    .REG_IN(0),
    .REG_OUT(0)
  )
GF_ADD_A0 
(
    .i_clk(i_clk), 
    .i_start(done_x1y1_const), 
    .in_1(x1y1_const), 
    .in_2(x0y0_reg),
    .o_done(done_a0), 
    .out(a0) 
);


wire done_a1;
wire [15:0] a1;

gf_add
  #(
    .WIDTH(16),
    .REG_IN(0),
    .REG_OUT(0)
  ) 
GF_ADD_A1 
(
    .i_clk(i_clk), 
    .i_start(done_x0y1_plus_x1y0), 
    .in_1(x0y1_plus_x1y0), 
    .in_2(x1y1_reg),
    .o_done(done_a1), 
    .out(a1) 
);

assign o_o = {a1,a0};
assign o_done = done_a0 & done_a1;



endmodule

