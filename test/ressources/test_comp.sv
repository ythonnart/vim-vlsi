////////////////////////////////////////////////////////////////////////////////
// compilation test
////////////////////////////////////////////////////////////////////////////////

interface ifmp1;
    logic [31:0] sig1;
    logic sig2;
    modport master (
        output sig1
    );
    modport slave (
        input  sig1,
        output sig2
    );
endinterface
// end ifmp1


////////////////////////////////////////////////////////////////////////////////
// Scratchpad zone for Paste functions, please leave tag
////////////////////////////////////////////////////////////////////////////////

// begin scratchpad

// end scratchpad
