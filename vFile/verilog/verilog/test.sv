module test();
logic clk,rst;
int error_count = 0;

cpu u_cpu (
    .clk(clk),
    .rst(rst) // 确保你的 cpu.sv 里的复位逻辑和这里对应
);

task check_regFile(
input int unsigned index,
input logic [31:0] expected_value
);
    begin
        if (u_cpu.myID.myRf.regs[index] !== expected_value) begin
            $error("Test failed: Register x%0d expected %h, got %h", index, expected_value, u_cpu.myID.myRf.regs[index]);
            error_count++;
        end else begin
            $display("Test passed: Register x%0d has value %h", index, u_cpu.myID.myRf.regs[index]);
        end
    end
endtask

task check_memory(
input int unsigned index,
input logic [31:0] expected_value
);
    begin

        if (u_cpu.myMEM.myRam.ram[index] !== expected_value) begin
            $error("Test failed: Memory[%0d] expected %h, got %h", index, expected_value, u_cpu.myMEM.myRam.ram[index]);
            error_count++;
        end else begin
            $display("Test passed: Memory[%0d] has value %h", index, u_cpu.myMEM.myRam.ram[index]);
        end
    end
endtask

always #5 clk = ~clk; // 10ns clock period
initial begin
    rst = 1'b0;
    clk = 1'b0;

    #50 rst = 1'b1;
    #500

    // Forwarding priority and RAW stress test:
    // cover newest-result priority, dual-source forwarding, load-use and branch forwarding.
    check_regFile(0, 32'd0);
    check_regFile(1, 32'd3);
    check_regFile(2, 32'd6);
    check_regFile(3, 32'd43);
    check_regFile(4, 32'd16);
    check_regFile(5, 32'd44);
    check_regFile(6, 32'd44);
    check_regFile(7, 32'd7);
    check_memory(0, 32'd0);
    check_memory(4, 32'd43);

    if (error_count == 0) begin
        $display("All tests passed!");
    end else begin
        $display("%0d tests failed.", error_count);
    end
    $finish;
end
endmodule
