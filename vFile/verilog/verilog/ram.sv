module ram (
    input logic rst,
    input logic clk,
    input logic [31:0] addr,
    input logic memory_re,
    input logic memory_we,
    input logic [31:0] w_ram_data,
    input logic [2:0] func3,

    output logic [31:0] ram_data
);


logic [31:0] ram [0:1023];
logic [9:0] ram_index;         //1024个数据，从0到1023，1023是9位

assign ram_index = addr[11:2];

// always_comb begin
//     if(memory_re)begin
//         ram_data = ram[ram_index];
//     end else begin
//         ram_data = 32'b0;
//     end
// end

always_ff@ (posedge clk)begin
    if(memory_re)begin
        ram_data <= ram[ram_index];
    end else begin
        ram_data <= 32'b0;
    end
end

always_ff@ (posedge clk)begin
    if(memory_we)begin
        case (func3)
            3'b010:          //sw
                ram[ram_index]      <= w_ram_data;          
            3'b000:          //sb
                case(addr[1:0])
                    2'b00:
                    ram[ram_index][7:0]   <= w_ram_data[7:0]; 
                    2'b01:
                    ram[ram_index][15:8]  <= w_ram_data[7:0];  
                    2'b10:
                    ram[ram_index][23:16] <= w_ram_data[7:0]; 
                    2'b11:
                    ram[ram_index][31:24] <= w_ram_data[7:0]; 
                endcase         
            3'b001:          //sh
                case(addr[1])
                    1'b0:
                    ram[ram_index][15:0]  <= w_ram_data[15:0]; 

                    1'b1:
                    ram[ram_index][31:16] <= w_ram_data[15:0];  
                endcase
        endcase


        /**
    logic [3:0]  byte_we;       // 4位字节写使能 (1表示写入对应字节)
    logic [31:0] aligned_wdata; // 移位对齐后的写入数据

    // 1. 组合逻辑：计算掩码与对齐数据
    always_comb begin
        byte_we = 4'b0000;
        if (memory_we) begin // 记得带上 memory_we 判断
            case (func3)
                3'b010: byte_we = 4'b1111;                // sw: 4字节全开
                3'b001: byte_we = 4'b0011 << addr[1:0];   // sh: 2字节开 (左移0或2)
                3'b000: byte_we = 4'b0001 << addr[1:0];   // sb: 1字节开 (左移0,1,2,3)
                default: byte_we = 4'b0000;
            endcase
        end
        
        // 又是移位魔法！跟读出时相反，写入时我们向左移位，把数据推到对应的字节线上
        aligned_wdata = w_ram_data << (addr[1:0] << 3); 
    end

    // 2. 时序逻辑：RAM 写入 (标准 BRAM Byte-Enable 模板)
    always_ff @(posedge clk) begin // 假设你这里是时序电路
        // 不再需要 case，直接根据 4 个开关独立控制 4 个字节通道！
        if (byte_we[0]) ram[ram_index][7:0]   <= aligned_wdata[7:0];
        if (byte_we[1]) ram[ram_index][15:8]  <= aligned_wdata[15:8];
        if (byte_we[2]) ram[ram_index][23:16] <= aligned_wdata[23:16];
        if (byte_we[3]) ram[ram_index][31:24] <= aligned_wdata[31:24];
    end
        **/
    end 
end
endmodule