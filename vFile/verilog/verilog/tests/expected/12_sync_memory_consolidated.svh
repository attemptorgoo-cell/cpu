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

if (stall_count !== 10) begin
    $error("Test failed: consolidated regression expected exactly 10 load-use stalls, got %0d", stall_count);
    error_count++;
end else begin
    $display("Test passed: consolidated regression observed exactly 10 load-use stalls");
end
