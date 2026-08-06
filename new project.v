module mac(
    input clk,
    input rst,
    input en,
    input [7:0] a,
    input [7:0] b,
    output reg [31:0] out
);

always @(posedge clk or posedge rst)
begin
    if(rst)
        out <= 32'd0;
    else if(en)
        out <= out + (a * b);
end

endmodule

module register_file(
    input clk,
    input rst,

    output reg [7:0] a00,
    output reg [7:0] a01,
    output reg [7:0] a10,
    output reg [7:0] a11,

    output reg [7:0] b00,
    output reg [7:0] b01,
    output reg [7:0] b10,
    output reg [7:0] b11
);

always @(posedge clk or posedge rst)
begin
    if(rst)
    begin
        // Matrix A
        a00 <= 8'd1;
        a01 <= 8'd2;
        a10 <= 8'd3;
        a11 <= 8'd4;

        // Matrix B
        b00 <= 8'd5;
        b01 <= 8'd6;
        b10 <= 8'd7;
        b11 <= 8'd8;
    end
end

endmodule

module fifo(
    input clk,
    input rst,
    input wr_en,
    input rd_en,
    input [7:0] din,
    output reg [7:0] dout
);

reg [7:0] mem[0:3];
reg [1:0] wptr,rptr;

always @(posedge clk or posedge rst)
begin
    if(rst)
    begin
        wptr <= 0;
        rptr <= 0;
        dout <= 0;
    end
    else
    begin
        if(wr_en)
        begin
            mem[wptr] <= din;
            wptr <= wptr + 1;
        end

        if(rd_en)
        begin
            dout <= mem[rptr];
            rptr <= rptr + 1;
        end
    end
end

endmodule

module matrix2x2(
    input clk,
    input rst,
    input start,

    input [7:0] a00,
    input [7:0] a01,
    input [7:0] a10,
    input [7:0] a11,

    input [7:0] b00,
    input [7:0] b01,
    input [7:0] b10,
    input [7:0] b11,

    output reg [31:0] c00,
    output reg [31:0] c01,
    output reg [31:0] c10,
    output reg [31:0] c11
);

always @(posedge clk or posedge rst)
begin
    if (rst)
    begin
        c00 <= 32'd0;
        c01 <= 32'd0;
        c10 <= 32'd0;
        c11 <= 32'd0;
    end
    else if (start)
    begin
        c00 <= (a00 * b00) + (a01 * b10);
        c01 <= (a00 * b01) + (a01 * b11);
        c10 <= (a10 * b00) + (a11 * b10);
        c11 <= (a10 * b01) + (a11 * b11);
    end
end

endmodule

module pe_array(
    input clk,
    input rst,
    input en,

    input [7:0] a00,a01,a10,a11,
    input [7:0] b00,b01,b10,b11,

    output [31:0] c00,
    output [31:0] c01,
    output [31:0] c10,
    output [31:0] c11
);

mac M1(
    .clk(clk),
    .rst(rst),
    .en(en),
    .a(a00),
    .b(b00),
    .out(c00)
);

mac M2(
    .clk(clk),
    .rst(rst),
    .en(en),
    .a(a01),
    .b(b01),
    .out(c01)
);

mac M3(
    .clk(clk),
    .rst(rst),
    .en(en),
    .a(a10),
    .b(b10),
    .out(c10)
);

mac M4(
    .clk(clk),
    .rst(rst),
    .en(en),
    .a(a11),
    .b(b11),
    .out(c11)
);

endmodule

module alu(
    input  [15:0] a,
    input  [15:0] b,
    input  [1:0] sel,
    output reg [15:0] y
);

always @(*) begin
    case(sel)
        2'b00: y = a + b;
        2'b01: y = a - b;
        2'b10: y = a & b;
        2'b11: y = a | b;
    endcase
end

endmodule

module sram(
    input clk,
    input we,
    input [3:0] addr,
    input [15:0] din,
    output reg [15:0] dout
);

reg [15:0] mem[0:15];

always @(posedge clk) begin
    if(we)
        mem[addr] <= din;

    dout <= mem[addr];
end

endmodule

module fsm_controller(
    input clk,
    input rst,
    input start,
    output reg load,
    output reg compute,
    output reg store,
    output reg done
);

parameter IDLE    = 2'b00,
          LOAD    = 2'b01,
          COMPUTE = 2'b10,
          STORE   = 2'b11;

reg [1:0] state;

always @(posedge clk or posedge rst) begin
    if(rst)
        state <= IDLE;
    else begin
        case(state)
            IDLE:    if(start) state <= LOAD;
            LOAD:    state <= COMPUTE;
            COMPUTE: state <= STORE;
            STORE:   state <= IDLE;
        endcase
    end
end

always @(*) begin
    load = 0;
    compute = 0;
    store = 0;
    done = 0;

    case(state)
        LOAD: begin
            load = 1;
        end

        COMPUTE: begin
            compute = 1;
        end

        STORE: begin
            store = 1;
            done = 1;
        end
    endcase
end

endmodule

module top(
    input clk,
    input rst,
    input start
);

wire load;
wire compute;
wire store;
wire done;

fsm_controller fsm(
    .clk(clk),
    .rst(rst),
    .start(start),
    .load(load),
    .compute(compute),
    .store(store),
    .done(done)
);

// Instantiate your existing modules here
// register_file rf(...);
// fifo fifo1(...);
// matrix2x2 mat(...);
// pe_array pe(...);
// alu alu1(...);
// sram mem(...);

endmodule

module top_tb;

reg clk;
reg rst;
reg start;

top uut (
    .clk(clk),
    .rst(rst),
    .start(start)
);

// Clock generation
always #5 clk = ~clk;

// Test sequence
initial begin
    $dumpfile("dump.vcd");
    $dumpvars(0,top_tb);
    clk = 0;
    rst = 1;
    start = 0;

    // Reset
    #20;
    rst = 0;

    // Start operation
    #10;
    start = 1;

    #10;
    start = 0;

    // Wait for computation
    #200;

    $finish;
end

// Monitor signals
initial begin
    $monitor("Time=%0t clk=%b rst=%b start=%b",
              $time, clk, rst, start);
end

endmodule