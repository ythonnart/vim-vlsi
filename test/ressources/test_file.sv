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
    parameter machin = {1, 0, 3},
    parameter chose = 10 , //hello
    parameter thing={1,0} // unused comment
)(
);
endmodule
// end generics_multi
