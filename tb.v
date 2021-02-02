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

wire [29:0] mem_addr;
wire cache_r_hit;
wire [31:0] cache_wb_data;
wire [31:0] cache_data;

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
    rst = 1;
    #15;rst=0;
    rd = 0;
    wr = 1;
    addr = 30'd0;
    wdata = 32'h87654321;
    #105;wr=0;rd=1;addr = 30'd1;
    #305;addr = 30'd1024;
end

cache_control u_cache_control(
    .clk(clk),
    .rst(rst),
    .addr(addr),
    .wdata(wdata),
    .mem_data(mem_data),
    .wr(wr),
    .rd(rd),
    .mem_addr(mem_addr),
    .cache_r_hit(cache_r_hit),
    .cache_wb_data(cache_wb_data),
    .cache_data(cache_data)
);

endmodule