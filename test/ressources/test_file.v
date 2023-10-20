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

// begin generics_multi
module generics_multi #(
    parameter truc = 4,
    //unused comment
    parameter machin = 33,
    parameter chose = 10 , //hello
    parameter thing=8 // unused comment
)(
);
endmodule
// end generics_multi

////////////////////////////////////////////////////////////////////////////////
// Ports test (fully qualified)
////////////////////////////////////////////////////////////////////////////////
// begin port1
module port1 (
    input wire port1);
endmodule
// end port1

// begin port1a
module port1a (input wire port1);
endmodule
// end port1a

// begin port1b
module port1b (
    input wire port1
);
endmodule
// end port1b

// begin ports_multi
module ports_multi (
    input wire port1,
    output wire port2,
    inout wire port3
);
endmodule
// end ports_multi



////////////////////////////////////////////////////////////////////////////////
// Ports and generics test (typedef type)
////////////////////////////////////////////////////////////////////////////////

// begin pg1
module pg1 #(
    parameter param1 = 4)(
    input wire port1);
endmodule
// end pg1

// begin pg1a
module pg1a #(parameter param1 = 4)(input wire port1);
endmodule
// end pg1a

// begin pg1b
module pg1b #(
    parameter param1 = 4
)(input wire port1);
endmodule
// end pg1b

// begin pgs_multi
module pgs_multi #(
    parameter truc = 4,
    //unused comment
    parameter machin = 33,
    parameter chose = 10 , //hello
    parameter thing=8 // unused comment
)(
    input wire port1,
    output wire port2,
    inout wire port3
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
    input wire [BUS_WIDTH-1:0] bus,
    input wire [31:0]          bus2
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
// begin pdt2
module pdt2 (
    input port1, port2, output port3, inout port4
);
endmodule
// end pdt2
