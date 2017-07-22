" Load specific functions for VHDL entity yank/paste
let b:VlsiYank              = function('vlsi#verilog#Yank')
let b:VlsiPasteAsDefinition = function('vlsi#verilog#PasteAsModule')
let b:VlsiPasteAsInstance   = function('vlsi#verilog#PasteAsInstance')
 
" Create default bindings
call vlsi#Bindings()
