/*
 * This file is testbench for KeyGen module.
 *
 * Copyright (C) 2023
 * Authors: Sanjay Deshpande <sanjay.deshpande@sandboxquantum.com>
 *          
*/


module commit_tb
#(
   parameter FIELD = "GF256",
//     parameter FIELD = "P251",
    parameter WIDTH = 32,
    parameter PARAMETER_SET = "L1",
    
    parameter LAMBDA =   (PARAMETER_SET == "L1")? 128:
                            (PARAMETER_SET == "L3")? 192:
                            (PARAMETER_SET == "L5")? 256:
                                                     128,
                                                    
    parameter M =  (PARAMETER_SET == "L1")? 230:
                        (PARAMETER_SET == "L3")? 352:
                        (PARAMETER_SET == "L5")? 480:
                                                 230,

    parameter WEIGHT =  (PARAMETER_SET == "L1")? 79:
                        (PARAMETER_SET == "L3")? 120:
                        (PARAMETER_SET == "L5")? 150:
                                                 79,

    parameter D_SPLIT = (PARAMETER_SET == "L1")? 1:
                        (PARAMETER_SET == "L3")? 2:
                        (PARAMETER_SET == "L5")? 2:
                                                 1,
    //  k + 2w + t(2d + 1)η

    parameter  K =  (PARAMETER_SET == "L1")? 126:
                    (PARAMETER_SET == "L3")? 193:
                    (PARAMETER_SET == "L5")? 278:
                                               1,
    
    parameter ETA = 4,

    parameter T =   (PARAMETER_SET == "L5")? 4:
                                             3, 
    
    parameter D_HYPERCUBE = 8,

    parameter SEED_SIZE = LAMBDA,
    
    parameter NUMBER_OF_SEED_BITS = (2**D_HYPERCUBE) * SEED_SIZE,
    
    parameter SALT_SIZE = 2*LAMBDA,

    parameter HASH_INPUT_SIZE = LAMBDA + 2*LAMBDA,
    
    // parameter HASH_OUTPUT_SIZE = 8*(K + 2*WEIGHT + T*(2*D_SPLIT + 1)*ETA)
    parameter HASH_OUTPUT_SIZE = 8*(K + 2*D_SPLIT*WEIGHT + T*D_SPLIT*3),
    
    parameter SK_SIZE = 8*(K + 2*D_SPLIT*WEIGHT),
    parameter SK_SIZE_ADJ = SK_SIZE + (WIDTH - SK_SIZE%WIDTH)%WIDTH,
    
    parameter COMMIT_INPUT_SIZE = SALT_SIZE + SEED_SIZE + 32,
    parameter COMMIT_INPUT_SIZE_LAST = SALT_SIZE + SEED_SIZE + HASH_OUTPUT_SIZE + 32,
    parameter COMMIT_OUTPUT_SIZE = LAMBDA,
    parameter COMMIT_RAM_DEPTH = (COMMIT_OUTPUT_SIZE*(2**D_HYPERCUBE))/32
    
)(

);

reg                                 i_clk = 0;
reg                                 i_rst;
reg                                 i_start;

reg   [32-1:0]                          i_seed_root;
reg  [`CLOG2(HASH_INPUT_SIZE/32)-1:0]   i_seed_root_addr;
reg                                     i_seed_root_wr_en;

wire   [32-1:0]                             i_seed_e;
wire  [`CLOG2(NUMBER_OF_SEED_BITS/32)-1:0]  o_seed_e_addr;
wire                                        o_seed_e_rd;

// wire   [32-1:0]                             i_salt;
reg   [32-1:0]                             i_salt;

reg  [`CLOG2(SALT_SIZE/32)-1:0]            i_salt_addr;
reg                                        i_salt_wr_en;

wire   [32-1:0]                             i_sk;
wire  [`CLOG2(SK_SIZE/WIDTH)-1:0]           o_sk_addr;
wire                                        o_sk_rd_en;

wire  [`CLOG2(SALT_SIZE/32)-1:0]            o_salt_addr;
wire                                        o_salt_rd;

wire                                o_done;

wire [32-1:0]                       o_hash_data_in;
wire [`CLOG2(COMMIT_INPUT_SIZE_LAST/32) -1:0]       i_hash_addr;
wire                                i_hash_rd_en;
wire [32-1:0]                       i_hash_data_out;
wire                                i_hash_data_out_valid;
wire                                o_hash_data_out_ready;
wire  [32-1:0]                      o_hash_input_length; // in bits
wire  [32-1:0]                      o_hash_output_length; // in bits
wire                                o_hash_start;
wire                                i_hash_done;
wire                                i_hash_force_done_ack;
wire                                o_force_done_ack;

commit #(.FIELD(FIELD), .PARAMETER_SET(PARAMETER_SET), .FILE_SK("SK_POLY_L1.MEM"))
// commit #(.FIELD(FIELD), .PARAMETER_SET(PARAMETER_SET), .FILE_SK("ZERO.MEM"))
DUT 
(
.i_clk(i_clk),
.i_rst(i_rst),
.i_start(i_start),

.i_seed_root(i_seed_root),
.i_seed_root_addr(i_seed_root_addr),
.i_seed_root_wr_en(i_seed_root_wr_en),

.i_e(1),

// .i_seed_e(i_seed_e),
// .o_seed_e_addr(o_seed_e_addr),
// .o_seed_e_rd(o_seed_e_rd),

.i_salt(i_salt),
.i_salt_addr(i_salt_addr),
.i_salt_wr_en(i_salt_wr_en),
//.o_salt_addr(o_salt_addr),
//.o_salt_rd(o_salt_rd),

.o_done          (o_done       ),

.o_sk_rd_en (),
.o_sk_addr (),
.i_sk (0),

.i_acc_rd (0),
.i_acc_addr (0),
.o_acc (),

.i_commit_rd (0),
.i_commit_addr (0),
.o_commit (),

.i_input_mshare_sel (0),
.i_input_mshare_rd (0),
.i_input_mshare_addr (0),
.o_input_mshare (),

.o_hash_data_in          (o_hash_data_in       ),   
.i_hash_addr             (i_hash_addr          ),   
.i_hash_rd_en            (i_hash_rd_en         ),   
.i_hash_data_out         (i_hash_data_out      ),   
.i_hash_data_out_valid   (i_hash_data_out_valid),   
.o_hash_data_out_ready   (o_hash_data_out_ready),   
.o_hash_input_length     (o_hash_input_length  ),   
.o_hash_output_length    (o_hash_output_length ),   
.o_hash_start            (o_hash_start         ),   
.i_hash_force_done_ack   (i_hash_force_done_ack),   
.o_hash_force_done       (o_hash_force_done    )

);


