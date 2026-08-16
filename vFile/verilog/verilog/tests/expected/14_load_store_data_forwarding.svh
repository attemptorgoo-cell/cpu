// This test also counts valid Store instructions entering MEM.
check_regFile(0, 32'd0);
check_regFile(1, 32'd42);
check_regFile(2, 32'd8);
check_regFile(3, 32'd12);
check_regFile(5, 32'd42);
check_regFile(6, 32'd8);
check_regFile(7, 32'd12);
check_memory(0, 32'd42);
check_memory(1, 32'd42);
check_memory(2, 32'd42);
check_memory(3, 32'd12);
check_memory(4, 32'd12);

if (stall_count !== 2) begin
    $error("Test failed: late Store-data forwarding expected exactly 2 address-driven stalls, got %0d", stall_count);
    error_count++;
end else begin
    $display("Test passed: late Store-data forwarding observed exactly 2 address-driven stalls");
end

if (store_commit_count !== 6) begin
    $error("Test failed: late Store-data forwarding expected exactly 6 Store commits, got %0d", store_commit_count);
    error_count++;
end else begin
    $display("Test passed: late Store-data forwarding observed exactly 6 Store commits");
end
