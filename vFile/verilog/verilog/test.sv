module test();
logic clk,rst;

initial begin
    rst = 1'b0;
    clk = 1'b0;

    // #30 rst = 1'b0;   避免高阻态x的出现
    #50 rst = 1'b1;
    #500 $finish;
end

always #10 clk = ~clk;

cpu u_cpu (
    .clk(clk),
    .rst(rst) // 确保你的 cpu.sv 里的复位逻辑和这里对应
);
endmodule