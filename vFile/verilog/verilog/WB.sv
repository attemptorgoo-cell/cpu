import my_riscv_pkg::*; 
module WB(
    input logic clk,
    input logic rst,

    input mem_wb_bus_t mem_wb_bus,
    output wb_id_bus_t wb_id_bus,
    
    output wb_ex_bus_t wb_ex_bus    //数据旁路
);

assign  wb_id_bus.w_data = (mem_wb_bus.memory_re) ? mem_wb_bus.ram_data :
                                         mem_wb_bus.w_data;

//如果访问读内存，那w_data是计算的地址，而ram_data才是真正的要写回rd的地址

assign wb_id_bus.we     = mem_wb_bus.we;
assign wb_id_bus.rd     = mem_wb_bus.rd;



//数据旁路

assign wb_ex_bus.rd     = mem_wb_bus.rd;
assign wb_ex_bus.we     = mem_wb_bus.we;
assign wb_ex_bus.w_data = wb_id_bus.w_data;        
    //旁路转发的是，写回的w_data，他经过?处理，mem_wb_bus.w_data在lw指令下是地址

endmodule
