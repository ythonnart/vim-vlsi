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
    parameter machin = {1, 0, 3},
    parameter chose = 10 , //hello
    parameter thing={1,0} // unused comment
)(
);
endmodule
// end generics_multi

////////////////////////////////////////////////////////////////////////////////
// Ports test
////////////////////////////////////////////////////////////////////////////////
///// Fully qualified
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


typedef logic mytype;
///// alternate type
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
