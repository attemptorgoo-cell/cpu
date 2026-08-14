import my_riscv_pkg::*; 
//导入package

module decoder(
    input logic clk,
    input logic [31:0] instr,
    output decode_out_t decode_out
);

logic [2:0] func3;
logic [6:0] func7;
logic [31:0] imm;
logic [31:0] offset_Stype;
logic [31:0] offset_Btype;
logic [31:0] offset_jal;
logic [31:0] offset_jalr;

assign func3 = instr[14:12];
assign func7 = instr[31:25];

assign imm          = {{20{instr[31]}} , instr[31:20]};
//立即数位宽拓展到32，保留符号
assign offset_Stype = {{20{instr[31]}} , instr[31:25] , instr[11:7]};
assign offset_Btype = {{20{instr[31]}} , instr[7] , instr[30:25] , instr[11:8] , 1'b0};
//隐含条件：因为 RISC-V 指令至少是 16 位（2 字节）对齐的，所以跳转地址必定是 2 的倍数，
//这意味着 offset[0] 永远固定为 0，不需要在指令中浪费 1 个 bit 来存储它。

assign offset_jal  = {{12{instr[31]}} , instr[19:12] , instr[20] , instr[30:21] , 1'b0};
assign offset_jalr = {{20{instr[31]}} , instr[31:20]};

always_comb begin
    decode_out = '0; //默认值，防止产生锁存？

case(instr[6:0])
//-------------------------------------------------------------------------------------------
//确定是j型指令,分为jal,jalr
    7'b1101111:begin         //jal
        decode_out.imm       = offset_jal;
        decode_out.is_jal    = 1'b1;

        decode_out.rd  = instr[11:7];

        decode_out.we  = 1'b1;
    end

    7'b1100111:begin         //jalr
        decode_out.imm       = offset_jalr;
        decode_out.is_jalr   = 1'b1;

        decode_out.rd  = instr[11:7];
        decode_out.rs1 = instr[19:15];

        decode_out.we  = 1'b1;

        decode_out.use_rs1 = 1'b1;
    end

//-------------------------------------------------------------------------------------------
//确定是b型指令,分为beq, bne, blt, bge, bltu, bgeu。
    7'b1100011:begin
        decode_out.alu_op    = 4'b0000;
        decode_out.rs1       = instr[19:15];
        decode_out.rs2       = instr[24:20];
        
        decode_out.imm_we    = 1'b0;
        // B型立即数拼接逻辑 (13位，最低位默认补0)
        decode_out.imm       = offset_Btype;
        
        decode_out.is_branch = 1'b1;
        decode_out.func3     = func3;

        decode_out.use_rs1 = 1'b1;
        decode_out.use_rs2 = 1'b1;
    end


//-------------------------------------------------------------------------------------------
//确定是u型指令,分为lui/auipc
    7'b0110111:begin
        decode_out.alu_op   = 4'b0000;

        decode_out.we  = 1'b1;                 
        decode_out.rs1 = 5'b0;
        decode_out.rd  = instr[11:7];

        decode_out.imm = {instr[31:12] , 12'b0};
        decode_out.imm_we = 1'b1;


    end

    7'b0010111:begin
        decode_out.alu_op   = 4'b0000;

        decode_out.we  = 1'b1; 
        decode_out.rd  = instr[11:7];

        decode_out.imm = {instr[31:12] , 12'b0};
        decode_out.imm_we   = 1'b1;

        decode_out.is_auipc = 1'b1;

    end


//-------------------------------------------------------------------------------------------
//确定是s型指令,分为sw,sh,sb
    7'b0100011:begin
        decode_out.rs1 = instr[19:15];
        decode_out.rs2 = instr[24:20];

        decode_out.we  = 1'b0;                 //s不写寄存器

        decode_out.imm_we     = 1'b1;
        decode_out.imm        = offset_Stype;  //参与计算的是offset偏移量
        
        decode_out.alu_op     = 4'b0000;
        decode_out.memory_re  = 0;
        decode_out.memory_we  = 1;
        decode_out.func3      = func3;

        decode_out.use_rs1 = 1'b1;
        decode_out.use_rs2 = 1'b1;
    end
    7'b0000011:begin
//-------------------------------------------------------------------------------------------
//确定是l型指令,分为lw,lb,lh,lbu,lhu

        decode_out.rs1 = instr[19:15];
        decode_out.rd  = instr[11:7];
        decode_out.we  = 1'b1;

        decode_out.imm_we     = 1'b1;
        decode_out.imm        = imm;
        
        decode_out.alu_op     = 4'b0000;
        decode_out.memory_re  = 1;
        decode_out.func3      = func3;

        decode_out.use_rs1 = 1'b1;


    end
    7'b0010011:begin
//-------------------------------------------------------------------------------------------
//确定是I-imm型指令,分为ADDI, SLTI, SLTIU, XORI, ORI, ANDI, SLLI, SRLI, SRAI 
        decode_out.rs1 = instr[19:15];
        decode_out.rd  = instr[11:7];
        decode_out.we  = 1'b1;


        decode_out.imm_we  = 1'b1;
        decode_out.imm     = imm;
        decode_out.use_rs1 = 1'b1;
 
    case(func3) 
        3'b000:
            decode_out.alu_op = 4'b0000;   //"ADDI"
        3'b111:
            decode_out.alu_op = 4'b0010;   //"ANDI"
        3'b110:
            decode_out.alu_op = 4'b0011;   //"ORI"
        3'b100:
            decode_out.alu_op = 4'b0100;   //"XORI"
        3'b001:
            decode_out.alu_op = 4'b0101;   //"SLLI"

        3'b101:
        begin
            if(instr[30] == 0)
            decode_out.alu_op = 4'b0110;   //"SRLI"
            else
            decode_out.alu_op = 4'b0111;   //"SRAI"   
        end
        3'b010:
            decode_out.alu_op = 4'b1000;   //"SLTI"
        3'b011:
            decode_out.alu_op = 4'b1001;   //"sltiu"
    endcase
    end
    

//------------------------------------------------------------------------------------------
//确定是R型指令,分为add/sub/and/or/xor/sll/sra
    7'b0110011:begin

    decode_out.rs1 = instr[19:15];
    decode_out.rs2 = instr[24:20];
    decode_out.rd  = instr[11:7];
    decode_out.we  = 1'b1;

    decode_out.use_rs1 = 1'b1;
    decode_out.use_rs2 = 1'b1;

    case({func7,func3})
        10'b0000000_000:
            decode_out.alu_op = 4'b0000;//"ADD"
        10'b0100000_000:
            decode_out.alu_op = 4'b0001;//"SUB"
        10'b0000000_111:
            decode_out.alu_op = 4'b0010;//"AND"
        10'b0000000_110:
            decode_out.alu_op = 4'b0011;//"OR"
        10'b0000000_100:
            decode_out.alu_op = 4'b0100;//"XOR"
        10'b0000000_001:
            decode_out.alu_op = 4'b0101;//"SLL"
        10'b0000000_101:
            decode_out.alu_op = 4'b0110;//"SRL"
        10'b0100000_101:
            decode_out.alu_op = 4'b0111;//"SRA"    
        10'b0000000_010:
            decode_out.alu_op = 4'b1000;//"SLT"
        10'b0000000_011:
            decode_out.alu_op = 4'b1001;//"SLTU"
 
    endcase
    end
  
endcase

end

endmodule