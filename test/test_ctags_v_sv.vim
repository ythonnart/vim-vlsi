" Test suite for VlsiYank for SystemVerilog
" Install https://github.com/laurentalacoque/vim-unittest (fixed version of 
" https://github.com/h1mesuke/vim-unittest)
" Run :UnitTest <this file>
"
" where are we?
let s:here= expand('<sfile>:p:h')

let s:tctags = unittest#testcase#new("Test ctags generation for SystemVerilog", {'data' : s:here .. '/ressources/test_ctags.sv'})

"--------------------------------------------------------------------------------
" Setup and Teardown
"--------------------------------------------------------------------------------
" {{{ 1

function! s:tctags.SETUP()
    let datafile = s:tctags.data.file
    let ctags_exec = s:here .. "/../bin/ctags/systemverilog.pl"
    call self.puts(ctags_exec)
    let self.ctags_out = systemlist(ctags_exec .. " " .. datafile)
    "let self.ctags_out = systemlist("cat ~/temp/ctags")
endfunction

" }}}

"--------------------------------------------------------------------------------
" Helper functions
"--------------------------------------------------------------------------------
" {{{ 1
function! s:lookfor(list,elem)
    let obj = 0
    for item in a:list
        if item.tag ==# a:elem
            return item
        endif
    endfor
    return obj
endfunction

let s:expected_tags_fields = {
            \ 'include1.sv': #{kind:'h'},
            \ 'EMPTY_DEFINE'       : #{kind:'d'},
            \ 'VALUE_DEFINE'       : #{kind:'d', signature:' (3)'},
            \ 'typedef1'       : #{kind:'t'},
            \ 'inter1' : #{kind:'I'},
            \ 'inter1sig1' : #{kind:'s', interface:'inter1::signals'},
            \ 'inter1sig2' : #{kind:'s', interface:'inter1::signals'},
            \ 'inter1modport1' : #{kind:'P', interface:'inter1::modports'},
            \ 'inter1modport2' : #{kind:'P', interface:'inter1::modports'},
            \ 'mod1'       : #{kind:'m'},
            \ 'mod1gen1'       : #{kind:'g', module:'mod1::generics', signature:' (1)'},
            \ 'mod1gen2'       : #{kind:'g', module:'mod1::generics', signature:' (2)'},
            \ 'mod1port1'      : #{kind:'p', module:'mod1::ports', signature:' (in)'},
            \ 'mod1port2'      : #{kind:'p', module:'mod1::ports', signature:' (out)'},
            \ 'mod1port3'      : #{kind:'p', module:'mod1::ports', signature:' (inout)'},
            \ 'mod1port4'      : #{kind:'p', module:'mod1::ports', signature:' (inter1.inter1modport1)'},
            \ 'mod1sig1'       : #{kind:'s', module:'mod1::signals', signature:' (logic)'},
            \ 'mod1inst2'      : #{kind:'i', module:'mod1::instances', signature:' (inst_entity2)'},
            \ 'mod1proc1'      : #{kind:'r', module:'mod1::processes', signature:' (initial)'},
            \ 'line52'         : #{kind:'r', module:'mod1::processes', signature:' (initial)'},
            \ 'mod1proc3'      : #{kind:'r', module:'mod1::processes', signature:' (always)'},
\ }
let s:failing_expected_tags_fields = {
            \ 'mod1inst1'      : #{kind:'i', module:'mod1::instances', signature:' (inst_entity)'},
            \}
