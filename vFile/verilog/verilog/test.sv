module test();
logic clk,rst;

cpu u_cpu (
    .clk(clk),
    .rst(rst) // 确保你的 cpu.sv 里的复位逻辑和这里对应
);

task check_regFile(
input int unsigned index
input logic [31:0] expected_value
);
    begin
        if (u_cpu.myID.myRf.regs[index] !== expected_value) begin
            $error("Test failed: Register x%0d expected %h, got %h", index, expected_value, u_cpu.myID.myRf.regs[index]);
        end else begin
            $display("Test passed: Register x%0d has value %h", index, u_cpu.myID.myRf.regs[index]);
        end
    end
endtask

always #5 clk = ~clk; // 10ns clock period
initial begin
    rst = 1'b0;
    clk = 1'b0;

    #50 rst = 1'b1;
    #500 
    check_regFile(1, 32'h00000005); // 检查寄存器 x1 是否为 5
    $finish;
end

endmodule