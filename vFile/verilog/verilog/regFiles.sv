//暂时无复位，没有处理内部冲突
module regFiles(
    input  logic clk,
    input  logic rst,
    input  logic [4:0] rs1,rs2,rd,

//r
    output logic [31:0] rdata1,rdata2,

//w
    input  logic we,
    input  logic [31:0] wdata
);

logic [31:0] regs [0:31];
//寄存器本体

//read data 同周期转写
assign rdata1 = (rs1 == 0)? 32'd0 :
                (we == 1 && rs1 == rd) ? wdata :
                regs[rs1];

assign rdata2 = (rs2 == 0)? 32'd0 :
                (we == 1 && rs2 == rd) ? wdata :
                regs[rs2];

//write data
always_ff @(posedge clk) begin
    if(~rst) begin
    for (int i = 0 ; i < 32; i++) regs[i] = 0;
    end else 
    if(we) begin
    regs[rd] <= (rd == 0)? 32'd0 : wdata;
    end
end

endmodule