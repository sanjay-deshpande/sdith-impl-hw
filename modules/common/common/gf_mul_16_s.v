/*
 *Copyright (c) SandboxAQ. All rights reserved.
 *SPDX-License-Identifier: Apache-2.0   
*/


module gf_mul_16_s
#(
    parameter REG_IN = 1,
    parameter REG_OUT = 1
)
(
    input i_clk,
    input i_start,
    input [15:0] i_x,
    input [15:0] i_y,
    output [15:0] o_o,
    output o_done
    );

parameter SDITH_IRRED_CST_GF2P16 = 8'h20;

wire [7:0] xx_0;
wire [7:0] xx_1;
wire [7:0] yy_0;
wire [7:0] yy_1;

wire [7:0] x0y0;
wire [7:0] x1y0;
wire [7:0] x0y1;
wire [7:0] x1y1;

wire done_x0y0;
wire done_x0y1;
wire done_x1y0;
wire done_x1y1;


always@(posedge i_clk) 
begin
  if (i_start) begin
    x_reg = i_x;
    y_reg = i_y;
  end  
end

assign xx_0 = i_x[7:0];
assign xx_1 = i_x[15:8];

assign yy_0 = i_y[7:0];
assign yy_1 = i_y[15:8];

wire sel_in;

// assign sel_in = (done_x0y0)? 1: 0;



gf_mul 
  #(
    .REG_IN(1),
    .REG_OUT(1)
  )
GF_MUL_X0Y0
  (
    .clk(i_clk),
    .start(i_start),
    .in_1(i_start?xx_0: ),
    .in_2(i_start?yy_0: ),
    .out(x0y0),
    .done(done_x0y0)
  );


// wire [7:0] x0y0_reg;
// pipeline_reg_gen #(.WIDTH(8), .REG_STAGES(2))
// XOYO_REG
// (
//     .i_clk(i_clk),
//     .i_data_in(x0y0),
//     .o_data_out(x0y0_reg)
// );

// wire done_x0y0_reg;
// pipeline_reg_gen #(.WIDTH(8), .REG_STAGES(2))
// DONE_XOYO_REG
// (
//     .i_clk(i_clk),
//     .i_data_in(done_x0y0),
//     .o_data_out(done_x0y0_reg)
// );


gf_mul 
  #(
    .REG_IN(1),
    .REG_OUT(1)
  )
GF_MUL_X0Y1
  (
    .clk(i_clk),
    .start(i_start),
    .in_1(xx_0),
    .in_2(yy_1),
    .out(x0y1),
    .done(done_x0y1)
  );

  gf_mul 
  #(
    .REG_IN(1),
    .REG_OUT(1)
  )
GF_MUL_X1Y0
  (
    .clk(i_clk),
    .start(i_start),
    .in_1(xx_1),
    .in_2(yy_0),
    .out(x1y0),
    .done(done_x1y0)
  );

    gf_mul 
  #(
    .REG_IN(1),
    .REG_OUT(1)
  )
GF_MUL_X1Y1
  (
    .clk(i_clk),
    .start(i_start),
    .in_1(xx_1),
    .in_2(yy_1),
    .out(x1y1),
    .done(done_x1y1)
  );

wire [7:0] x1y1_reg;
pipeline_reg_gen #(.WIDTH(8), .REG_STAGES(2))
X1Y1_REG
(
    .i_clk(i_clk),
    .i_data_in(x1y1),
    .o_data_out(x1y1_reg)
);

wire done_x1y1_reg;
pipeline_reg_gen #(.WIDTH(8), .REG_STAGES(2))
DONE_X1Y1_REG
(
    .i_clk(i_clk),
    .i_data_in(done_x1y1),
    .o_data_out(done_x1y1_reg)
);



wire [7:0] x0y1_plus_x1y0;
wire done_x0y1_plus_x1y0;

gf_add 
  #(
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



wire [7:0] x1y1_const;
wire done_x1y1_const;
    gf_mul 
  #(
    .REG_IN(1),
    .REG_OUT(1)
  )
GF_MUL_X1Y1_CONST
  (
    .clk(i_clk),
    .start(done_x1y1),
    .in_1(x1y1),
    .in_2(SDITH_IRRED_CST_GF2P16),
    .out(x1y1_const), //a2
    .done(done_x1y1_const)
  );



// need to add final additions

wire done_a0;
wire [7:0] a0;

gf_add 
  #(
    .REG_IN(1),
    .REG_OUT(1)
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
wire [7:0] a1;

gf_add
  #(
    .REG_IN(1),
    .REG_OUT(1)
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

