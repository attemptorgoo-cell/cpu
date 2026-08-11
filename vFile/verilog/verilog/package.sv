package my_riscv_pkg;

typedef struct packed {
    logic [4:0] rs2;     
    logic [4:0] rs1;     
    logic [4:0] rd;      
    logic [3:0] alu_op;
    logic we;     //这条指令最终要不要写回

    logic imm_we;        //是否使用了立即数
    logic [31:0] imm;    

    logic memory_we;
    logic memory_re;
    logic [2:0] func3;
    
    logic is_auipc;
    logic is_branch;

    logic is_jal;
    logic is_jalr;
} decode_out_t;  
//使用t.rd的方式访问
typedef struct packed {
    logic [31:0] pc_branch;
    logic branch_sign;
} ex_if_bus_t;  //t means type

typedef struct packed {
    logic [31:0] instr;
    logic [31:0] pc;
} if_id_bus_t;  //t means type

typedef struct packed {
    logic [31:0] src1_data;
    logic [31:0] src2_data;//R_type的源寄存器中的数据
    
    logic [4:0] rs1;
    logic [4:0] rs2;
    logic [4:0] rd;
    logic [3:0] alu_op;

    logic we;

    logic imm_we;
    logic [31:0] imm;       //立即数生成
    
    logic memory_we;
    logic memory_re;
    logic [2:0] func3;

    logic [31:0] pc;
    logic is_auipc;

    logic is_branch;

    logic is_jal;
    logic is_jalr;
} id_ex_bus_t;  //t means type

typedef struct packed {
    

    logic [31:0] w_data;
    logic [4:0] rd; 
    logic [4:0] rs1;
    logic [4:0] rs2;

    logic [31:0] src1_data;
    logic [31:0] src2_data;//R_type的源寄存器中的数据

    logic we;

    logic memory_we;
    logic memory_re;
    logic [2:0] func3;

} ex_mem_bus_t;

typedef struct packed {
    logic [31:0] w_data;
    logic [4:0] rd; 
    logic we;
    logic [4:0] rs1;
    logic [4:0] rs2;

    logic [31:0] ram_data;
    logic memory_we;
    logic memory_re;
} mem_wb_bus_t;

typedef struct packed {
    
    logic [4:0] rd; 
    logic [31:0] w_data;
    logic we;

} wb_id_bus_t;


//数据旁路，实现“WB慢两拍”的问题,数据回传目标寄存器，和写回数据
typedef struct packed {
    logic [4:0] rd; 
    logic [31:0] w_data;
    logic we;

}  wb_ex_bus_t;

typedef struct packed {
    logic [4:0] rd; 
    logic [31:0] w_data;
    logic we;

}  mem_ex_bus_t;



endpackage