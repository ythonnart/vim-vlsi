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
function! s:get_canonical(comment_start, tag) dict
 " get the line array
 let line_array = self.data.get(a:tag)
 " remove comments
 for i in range( len(line_array) )
     let line_array[i] = substitute(line_array[i],a:comment_start ..'.*$','','g')
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
    call self.assert_equal(a:wanted, pasted, '['.. a:entity_name ..'] Paste failed for command ' .. a:paste_command)
endfunction


" create test functions
function! s:install_test_functions()
    for module_name in keys(s:default_modules)
        "systemverilog
        for command_name in keys(s:reference[module_name])
            let test_fn_name = "test_systemverilog_" .. command_name .. "_" .. module_name
            let s:tc[test_fn_name] = function('s:test_paste_equals',
                 \ [s:reference[module_name][command_name],module_name, command_name])
        endfor
        " verilog
        for command_name in keys(s:reference_verilog[module_name])
            let test_fn_name = "test_verilog_" .. command_name .. "_" .. module_name
            let s:tc_v[test_fn_name] = function('s:test_paste_equals',
                 \ [s:reference_verilog[module_name][command_name],module_name, command_name])
        endfor
        " verilog prefix / suffix
        for command_name in keys(s:reference_verilog_prefix_suffix[module_name])
            let elements = split(command_name)
            let cmd = elements[0]
            let exec_command = join([cmd, module_name, elements[1], elements[2]])
            let test_fn_name = "test_verilog_prefix_suffix_" .. cmd .. "_" .. module_name
            let s:tc_v[test_fn_name] = function('s:test_paste_equals',
                 \ [s:reference_verilog_prefix_suffix[module_name][command_name],module_name, exec_command])
        endfor
        " vhdl
        for command_name in keys(s:reference_vhdl[module_name])
            let test_fn_name = "test_vhdl_" .. command_name .. "_" .. module_name
            let s:tc_vhdl[test_fn_name] = function('s:test_paste_equals',
                 \ [s:reference_vhdl[module_name][command_name],module_name, command_name])
        endfor
    endfor
    " vhdl with prefix and suffix
    for module_name in keys(s:reference_vhdl_prefix_suffix)
        for command_name in keys(s:reference_vhdl_prefix_suffix[module_name])
            let test_fn_name = "test_vhdl_prefix_suffix_" .. command_name .. "_" .. module_name
            let command = command_name .. " " .. module_name .." _s p_"
            let s:tc_vhdl[test_fn_name] = function('s:test_paste_equals',
                 \ [s:reference_vhdl_prefix_suffix[module_name][command_name],module_name, command])
        endfor
    endfor
endfunction
" }}}

"--------------------------------------------------------------------------------
" Testcases
"--------------------------------------------------------------------------------
"systemverilog
let s:tc      = unittest#testcase#new("Test VlsiPaste functions for SystemVerilog", {'data' : s:here .. '/ressources/test_file.sv'})
"systemverilog-compile
let s:co_sverilog = unittest#testcase#new("SystemVerilog compilation for VlsiPaste functions")
"verilog
let s:tc_v    = unittest#testcase#new("Test VlsiPaste functions for Verilog",       {'data' : s:here .. '/ressources/test_file.v'})
"verilog-compile
let s:co_verilog = unittest#testcase#new("Verilog compilation for VlsiPaste functions")
"vhdl
let s:tc_vhdl = unittest#testcase#new("Test VlsiPaste functions for Vhdl",          {'data' : s:here .. '/ressources/test_file.vhd'})
"vhdl-compile
let s:co_vhdl = unittest#testcase#new("VHDL compilation for VlsiPaste functions")

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

