import my_riscv_pkg::*; 
module ID(
    input logic clk,
    input logic rst,

    input if_id_bus_t if_id_bus,
    input wb_id_bus_t wb_id_bus,                //接受写回阶段传回来的数据

    output id_ex_bus_t id_ex_bus
);

decode_out_t decode_out;

decoder myDecoder(
.clk(clk),
.instr(if_id_bus.instr),
.decode_out(decode_out)
);


assign id_ex_bus.pc        = if_id_bus.pc;
assign id_ex_bus.is_auipc  = decode_out.is_auipc;
assign id_ex_bus.is_branch = decode_out.is_branch;
assign id_ex_bus.is_jal    = decode_out.is_jal;
assign id_ex_bus.is_jalr   = decode_out.is_jalr;

assign id_ex_bus.alu_op    = decode_out.alu_op;
assign id_ex_bus.we        = decode_out.we;
assign id_ex_bus.rd        = decode_out.rd;

assign id_ex_bus.rs1       = decode_out.rs1;
assign id_ex_bus.rs2       = decode_out.rs2;


assign id_ex_bus.imm_we    = decode_out.imm_we; //I型指令
assign id_ex_bus.imm       = decode_out.imm; 


assign id_ex_bus.memory_we = decode_out.memory_we;
assign id_ex_bus.memory_re = decode_out.memory_re;
assign id_ex_bus.func3     = decode_out.func3;


regFiles myRf(
.clk(clk),
.rst(rst),
.rs1(decode_out.rs1),
.rs2(decode_out.rs2),
.rd(wb_id_bus.rd),
.rdata1(id_ex_bus.src1_data),
.rdata2(id_ex_bus.src2_data),
.we(wb_id_bus.we),
//在这里 we被接上了
.wdata(wb_id_bus.w_data)

);

endmodule