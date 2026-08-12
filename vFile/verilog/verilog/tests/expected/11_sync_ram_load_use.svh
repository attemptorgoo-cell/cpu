check_regFile(0, 32'd0);
check_regFile(1, 32'd42);
check_regFile(2, 32'd42);
check_regFile(3, 32'd43);
check_regFile(4, 32'd85);
check_regFile(5, 32'd85);
check_regFile(6, 32'd0);
check_regFile(7, 32'd85);
check_regFile(8, 32'd85);
check_regFile(9, 32'd170);
check_memory(0, 32'd42);
check_memory(1, 32'd85);
check_memory(2, 32'd85);

if (stall_count !== 4) begin
    $error("Test failed: expected exactly 4 one-cycle load-use stalls, got %0d", stall_count);
    error_count++;
end else begin
    $display("Test passed: observed exactly 4 one-cycle load-use stalls");
end
