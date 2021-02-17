/*
4路组相联
写回
每路：4KB大小 
索引：0~1023 10 bit
标记：20bit
偏移：0bit

替换算法：
访问一次，计数器加一，如果计数值已经为4，则其他计数器减一。
所有计数器的值均为4时，全部清零。
替换时，寻找计数值最低的替换。
*/
module cache (
    input clk,
    input rst,
    input [29:0] addr,
    input [31:0] wdata,   //写入cache的数据
    input rd,
    input wr,
    input substitude,     //cache_control 发出信号
    //input [1:0] substitude_situation
    input [31:0] substitude_data,
    output reg substitude_fin,
    output reg dirty_bit,
    output reg r_hit,
    output reg r_miss,
    output reg w_hit,
    output reg w_miss,
    output reg [31:0] wb_data,  //写回的数据
    output reg [31:0] data
);
integer i;
/*
每路：
1bit 有效位
1bit 修改位 dirty 
20bit 标记位
32bit 数据
*/
reg [53:0] ram_1 [0:1023];
reg [53:0] ram_2 [0:1023];
reg [53:0] ram_3 [0:1023];
reg [53:0] ram_4 [0:1023];

reg [1:0] count_1;
reg [1:0] count_2;
reg [1:0] count_3;
reg [1:0] count_4;

reg [1:0] count_min_1;
reg [1:0] count_min_2;
reg [1:0] count_min_3;

wire [53:0] ram_a;
wire [53:0] ram_b;
wire [53:0] ram_c;
wire [53:0] ram_d;

assign ram_a = ram_1[addr[9:0]];
assign ram_b = ram_2[addr[9:0]];
assign ram_c = ram_3[addr[9:0]];
assign ram_d = ram_4[addr[9:0]];

//初始化
always @(posedge clk or posedge rst) begin
    if (rst) begin 
        for (i = 0;i < 1024 ;i = i+1 ) begin   
            ram_1[i] <= ram_1[i] & 54'd0;  
            ram_2[i] <= ram_2[i] & 54'd0; 
            ram_3[i] <= ram_3[i] & 54'd0; 
            ram_4[i] <= ram_4[i] & 54'd0;
        end   
        r_hit <= 1'b0;
        r_miss <= 1'b0;
        w_hit <= 1'b0;
        w_miss <= 1'b0;
    end
end

//读
always @(*) begin
    if (rd) begin 
        if (ram_a[51:32] == addr[29:10] && ram_a[53]) begin
            data <= ram_a[31:0];
            r_hit <= 1'b1;
            r_miss <= 1'b0;
        end
        else if (ram_b[51:32] == addr[29:10] && ram_b[53]) begin 
            data <= ram_b[31:0];
            r_hit <= 1'b1;
            r_miss <= 1'b0;
        end
        else if (ram_c[51:32] == addr[29:10] && ram_c[53]) begin 
            data <= ram_c[31:0];
            r_hit <= 1'b1;
            r_miss <= 1'b0;
        end
        else if (ram_d[51:32] == addr[29:10] && ram_d[53]) begin 
            data <= ram_d[31:0];
            r_hit <= 1'b1;
            r_miss <= 1'b0;
        end
        else begin 
            data <= 32'd0;
            r_hit <= 1'b0;
            r_miss <= 1'b1;      //未命中
        end
    end
    else begin
        data <= 32'h00000000;
        r_hit <= 1'b0;
        r_miss <= 1'b0;
    end
end

//写
always @(posedge clk) begin
    if (wr) begin
        if (ram_a[51:32] == addr[29:10] && ram_a[53]) begin 
            ram_1[addr[9:0]] <= {1'b1,1'b1,addr[29:10],wdata};
            w_hit <= 1'b1;
        end
        else if (ram_b[51:32] == addr[29:10] && ram_b[53]) begin 
            ram_2[addr[9:0]] <= {1'b1,1'b1,addr[29:10],wdata};
            w_hit <= 1'b1;
        end
        else if (ram_c[51:32] == addr[29:10] && ram_c[53]) begin 
            ram_3[addr[9:0]] <= {1'b1,1'b1,addr[29:10],wdata};
            w_hit <= 1'b1;
        end
        else if (ram_d[51:32] == addr[29:10] && ram_d[53]) begin 
            ram_4[addr[9:0]] <= {1'b1,1'b1,addr[29:10],wdata};
            w_hit <= 1'b1;
        end
        else begin  
            w_miss <= 1'b1;
            w_hit <= 1'b0;
        end
    end
    else begin
        w_hit <= 1'b0;
        w_miss <= 1'b0;
    end
end

