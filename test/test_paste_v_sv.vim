" Test suite for VlsiYank for SystemVerilog
" Install https://github.com/laurentalacoque/vim-unittest (fixed version of 
" https://github.com/h1mesuke/vim-unittest)
" Run :UnitTest <this file>
"
" where are we?
let s:here= expand('<sfile>:p:h')

"--------------------------------------------------------------------------------
" Helper functions
"--------------------------------------------------------------------------------
" {{{ 1
function! s:get_canonical(tag) dict
 " get the line array
 let line_array = self.data.get(a:tag)
 " remove comments
 for i in range( len(line_array) )
     let line_array[i] = substitute(line_array[i],'\/\/.*$','','g')
 endfor
 " join with spaces
 let line = join(line_array, ' ')
 " substitute multispaces as single space
 let line = trim(substitute(line,'\s\+',' ','g'))
 return line
endfunction

" s:test_paste("module ...", "modg0p0", "VlsiPasteAsDefinition")
" pastes module "modg0p0" in 'scratchpad' location
" Get the pasted text and compare it to a:wanted
function! s:test_paste_equals(wanted, entity_name, paste_command) dict
    " go to scratchpad
    call self.data.goto('scratchpad')
    exec a:paste_command .. " " .. a:entity_name
    " retrieve pasted text
    let pasted = self.get_canonical('scratchpad')
    call self.assert_equal(a:wanted, pasted, '['.. a:entity_name ..'] Paste failed for command' .. a:paste_command)
endfunction


" create test functions
function! s:install_test_functions()
    for module_name in keys(s:default_modules)
        for command_name in keys(s:reference[module_name])
            let test_fn_name = "test_systemverilog_" .. command_name .. "_" .. module_name
            let s:tc[test_fn_name] = function('s:test_paste_equals',
                 \ [s:reference[module_name][command_name],module_name, command_name])
        endfor
        for command_name in keys(s:reference_verilog[module_name])
            let test_fn_name = "test_verilog_" .. command_name .. "_" .. module_name
            let s:tc_v[test_fn_name] = function('s:test_paste_equals',
                 \ [s:reference_verilog[module_name][command_name],module_name, command_name])
        endfor
    endfor
endfunction
" }}}

"--------------------------------------------------------------------------------
" Testcases
"--------------------------------------------------------------------------------
"systemverilog
let s:tc  = unittest#testcase#new("Test VlsiPaste functions for SystemVerilog", {'data' : s:here .. '/ressources/test_file.sv'})
"verilog
let s:tc_v = unittest#testcase#new("Test VlsiPaste functions for Verilog",      {'data' : s:here .. '/ressources/test_file.v'})

"--------------------------------------------------------------------------------
" Unittest function auto-generation
"--------------------------------------------------------------------------------
" {{{ 1

" DATA TO PASTE
" {{{ 2
let s:default_interface = {'if': 
            \ {'generics': [], 
                \ 'modports': {'slave': [
                    \ {'dir': 'i', 'name': 'sig1', 'type': 'logic', 'range': '31{{:}}0'},
                    \ {'dir': 'o', 'name': 'sig2', 'type': 'logic', 'range': 0         }]
                \ }, 'ports_by_name': {'sig1': {'dir': 'io', 'name': 'sig1', 'type': 'logic', 'range': '31{{:}}0'}, 'sig2': {'dir': 'io', 'name': 'sig2', 'type': 'logic', 'range': 0}}, 
                \ 'ports': [
                    \ {'dir': 'io', 'name': 'sig1', 'type': 'logic', 'range': '31{{:}}0'},
                    \ {'dir': 'io', 'name': 'sig2', 'type': 'logic', 'range': 0         }], 
                \'lang': 'systemverilog'}}

