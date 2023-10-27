" Test suite for VlsiYank for SystemVerilog
" Install https://github.com/laurentalacoque/vim-unittest (fixed version of 
" https://github.com/h1mesuke/vim-unittest)
" Run :UnitTest <this file>
"
" where are we?
let s:here= expand('<sfile>:p:h')

let s:tc = unittest#testcase#new("Test ctags generation for VHDL", {'data' : s:here .. '/ressources/test_ctags.vhd'})

"--------------------------------------------------------------------------------
" Setup and Teardown
"--------------------------------------------------------------------------------
" {{{ 1

function! s:tc.SETUP()
    let datafile = s:tc.data.file
    let ctags_exec = s:here .. "/../bin/ctags/vhdl.pl"
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
            \ 'mod1'           : #{kind:'e'},
            \ 'mod1gen1'       : #{kind:'g', entity:'mod1::generics'},
            \ 'mod1gen2'       : #{kind:'g', entity:'mod1::generics'},
            \ 'mod1port1'      : #{kind:'p', entity:'mod1::ports', signature:' (in)'},
            \ 'mod1port2'      : #{kind:'p', entity:'mod1::ports', signature:' (out)'},
            \ 'mod1port3'      : #{kind:'p', entity:'mod1::ports', signature:' (inout)'},
            \ 'mod1_arch1'     : #{kind:'a', entity:'mod1'},
            \ 'comp1'          : #{kind:'c', architecture:'mod1::mod1_arch1::components'},
            \ 'arch1type1'     : #{kind:'t', architecture:'mod1::mod1_arch1::types'},
            \ 'arch1proc1'     : #{kind:'r', architecture:'mod1::mod1_arch1::processes'},
            \ 'arch1sig1'      : #{kind:'s', architecture:'mod1::mod1_arch1::signals'},
            \ 'arch1sig2'      : #{kind:'s', architecture:'mod1::mod1_arch1::signals'},
            \ 'arch1sig3'      : #{kind:'s', architecture:'mod1::mod1_arch1::signals'},
            \ 'u_comp1'        : #{kind:'i', architecture:'mod1::mod1_arch1::instances', signature:' (comp1)'},
            \ 'modfailport'    : #{kind:'e'},
            \ 'modfailportok'  : #{kind:'p', entity:'modfailport::ports', signature:' (in)'},
            \ 'missing_port2'  : #{kind:'p', entity:'modfailport::ports', signature:' (out)'},
\ }
" }}}
""" test functions

"--------------------------------------------------------------------------------
" CTAGS test functions
"--------------------------------------------------------------------------------
" {{{ 
"
function s:tc.test_v_sv_ctags_structure_valid()
    if !has_key(self,"ctags_out")
        return
    endif
    let valid_kinds = '[egpatscirKkfPv]'
    " valid field names
    let all_valid_field_names = #{file:1, line:1, signature:1, kind:1, entity:1, access:1, architecture:1}
    "e.g. module::generics
    let all_valid_scope_targets = #{entities:1,generics:1,ports:1,architectures:1,types:1,signals:1,components:1,instances:1,processes:1,packages:1,package:1,bodies:1,functions:1,procedures:1,variables:1}

    let invalid_line_count = 0
    let invalid_kind_count  = 0
    let invalid_field_count  = 0
    let invalid_field_file_count  = 0
    let invalid_field_line_count  = 0
    let extraneous_fields_count = 0

    let parsed_lines = []
    let modules = {}
    let duplicate_entities_count = 0

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
                if kind =~# '[ea]'
                    if has_key(modules,tag)
                        let duplicate_entities_count +=1
                        call self.puts("Duplicate entity/architecture '"..tag.."'")
                    endif
                    let modules[tag] = 1
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
    call self.assert_equal(0,duplicate_entities_count,"ctags contains "..duplicate_entities_count .. " duplicate entities")

    let element_in_element_count = 0
    let invalid_scope_count = 0
    let invalid_scope_reference_count = 0
    let invalid_scope_target_count = 0
    " iterate through parsed lines
    for pl in parsed_lines
        " check for modules inside modules (and interface,...)
        if pl.kind =~# '[e]'
            "element, shouldn't have a scope
            if has_key(pl.fields,'entity')
                call self.puts("Element '"..pl.tag.."' shouldn't have a scope")
                let element_in_element_count +=1
            endif
        endif "module or interface

        "Check if the element has a scope
        let scope = ""
        let elements = {}

        if has_key(pl.fields,'entity')
            let scope = pl.fields.entity
            let elements = modules
        endif

        if has_key(pl.fields,'architecture')
            let scope = pl.fields.architecture
            let elements = modules
        endif

        if scope !=# ''
            " element has a scope grand_father::father::target
            " or                                father::target
            " or                                father
            let parsed_scope = split(scope,'::')
            " list of all references until (not including) last element
            let scope_references = parsed_scope[:-2]
            " last element of scope is scope target or father
            let scope_last = parsed_scope[-1]

            for unit_scope in scope_references
                " check that this references a valid element
                if !has_key(elements, unit_scope)
                    let invalid_scope_reference_count +=1
                    call self.puts("Element '"..pl.tag.."' has unexisting reference scope '"..unit_scope.."' ("..scope..")")
                endif
            endfor

            if !has_key(elements,scope_last) && !has_key(all_valid_scope_targets,scope_last)
                    let invalid_scope_reference_count +=1
                    call self.puts("Element '"..pl.tag.."' has unexisting reference scope '"..unit_scope.."' or target ("..scope..")")
            endif

        endif

    endfor " foreach parsed_line
    call self.assert_equal(0,element_in_element_count,"ctags contains elements which scope into other elements")
    call self.assert_equal(0,invalid_scope_count,"ctags contains elements which invalid scopes")
    call self.assert_equal(0,invalid_scope_reference_count,"ctags contains elements which unexisting scope references")

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



