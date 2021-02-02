module cache
(
    input sys_clk,
    input sys_rst,
    input [31:0] addr,
    input [511:0] rom_block,         //来自rom的block
    output wire [31:0] inst,
    //output wire [25:0] tag,       //全相联,26位标签
    output wire hit,              //命中标记
    output wire miss,             //缺失标记
    output wire replaced,          //替换完成标记
    output wire inst
);
`define HIT 1'b1
`define NOT_HIT 1'b0
`define MISS 1'b1
`define NOT_MISS 1'b0


reg [538:0] block_data;   //0~511位为数据位，512~537位为tag位，538位为Valid位
reg [3:0] block_offset = [5:2]addr;
reg [25:0] tag = [31:6]addr;

wire valid;

assign valid = block_data[538];
assign hit = ([31:6]addr == [537:512] block_data&valid)?HIT:NOT_HIT;
assign miss = ([31:6]addr != [537:512] block_data|!valid)?MISS:NOT_MISS;

always @(posedge sys_clk) begin
    if(!sys_clk)
        [538:0]block_data <= 539'b0;
    else if(rom_block)begin
        [511:0]blcok_data <= rom_blcok;
        [538:512]block_data <= {1'b1,tag};          //更新tag
        replaced <= 1'b1;
    end
end


assign inst = (block_offset == 4'b0)?[31:0]block_data:
(block_offset == 4'b0001)?[63:32]block_data:
(block_offset == 4'b0010)?[95:64]block_data:
(block_offset == 4'b0011)?[127:96]block_data:
(block_offset == 4'b0100)?[159:128]block_data:
(block_offset == 4'b0101)?[191:160]block_data:
(block_offset == 4'b0110)?[223:192]block_data:
(block_offset == 4'b0111)?[255:224]block_data:
(block_offset == 4'b1000)?[287:256]block_data:
(block_offset == 4'b1001)?[319:288]block_data:
(block_offset == 4'b1010)?[351:320]block_data:
(block_offset == 4'b1011)?[383:352]block_data:
(block_offset == 4'b1100)?[415:384]block_data:
(block_offset == 4'b1101)?[447:416]block_data:
(block_offset == 4'b1110)?[479:448]block_data:
(block_offset == 4'b1111)?[511:480]block_data:32'b0;

endmodule