//替换
always @(posedge clk or posedge rst) begin
    if (rst) begin
        count_1 <= 2'b00;
        count_2 <= 2'b00;
        count_3 <= 2'b00;
        count_4 <= 2'b00;
    end
    else begin 
        if (count_1 == 2'b11 && count_2 == 2'b11 && count_3 == 2'b11 && count_4 == 2'b11) begin 
            count_1 <= 2'b00;
            count_2 <= 2'b00;
            count_3 <= 2'b00;
            count_4 <= 2'b00;
        end
        if (ram_a[51:32] == addr[29:10] && ram_a[53] && (w_hit || r_hit)) begin
            if (count_1 != 2'b11) count_1 <= count_1 + 1'b1;
            else begin
                if (count_2 != 2'b00) count_2 <= count_2 - 1'b1;
                else count_2 <= 2'b00;
                if (count_3 != 2'b00) count_3 <= count_3 - 1'b1;
                else count_3 <= 2'b00;
                if (count_4 != 2'b00) count_4 <= count_4 - 1'b1;
                else count_4 <= 2'b00;
            end
        end
        else if (ram_b[51:32] == addr[29:10] && ram_b[53] && (w_hit || r_hit)) begin
            if (count_2 != 2'b11) count_2 <= count_2 + 1'b1;
            else begin
                if (count_1 != 2'b00) count_1 <= count_1 - 1'b1;
                else count_1 <= 2'b00;
                if (count_3 != 2'b00) count_3 <= count_3 - 1'b1;
                else count_3 <= 2'b00;
                if (count_4 != 2'b00) count_4 <= count_4 - 1'b1;
                else count_4 <= 2'b00;
            end
        end
        else if (ram_c[51:32] == addr[29:10] && ram_c[53] && (w_hit || r_hit)) begin
            if (count_3 != 2'b11) count_3 <= count_3 + 1'b1;
            else begin
                if (count_1 != 2'b00) count_1 <= count_1 - 1'b1;
                else count_1 <= 2'b00;
                if (count_2 != 2'b00) count_2 <= count_2 - 1'b1;
                else count_2 <= 2'b00;
                if (count_4 != 2'b00) count_4 <= count_4 - 1'b1;
                else count_4 <= 2'b00;
            end
        end
        else if (ram_d[51:32] == addr[29:10] && ram_d[53] && (w_hit || r_hit)) begin
            if (count_4 != 2'b11) count_4 <= count_4 + 1'b1;
            else begin
                if (count_1 != 2'b00) count_1 <= count_1 - 1'b1;
                else count_1 <= 2'b00;
                if (count_2 != 2'b00) count_2 <= count_2 - 1'b1;
                else count_2 <= 2'b00;
                if (count_3 != 2'b00) count_3 <= count_3 - 1'b1;
                else count_3 <= 2'b00;
            end
        end
        if (substitude) begin
            if (count_1 == count_2 && count_1 == count_3 && count_1 == count_4) begin  //相等
            case (count_1)
                2'b00:count_1 <= 2'b00; 
                2'b01:count_2 <= 2'b00; 
                2'b10:count_3 <= 2'b00; 
                2'b11:count_4 <= 2'b00; 
            endcase
            end
            else begin 
                if (count_1 == count_min_3) count_1 <= 2'b00; 
                else if (count_2 == count_min_3) count_2 <= 2'b00; 
                else if (count_3 == count_min_3) count_3 <= 2'b00; 
                else count_4 <= 2'b00; 
            end
        end
    end
end

always @(posedge clk) begin
    substitude_fin <= 1'b0;
    if (substitude) begin
        if (count_1 == count_2 && count_1 == count_3 && count_1 == count_4) begin  //相等
            case (count_1)
                2'b00:ram_1[addr[9:0]] <= {1'b1,1'b0,addr[29:10],substitude_data}; 
                2'b01:ram_2[addr[9:0]] <= {1'b1,1'b0,addr[29:10],substitude_data}; 
                2'b10:ram_3[addr[9:0]] <= {1'b1,1'b0,addr[29:10],substitude_data}; 
                2'b11:ram_4[addr[9:0]] <= {1'b1,1'b0,addr[29:10],substitude_data}; 
            endcase
        end
        else begin 
            if (count_1 == count_min_3) ram_1[addr[9:0]] <= {1'b1,1'b0,addr[29:10],substitude_data}; 
            else if (count_2 == count_min_3) ram_2[addr[9:0]] <= {1'b1,1'b0,addr[29:10],substitude_data}; 
            else if (count_3 == count_min_3) ram_3[addr[9:0]] <= {1'b1,1'b0,addr[29:10],substitude_data}; 
            else ram_4[addr[9:0]] <= {1'b1,1'b0,addr[29:10],substitude_data}; 
        end
        substitude_fin <= 1'b1;
    end
    if (count_1 == count_2 && count_1 == count_3 && count_1 == count_4) begin  //相等
            case (count_1)
                2'b00:begin 
                    dirty_bit <= ram_a[52]; 
                    wb_data <= ram_a[31:0];
                end
                2'b01:begin 
                    dirty_bit <= ram_b[52]; 
                    wb_data <= ram_b[31:0];
                end
                2'b10:begin 
                    dirty_bit <= ram_c[52]; 
                    wb_data <= ram_c[31:0];
                end
                2'b11:begin 
                    dirty_bit <= ram_d[52]; 
                    wb_data <= ram_d[31:0];
                end
            endcase
        end
    else begin 
        if (count_1 == count_min_3) begin 
            dirty_bit <= ram_a[52]; 
            wb_data <= ram_a[31:0];
        end
        else if (count_2 == count_min_3) begin  
            dirty_bit <= ram_b[52]; 
            wb_data <= ram_b[31:0];
        end
        else if (count_3 == count_min_3) begin 
            dirty_bit <= ram_c[52]; 
            wb_data <= ram_c[31:0];
        end
        else begin 
            ram_4[addr[9:0]] <= dirty_bit <= ram_d[52]; 
            wb_data <= ram_d[31:0];
        end
    end
end

always @(*) begin
    if (count_1 < count_2) count_min_1 <= count_1;
    else count_min_1 <= count_2;
end

always @(*) begin
    if (count_3 < count_4) count_min_2 <= count_3;
    else count_min_2 <= count_4;
end

always @(*) begin
    if (count_min_1 < count_min_2) count_min_3 <= count_min_1;
    else count_min_3 <= count_min_2;
end
    
endmodule
