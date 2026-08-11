module alu(
    input  logic [3:0] alu_op,
    input  logic [31:0] A,
    input  logic [31:0] B,
    output logic [31:0] C
);
//alu需要判断数据是不是被更新了的

always_comb begin
    case(alu_op)
    4'b0000:    C = A + B;       //add
    4'b0001:    C = A - B;       //sub
    4'b0010:    C = A & B;       //and
    4'b0011:    C = A | B;       //or
    4'b0100:    C = A ^ B;       //xor
    4'b0101:    C = A << B[4:0];               //sll左移
    4'b0110:    C = A >> B[4:0];               //srl右移
    4'b0111:    C = $signed(A) >>> B[4:0];     //sra右移
    4'b1000:    C = ($signed(A) < $signed(B)) ? 1 : 0;    //有符号数比较大小
    4'b1001:    C = (A < B) ? 1 : 0;                      //无符号数比较大小
    default:    C = 32'b0;
    endcase
end

endmodule
