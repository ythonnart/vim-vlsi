////////////////////////////////////////////////////////////////////////////////
// Generics test
////////////////////////////////////////////////////////////////////////////////


// begin minimal
module minimal;
endmodule
// end minimal

// begin generic1
module generic1 #(
    parameter param1 = 4);
endmodule
// end generic1

// begin generic1a
module generic1a #(parameter param1 = 4);
endmodule
// end generic1a

// begin generic1b
module generic1b #(
    parameter param1 = 4
)();
endmodule
// end generic1b

// begin generic_special_val
module generic_special_val #(
    parameter param1 = {1,0,3}
)();
endmodule
// end generic_special_val

// begin generics_multi
module generics_multi #(
    parameter truc = 4,
    //unused comment
    parameter machin = 33,
    parameter chose = 10 , //hello
    parameter thing= 6 // unused comment
)(
);
endmodule
// end generics_multi

// begin generics_in_body
module generics_in_body;
    parameter param1 = 1;
    parameter param2 = 2;
endmodule
// end generics_in_body

////////////////////////////////////////////////////////////////////////////////
// Ports test (fully qualified)
////////////////////////////////////////////////////////////////////////////////
// begin port1
module port1 (
    input logic port1);
endmodule
// end port1

// begin port1a
module port1a (input logic port1);
endmodule
// end port1a

// begin port1b
module port1b (
    input logic port1
);
endmodule
// end port1b

// begin ports_multi
module ports_multi (
    input logic port1,
    output logic port2,
    inout logic port3
);
endmodule
// end ports_multi

// begin ports_multi_in_body
module ports_multi_in_body (
    port1, port2, port3
);
    input logic port1;
    output logic port2;
    inout logic port3;
endmodule
// end ports_multi_in_body



////////////////////////////////////////////////////////////////////////////////
// Ports test (typedef type)
////////////////////////////////////////////////////////////////////////////////
typedef logic mytype;
// begin porttype1
module porttype1 (
    input mytype port1);
endmodule
// end porttype1

// begin porttype1a
module porttype1a (input mytype port1);
endmodule
// end porttype1a

// begin porttype1b
module porttype1b (
    input mytype port1
);
endmodule
// end porttype1b

// begin porttypes_multi
module porttypes_multi (
    input mytype port1,
    output mytype port2,
    inout mytype port3
);
endmodule
// end porttypes_multi

////////////////////////////////////////////////////////////////////////////////
// Ports and generics test (typedef type)
////////////////////////////////////////////////////////////////////////////////

// begin pg1
module pg1 #(
    parameter param1 = 4)(
    input logic port1);
endmodule
// end pg1

// begin pg1a
module pg1a #(parameter param1 = 4)(input logic port1);
endmodule
// end pg1a

// begin pg1b
module pg1b #(
    parameter param1 = 4
)(input logic port1);
endmodule
// end pg1b

// begin pgs_multi
module pgs_multi #(
    parameter truc = 4,
    //unused comment
    parameter machin = 33,
    parameter chose = 10 , //hello
    parameter thing=6 // unused comment
)(
    input logic port1,
    output logic port2,
    inout logic port3
);
endmodule
// end pgs_multi

////////////////////////////////////////////////////////////////////////////////
// Ports with range
////////////////////////////////////////////////////////////////////////////////

// begin pr1
module pr1 #(
    parameter BUS_WIDTH = 32
    ) (
    input logic [BUS_WIDTH-1:0] bus,
    input logic [31:0]          bus2
);
endmodule
// end pr1

////////////////////////////////////////////////////////////////////////////////
// Ports with default type
////////////////////////////////////////////////////////////////////////////////

// begin pdt
module pdt (
    input port1,
    output [3:0] port2,
    inout port3
);
endmodule
// end pdt
//
// begin pdt1
module pdt1 (
    input port1, port2,
    output port3,
    inout port4
);
endmodule
// end pdt1
//
// begin pdt2
module pdt2 (
    input port1, port2, output port3, inout port4
);
endmodule
// end pdt2

////////////////////////////////////////////////////////////////////////////////
// Interfaces definition
////////////////////////////////////////////////////////////////////////////////

// begin if1
interface if1;
    logic [31:0] sig1;
    logic sig2;
endinterface
// end if1

// begin if1g
interface if1g #(
    parameter gen1 = 32
);
    logic [gen1:0] sig1;
    logic sig2;
endinterface
// end if1g

// begin ifmp1
interface ifmp1;
    logic [31:0] sig1;
    logic sig2;
    modport master (
        output sig1
    );
    modport slave (
        input sig1,
        output sig2
    );
endinterface
// end ifmp1
