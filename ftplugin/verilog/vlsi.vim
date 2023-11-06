" Load specific functions for verilog entity yank/paste
let b:VlsiYank              = function('vlsi#v_sv#Yank')
let b:VlsiPasteAsDefinition = function('vlsi#GenericPaste',[vlsi#v_sv#formatPatterns.definition])
let b:VlsiPasteAsInstance   = function('vlsi#GenericPaste',[vlsi#v_sv#formatPatterns.instance])
let b:VlsiPasteSignals      = function('vlsi#GenericPaste',[vlsi#v_sv#formatPatterns.signals])
let b:vlsi_config           = #{
            \ language            : 'verilog',
            \ comment             : "//",
            \ default_scalar_type : 'wire',
            \ default_vector_type : 'wire',
            \ entity_regexp       : #{begin:'\c^\s*\(module\)', end:'\c^\s*endmodule'},
            \ kind2dir            : #{i: 'input', o: 'output', io: 'inout'},
            \ formatRange         : function("vlsi#v_sv#formatRange")}

" Create default bindings
call vlsi#Bindings()

" Tagbar ctags configuration
let g:tagbar_type_verilog = {
    \ 'ctagsbin' : expand('<sfile>:p:h:h:h') . '/bin/ctags/systemverilog.pl',
    \ 'kinds'     : [
        \ 'h:headers:1:0',
        \ 'd:macros:1:0',
        \ 't:typedefs:1:0',
        \ 'I:interfaces:1:0',
        \ 'm:modules:1:0',
        \ 'g:parameters:1:0',
        \ 'p:ports:1:0',
        \ 'P:modports:1:0',
        \ 's:signals:1:0',
        \ 'i:instances:1:0',
        \ 'r:processes:1:0',
    \ ],
    \ 'sro'        : '::',
    \ 'scope2kind' : {
        \ 'module'       : 'm',
        \ 'interface'    : 'I',
        \ 'parameter'    : 'g',
        \ 'port'         : 'p',
        \ 'signal'       : 's',
        \ 'modport'      : 'P',
        \ 'instance'     : 'i',
        \ 'process'      : 'r',
    \ },
    \ 'kind2scope' : {
        \ 'm' : 'module',
        \ 'I' : 'interface',
        \ 'g' : 'parameter',
        \ 'p' : 'port',
        \ 's' : 'signal',
        \ 'P' : 'modport',
        \ 'i' : 'instance',
        \ 'r' : 'process',
    \ },
\ }

