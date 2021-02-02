module cache_control
(
    input sys_clk,
    input sys_rst,
    input ce,          //来自取指阶段的使能信号
    input hit,
    input miss,
    input replaced,
    input [511:0] rom_block,       //来自rom的数据
    output [511:0] cache_block,    //cache要替换的块     
    output wire [31:0] cache_addr,       //给cache的地址   
    output wire [31:0] inst,
    input [31:0] cache_inst,
    output [31:0] rom_addr         //给Rom的地址，取出所需要的块
);

`define idle 1'b0  //暂停阶段
`define read 1'b1  //读取阶段
`define read_rom 2'b10   //读取rom替换阶段

reg [1:0] next_stage
reg [1:0] cur_stage

always @(posedge sys_clk) begin
    if(!sys_rst)
        cur_stage <= idle;
    else
        cur_stage <= next_stage;
end

inst = (hit)?cache_inst:32'b0;           //命中则把取出的地址输出,丢失则输出0，默认0为输出失败



always @(*) begin
    case(cur_stage)begin
        idle:begin
            if(ce)       //如果传来读取请求，那么进入read状态
                next_stage = read;
            else
                next_stage = idle;
        end
        read:begin
            if(hit)      //如果命中，那么转回idle模式
                next_stage = idle;
            else if (miss)    //如果缺失，那么转到read_rom 模式
                next_stage = read_rom;
            else
                next_stage = read;
            end
        read_rom:begin
            if(replaced)
                next_stage = read;     //替换成功，转到read阶段继续读取
            else
                next_stage = read_rom;
        end
        default:next_stage = idle;
    endcase
end

always @(posedge sys_clk) begin
    if(!sys_clk) begin
        cache_block <= 512'b0;
        cache_addr <= 32'b0;
        inst <= 32'b0
        rom_addr <= 32'b0;
    end
    else begin
        case(next_stage) begin
            idle:begin
                cache_block <= 512'b0;
                cache_addr <= 32'b0;
                inst <= 32'b0
                rom_addr <= 32'b0;
            end
            read:begin 
                cache_addr <= addr;
            end
            read_rom:begin  
                rom_addr <= {cache_addr[31:10],9'b0};   //块的大小为512位
                    if(rom_block) begin
                        cache_block <= rom_block;
                    end
            end
            default:begin
                cache_block <= 512'b0;
                cache_addr <= 32'b0;
                inst <= 32'b0
                rom_addr <= 32'b0;
            end
        endcase
    end
end