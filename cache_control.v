/*
采用状态机
空闲
比对     如果Hit 则转为空闲，如果miss，且dirty为1，转到写回，否则转到替换
写回     完成后转到替换
替换     完成后返回比对
*/
module cache_control (
    input clk,
    input rst,
    input [29:0] addr,
    input [31:0] wdata,
    input [31:0] mem_data,
    input wr,
    input rd,
    output reg [29:0] mem_addr,
    output wire cache_r_hit,
    output wire [31:0] cache_wb_data,
    output reg [31:0] cache_data
);

wire dirty_bit;

reg substitude;
reg cache_wr;
reg cache_rd;
reg [31:0] substitude_data;

wire w_hit;
wire w_miss;
wire r_hit;
wire r_miss;
wire [31:0] wb_data;
wire [31:0] data;

reg [1:0] cur_state;
reg [1:0] next_state;

localparam s0 = 2'b00;
localparam s1 = 2'b01;
localparam s2 = 2'b10;
localparam s3 = 2'b11;

always @(posedge clk or posedge rst) begin
    if (rst) begin 
        cur_state <= s0;
    end
    else begin 
        cur_state <= next_state;
    end
end
    
always @(*) begin
    if (rst) begin 
        next_state <= s0;
    end
    else begin 
        case (cur_state)
            s0:begin
                if (wr || rd) next_state <= s1;
                else next_state <= s0;
            end 
            s1:begin
                if ((w_miss || r_miss) && dirty_bit) next_state <= s2;
                else if (w_miss || r_miss) next_state <= s3;
                else if (wr || rd) next_state <= s1;
                else next_state <= s0;
            end
            s2:begin 
                next_state <= s3;
            end
            s3:begin 
                next_state <= s1;
            end
            default: next_state <= s0;
        endcase
    end
end

always @(posedge clk or posedge rst) begin
    if (rst) begin 
        substitude <= 1'b0;
        cache_data <= 32'b0;
        cache_wr <= 1'b0;
        cache_rd <= 1'b0;
    end
    else begin 
        case (next_state)
            s0:begin 
                //substitude <= 1'b0;
                cache_data <= 32'b0;
                cache_wr <= 1'b0;
                cache_rd <= 1'b0;
            end
            s1:begin
                //substitude <= 1'b0;
                cache_rd <= rd;
                cache_wr <= wr;
                if (r_hit) cache_data <= data;
                else cache_data <= 32'b0;
            end
            s2:begin 
                cache_wr <= 1'b0;
                cache_rd <= 1'b0;
                //substitude <= 1'b0;
            end
            s3:begin 
                cache_wr <= 1'b0;
                cache_rd <= 1'b0;
                //substitude_data <= mem_data;
                //substitude <= 1'b1;
            end
            default:begin 
                //substitude <= 1'b0;
                cache_data <= 32'b0;
                cache_wr <= 1'b0;
                cache_rd <= 1'b0;
            end
        endcase
    end
end

always @(*) begin
    if (next_state == s3) begin 
        substitude <= 1'b1;
        substitude_data <= mem_data;
    end
    else begin
        substitude <= 1'b0;
        substitude_data <= 32'b0;
    end    
end

cache u_cache(
.clk(clk),
.rst(rst),
.addr(addr),
.wdata(wdata),
.rd(cache_rd),
.wr(cache_wr),
.substitude(substitude),
.substitude_data(substitude_data),
.dirty_bit(dirty_bit),
.r_hit(r_hit),
.r_miss(r_miss),
.w_hit(w_hit),
.w_miss(w_miss),
.wb_data(wb_data),
.data(data)
);

assign cache_r_hit = r_hit;
assign cache_wb_data = wb_data;

endmodule