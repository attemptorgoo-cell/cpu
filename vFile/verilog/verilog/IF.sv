import my_riscv_pkg::*; 
module IF(
    input logic clk,
    input logic rst,
    input ex_if_bus_t ex_if_bus,
    input logic stall,
    output if_id_bus_t if_id_bus
);
logic [31:0] pc;
logic start_flag;
logic [31:0] rom [1023:0];

initial begin
        // 你可以写一个 hex 文件，里面放你的机器码
    $readmemh("D:/03_uncompleted/cpu/vFile/verilog/verilog/inst_data.hex", rom);
    
    $display("DEBUG: ROM[0] = %h, ROM[1] = %h", rom[0], rom[1]);
    //只用正斜杠或者双反斜杠，绝对地址
end

always_ff @(posedge clk or negedge rst)begin
    if(rst == 1'b0)begin
        start_flag <= 1'b1;
        if_id_bus <= '0;
        pc <= 32'b0;
    end
    else if(start_flag == 1'b1)begin
        
        if(ex_if_bus.branch_sign)begin
            pc <= ex_if_bus.pc_branch;              //下一条指令
            if_id_bus.valid <= 1'b0;    

        end 
        
        else if(stall)begin
            pc <= pc;
            if_id_bus <= if_id_bus;
        end

        else begin
            pc <= pc + 32'd4; 
            if_id_bus.valid <= 1'b1;
            if_id_bus.instr <= rom[pc[11:2]];
            if_id_bus.pc    <= pc;
        end

           
    end
end

endmodule