" }}}
""" test functions

"--------------------------------------------------------------------------------
" CTAGS test functions
"--------------------------------------------------------------------------------
" {{{ 
"
function s:tctags.test_v_sv_ctags_structure_valid()
    if !has_key(self,"ctags_out")
        return
    endif
    if exists('g:include_failing_tests')
        call extend(s:expected_tags_fields, s:failing_expected_tags_fields)
    endif

    let valid_kinds = '[dhmIgpPsirt]'
    " valid field names
    let all_valid_field_names = #{file:1, line:1, signature:1, kind:1, module:1, access:1, interface:1}
    "e.g. module::generics
    let all_valid_scope_targets = #{ports:1,generics:1,instances:1, modports:1, signals:1, processes:1}

    let invalid_line_count = 0
    let invalid_kind_count  = 0
    let invalid_field_count  = 0
    let invalid_field_file_count  = 0
    let invalid_field_line_count  = 0
    let extraneous_fields_count = 0

    let parsed_lines = []
    let modules = {}
    let interfaces = {}
    let duplicate_modules_count = 0
    let duplicate_interfaces_count = 0

    for line_num in range(len(self.ctags_out))
        let line = self.ctags_out[line_num]
        " skip white lines and lines starting with comment
        if line =~ '^\s*$' || line =~ '^;'
            continue
        endif

        "should be ^tag     file    /search/; fields...
        " first we escape the \/ that could be inside the patter field
        let modline = substitute(line,'\\\/',"\x01",'g')
        let ml = matchlist(modline,'^\(\S\+\)\t\(\S\+\)\t\(\/[^/]\+\/\);"\t\s*\(.*\)$')
        if !len(ml)
            "invalid line
            let invalid_line_count +=1
            call self.puts("Invalid format for line["..line_num.."]: "..line)
        else
            " valid line
            let tag    = ml[1]
            let fn     = ml[2]
            let pat    = substitute(ml[3],"\x01",'\\\/','g') "substitute back
            let extras = substitute(ml[4],"\x01",'\\\/','g') "substitute back
            let fields = split(extras,"\t")
            let parsed_fields = {}
            let kind   = matchstr(trim(fields[0]),'^\(kind:\)\?\zs\w$')
            if  kind ==# '' || kind !~# valid_kinds
                let invalid_kind_count +=1
                call self.puts("Invalid kind for tag '"..tag.."' : '"..kind.."'")
                let parsed_fields.kind = ''
            else
                "Valid kind
                let parsed_fields.kind = kind

                " Check for duplicate module/interface declaration
                if kind ==# 'm'
                    if has_key(modules,tag)
                        let duplicate_modules_count +=1
                        call self.puts("Duplicate module '"..tag.."'")
                    endif
                    let modules[tag] = 1
                elseif kind ==# 'I'
                    if has_key(interfaces,tag)
                        let duplicate_interfaces_count +=1
                        call self.puts("Duplicate interface '"..tag.."'")
                    endif
                    let interfaces[tag] = 1
                endif
            endif

            for curfield in fields[1:]
                let curfield = trim(curfield)
                let fl = matchlist(curfield,'^\(\w\+\):\(.*\)$')
                if len(fl) == 0
                    let invalid_field_count +=1
                    call self.puts("Invalid field for tag '".. tag .."' : '".. curfield .."'")
                else
                    let fieldname = fl[1]
                    let fieldvalue= fl[2]
                    let parsed_fields[fieldname] = fieldvalue
                endif
            endfor "foreach field
            " check for file field
            if !has_key(parsed_fields, 'file')
                let invalid_field_file_count +=1
                call self.puts("missing 'file:' field for tag '"..tag.."'")
            endif
            " check for line field
            if !has_key(parsed_fields, 'line')
                let invalid_field_line_count +=1
                call self.puts("missing 'line:' field for tag '"..tag.."'")
            endif

            " check for unknown field
            for fname in keys(parsed_fields)
                if !has_key(all_valid_field_names, fname)
                    let extraneous_fields_count +=1
                    call self.puts("Unknown field '"..fname.."' for tag '"..tag.."'")
                endif
            endfor

            " add parsed line
            let parsed_lines += [{'tag': tag, 'file':fn, 'pattern':pat, 'kind': parsed_fields.kind, 'fields': parsed_fields}]
        endif " is valid line
    endfor " foreach line in file

    call self.assert_equal(0,invalid_line_count,"ctags contains "..invalid_line_count.." invalid lines")
    call self.assert_equal(0,invalid_kind_count,"ctags contains "..invalid_kind_count.." invalid kinds")
    call self.assert_equal(0,invalid_field_count,"ctags contains "..invalid_field_count.." invalid fields")
    call self.assert_equal(0,invalid_field_file_count,"ctags contains "..invalid_field_file_count.. " missing 'file:' fields")
    call self.assert_equal(0,invalid_field_line_count,"ctags contains "..invalid_field_line_count.. " missing 'line:' fields")
    call self.assert_equal(0,extraneous_fields_count,"ctags contains "..extraneous_fields_count .. " unknown fields")
    call self.assert_equal(0,duplicate_modules_count,"ctags contains "..duplicate_modules_count .. " duplicate modules")
    call self.assert_equal(0,duplicate_interfaces_count,"ctags contains "..duplicate_interfaces_count .. " duplicate interfaces")

    let element_in_element_count = 0
    let dual_scope_count = 0
    let invalid_scope_count = 0
    let invalid_scope_reference_count = 0
    let invalid_scope_target_count = 0
    " iterate through parsed lines
    for pl in parsed_lines
        " check for modules inside modules (and interface,...)
        if pl.kind =~# '[mI]'
            "element, shouldn't have a scope
            if has_key(pl.fields,'module') || has_key(pl.fields,'interface')
                call self.puts("Element '"..pl.tag.."' shouldn't have a scope")
                let element_in_element_count +=1
            endif
        endif "module or interface

        " check for invalid 'fields.module' scope fields
        if has_key(pl.fields,'module') && has_key(pl.fields,'interface')
            call self.puts("Element '"..pl.tag.."' has dual module and interface scopes')
            let dual_scope_count +=1
        else
            "Check if the element has a scope
            let scope = ""
            let elements = {}
            if has_key(pl.fields,'module')
                let scope = pl.fields.module
                let elements = modules
            endif
            if has_key(pl.fields,'interface')
                let scope = pl.fields.interface
                let elements = interfaces
            endif

            if scope !=# ''
                " element has a scope
                let parsed_scope = split(scope,'::')
                if len(parsed_scope) != 2
                    let invalid_scope_count +=1
                    call self.puts("Element '"..pl.tag.."' has invalid scope '"..scope.."'")
                else
                    "module :: ports kind of scope
                    "parsed_scope[0] should be a valid module or interface
                    "parsed_scope[1] should be a valid scope target
                    if !has_key(elements, parsed_scope[0])
                        let invalid_scope_reference_count +=1
                        call self.puts("Element '"..pl.tag.."' has unexisting reference scope '"..parsed_scope[0].."'")
                    endif
                    if !has_key(all_valid_scope_targets, parsed_scope[1])
                        let invalid_scope_target_count +=1
                        call self.puts("Element '"..pl.tag.."' has invalid scope target '"..parsed_scope[1].."'")
                    endif
                endif
            endif

        endif
    endfor " foreach parsed_line
    call self.assert_equal(0,element_in_element_count,"ctags contains elements which scope into other elements")
    call self.assert_equal(0,dual_scope_count,"ctags contains elements which dual scopes")
    call self.assert_equal(0,invalid_scope_count,"ctags contains elements which invalid scopes")
    call self.assert_equal(0,invalid_scope_reference_count,"ctags contains elements which unexisting scope references")
    call self.assert_equal(0,invalid_scope_target_count,"ctags contains elements which invalid scope targets")

    """ finally compare expected tags and fields
    for tag in keys(s:expected_tags_fields)
        " find expected tag in parsed_lines
        let obj = s:lookfor(parsed_lines,tag)
        if type(obj) == type(0) && obj == 0
            " failed to find it
            call self.assert(0,"Missing expected tag "..tag)
        else
            "found it
            "compare wanted fields
            let expected_fields = s:expected_tags_fields[tag]
            for key in keys(expected_fields)
                if !has_key(obj.fields,key)
                    " object doesn't have the mandatory field
                    call self.assert(0,"missing field "..key.." in object '".tag."'")
                else
                    " object has key, compare values
                    call self.assert_equal(expected_fields[key], obj.fields[key], "value mismatch for field '"..key.."' of object '"..tag.."'")
                endif
            endfor "foreach compared fields
        endif " object 'tag' found
    endfor " foreach expected objects
endfunction
" }}}
" vim: :fdm=marker
