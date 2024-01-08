/*
 *Copyright (c) SandboxAQ. All rights reserved.
 *SPDX-License-Identifier: Apache-2.0   
*/



module gf251_add_tb(

    );
    
reg clk = 0;
reg start = 0;
reg [7:0] in_1;
reg [7:0] in_2;
wire [7:0] out;
wire done;


gf251_add
DUT
(
    .i_clk(clk),
    .in_1(in_1),
    .in_2(in_2),
    .start(start),
    .out(out),
    .done(done)
);
 
 initial
 begin
     start <= 0;
     in_1 <= 0;
     in_2 <= 0;
     #100
     start <= 1;
     in_1  <= 1;
     in_2  <= 20;
     
     #10 
     start <= 1;
     in_1  <= 234;
     in_2  <= 31;
     
     #10 
     start <= 1;
     in_1  <= 240;
     in_2  <= 85;
     
      #10 
     start <= 1;
     in_1  <= 245;
     in_2  <= 165;
     
     
     #10 
     start <= 0;
 
 end
 
 always #5 clk = ~clk;
 
endmodule
