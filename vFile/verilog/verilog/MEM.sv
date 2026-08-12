import my_riscv_pkg::*; 
//异步读与异常，没有处理
module MEM(
    input logic clk,
    input logic rst,
    input  ex_mem_bus_t  ex_mem_bus,
    output mem_wb_bus_t  mem_wb_bus,


    output mem_ex_bus_t  mem_ex_bus,    //数据旁路
    output logic [31:0] ram_data_out
);

logic [31:0] addr;
logic [31:0] ram_data;
logic [31:0] w_ram_data;

ram myRam(
.rst(rst),
.clk(clk),
.addr(addr),
.memory_re(ex_mem_bus.memory_re & ex_mem_bus.valid),
.memory_we(ex_mem_bus.memory_we & ex_mem_bus.valid),
.ram_data(ram_data),                    //在读时会慢一拍
.w_ram_data(w_ram_data),
.func3(ex_mem_bus.func3)
);

assign ram_data_out = ram_data;     //是否使用由wb决定

always_comb begin : forwarding_logic
    mem_ex_bus = '0;
    if(ex_mem_bus.valid)begin
        mem_ex_bus.we     = (ex_mem_bus.memory_re) ? 1'b0 : ex_mem_bus.we;   //同步读的数据通路在wb，此处没有可以输出的数据
        mem_ex_bus.rd     = ex_mem_bus.rd;
        mem_ex_bus.w_data = ex_mem_bus.w_data;
    end
end

always_comb begin : ram_data_assignment //传递ram的数据
    addr       = 32'b0;
    w_ram_data = 32'b0;

    if(ex_mem_bus.valid)begin       
        addr = (ex_mem_bus.memory_we || ex_mem_bus.memory_re) ? ex_mem_bus.w_data : 32'b0;
        if(ex_mem_bus.memory_we) w_ram_data = ex_mem_bus.src2_data;
    end
end
    
always_comb begin : signal_assignment
    mem_wb_bus = '0;
    if(ex_mem_bus.valid)begin
        mem_wb_bus.valid  = ex_mem_bus.valid;
        mem_wb_bus.w_data = ex_mem_bus.w_data; 
        //ex阶段已经算好了rd 的返回地址

        mem_wb_bus.rd            = ex_mem_bus.rd;
        mem_wb_bus.we            = ex_mem_bus.we;
        mem_wb_bus.rs1           = ex_mem_bus.rs1;
        mem_wb_bus.rs2           = ex_mem_bus.rs2;
        mem_wb_bus.memory_we     = ex_mem_bus.memory_we;    //访存
        mem_wb_bus.memory_re     = ex_mem_bus.memory_re;

        mem_wb_bus.addr          = addr;
        mem_wb_bus.func3         = ex_mem_bus.func3;
    end
end
endmodule