import my_riscv_pkg::*;

module test();
logic clk,rst;
int error_count = 0;
int unsigned stall_count = 0;
int unsigned store_commit_count = 0;
logic [31:0] decode_probe_instr;
decode_out_t decode_probe_out;

cpu u_cpu (
    .clk(clk),
    .rst(rst) // 确保你的 cpu.sv 里的复位逻辑和这里对应
);

decoder decode_probe (
    .clk(clk),
    .instr(decode_probe_instr),
    .decode_out(decode_probe_out)
);

task check_decode_use(
input logic [31:0] instr,
input logic expected_use_rs1,
input logic expected_use_rs2,
input string instruction_name
);
    begin
        decode_probe_instr = instr;
        #1;
        if (
            decode_probe_out.use_rs1 !== expected_use_rs1 ||
            decode_probe_out.use_rs2 !== expected_use_rs2
        ) begin
            $error(
                "Decode failed for %s: expected use_rs1/use_rs2=%0b/%0b, got %0b/%0b",
                instruction_name,
                expected_use_rs1,
                expected_use_rs2,
                decode_probe_out.use_rs1,
                decode_probe_out.use_rs2
            );
            error_count++;
        end else begin
            $display(
                "Decode passed for %s: use_rs1/use_rs2=%0b/%0b",
                instruction_name,
                decode_probe_out.use_rs1,
                decode_probe_out.use_rs2
            );
        end
    end
endtask

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

always_ff @(posedge clk or negedge rst) begin
    if (!rst) begin
        stall_count <= 0;
    end else if (u_cpu.stall) begin
        stall_count <= stall_count + 1;
    end
end

always_ff @(posedge clk or negedge rst) begin
    if (!rst) begin
        store_commit_count <= 0;
    end else if (u_cpu.ex_mem_bus_reg.valid && u_cpu.ex_mem_bus_reg.memory_we) begin
        store_commit_count <= store_commit_count + 1;
    end
end

initial begin
    rst = 1'b0;
    clk = 1'b0;
    decode_probe_instr = 32'b0;

    #50 rst = 1'b1;
    #800

    // Test 16: post-late-forwarding consolidated synchronous-memory regression.
    // Covers all Load widths/extensions, Store widths/lanes, Load-use consumers,
    // WB-to-MEM Store-data forwarding, taken redirect and wrong-path Store suppression.
    check_regFile(0, 32'd0);
    check_regFile(1, 32'h80ff7f01);
    check_regFile(2, 32'h80ff7f01);
    check_regFile(3, 32'h80ff7f02);
    check_regFile(4, 32'h00000001);
    check_regFile(5, 32'h00000002);
    check_regFile(6, 32'h0000007f);
    check_regFile(7, 32'h00000080);
    check_regFile(8, 32'h000000ff);
    check_regFile(9, 32'h00000100);
    check_regFile(10, 32'hffffff80);
    check_regFile(11, 32'hffffff81);
    check_regFile(12, 32'h00007f01);
    check_regFile(13, 32'h00007f02);
    check_regFile(14, 32'h000080ff);
    check_regFile(15, 32'h00008100);
    check_regFile(18, 32'h0000a1b2);
    check_regFile(19, 32'ha1b25501);
    check_regFile(20, 32'ha1b25501);
    check_regFile(21, 32'ha1b25501);
    check_regFile(22, 32'ha1b25501);
    check_regFile(23, 32'd7);
    check_memory(0, 32'ha1b25501);
    check_memory(1, 32'ha1b25501);
    check_memory(2, 32'd0);

    if (stall_count !== 9) begin
        $error("Test failed: consolidated regression expected exactly 9 load-use stalls after late Store-data forwarding, got %0d", stall_count);
        error_count++;
    end else begin
        $display("Test passed: consolidated regression observed exactly 9 load-use stalls after late Store-data forwarding");
    end

    if (error_count == 0) begin
        $display("All tests passed!");
    end else begin
        $display("%0d tests failed.", error_count);
    end
    $finish;
end
endmodule
