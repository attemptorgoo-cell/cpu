import my_riscv_pkg::*; 
module ID(
    input logic clk,
    input logic rst,

    input if_id_bus_t if_id_bus,
    input wb_id_bus_t wb_id_bus,                //接受写回阶段传回来的数据

    output id_ex_bus_t id_ex_bus
);

decode_out_t decode_out;

logic [31:0] src1_data;
logic [31:0] src2_data;
//避免id_ex_bus的多重驱动

decoder myDecoder(
.clk(clk),
.instr(if_id_bus.instr),
.decode_out(decode_out)
);

regFiles myRf(
.clk(clk),
.rst(rst),
.rs1(decode_out.rs1),
.rs2(decode_out.rs2),
.rd(wb_id_bus.rd),
.rdata1(src1_data),      // 不可使用id_ex_bus.src1_data，因为id_ex_bus在下方comb有赋值
.rdata2(src2_data),
.we(wb_id_bus.we),
//在这里 we被接上了
.wdata(wb_id_bus.w_data)

);


always_comb begin : signal_assignment
    id_ex_bus = '0;

    if(if_id_bus.valid)begin

        id_ex_bus.valid     = if_id_bus.valid;

        id_ex_bus.pc        = if_id_bus.pc;
        id_ex_bus.is_auipc  = decode_out.is_auipc;
        id_ex_bus.is_branch = decode_out.is_branch;
        id_ex_bus.is_jal    = decode_out.is_jal;
        id_ex_bus.is_jalr   = decode_out.is_jalr;

        id_ex_bus.alu_op    = decode_out.alu_op;
        id_ex_bus.we        = decode_out.we;
        id_ex_bus.rd        = decode_out.rd;

        id_ex_bus.rs1       = decode_out.rs1;
        id_ex_bus.rs2       = decode_out.rs2;

        id_ex_bus.src1_data = src1_data;
        id_ex_bus.src2_data = src2_data;

        id_ex_bus.imm_we    = decode_out.imm_we;  //I型指令
        id_ex_bus.imm       = decode_out.imm;

        id_ex_bus.memory_we = decode_out.memory_we;
        id_ex_bus.memory_re = decode_out.memory_re;
        id_ex_bus.func3     = decode_out.func3;
    
    end
end
endmodule