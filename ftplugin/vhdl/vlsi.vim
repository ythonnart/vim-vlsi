" Load specific functions for VHDL entity yank/paste
let b:VlsiYank             = function('vlsi#vhdl#Yank')
let b:VlsiPasteAsEntity    = function('vlsi#vhdl#PasteAsEntity')
let b:VlsiPasteAsComponent = function('vlsi#vhdl#PasteAsComponent')
let b:VlsiPasteAsInstance  = function('vlsi#vhdl#PasteAsInstance')
 
" Create default bindings
call vlsi#Bindings()