" Reference for Verilog with prefix and suffix
let s:reference_verilog_prefix_suffix = #{
            \ modg0p0 : {
                \ "VlsiPasteAsInstance _s p_"   : "modg0p0 u_p_modg0p0_s;",
                \ "VlsiPasteSignals _s p_"      : "",
            \},
            \ modg0p1 : {
                \ "VlsiPasteAsInstance _s p_"   : "modg0p1 u_p_modg0p1_s ( .port1 (p_port1_s) );",
                \ "VlsiPasteSignals _s p_"      : "wire p_port1_s;",
            \},
            \ modg0p1_with_range : {
                \ "VlsiPasteAsInstance _s p_"   : "modg0p1_with_range u_p_modg0p1_with_range_s ( .port1 (p_port1_s) );",
                \ "VlsiPasteSignals _s p_"      : "wire [size:0] p_port1_s;",
            \},
            \ modg0p1_with_interface : {
                \ "VlsiPasteAsInstance _s p_"   : "modg0p1_with_interface u_p_modg0p1_with_interface_s ( .port1_sig1 (p_port1_sig1_s), .port1_sig2 (p_port1_sig2_s) );",
                \ "VlsiPasteSignals _s p_"      : "wire [31:0] p_port1_sig1_s; wire p_port1_sig2_s;",
            \},
            \ modg1p0 : {
                \ "VlsiPasteAsInstance _s p_"   : "modg1p0 #( .param1 (1) ) u_p_modg1p0_s;",
                \ "VlsiPasteSignals _s p_"      : "",
            \},
            \ modg1p1 : {
                \ "VlsiPasteAsInstance _s p_"   : "modg1p1 #( .param1 (1) ) u_p_modg1p1_s ( .port1 (p_port1_s) );",
                \ "VlsiPasteSignals _s p_"      : "wire p_port1_s;",
            \},
            \ modg2p0 : {
                \ "VlsiPasteAsInstance _s p_"   : "modg2p0 #( .param1 (1), .param2 (2) ) u_p_modg2p0_s;",
                \ "VlsiPasteSignals _s p_"      : "",
            \},
            \ modg0p3 : {
                \ "VlsiPasteAsInstance _s p_"   : "modg0p3 u_p_modg0p3_s ( .port1 (p_port1_s), .port2 (p_port2_s), .port3 (p_port3_s) );",
                \ "VlsiPasteSignals _s p_"      : "wire p_port1_s; wire p_port2_s; wire p_port3_s;",
            \},
            \ modg2p3 : {
                \ "VlsiPasteAsInstance _s p_"   : "modg2p3 #( .param1 (1), .param2 (2) ) u_p_modg2p3_s ( .port1 (p_port1_s), .port2 (p_port2_s), .port3 (p_port3_s) );",
                \ "VlsiPasteSignals _s p_"      : "wire p_port1_s; wire p_port2_s; wire p_port3_s;",
            \},
\}

