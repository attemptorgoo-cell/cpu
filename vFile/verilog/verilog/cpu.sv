import my_riscv_pkg::*; 
module cpu(
    input logic clk,
    input logic rst,
    output logic cpuOutput
);

if_id_bus_t if_id_bus,if_id_bus_reg;
id_ex_bus_t id_ex_bus,id_ex_bus_reg;
ex_mem_bus_t ex_mem_bus,ex_mem_bus_reg;
mem_wb_bus_t mem_wb_bus,mem_wb_bus_reg; 
wb_id_bus_t wb_id_bus;
//reg表示打一拍的数据,wb写回不需要打拍

//下面是旁路数据的
wb_ex_bus_t wb_ex_bus;
mem_ex_bus_t mem_ex_bus;
//下面是b分支的跳转
ex_if_bus_t ex_if_bus;
logic branch_sign;
IF myIF(
.clk(clk),
.rst(rst),
.if_id_bus(if_id_bus),
.ex_if_bus(ex_if_bus)
);

ID myID(
.clk(clk),
.rst(rst),
.if_id_bus(if_id_bus_reg),
.wb_id_bus(wb_id_bus),
.id_ex_bus(id_ex_bus)
);


EX myEX(
.clk(clk),
.rst(rst),
.id_ex_bus(id_ex_bus_reg),
.ex_mem_bus(ex_mem_bus),
.mem_ex_bus(mem_ex_bus),    //数据旁路
.wb_ex_bus(wb_ex_bus),       //数据旁路
.branch_sign(branch_sign),
.ex_if_bus(ex_if_bus)
);

MEM myMEM(
.clk(clk),
.rst(rst),
.ex_mem_bus(ex_mem_bus_reg),
.mem_wb_bus(mem_wb_bus),
.mem_ex_bus(mem_ex_bus)     //数据旁路
);

WB myWB(
.clk(clk),
.rst(rst),
.mem_wb_bus(mem_wb_bus_reg),
.wb_id_bus(wb_id_bus),
.wb_ex_bus(wb_ex_bus)       //数据旁路
//减少长路径
);

always_ff @(posedge clk or negedge rst)begin
    if(~rst)begin
        if_id_bus_reg <= '0;
        id_ex_bus_reg <= '0;
        ex_mem_bus_reg <= '0;
        mem_wb_bus_reg <= '0;
    end
    else if(branch_sign)begin
        if_id_bus_reg <= '0;
        id_ex_bus_reg <= '0;
        //bubble 清除2条不应该出现的指令 
    end
    else begin
        if_id_bus_reg <= if_id_bus;
        id_ex_bus_reg <= id_ex_bus; 
    end
    ex_mem_bus_reg <= ex_mem_bus;
    mem_wb_bus_reg <= mem_wb_bus;
end


endmodule