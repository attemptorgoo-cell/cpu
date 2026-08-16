import my_riscv_pkg::*; 
module WB(
    input logic clk,
    input logic rst,

    input mem_wb_bus_t mem_wb_bus,
    input logic [31:0] ram_data_in,

    // input stall,

    output wb_id_bus_t wb_id_bus,
    
    output wb_ex_bus_t wb_ex_bus    //数据旁路

);
logic [31:0] w_data_loadType;
logic [31:0] shifted_ram_data;

always_comb begin : signal_assignment
    wb_id_bus = '0;
    shifted_ram_data = '0;
    w_data_loadType  = 32'b0;


    if(mem_wb_bus.valid)begin
        wb_id_bus.valid = mem_wb_bus.valid;

        wb_id_bus.we     = mem_wb_bus.we;
        wb_id_bus.rd     = mem_wb_bus.rd;

        if(mem_wb_bus.memory_re)begin
            shifted_ram_data = ram_data_in >> ({30'b0 , mem_wb_bus.addr[1:0]} << 3);   // 移动0/8/16/24位
            case (mem_wb_bus.func3)
                3'b010  : w_data_loadType  = ram_data_in;                                  // lw
                3'b000  : w_data_loadType  = {{24{shifted_ram_data[7]}} , shifted_ram_data[7:0]}; // lb
                3'b100  : w_data_loadType  = {24'b0 , shifted_ram_data[7:0]};           // lbu
                3'b001  : w_data_loadType  = {{16{shifted_ram_data[15]}}, shifted_ram_data[15:0]};// lh
                3'b101  : w_data_loadType  = {16'b0 , shifted_ram_data[15:0]};          // lhu
            endcase

        end
        wb_id_bus.w_data = (mem_wb_bus.memory_re) ? w_data_loadType :
                                        mem_wb_bus.w_data;
//如果访问读内存，那w_data是计算的读内存地址，即addr，而ram_data_in才是真正的要写回rd的内容
    end
end

always_comb begin : data_forwarding_logic  //数据旁路
    wb_ex_bus = '0;
    if(mem_wb_bus.valid)begin
        wb_ex_bus.rd            = mem_wb_bus.rd;
        wb_ex_bus.we            = mem_wb_bus.we;
        wb_ex_bus.w_data        = wb_id_bus.w_data;
        wb_ex_bus.valid         = mem_wb_bus.valid;
        wb_ex_bus.memory_re     = mem_wb_bus.memory_re;
     
    //load-use与之前的共享数据通路
    end
end
endmodule
