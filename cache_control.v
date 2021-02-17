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
    input [31:0] wdata,  //写入cache的数据
    input [31:0] mem_data,
    input wr,
    input rd,
    input mem_write_fin,
    input mem_read_fin,
    output reg miss,         //未命中信号 暂停流水线
    output reg mem_read_ce,
    output reg mem_write_ce,
    output wire cache_r_hit,
    output wire [31:0] cache_wb_data,   //cache 写回mem的数据
    output reg [31:0] cache_data
);

wire dirty_bit;

reg substitude;
reg cache_wr;
reg cache_rd;
reg [31:0] substitude_data;

wire substitude_fin;
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
                if (wr || rd) begin 
                    next_state <= s1;
                end
                else begin 
                    next_state <= s0;
                end
            end 
            s1:begin
                if ((w_miss || r_miss) && dirty_bit) begin 
                    next_state <= s2;
                end
                else if (w_miss || r_miss) begin 
                    next_state <= s3;
                end
                else if (wr || rd) begin 
                    next_state <= s1;
                end
                else begin  
                    next_state <= s0;
                end
            end
            s2:begin 
                if (mem_write_fin) next_state <= s3;
                else next_state <= s2;
            end
            s3:begin 
                if(substitude_fin) next_state <= s1;
                else next_state <= s3;
            end
            default: next_state <= s0;
        endcase
    end
end

always @(*) begin
    if (next_state == s2 || next_state == s3) begin 
        miss <= 1'b1;
        cache_data <= data;
    end
    else if (next_state == s1 && r_hit == 1'b0) begin 
        miss <= 1'b1;
        cache_data <= data;
    end
    else begin  
        miss <= 1'b0;
        cache_data <= data;
    end
end

always @(posedge clk or posedge rst) begin
    if (rst) begin 
        substitude <= 1'b0;
        cache_data <= 32'b0;
        cache_wr <= 1'b0;
        cache_rd <= 1'b0;
        //miss <= 1'b0;
    end
    else begin 
        case (next_state)
            s0:begin 
                //substitude <= 1'b0;
                //miss <= 1'b0;
                cache_data <= 32'b0;
                cache_wr <= 1'b0;
                cache_rd <= 1'b0;
                mem_read_ce <= 1'b0;
                mem_write_ce <= 1'b0;
            end
            s1:begin
                //substitude <= 1'b0;
                cache_rd <= rd;
                cache_wr <= wr;
                mem_read_ce <= 1'b0;
                mem_write_ce <= 1'b0;
                /*if (r_hit) begin 
                    cache_data <= data;
                    //miss <= 1'b0;
                end
                else begin 
                    cache_data <= 32'b0;
                    //miss <= 1'b1;
                end*/
            end
            s2:begin 
                cache_wr <= 1'b0;
                cache_rd <= 1'b0;
                mem_write_ce <= 1'b1;
                //miss <= 1'b1;
                //substitude <= 1'b0;
            end
            s3:begin 
                cache_wr <= 1'b0;
                cache_rd <= 1'b0;
                mem_read_ce <= 1'b1;
                mem_write_ce <= 1'b0;
                //miss <= 1'b1;
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
    if (next_state == s3 && mem_read_fin) begin 
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
.substitude_fin(substitude_fin),
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