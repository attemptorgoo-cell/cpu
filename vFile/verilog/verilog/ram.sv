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

always_comb begin
    if(memory_re)begin
        ram_data = ram[ram_index];
    end else begin
        ram_data = 32'b0;
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
    end 
end
endmodule