hash_mem_interface #(.IO_WIDTH(32), .MAX_RAM_DEPTH(COMMIT_INPUT_SIZE_LAST/32), .PARAMETER_SET(PARAMETER_SET))
  HASH_INTERFACE
   (
    .clk                (i_clk                   ),
    .rst                (i_rst                   ),
    .i_data_in          (o_hash_data_in          ),
    .o_addr             (i_hash_addr             ),            
    .o_rd_en            (i_hash_rd_en            ),
    .o_data_out         (i_hash_data_out         ),
    .o_data_out_valid   (i_hash_data_out_valid   ),
    .i_data_out_ready   (o_hash_data_out_ready   ), 
    .i_input_length     (o_hash_input_length     ),
    .i_output_length    (o_hash_output_length    ),                 
    .i_start            (o_hash_start            ),
    .o_force_done_ack   (i_hash_force_done_ack   ),
    .i_force_done       (o_hash_force_done       ) 
    
    );

integer start_time, end_time;
integer mult_start_time;
integer gen_h_start_time;
initial 
begin
    i_rst <= 1;
    i_start <= 0;

    #100

    i_rst <= 0;

   i_seed_root <= 0;
   i_seed_root <= 0;i_seed_root_wr_en <= 1;
   i_seed_root <= 0;i_seed_root_addr <= 0; #10  
   i_seed_root <= 0;i_seed_root_addr <= 1; #10  
   i_seed_root <= 0;i_seed_root_addr <= 2; #10  
   i_seed_root <= 0;i_seed_root_addr <= 3; #10
   i_seed_root_wr_en <= 0;

   i_salt <= 0;
   i_salt <= 0;i_salt_wr_en <= 1;
   i_salt <= 0;i_salt_addr <= 0; #10  
   i_salt <= 0;i_salt_addr <= 1; #10  
   i_salt <= 0;i_salt_addr <= 2; #10  
   i_salt <= 0;i_salt_addr <= 3; #10
   i_salt <= 0;i_salt_addr <= 4; #10
   i_salt <= 0;i_salt_addr <= 5; #10
   i_salt <= 0;i_salt_addr <= 6; #10
   i_salt <= 0;i_salt_addr <= 7; #10
   i_salt_wr_en <= 0;

//    i_seed_root <= 0;i_seed_root_addr <= 4; #10  
//    i_seed_root <= 0;i_seed_root_addr <= 5; #10  
//    i_seed_root <= 0;i_seed_root_addr <= 6; #10  
//    i_seed_root <= 0;i_seed_root_addr <= 7; #10
//    i_seed_root <= 0;i_seed_root_addr <= 8; #10  
//    i_seed_root <= 0;i_seed_root_addr <= 9; #10  
//    i_seed_root <= 0;i_seed_root_addr <= 10; #10  
//    i_seed_root <= 0;i_seed_root_addr <= 11; #10
    
    // if (PARAMETER_SET == "L3") begin
    //     i_seed_root <= 0;i_seed_root_addr <= 4; #10  
    //     i_seed_root <= 0;i_seed_root_addr <= 5; #10;
    // end
   
    // if (PARAMETER_SET == "L5") begin
    //     i_seed_root <= 0;i_seed_root_addr <= 4; #10  
    //     i_seed_root <= 0;i_seed_root_addr <= 5; #10  
    //     i_seed_root <= 0;i_seed_root_addr <= 6; #10  
    //     i_seed_root <= 0;i_seed_root_addr <= 7; #10; 
    // end
    
   i_seed_root_wr_en <= 0;
    
    #10
    i_start <= 1;
    start_time = $time;
    #10
    i_start <= 0;

    #100
    
    @(posedge o_done)
    end_time = $time;

    $display("Time taken for Commit =", (end_time-start_time-5)/10 );
    
    
    #100
    $finish;

end

//  always
//  begin
//      @(posedge o_done)
//     //  $writememb("HSA_L1.mem", DUT.MAT_VEC_MUL.RESULT_MEM.mem);
//  end

//  mem_single #(.WIDTH(32), .DEPTH(SALT_SIZE/32), .INIT(1)) 
//  SALT_MEM
//  (
//  .clock(i_clk),
//  .data(0),
//  .address(o_salt_rd? o_salt_addr: 0),
//  .wr_en(0),
//  .q(i_salt)
//  );


mem_single #(.WIDTH(32), .DEPTH(NUMBER_OF_SEED_BITS/32), .INIT(1)) 
 SEED_MEM
 (
 .clock(i_clk),
 .data(0),
 .address(o_seed_e_rd? o_seed_e_addr: 0),
 .wr_en(0),
 .q(i_seed_e)
 );

always #5 i_clk = ! i_clk;

 

endmodule