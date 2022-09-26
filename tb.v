`timescale 1ps/1ps
module tb (
);

reg clk;
reg rst;
reg [29:0] addr;
reg [31:0] wdata;
reg [31:0] mem_data;
reg wr;
reg rd;

reg mem_read_fin;

wire [29:0] mem_addr;
wire cache_r_hit;
wire [31:0] cache_wb_data;
wire [31:0] cache_data;

integer i;

initial begin
    clk = 0;
end

always @(*) begin
    forever begin 
        #5;clk = !clk;
    end
end

initial begin
    mem_data <= 32'h12345678;
end

initial begin
    $dumpfile("tb.vcd"); 
    $dumpvars;
    $dumpvars(0,tb.u_cache_control.u_cache.ram_1[1]);
    $dumpvars(0,tb.u_cache_control.u_cache.ram_2[1]);
    $dumpvars(0,tb.u_cache_control.u_cache.ram_3[1]);
    $dumpvars(0,tb.u_cache_control.u_cache.ram_4[1]);
    $dumpvars(0,tb.u_cache_control.u_cache.ram_1[0]);
    $dumpvars(0,tb.u_cache_control.u_cache.ram_2[0]);
    $dumpvars(0,tb.u_cache_control.u_cache.ram_3[0]);
    $dumpvars(0,tb.u_cache_control.u_cache.ram_4[0]);
    rst = 1;
    #15;rst=0;
    mem_read_fin = 0;
    rd = 1;
    wr = 0;
    addr = 30'd0;
    wdata = 32'h87654321;
    #40;mem_read_fin = 1;
    #105;wr=0;rd=1;addr = 30'd1;
    #305;addr = 30'd1024;
    #400;$finish;
end

cache_control u_cache_control(
    .clk(clk),
    .rst(rst),
    .addr(addr),
    .wdata(wdata),
    .mem_data(mem_data),
    .wr(wr),
    .rd(rd),
    //.mem_addr(mem_addr),
    .cache_r_hit(cache_r_hit),
    .cache_wb_data(cache_wb_data),
    .cache_data(cache_data),
    .mem_read_fin(mem_read_fin)
);

endmodule