" Modules to paste
let s:default_modules = #{
        \ modg0p0: #{
            \ lang     : 'systemverilog',
            \ generics : [],
            \ ports    : [],
        \ },
        \
        \ modg0p1: #{
            \ lang     : 'systemverilog',
            \ generics : [],
            \ ports    : [
                \#{ name:'port1', type:'', range:'', dir:'i' },
            \ ],
        \ },
        \
        \ modg0p1_with_range: #{
            \ lang     : 'systemverilog',
            \ generics : [],
            \ ports    : [
                \#{ name:'port1', type:'', range:'size{{:}}0', dir:'i' },
            \ ],
        \ },
        \
        \ modg0p1_with_interface: #{
            \ lang     : 'systemverilog',
            \ generics : [],
            \ ports    : [
                \#{ name:'port1', type:'if.slave', range:'', dir:'i' },
            \ ],
        \ },
        \
        \ modg1p0: #{
            \ lang     : 'systemverilog',
            \ generics : [
                \ #{ name:'param1', type:'natural', value:'1'},
            \ ],
            \ ports    : []
        \ },
        \
        \ modg1p1: #{
            \ lang     : 'systemverilog',
            \ generics : [
                \ #{ name:'param1', type:'natural', value:'1'},
            \ ],
            \ ports    : [
                \#{ name:'port1', type:'', range:'', dir:'i' },
            \ ],
        \ },
        \ modg2p0: #{
            \ lang     : 'systemverilog',
            \ generics : [
                \ #{ name:'param1', type:'natural', value:'1'},
                \ #{ name:'param2', type:'natural', value:'2'},
            \ ],
            \ ports    : []
        \ },
        \
        \ modg0p3: #{
            \ lang     : 'systemverilog',
            \ generics : [],
            \ ports    : [
                \#{ name:'port1', type:'', range:'', dir:'i' },
                \#{ name:'port2', type:'', range:'', dir:'o' },
                \#{ name:'port3', type:'', range:'', dir:'io' },
            \ ],
        \ },
        \
        \ modg2p3: #{
            \ lang     : 'systemverilog',
            \ generics : [
                \ #{ name:'param1', type:'natural', value:'1'},
                \ #{ name:'param2', type:'natural', value:'2'},
            \ ],
            \ ports    : [
                \#{ name:'port1', type:'', range:'', dir:'i' },
                \#{ name:'port2', type:'', range:'', dir:'o' },
                \#{ name:'port3', type:'', range:'', dir:'io' },
            \ ],
        \ },
\ }
" }}} 
"
" REFERENCE DATA
" {{{ 2

" Reference for SystemVerilog
let s:reference = #{
            \ modg0p0 : #{
                \ VlsiPasteAsDefinition : "module modg0p0; endmodule",
                \ VlsiPasteAsInstance   : "modg0p0 u_modg0p0;",
                \ VlsiPasteSignals      : "",
            \},
            \ modg0p1 : #{
                \ VlsiPasteAsDefinition : "module modg0p1 ( input logic port1 ); endmodule",
                \ VlsiPasteAsInstance   : "modg0p1 u_modg0p1 ( .port1 (port1) );",
                \ VlsiPasteSignals      : "logic port1;",
            \},
            \ modg0p1_with_range : #{
                \ VlsiPasteAsDefinition : "module modg0p1_with_range ( input logic [size:0] port1 ); endmodule",
                \ VlsiPasteAsInstance   : "modg0p1_with_range u_modg0p1_with_range ( .port1 (port1) );",
                \ VlsiPasteSignals      : "logic [size:0] port1;",
            \},
            \ modg0p1_with_interface : #{
                \ VlsiPasteAsDefinition : "module modg0p1_with_interface ( if.slave port1 ); endmodule",
                \ VlsiPasteAsInstance   : "modg0p1_with_interface u_modg0p1_with_interface ( .port1 (port1) );",
                \ VlsiPasteSignals      : "if.slave port1;",
            \},
            \ modg1p0 : #{
                \ VlsiPasteAsDefinition : "module modg1p0 #( parameter param1 = 1 ); endmodule",
                \ VlsiPasteAsInstance   : "modg1p0 #( .param1 (1) ) u_modg1p0;",
                \ VlsiPasteSignals      : "",
            \},
            \ modg1p1 : #{
                \ VlsiPasteAsDefinition : "module modg1p1 #( parameter param1 = 1 ) ( input logic port1 ); endmodule",
                \ VlsiPasteAsInstance   : "modg1p1 #( .param1 (1) ) u_modg1p1 ( .port1 (port1) );",
                \ VlsiPasteSignals      : "logic port1;",
            \},
            \ modg2p0 : #{
                \ VlsiPasteAsDefinition : "module modg2p0 #( parameter param1 = 1, parameter param2 = 2 ); endmodule",
                \ VlsiPasteAsInstance   : "modg2p0 #( .param1 (1), .param2 (2) ) u_modg2p0;",
                \ VlsiPasteSignals      : "",
            \},
            \ modg0p3 : #{
                \ VlsiPasteAsDefinition : "module modg0p3 ( input logic port1, output logic port2, inout logic port3 ); endmodule",
                \ VlsiPasteAsInstance   : "modg0p3 u_modg0p3 ( .port1 (port1), .port2 (port2), .port3 (port3) );",
                \ VlsiPasteSignals      : "logic port1; logic port2; logic port3;",
            \},
            \ modg2p3 : #{
                \ VlsiPasteAsDefinition : "module modg2p3 #( parameter param1 = 1, parameter param2 = 2 ) ( input logic port1, output logic port2, inout logic port3 ); endmodule",
                \ VlsiPasteAsInstance   : "modg2p3 #( .param1 (1), .param2 (2) ) u_modg2p3 ( .port1 (port1), .port2 (port2), .port3 (port3) );",
                \ VlsiPasteSignals      : "logic port1; logic port2; logic port3;",
            \},
