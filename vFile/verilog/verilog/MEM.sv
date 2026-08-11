import my_riscv_pkg::*; 
//异步读与异常，没有处理
module MEM(
    input logic clk,
    input logic rst,
    input  ex_mem_bus_t  ex_mem_bus,
    output mem_wb_bus_t  mem_wb_bus,
    
    output mem_ex_bus_t  mem_ex_bus    //数据旁路

    
);

logic [31:0] addr;
logic memory_re;
logic memory_we;
logic [31:0] ram_data;
logic [31:0] w_ram_data;

    //传递ram的数据
    assign addr                  = (memory_we || memory_re) ? ex_mem_bus.w_data : 32'b0;
    assign memory_re             = ex_mem_bus.memory_re;
    assign memory_we             = ex_mem_bus.memory_we;

    assign mem_wb_bus.w_data     = ex_mem_bus.w_data;
    assign mem_wb_bus.rd         = ex_mem_bus.rd;
    assign mem_wb_bus.we         = ex_mem_bus.we;

    assign mem_wb_bus.rs1        = ex_mem_bus.rs1;
    assign mem_wb_bus.rs2        = ex_mem_bus.rs2;
    assign mem_wb_bus.memory_re  = memory_re;
    assign mem_wb_bus.memory_we  = memory_we;


ram myRam(
.rst(rst),
.clk(clk),
.addr(addr),
.memory_re(memory_re),
.memory_we(memory_we),
.ram_data(ram_data),
.w_ram_data(w_ram_data),
.func3(ex_mem_bus.func3)
);
    //数据旁路
//    logic [31:0] transform_data;?
    assign mem_ex_bus.we         = ex_mem_bus.we;
    assign mem_ex_bus.rd         = ex_mem_bus.rd;

    assign mem_ex_bus.w_data     = (ex_mem_bus.memory_re) ? mem_wb_bus.ram_data :
                                                            ex_mem_bus.w_data   ;

    //如果是l指令，传回的data应当是ram_data    

always_comb begin

//复杂逻辑写在comb里
    if(memory_we)begin
        w_ram_data = ex_mem_bus.src2_data;
    end else begin
        w_ram_data = 32'b0;
    end

    if(memory_re)begin 
         //读出来的分类截取，传递到wb
        case (ex_mem_bus.func3)
            3'b010: 
                mem_wb_bus.ram_data = ram_data;     //lw
            3'b000:                                              //lb
                case(ex_mem_bus.w_data[1:0])
                    2'b00:
                    mem_wb_bus.ram_data  = 
                    {{24{ram_data[7]}} , ram_data[7:0]}; 

                    2'b01:
                    mem_wb_bus.ram_data  = 
                    {{24{ram_data[15]}} , ram_data[15:8]};  

                    2'b10:
                    mem_wb_bus.ram_data  = 
                    {{24{ram_data[23]}} , ram_data[23:16]};

                    2'b11:
                    mem_wb_bus.ram_data  = 
                    {{24{ram_data[31]}} ,ram_data[31:24]};
                endcase

            3'b100:                                             //lbu            
                case(ex_mem_bus.w_data[1:0])
                    2'b00:
                    mem_wb_bus.ram_data  = 
                    {24'b0 , ram_data[7:0]}; 

                    2'b01:
                    mem_wb_bus.ram_data  = 
                    {24'b0 , ram_data[15:8]};  

                    2'b10:
                    mem_wb_bus.ram_data  = 
                    {24'b0 , ram_data[23:16]};

                    2'b11:
                    mem_wb_bus.ram_data  = 
                    {24'b0 ,ram_data[31:24]};
                endcase
            3'b001:                                             //lh
                case(ex_mem_bus.w_data[1])
                    1'b0:
                    mem_wb_bus.ram_data  = 
                    {{16{ram_data[15]}} , ram_data[15:0]}; 

                    1'b1:
                    mem_wb_bus.ram_data  = 
                    {{16{ram_data[31]}} , ram_data[31:16]};
                endcase
                
            3'b101:                                             //lhu
                case(ex_mem_bus.w_data[1])
                    1'b0:
                    mem_wb_bus.ram_data  = 
                    {16'b0 , ram_data[15:0]}; 

                    1'b1:
                    mem_wb_bus.ram_data  = 
                    {16'b0 , ram_data[31:16]};
                endcase

            default:
                mem_wb_bus.ram_data = 32'b0;

        endcase
       
    end else begin
            mem_wb_bus.ram_data = 32'b0;

    end

        //跳变，与输出端口的分发？
end


endmodule