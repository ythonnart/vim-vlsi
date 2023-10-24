vim-vlsim : useful scripts for VLSI design
==========================================

This fork of [ythonnart/vim-vlsi](https://github.com/ythonnart/vim-vlsi)
contains improvements (such as VlsiPasteSignals) and a deep refactoring.
Rewriting `PasteAs*` for new languages is now much more efficient as it 
only consists of filling a structure of patterns.

## VLSI Module/Entity Yank & Paste
The VLSI plugin defines module yank & paste, keeping a list of registered
modules in memory.

Each module is defined by:
* its name
* a set of generic parameters with their types and default value
* a set of input and output ports, with their direction and range

Plugin architecture is modular with respect to filetype.
Paste is possible from a filetype to another.

Current supported filetypes:
* Verilog
* SystemVerilog
* VHDL


### Commands
`:VlsiYank                            ` Yank the module containing the cursor.
                                       default mapping: `<M-F6>`, `<leader-y>`

`:VlsiList                            ` Display the available module list.
                                       default mapping: not mapped

`:VlsiDefineNew                       ` Interactively capture a new module.
                                       default mapping: `<M-S-F6>`

`:VlsiPasteAsDefinition [{modulename}]` Paste module definition.
                                       default mapping: `<S-F6>`, `<leader>pe`, `<leader>pm`

`:VlsiPasteAsInterface [{modulename}] ` Paste module interface.
                                       default mapping: `<C-F6>`, `<leader>pc`

`:VlsiPasteAsInstance [{modulename}]  ` Paste module as bound instance.
                                       default mapping: `<F6>`,`<leader>pi`

`:VlsiPasteSignals [{modulename}]     ` Paste module IOs as signals
                                       default mapping: `<F6>`, `<leader>ps`

## VLSI Tagbar plugin integration
The VLSI plugin adds support for ctags-compatible tag file generation and
corresponding configuration for the Tagbar plugin. for more information, see:

Tagbar: a class outline viewer for Vim
<https://github.com/majutsushi/tagbar>

Scoped tag generation is available for VHDL and Verilog.

## Authors:
* Laurent Alacoque
* Yvain Thonnart

## Copyright & Licencse:
(c) 2009 - 2023 by the authors

The VIM LICENSE applies to vim-vlsi
(see vim copyright) except use vim-vlsi instead of "Vim".

NO WARRANTY, EXPRESS OR IMPLIED.  USE AT-YOUR-OWN-RISK.
