import my_riscv_pkg::*; 
module EX(
    input logic clk,
    input logic rst,
    input id_ex_bus_t id_ex_bus,    

    input mem_ex_bus_t mem_ex_bus,  //数据旁路
    input wb_ex_bus_t wb_ex_bus,    //数据旁路

    output ex_mem_bus_t ex_mem_bus,
    output ex_if_bus_t ex_if_bus,

    output logic branch_sign
);

logic [31:0] A;
logic [31:0] B;
logic [31:0] alu_result;

logic [31:0] S_type_src2_data;



//数据旁路
always_comb begin
    A = (id_ex_bus.is_auipc == 1'b1) ? id_ex_bus.pc :
        (id_ex_bus.rs1 == 5'b0) ? 32'b0 :
        (mem_ex_bus.we && mem_ex_bus.rd == id_ex_bus.rs1) ? mem_ex_bus.w_data : 
        (wb_ex_bus.we && wb_ex_bus.rd == id_ex_bus.rs1) ? wb_ex_bus.w_data :
        id_ex_bus.src1_data;
    
    B = (id_ex_bus.imm_we) ? id_ex_bus.imm :     //imm立即数，i型指令无rs2
        (id_ex_bus.rs2 == 5'b0) ? 32'b0 :       
        (mem_ex_bus.we && mem_ex_bus.rd == id_ex_bus.rs2) ? mem_ex_bus.w_data : 
        (wb_ex_bus.we && wb_ex_bus.rd == id_ex_bus.rs2) ? wb_ex_bus.w_data :
        id_ex_bus.src2_data;
    
    //下面是s型指令的src2_data数据通路
    S_type_src2_data = 
        (id_ex_bus.rs2 == 5'b0) ? 32'b0 :       
        (mem_ex_bus.we && mem_ex_bus.rd == id_ex_bus.rs2) ? mem_ex_bus.w_data : 
        (wb_ex_bus.we && wb_ex_bus.rd  == id_ex_bus.rs2) ? wb_ex_bus.w_data :
        id_ex_bus.src2_data;

end



alu myAlu(
.alu_op(id_ex_bus.alu_op),
.A(A),
.B(B),
.C(alu_result)
);

assign ex_mem_bus.w_data  = (id_ex_bus.is_jal || id_ex_bus.is_jalr) ? id_ex_bus.pc + 32'd4 :
                            alu_result;
assign ex_mem_bus.we      = id_ex_bus.we;
assign ex_mem_bus.rd      = id_ex_bus.rd;

assign ex_mem_bus.rs1     = id_ex_bus.rs1;
assign ex_mem_bus.rs2     = id_ex_bus.rs2;

assign ex_mem_bus.src1_data     = id_ex_bus.src1_data;
assign ex_mem_bus.src2_data     = S_type_src2_data;

assign ex_mem_bus.memory_we     = id_ex_bus.memory_we;    //访存
assign ex_mem_bus.memory_re     = id_ex_bus.memory_re;
assign ex_mem_bus.func3         = id_ex_bus.func3;

always_comb begin
    ex_if_bus.branch_sign = 1'b0;
    ex_if_bus.pc_branch   = 32'b0;
    branch_sign           = 1'b0;  // 你的中间变量也给个初值


    if(id_ex_bus.is_branch)begin
        case(id_ex_bus.func3)
            3'b000:  branch_sign = (A == B);
            3'b001:  branch_sign = (A != B);
            3'b100:  branch_sign = ($signed(A) < $signed(B));
            3'b101:  branch_sign = ($signed(A) >= $signed(B));
            3'b110:  branch_sign = (A < B);
            3'b111:  branch_sign = (A >= B);
            default: branch_sign = 1'b0; // 保底处理
        endcase
        if(branch_sign)begin
            ex_if_bus.branch_sign = 1'b1;
            ex_if_bus.pc_branch   = id_ex_bus.pc + id_ex_bus.imm;
        end
    end

    if(id_ex_bus.is_jal || id_ex_bus.is_jalr)begin
        branch_sign = 1;
        ex_if_bus.branch_sign = 1'b1;//借用了跳转的逻辑
        ex_if_bus.pc_branch   = (id_ex_bus.is_jal)  ? id_ex_bus.pc + id_ex_bus.imm :
                                (id_ex_bus.is_jalr) ? (A + id_ex_bus.imm) & ~1 :
                                32'b0;
    end
end
endmodule