" Reference for Verilog
let s:reference_vhdl = #{
            \ modg0p0 : #{
                \ VlsiPasteAsDefinition : "entity modg0p0 is end entity modg0p0;",
                \ VlsiPasteAsInterface  : "component modg0p0 is end component modg0p0;",
                \ VlsiPasteAsInstance   : "u_modg0p0 : modg0p0 ;",
                \ VlsiPasteSignals      : "",
            \},
            \ modg0p1 : #{
                \ VlsiPasteAsDefinition : "entity modg0p1 is port ( port1 : in std_logic ); end entity modg0p1;",
                \ VlsiPasteAsInterface  : "component modg0p1 is port ( port1 : in std_logic ); end component modg0p1;",
                \ VlsiPasteAsInstance   : "u_modg0p1 : modg0p1 port map ( port1 => port1 );",
                \ VlsiPasteSignals      : "signal port1 : std_logic;",
            \},
            \ modg0p1_with_range : #{
                \ VlsiPasteAsDefinition : "entity modg0p1_with_range is port ( port1 : in std_logic_vector(size downto 0) ); end entity modg0p1_with_range;",
                \ VlsiPasteAsInterface  : "component modg0p1_with_range is port ( port1 : in std_logic_vector(size downto 0) ); end component modg0p1_with_range;",
                \ VlsiPasteAsInstance   : "u_modg0p1_with_range : modg0p1_with_range port map ( port1 => port1 );",
                \ VlsiPasteSignals      : "signal port1 : std_logic_vector(size downto 0);",
            \},
            \ modg0p1_with_interface : #{
                \ VlsiPasteAsDefinition : "entity modg0p1_with_interface is port ( port1_sig1 : in std_logic_vector(31 downto 0); port1_sig2 : out std_logic ); end entity modg0p1_with_interface;",
                \ VlsiPasteAsInterface  : "component modg0p1_with_interface is port ( port1_sig1 : in std_logic_vector(31 downto 0); port1_sig2 : out std_logic ); end component modg0p1_with_interface;",
                \ VlsiPasteAsInstance   : "u_modg0p1_with_interface : modg0p1_with_interface port map ( port1_sig1 => port1_sig1, port1_sig2 => port1_sig2 );",
                \ VlsiPasteSignals      : "signal port1_sig1 : std_logic_vector(31 downto 0); signal port1_sig2 : std_logic ;",
            \},
            \ modg1p0 : #{
                \ VlsiPasteAsDefinition : "entity modg1p0 is generic ( param1 : natural := 1 ); end entity modg1p0;",
                \ VlsiPasteAsInterface  : "component modg1p0 is generic ( param1 : natural := 1 ); end component modg1p0;",
                \ VlsiPasteAsInstance   : "u_modg1p0 : modg1p0 generic map ( param1 => 1 ) ;",
                \ VlsiPasteSignals      : "",
            \},
            \ modg1p1 : #{
                \ VlsiPasteAsDefinition : "entity modg1p1 is generic ( param1 : natural := 1 ); port ( port1 : in std_logic ); end entity modg1p1;",
                \ VlsiPasteAsInterface  : "component modg1p1 is generic ( param1 : natural := 1 ); port ( port1 : in std_logic ); end component modg1p1;",
                \ VlsiPasteAsInstance   : "u_modg1p1 : modg1p1 generic map ( param1 => 1 ) port map ( port1 => port1 );",
                \ VlsiPasteSignals      : "signal port1 : std_logic;",
            \},
            \ modg2p0 : #{
                \ VlsiPasteAsDefinition : "entity modg2p0 is generic ( param1 : natural := 1; param2 : natural := 2 ); end entity modg2p0;",
                \ VlsiPasteAsInterface  : "component modg2p0 is generic ( param1 : natural := 1; param2 : natural := 2 ); end component modg2p0;",
                \ VlsiPasteAsInstance   : "u_modg2p0 : modg2p0 generic map ( param1 => 1, param2 => 2 ) ;",
                \ VlsiPasteSignals      : "",
            \},
            \ modg0p3 : #{
                \ VlsiPasteAsDefinition : "entity modg0p3 is port ( port1 : in std_logic; port2 : out std_logic; port3 : inout std_logic ); end entity modg0p3;",
                \ VlsiPasteAsInterface  : "component modg0p3 is port ( port1 : in std_logic; port2 : out std_logic; port3 : inout std_logic ); end component modg0p3;",
                \ VlsiPasteAsInstance   : "u_modg0p3 : modg0p3 port map ( port1 => port1, port2 => port2, port3 => port3 );",
                \ VlsiPasteSignals      : "signal port1 : std_logic; signal port2 : std_logic; signal port3 : std_logic;",
            \},
            \ modg2p3 : #{
                \ VlsiPasteAsDefinition : "entity modg2p3 is generic ( param1 : natural := 1; param2 : natural := 2 ); port ( port1 : in std_logic; port2 : out std_logic; port3 : inout std_logic ); end entity modg2p3;",
                \ VlsiPasteAsInterface  : "component modg2p3 is generic ( param1 : natural := 1; param2 : natural := 2 ); port ( port1 : in std_logic; port2 : out std_logic; port3 : inout std_logic ); end component modg2p3;",
                \ VlsiPasteAsInstance   : "u_modg2p3 : modg2p3 generic map ( param1 => 1, param2 => 2 ) port map ( port1 => port1, port2 => port2, port3 => port3 );",
                \ VlsiPasteSignals      : "signal port1 : std_logic; signal port2 : std_logic; signal port3 : std_logic;",
            \},
\}

