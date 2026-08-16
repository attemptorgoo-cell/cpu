// This test also counts valid Store instructions entering MEM.
check_regFile(0, 32'd0);
check_regFile(1, 32'd7);
check_regFile(2, 32'd42);
check_regFile(5, 32'd7);
check_regFile(6, 32'd0);
check_memory(0, 32'd7);
check_memory(1, 32'd42);
check_memory(2, 32'd0);
check_memory(3, 32'd0);

if (stall_count !== 0) begin
    $error("Test failed: late Store-data edge cases expected zero stalls, got %0d", stall_count);
    error_count++;
end else begin
    $display("Test passed: late Store-data edge cases observed zero stalls");
end

if (store_commit_count !== 4) begin
    $error("Test failed: late Store-data edge cases expected exactly 4 Store commits, got %0d", store_commit_count);
    error_count++;
end else begin
    $display("Test passed: late Store-data edge cases observed exactly 4 Store commits");
end
