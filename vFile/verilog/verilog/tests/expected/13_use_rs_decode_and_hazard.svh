// Test 13 additionally instantiated a standalone decoder probe and used the
// check_decode_use task. These are the exact decoder calls and architectural
// checks from the passing run.
check_decode_use(32'h0000006f, 1'b0, 1'b0, "JAL");
check_decode_use(32'h000280e7, 1'b1, 1'b0, "JALR");
check_decode_use(32'h00628063, 1'b1, 1'b1, "BRANCH");
check_decode_use(32'h000283b7, 1'b0, 1'b0, "LUI");
check_decode_use(32'h00028397, 1'b0, 1'b0, "AUIPC");
check_decode_use(32'h00532023, 1'b1, 1'b1, "STORE");
check_decode_use(32'h00032283, 1'b1, 1'b0, "LOAD");
check_decode_use(32'h00530293, 1'b1, 1'b0, "OP-IMM");
check_decode_use(32'h007302b3, 1'b1, 1'b1, "OP");
check_decode_use(32'hffffffff, 1'b0, 1'b0, "UNKNOWN OPCODE");

check_regFile(0, 32'd0);
check_regFile(1, 32'd42);
check_regFile(5, 32'd42);
check_regFile(6, 32'd5);
check_regFile(7, 32'h00028000);
check_regFile(8, 32'd42);
check_regFile(9, 32'd43);
check_regFile(10, 32'd42);
check_regFile(11, 32'd42);
check_regFile(12, 32'd42);
check_memory(0, 32'd42);
check_memory(1, 32'd42);

if (stall_count !== 3) begin
    $error("Test failed: use_rs regression expected exactly 3 true load-use stalls, got %0d", stall_count);
    error_count++;
end else begin
    $display("Test passed: use_rs regression observed exactly 3 true load-use stalls");
end