\}

" Reference for Verilog
let s:reference_verilog = #{
            \ modg0p0 : #{
                \ VlsiPasteAsDefinition : "module modg0p0; endmodule",
                \ VlsiPasteAsInstance   : "modg0p0 u_modg0p0;",
                \ VlsiPasteSignals      : "",
            \},
            \ modg0p1 : #{
                \ VlsiPasteAsDefinition : "module modg0p1 ( input wire port1 ); endmodule",
                \ VlsiPasteAsInstance   : "modg0p1 u_modg0p1 ( .port1 (port1) );",
                \ VlsiPasteSignals      : "wire port1;",
            \},
            \ modg0p1_with_range : #{
                \ VlsiPasteAsDefinition : "module modg0p1_with_range ( input wire [size:0] port1 ); endmodule",
                \ VlsiPasteAsInstance   : "modg0p1_with_range u_modg0p1_with_range ( .port1 (port1) );",
                \ VlsiPasteSignals      : "wire [size:0] port1;",
            \},
            \ modg0p1_with_interface : #{
                \ VlsiPasteAsDefinition : "module modg0p1_with_interface ( input wire [31:0] port1_sig1, output wire port1_sig2 ); endmodule",
                \ VlsiPasteAsInstance   : "modg0p1_with_interface u_modg0p1_with_interface ( .port1_sig1 (port1_sig1), .port1_sig2 (port1_sig2) );",
                \ VlsiPasteSignals      : "wire [31:0] port1_sig1; wire port1_sig2;",
            \},
            \ modg1p0 : #{
                \ VlsiPasteAsDefinition : "module modg1p0 #( parameter param1 = 1 ); endmodule",
                \ VlsiPasteAsInstance   : "modg1p0 #( .param1 (1) ) u_modg1p0;",
                \ VlsiPasteSignals      : "",
            \},
            \ modg1p1 : #{
                \ VlsiPasteAsDefinition : "module modg1p1 #( parameter param1 = 1 ) ( input wire port1 ); endmodule",
                \ VlsiPasteAsInstance   : "modg1p1 #( .param1 (1) ) u_modg1p1 ( .port1 (port1) );",
                \ VlsiPasteSignals      : "wire port1;",
            \},
            \ modg2p0 : #{
                \ VlsiPasteAsDefinition : "module modg2p0 #( parameter param1 = 1, parameter param2 = 2 ); endmodule",
                \ VlsiPasteAsInstance   : "modg2p0 #( .param1 (1), .param2 (2) ) u_modg2p0;",
                \ VlsiPasteSignals      : "",
            \},
            \ modg0p3 : #{
                \ VlsiPasteAsDefinition : "module modg0p3 ( input wire port1, output wire port2, inout wire port3 ); endmodule",
                \ VlsiPasteAsInstance   : "modg0p3 u_modg0p3 ( .port1 (port1), .port2 (port2), .port3 (port3) );",
                \ VlsiPasteSignals      : "wire port1; wire port2; wire port3;",
            \},
            \ modg2p3 : #{
                \ VlsiPasteAsDefinition : "module modg2p3 #( parameter param1 = 1, parameter param2 = 2 ) ( input wire port1, output wire port2, inout wire port3 ); endmodule",
                \ VlsiPasteAsInstance   : "modg2p3 #( .param1 (1), .param2 (2) ) u_modg2p3 ( .port1 (port1), .port2 (port2), .port3 (port3) );",
                \ VlsiPasteSignals      : "wire port1; wire port2; wire port3;",
            \},
\}

" }}}
" }}}
"--------------------------------------------------------------------------------
" Setup and Teardown
"--------------------------------------------------------------------------------
" {{{ 1
""" Once SETUP
function! s:tc.SETUP()
    " define markers for data accessors
    call self.puts("Setting marker format for SystemVerilog")
    let self.data.marker_formats = ['// begin %s', '// end %s']
    let s:tc.get_canonical = function ('s:get_canonical')
endfunction
function! s:tc_v.SETUP()
    " define markers for data accessors
    call self.puts("Setting marker format for Verilog")
    let self.data.marker_formats = ['// begin %s', '// end %s']
    let s:tc_v.get_canonical = function ('s:get_canonical')
endfunction

""" every test setup
function! s:tc.setup()
    " Always start with a predefined module
    let g:modules    = s:default_modules
    let g:interfaces = s:default_interface
endfunction

function! s:tc_v.setup()
    " Always start with a predefined module
    let g:modules    = s:default_modules
    let g:interfaces = s:default_interface
endfunction

" }}}

""" test functions

call s:install_test_functions()

" vim: :fdm=marker
