//定义操作类型
`define FI 3'b000 //取指
`define W_RAM 3'b001 //写存储器
`define R_RAM 3'b010 //读存储器
`define R_REG 3'b011 //读寄存器
`define W_REG 3'b100 //写寄存器
//定义指令类型
`define NOP   4'b0000 //无操作
`define ADD   4'b0001 //加法
`define SUB   4'b0010 //减法
`define AND   4'b0011 //逻辑与
`define INC   4'b0100 //加1
`define LD    4'b0101 //取数
`define ST    4'b0110 //存数
`define JC    4'b0111 //C条件转移
`define JZ    4'b1000 //Z条件转移
`define JMP   4'b1001 //无条件转移
`define MOV   4'b1010 //移数
`define CMP   4'b1011 //比较
`define OR    4'b1100 //逻辑或
`define OUT   4'b1101 //输出
`define STP   4'b1110 //停机
`define NOT   4'b1111 //逻辑非
//定义操作类型的宏
`define IS_FI (SWCBA==`FI) //是否为取指令
`define IS_W_RAM (SWCBA==`W_RAM) //是否为写存储器
`define IS_R_RAM (SWCBA==`R_RAM) //是否为读存储器
`define IS_R_REG (SWCBA==`R_REG) //是否为读寄存器
`define IS_W_REG (SWCBA==`W_REG) //是否为写寄存器
//指令类型
`define IN_NOP (IR[7:4]==`NOP) //是否为无操作指令
`define IN_ADD (IR[7:4]==`ADD) //是否为加法

`define IN_SUB (IR[7:4]==`SUB) //是否为减法
`define IN_AND (IR[7:4]==`AND) //是否为逻辑与
`define IN_INC (IR[7:4]==`INC) //是否为加1
`define IN_LD  (IR[7:4]==`LD)  //是否为取数
`define IN_ST  (IR[7:4]==`ST)  //是否为存数
`define IN_JC  (IR[7:4]==`JC)  //是否为C条件转移
`define IN_JZ  (IR[7:4]==`JZ)  //是否为Z条件转移
`define IN_JMP (IR[7:4]==`JMP) //是否为无条件转移
`define IN_MOV (IR[7:4]==`MOV) //是否为移数
`define IN_CMP (IR[7:4]==`CMP) //是否为比较
`define IN_OR  (IR[7:4]==`OR)  //是否为逻辑或
`define IN_OUT (IR[7:4]==`OUT) //是否为输出
`define IN_STP (IR[7:4]==`STP) //是否为停机
`define IN_NOT (IR[7:4]==`NOT) //是否为逻辑非

module pipeline (
    input T3, CLR, C, Z,       
    input [7:0] IR,
    input [2:0] SWCBA,
    input [3:1] W,
    output reg SBUS, LAR, STOP, SHORT, SELCTL, MEMW,
                ARINC, MBUS, DRW, LPC, LIR, PCINC, CIN, ABUS, PCADD, M, LONG, LDZ, LDC,
    output reg [3:0] S,
    output reg [3:0] SEL
);
    reg ST0,SST0;
    always @(*) begin
        if (~CLR) begin
            ST0 = 0;  // 只复位ST0
        end else if (SST0) begin
            ST0 = 1;
        end
    end
    always @(negedge T3 or negedge CLR) begin
        if (~CLR) begin
            {SST0,SBUS, LAR, STOP, SHORT, SELCTL, MEMW,
            ARINC, MBUS, DRW, LPC, LIR, PCINC, 
            CIN, ABUS, PCADD, M, LONG, LDZ, LDC} <= 0;
            S <= 0;
            SEL <= 0;
        end
        else begin
            case (W)
                3'b000:begin
                    SBUS <= `IS_W_RAM ||
                            `IS_R_RAM ||
                            `IS_W_REG ||
                            `IS_FI;
                    LAR <= `IS_W_RAM ||
                            `IS_R_RAM;
                    STOP <= `IS_W_RAM ||
                            `IS_R_RAM ||
                            `IS_W_REG ||
                            `IS_R_REG ||
                            `IS_FI;
                    SST0 <= `IS_W_RAM ||
                            `IS_R_RAM;
                    SHORT <= `IS_W_RAM ||
                            `IS_R_RAM;
                    SELCTL <= `IS_W_RAM ||
                            `IS_R_RAM ||
                            `IS_W_REG ||
                            `IS_R_REG;
                    DRW <= `IS_W_REG;
                    MEMW <= `IS_W_RAM && ST0;
                    SEL[3] <= 0;
                    SEL[2] <= 0;
                    SEL[1] <= `IS_W_REG;
                    SEL[0] <= `IS_W_REG || `IS_R_REG;
                    LPC <= `IS_FI;
                    {ARINC, MBUS, LIR, PCINC,CIN,
                    ABUS, PCADD, M, LONG, LDZ, LDC} <= 0;
                    S <= 0;
                end
                3'b001:begin
                    if (SHORT) begin
                        SELCTL <= `IS_R_RAM || 
                                `IS_W_RAM ||
                                `IS_R_REG ||
                                `IS_W_REG;
                        STOP <= `IS_R_RAM || 
                                `IS_W_RAM ||
                                `IS_R_REG ||
                                `IS_W_REG ||
                                (`IS_FI && (~ST0 || ST0 && `IN_STP));
                        DRW <= `IS_W_REG || 
                                (`IS_FI && ST0 &&
                                    (`IN_ADD || 
                                    `IN_SUB || 
                                    `IN_AND || 
                                    `IN_INC || 
                                    `IN_MOV ||
                                    `IN_NOT || 
                                    `IN_OR));
                        SBUS <= `IS_W_RAM || 
                                (`IS_R_RAM && ~ST0) ||
                                `IS_W_REG ||
                                (`IS_FI && ~ST0);
                        LDZ <= `IS_FI && ST0 && 
                                    (`IN_ADD || 
                                    `IN_SUB ||
                                    `IN_AND ||
                                    `IN_INC ||
                                    `IN_CMP);
                        LDC <= `IS_FI && ST0 &&
                                    (`IN_ADD || 
                                    `IN_SUB || 
                                    `IN_INC || 
                                    `IN_CMP|| 
                                    `IN_NOT ||
                                    `IN_OR);
                        S[3] <= `IS_FI && ST0 && 
                                    (`IN_ADD ||
                                    `IN_AND ||
                                    `IN_MOV ||
                                    `IN_JMP ||
                                    `IN_LD ||
                                    `IN_ST ||
                                    `IN_OR||
                                    `IN_OUT);
                        S[2] <= `IS_FI && ST0 && 
                                    (`IN_SUB ||
                                    `IN_CMP ||
                                    `IN_JMP ||
                                    `IN_ST ||
                                    `IN_OR);
                        S[1] <= `IS_FI && ST0 && 
                                    (`IN_SUB ||
                                    `IN_AND ||
                                    `IN_MOV ||
                                    `IN_CMP ||
                                    `IN_JMP ||
                                    `IN_LD ||
                                    `IN_ST ||
                                    `IN_OR ||
                                    `IN_OUT);
                        S[0] <= `IS_FI && ST0 && 
                                    (`IN_ADD ||
                                    `IN_AND ||
                                    `IN_JMP ||
                                    `IN_ST);
                        SEL[3] <= `IS_W_REG && ST0;
                        SEL[2] <= 0;
                        SEL[1] <= `IS_W_REG && ~ST0;
                        SEL[0] <= `IS_R_REG ||
                                `IS_W_REG;
                        LPC <= `IS_FI && (~ST0 || ST0 && `IN_JMP);
                        LIR <= `IS_FI && ST0 &&
                                    (`IN_NOP || 
                                    `IN_AND ||
                                    `IN_INC ||
                                    `IN_MOV ||
                                    `IN_CMP ||
                                    `IN_JC && ~C || 
                                    `IN_JZ && ~Z ||
                                    `IN_NOT ||
                                    `IN_OR || 
                                    `IN_OUT);
                        PCINC <= `IS_FI && ST0 &&
                                    (`IN_NOP || 
                                    `IN_AND ||
                                    `IN_INC || 
                                    `IN_MOV || 
                                    `IN_CMP || 
                                    `IN_JC && ~C ||
                                    `IN_JZ && ~Z || 
                                    `IN_NOT || 
                                    `IN_OR || 
                                    `IN_OUT);
                        SHORT <= `IS_W_RAM || 
                                `IS_R_RAM || 
                                `IS_FI && ST0 &&
                                    (`IN_NOP || 
                                    `IN_AND || 
                                    `IN_INC || 
                                    `IN_MOV || 
                                    `IN_CMP || 
                                    `IN_JC && ~C || 
                                    `IN_JZ && ~Z || 
                                    `IN_NOT || 
                                    `IN_OR || 
                                    `IN_OUT);
                        PCADD <= `IS_FI && ST0 && 
                                    (C && `IN_JC || 
                                    Z && `IN_JZ);
                        SST0 <= (`IS_W_RAM && ~ST0) ||
                                (`IS_R_RAM && ~ST0);
                        LAR <= (`IS_W_RAM && ~ST0) ||
                                (`IS_R_RAM && ~ST0) ||
                                (`IS_FI && ST0 &&
                                    (`IN_ST || 
                                    `IN_LD));
                        MEMW <= `IS_W_RAM && ST0;
                        ARINC <= (`IS_W_RAM && ST0) ||
                                (`IS_R_RAM && ST0);
                        MBUS <= `IS_R_RAM && ST0;
                        CIN <= `IS_FI && ST0 && `IN_ADD;
                        ABUS <= `IS_FI && ST0 && 
                                    (`IN_ADD || 
                                    `IN_SUB ||
                                    `IN_AND || 
                                    `IN_INC || 
                                    `IN_MOV || 
                                    `IN_CMP || 
                                    `IN_JMP || 
                                    `IN_LD || 
                                    `IN_ST || 
                                    `IN_NOT || 
                                    `IN_OR || 
                                    `IN_OUT);
                        M <= `IS_FI && ST0 && (`IN_AND ||
                                    `IN_MOV || 
                                    `IN_JMP || 
                                    `IN_LD || 
                                    `IN_ST ||
                                    `IN_NOT || 
                                    `IN_OR || 
                                    `IN_OUT);
                        LONG <= 0;
                    end else begin
                        LIR <= `IS_FI && (~ST0 || ST0 && (`IN_ADD || `IN_SUB || `IN_JMP || `IN_ST));
                        PCINC <= `IS_FI && (~ST0 || ST0 && (`IN_ADD || `IN_SUB || `IN_JMP || `IN_ST));
                        LONG <=`IS_FI && ST0 && (`IN_JC && C || `IN_JZ && Z || `IN_LD);
                        DRW <= `IS_W_REG || `IS_FI && ST0 && `IN_LD;
                        M <= `IS_FI && ST0 && `IN_ST;
                        S[3] <= `IS_FI && ST0 && `IN_ST;
                        S[2] <= 0;
                        S[1] <= `IS_FI && ST0 && `IN_ST;
                        S[0] <= 0;
                        ABUS <= `IS_FI && ST0 && `IN_ST;
                        MEMW <= `IS_FI && ST0 && `IN_ST;
                        SST0 <= (`IS_FI && ~ST0) ||
                                (`IS_W_REG && ~ST0);
                        MBUS <= (`IS_FI && ST0) ||
                                (`IS_FI && ST0 && `IN_LD);
                        SBUS <= `IS_W_REG;
                        SELCTL <= `IS_R_REG || `IS_W_REG;
                        STOP <= `IS_R_REG || `IS_W_REG;
                        SEL[3] <= `IS_R_REG || (`IS_W_REG && ST0);
                        SEL[2] <= `IS_W_REG;
                        SEL[1] <= `IS_R_REG || (`IS_W_REG && ST0);
                        SEL[0] <= `IS_R_REG;
                        {LAR, SHORT, ARINC, LPC,  
                        CIN, PCADD, LDZ, LDC} <=0;
                    end
                end
                3'b010:begin
                    if (LONG) begin
                        LIR <= `IS_FI && ST0 && (`IN_JC && C || `IN_JZ && Z || `IN_LD);
                        PCINC <= `IS_FI && ST0 && (`IN_JC && C || `IN_JZ && Z || `IN_LD);
                        {SST0,SBUS, LAR, STOP, SHORT, SELCTL, MEMW,
                        ARINC, MBUS, DRW, LPC, 
                        CIN, ABUS, PCADD, M, LONG, LDZ, LDC} <=0;
                        S <= 0;
                        SEL <= 0;
                    end else begin
                        SELCTL <= `IS_R_RAM || 
                                `IS_W_RAM ||
                                `IS_R_REG ||
                                `IS_W_REG;
                        STOP <= `IS_R_RAM || 
                                `IS_W_RAM ||
                                `IS_R_REG ||
                                `IS_W_REG ||
                                (`IS_FI && (~ST0 || ST0 && `IN_STP));
                        DRW <= `IS_W_REG || 
                                (`IS_FI && ST0 &&
                                    (`IN_ADD || 
                                    `IN_SUB || 
                                    `IN_AND || 
                                    `IN_INC || 
                                    `IN_MOV ||
                                    `IN_NOT || 
                                    `IN_OR));
                        SBUS <= `IS_W_RAM || 
                                (`IS_R_RAM && ~ST0) ||
                                `IS_W_REG ||
                                (`IS_FI && ~ST0);
                        LDZ <= `IS_FI && ST0 && 
                                    (`IN_ADD || 
                                    `IN_SUB ||
                                    `IN_AND ||
                                    `IN_INC ||
                                    `IN_CMP);
                        LDC <= `IS_FI && ST0 &&
                                    (`IN_ADD || 
                                    `IN_SUB || 
                                    `IN_INC || 
                                    `IN_CMP|| 
                                    `IN_NOT ||
                                    `IN_OR);
                        S[3] <= `IS_FI && ST0 && 
                                    (`IN_ADD ||
                                    `IN_AND ||
                                    `IN_MOV ||
                                    `IN_JMP ||
                                    `IN_LD ||
                                    `IN_ST ||
                                    `IN_OR||
                                    `IN_OUT);
                        S[2] <= `IS_FI && ST0 && 
                                    (`IN_SUB ||
                                    `IN_CMP ||
                                    `IN_JMP ||
                                    `IN_ST ||
                                    `IN_OR);
                        S[1] <= `IS_FI && ST0 && 
                                    (`IN_SUB ||
                                    `IN_AND ||
                                    `IN_MOV ||
                                    `IN_CMP ||
                                    `IN_JMP ||
                                    `IN_LD ||
                                    `IN_ST ||
                                    `IN_OR ||
                                    `IN_OUT);
                        S[0] <= `IS_FI && ST0 && 
                                    (`IN_ADD ||
                                    `IN_AND ||
                                    `IN_JMP ||
                                    `IN_ST);
                        SEL[3] <= `IS_W_REG && ST0;
                        SEL[2] <= 0;
                        SEL[1] <= `IS_W_REG && ~ST0;
                        SEL[0] <= `IS_R_REG ||
                                `IS_W_REG;
                        LPC <= `IS_FI && (~ST0 || ST0 && `IN_JMP);
                        LIR <= `IS_FI && ST0 &&
                                    (`IN_NOP || 
                                    `IN_AND ||
                                    `IN_INC ||
                                    `IN_MOV ||
                                    `IN_CMP ||
                                    `IN_JC && ~C || 
                                    `IN_JZ && ~Z ||
                                    `IN_NOT ||
                                    `IN_OR || 
                                    `IN_OUT);
                        PCINC <= `IS_FI && ST0 &&
                                    (`IN_NOP || 
                                    `IN_AND ||
                                    `IN_INC || 
                                    `IN_MOV || 
                                    `IN_CMP || 
                                    `IN_JC && ~C ||
                                    `IN_JZ && ~Z || 
                                    `IN_NOT || 
                                    `IN_OR || 
                                    `IN_OUT);
                        SHORT <= `IS_W_RAM || 
                                `IS_R_RAM || 
                                `IS_FI && ST0 &&
                                    (`IN_NOP || 
                                    `IN_AND || 
                                    `IN_INC || 
                                    `IN_MOV || 
                                    `IN_CMP || 
                                    `IN_JC && ~C || 
                                    `IN_JZ && ~Z || 
                                    `IN_NOT || 
                                    `IN_OR || 
                                    `IN_OUT);
                        PCADD <= `IS_FI && ST0 && 
                                    (C && `IN_JC || 
                                    Z && `IN_JZ);
                        SST0 <= (`IS_W_RAM && ~ST0) ||
                                (`IS_R_RAM && ~ST0);
                        LAR <= (`IS_W_RAM && ~ST0) ||
                                (`IS_R_RAM && ~ST0) ||
                                (`IS_FI && ST0 &&
                                    (`IN_ST || 
                                    `IN_LD));
                        MEMW <= `IS_W_RAM && ST0;
                        ARINC <= (`IS_W_RAM && ST0) ||
                                (`IS_R_RAM && ST0);
                        MBUS <= `IS_R_RAM && ST0;
                        CIN <= `IS_FI && ST0 && `IN_ADD;
                        ABUS <= `IS_FI && ST0 && 
                                    (`IN_ADD || 
                                    `IN_SUB ||
                                    `IN_AND || 
                                    `IN_INC || 
                                    `IN_MOV || 
                                    `IN_CMP || 
                                    `IN_JMP || 
                                    `IN_LD || 
                                    `IN_ST || 
                                    `IN_NOT || 
                                    `IN_OR || 
                                    `IN_OUT);
                        M <= `IS_FI && ST0 && (`IN_AND ||
                                    `IN_MOV || 
                                    `IN_JMP || 
                                    `IN_LD || 
                                    `IN_ST ||
                                    `IN_NOT || 
                                    `IN_OR || 
                                    `IN_OUT);
                        LONG <= 0;
                    end
                end
                3'b100:begin
                        SELCTL <= `IS_R_RAM || 
                                `IS_W_RAM ||
                                `IS_R_REG ||
                                `IS_W_REG;
                        STOP <= `IS_R_RAM || 
                                `IS_W_RAM ||
                                `IS_R_REG ||
                                `IS_W_REG ||
                                (`IS_FI && (~ST0 || ST0 && `IN_STP));
                        DRW <= `IS_W_REG || 
                                (`IS_FI && ST0 &&
                                    (`IN_ADD || 
                                    `IN_SUB || 
                                    `IN_AND || 
                                    `IN_INC || 
                                    `IN_MOV ||
                                    `IN_NOT || 
                                    `IN_OR));
                        SBUS <= `IS_W_RAM || 
                                (`IS_R_RAM && ~ST0) ||
                                `IS_W_REG ||
                                (`IS_FI && ~ST0);
                        LDZ <= `IS_FI && ST0 && 
                                    (`IN_ADD || 
                                    `IN_SUB ||
                                    `IN_AND ||
                                    `IN_INC ||
                                    `IN_CMP);
                        LDC <= `IS_FI && ST0 &&
                                    (`IN_ADD || 
                                    `IN_SUB || 
                                    `IN_INC || 
                                    `IN_CMP|| 
                                    `IN_NOT ||
                                    `IN_OR);
                        S[3] <= `IS_FI && ST0 && 
                                    (`IN_ADD ||
                                    `IN_AND ||
                                    `IN_MOV ||
                                    `IN_JMP ||
                                    `IN_LD ||
                                    `IN_ST ||
                                    `IN_OR||
                                    `IN_OUT);
                        S[2] <= `IS_FI && ST0 && 
                                    (`IN_SUB ||
                                    `IN_CMP ||
                                    `IN_JMP ||
                                    `IN_ST ||
                                    `IN_OR);
                        S[1] <= `IS_FI && ST0 && 
                                    (`IN_SUB ||
                                    `IN_AND ||
                                    `IN_MOV ||
                                    `IN_CMP ||
                                    `IN_JMP ||
                                    `IN_LD ||
                                    `IN_ST ||
                                    `IN_OR ||
                                    `IN_OUT);
                        S[0] <= `IS_FI && ST0 && 
                                    (`IN_ADD ||
                                    `IN_AND ||
                                    `IN_JMP ||
                                    `IN_ST);
                        SEL[3] <= `IS_W_REG && ST0;
                        SEL[2] <= 0;
                        SEL[1] <= `IS_W_REG && ~ST0;
                        SEL[0] <= `IS_R_REG ||
                                `IS_W_REG;
                        LPC <= `IS_FI && (~ST0 || ST0 && `IN_JMP);
                        LIR <= `IS_FI && ST0 &&
                                    (`IN_NOP || 
                                    `IN_AND ||
                                    `IN_INC ||
                                    `IN_MOV ||
                                    `IN_CMP ||
                                    `IN_JC && ~C || 
                                    `IN_JZ && ~Z ||
                                    `IN_NOT ||
                                    `IN_OR || 
                                    `IN_OUT);
                        PCINC <= `IS_FI && ST0 &&
                                    (`IN_NOP || 
                                    `IN_AND ||
                                    `IN_INC || 
                                    `IN_MOV || 
                                    `IN_CMP || 
                                    `IN_JC && ~C ||
                                    `IN_JZ && ~Z || 
                                    `IN_NOT || 
                                    `IN_OR || 
                                    `IN_OUT);
                        SHORT <= `IS_W_RAM || 
                                `IS_R_RAM || 
                                `IS_FI && ST0 &&
                                    (`IN_NOP || 
                                    `IN_AND || 
                                    `IN_INC || 
                                    `IN_MOV || 
                                    `IN_CMP || 
                                    `IN_JC && ~C || 
                                    `IN_JZ && ~Z || 
                                    `IN_NOT || 
                                    `IN_OR || 
                                    `IN_OUT);
                        PCADD <= `IS_FI && ST0 && 
                                    (C && `IN_JC || 
                                    Z && `IN_JZ);
                        SST0 <= (`IS_W_RAM && ~ST0) ||
                                (`IS_R_RAM && ~ST0);
                        LAR <= (`IS_W_RAM && ~ST0) ||
                                (`IS_R_RAM && ~ST0) ||
                                (`IS_FI && ST0 &&
                                    (`IN_ST || 
                                    `IN_LD));
                        MEMW <= `IS_W_RAM && ST0;
                        ARINC <= (`IS_W_RAM && ST0) ||
                                (`IS_R_RAM && ST0);
                        MBUS <= `IS_R_RAM && ST0;
                        CIN <= `IS_FI && ST0 && `IN_ADD;
                        ABUS <= `IS_FI && ST0 && 
                                    (`IN_ADD || 
                                    `IN_SUB ||
                                    `IN_AND || 
                                    `IN_INC || 
                                    `IN_MOV || 
                                    `IN_CMP || 
                                    `IN_JMP || 
                                    `IN_LD || 
                                    `IN_ST || 
                                    `IN_NOT || 
                                    `IN_OR || 
                                    `IN_OUT);
                        M <= `IS_FI && ST0 && (`IN_AND ||
                                    `IN_MOV || 
                                    `IN_JMP || 
                                    `IN_LD || 
                                    `IN_ST ||
                                    `IN_NOT || 
                                    `IN_OR || 
                                    `IN_OUT);
                        LONG <= 0;
                end
                default:begin
                    {SST0,SBUS, LAR, STOP, SHORT, SELCTL, MEMW,
                    ARINC, MBUS, DRW, LPC, LIR, PCINC, 
                    CIN, ABUS, PCADD, M, LONG, LDZ, LDC} <=0;
                    S <= 0;
                    SEL <= 0;
                end
            endcase
        end
    end
endmodule