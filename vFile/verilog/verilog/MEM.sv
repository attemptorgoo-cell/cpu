import my_riscv_pkg::*; 
//异步读与异常，没有处理
module MEM(
    input logic clk,
    input logic rst,
    input  ex_mem_bus_t  ex_mem_bus,
    output mem_wb_bus_t  mem_wb_bus,
    
    output mem_ex_bus_t  mem_ex_bus    //数据旁路
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
.ram_data(ram_data),
.w_ram_data(w_ram_data),
.func3(ex_mem_bus.func3)
);

always_comb begin : forwarding_logic
    mem_ex_bus = '0;
    if(ex_mem_bus.valid)begin
        mem_ex_bus.we     = ex_mem_bus.we;
        mem_ex_bus.rd     = ex_mem_bus.rd;
        mem_ex_bus.w_data = (ex_mem_bus.memory_re) ? mem_wb_bus.ram_data :
                                                     ex_mem_bus.w_data   ;
    end//如果是l指令，传回的data应当是ram_data    
end

always_comb begin : ram_data_assignment //传递ram的数据
    addr      = 32'b0;
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

        if(ex_mem_bus.memory_re)begin
            logic [31:0] shifted_ram_data;
            shifted_ram_data = ram_data >> ({30'b0 , addr[1:0]} << 3);   // 移动0/8/16/24位
             case (ex_mem_bus.func3)
                3'b010: mem_wb_bus.ram_data  = ram_data;                                  // lw
                3'b000: mem_wb_bus.ram_data  = {{24{shifted_ram_data[7]}} , shifted_ram_data[7:0]}; // lb
                3'b100: mem_wb_bus.ram_data  = {24'b0 , shifted_ram_data[7:0]};           // lbu
                3'b001: mem_wb_bus.ram_data  = {{16{shifted_ram_data[15]}}, shifted_ram_data[15:0]};// lh
                3'b101: mem_wb_bus.ram_data  = {16'b0 , shifted_ram_data[15:0]};          // lhu
            endcase
        end
    end
end
endmodule