let s:reference_vhdl_prefix_suffix = #{
    \ modg2p3 : {
        \ "VlsiPasteAsInstance"   : "u_p_modg2p3_s : modg2p3 generic map ( param1 => 1, param2 => 2 ) port map ( port1 => p_port1_s, port2 => p_port2_s, port3 => p_port3_s );",
        \ "VlsiPasteSignals"      : "signal p_port1_s : std_logic; signal p_port2_s : std_logic; signal p_port3_s : std_logic;",
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
    "call self.puts("Setting marker format for SystemVerilog")
    let self.data.marker_formats = ['// begin %s', '// end %s']
    let s:tc.get_canonical = function ('s:get_canonical',['\/\/'])
endfunction

function! s:tc_v.SETUP() " define markers for data accessors
    "call self.puts("Setting marker format for Verilog")
    let self.data.marker_formats = ['// begin %s', '// end %s']
    let s:tc_v.get_canonical = function ('s:get_canonical',['\/\/'])
endfunction

function! s:tc_vhdl.SETUP() " define markers for data accessors
    "call self.puts("Setting marker format for Vhdl")
    let self.data.marker_formats = ['-- begin %s', '-- end %s']
    let s:tc_vhdl.get_canonical = function ('s:get_canonical',['--'])
endfunction

function! s:co_vhdl.SETUP() " define markers for data accessors
    let s:vcom_ok = system('vcom')
    if s:vcom_ok =~ "not found"
        let s:vcom_ok = 0
        call self.puts("vcom command not found, please use setcad")
    else
        let s:vcom_ok = 1
    endif
endfunction

function! s:co_verilog.SETUP() " define markers for data accessors
    let s:vlog_ok = system('vlog')
    if s:vlog_ok =~ "not found"
        let s:vlog_ok = 0
        call self.puts("vlog command not found, please use setcad")
    else
        let s:vlog_ok = 1
    endif
endfunction

function! s:co_sverilog.SETUP() " define markers for data accessors
    let s:vlog_ok = system('vlog')
    if s:vlog_ok =~ "not found"
        let s:vlog_ok = 0
        call self.puts("vlog command not found, please use setcad")
    else
        let s:vlog_ok = 1
    endif
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

function! s:tc_vhdl.setup()
    " Always start with a predefined module
    let g:modules    = s:default_modules
    let g:interfaces = s:default_interface
endfunction

""" Compilation for vhdl
function! s:co_vhdl.setup()
    " Always start with a predefined module
    let g:modules    = s:default_modules
    let g:interfaces = s:default_interface
    if s:vcom_ok
        let self.tempfilename = tempname() .. ".vhd"
        echomsg "__open_data_window__"
        if !bufexists(self.tempfilename)
          " The buffer doesn't exist.
          split
          hide edit `=self.tempfilename`
          exec "hide read ".. s:here .. "/ressources/test_comp.vhd"
        elseif bufwinnr(self.tempfilename) != -1
          " The buffer exists, and it has a window.
          execute bufwinnr(self.tempfilename) 'wincmd w'
        else
          " The buffer exists, but it has no window.
          split
          execute 'buffer' bufnr(data_file)
        endif
        autocmd! * <buffer>
        0
        /begin scratchpad/
    endif
endfunction

function! s:co_vhdl.teardown()
    if has_key(self,'tempfilename')
        call self.puts("- generating file for compilation: " .. self.tempfilename)
        exec "bdelete " .. self.tempfilename
        "exec "!rm " .. self.tempfilename
        unlet self.tempfilename
    endif
endfunction

""" Compilation for verilog
function! s:co_verilog.setup()
    " Always start with a predefined module
    let g:modules    = s:default_modules
    let g:interfaces = s:default_interface
    if s:vlog_ok
        let self.tempfilename = tempname() .. ".v"
        echomsg "__open_data_window__"
        if !bufexists(self.tempfilename)
          " The buffer doesn't exist.
          split
          hide edit `=self.tempfilename`
          exec "hide read ".. s:here .. "/ressources/test_comp.v"
        elseif bufwinnr(self.tempfilename) != -1
          " The buffer exists, and it has a window.
          execute bufwinnr(self.tempfilename) 'wincmd w'
        else
          " The buffer exists, but it has no window.
          split
          execute 'buffer' bufnr(data_file)
        endif
        autocmd! * <buffer>
        0
        /begin scratchpad/
    endif
endfunction

function! s:co_verilog.teardown()
    if has_key(self,'tempfilename')
        call self.puts("- generating file for compilation: " .. self.tempfilename)
        exec "bdelete " .. self.tempfilename
        "exec "!rm " .. self.tempfilename
        unlet self.tempfilename
    endif
endfunction

""" Compilation for systemverilog
function! s:co_sverilog.setup()
    " Always start with a predefined module
    let g:modules    = s:default_modules
    let g:interfaces = s:default_interface
    if s:vlog_ok
        let self.tempfilename = tempname() .. ".sv"
        echomsg "__open_data_window__"
        if !bufexists(self.tempfilename)
          " The buffer doesn't exist.
          split
          hide edit `=self.tempfilename`
          exec "hide read ".. s:here .. "/ressources/test_comp.sv"
        elseif bufwinnr(self.tempfilename) != -1
          " The buffer exists, and it has a window.
          execute bufwinnr(self.tempfilename) 'wincmd w'
        else
          " The buffer exists, but it has no window.
          split
          execute 'buffer' bufnr(data_file)
        endif
        autocmd! * <buffer>
        0
        /begin scratchpad/
    endif
endfunction

function! s:co_sverilog.teardown()
    if has_key(self,'tempfilename')
        call self.puts("- generating file for compilation: " .. self.tempfilename)
        exec "bdelete " .. self.tempfilename
        "exec "!rm " .. self.tempfilename
        unlet self.tempfilename
    endif
endfunction
" }}}

""" test functions

""" generate basic paste functions
call s:install_test_functions()

""" test the compilation of a VHDL entity
function s:co_vhdl.test_vhdl_compilation_entity()
    if !s:vcom_ok
        call self.puts("VCOM not found")
        return
    endif
    if !has_key(self,"tempfilename")
        call self.puts("tempfilename is not defined!")
        return
    endif

    VlsiPasteAsDefinition modg2p3
    wq

    let vcom_output = system('vcom ' .. self.tempfilename)

    call self.assert_equal(0,v:shell_error, "Compilation error")

    if v:shell_error != 0
        call self.puts(vcom_output)
    endif
endfunction

""" test the compilation of entity, architecture, component and instances
function s:co_vhdl.test_vhdl_compilation_entity_architecture()
    if !s:vcom_ok
        call self.puts("VCOM not found")
        return
    endif
    if !has_key(self,"tempfilename")
        call self.puts("tempfilename is not defined!")
        return
    endif

    " paste entity
    VlsiPasteAsDefinition modg2p3
    call append(line('.'),["","architecture test of modg2p3 is"])
    norm 2j
    " paste component
    VlsiPasteAsInterface modg0p3
    VlsiPasteSignals modg0p3 _north
    VlsiPasteSignals modg0p3 _south
    call append(line('.'),["begin"])
    norm 1j
    VlsiPasteAsInstance modg0p3 _north
    VlsiPasteAsInstance modg0p3 _south
    call append(line('.'),["end architecture test;"])
    norm 1j

    w
    let vcom_output = system('vcom ' .. self.tempfilename)
    call self.assert_equal(0,v:shell_error, "Compilation error")
    if v:shell_error != 0
        call self.puts(vcom_output)
    endif

endfunction

" generation and compilation of complex verilog
function s:co_verilog.test_verilog_compilation_complex()
    if !s:vlog_ok
        call self.puts("VLOG not found")
        return
    endif
    if !has_key(self,"tempfilename")
        call self.puts("tempfilename is not defined!")
        return
    endif

    " paste entity
    VlsiPasteAsDefinition modg2p3
    "move two lines up to be in the module
    norm 2k
    " paste signals
    VlsiPasteSignals modg0p3 _north
    VlsiPasteSignals modg0p3 _south
    " paste instances
    VlsiPasteAsInstance modg0p3 _north
    VlsiPasteAsInstance modg0p3 _south

    w
    let vcom_output = system('vlog ' .. self.tempfilename)
    call self.assert_equal(0,v:shell_error, "Compilation error")
    if v:shell_error != 0
        call self.puts(vcom_output)
    endif

endfunction

" generation and compilation of complex systemverilog
function s:co_sverilog.test_systemverilog_compilation_complex()
    if !s:vlog_ok
        call self.puts("VLOG not found")
        return
    endif
    if !has_key(self,"tempfilename")
        call self.puts("tempfilename is not defined!")
        return
    endif

    " paste entity
    VlsiPasteAsDefinition modg2p3
    "move two lines up to be in the module
    norm 2k
    " paste signals
    VlsiPasteSignals modg0p3 _north
    VlsiPasteSignals modg0p3 _south
    " paste instances
    VlsiPasteAsInstance modg0p3 _north
    VlsiPasteAsInstance modg0p3 _south

    w
    let vcom_output = system('vlog ' .. self.tempfilename)
    call self.assert_equal(0,v:shell_error, "Compilation error")
    if v:shell_error != 0
        call self.puts(vcom_output)
    endif

endfunction
" vim: :fdm=marker
