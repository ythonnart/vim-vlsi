vim-vlsi : useful scripts for VLSI design
=========================================

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
* VHDL


### Commands
`:VlsiYank                            ` Yank the module containing the cursor.
                                       default mapping: `<M-F6>`

`:VlsiList                            ` Display the available module list.
                                       default mapping: not mapped

`:VlsiDefineNew                       ` Interactively capture a new module.
                                       default mapping: `<M-S-F6>`

`:VlsiPasteAsDefinition [{modulename}]` Paste module definition.
                                       default mapping: `<S-F6>`

`:VlsiPasteAsInterface [{modulename}] ` Paste module interface.
                                       default mapping: `<C-F6>`

`:VlsiPasteAsInstance [{modulename}]  ` Paste module as bound instance.
                                       default mapping: `<F6>`

## VLSI Tagbar plugin integration
The VLSI plugin adds support for ctags-compatible tag file generation and
corresponding configuration for the Tagbar plugin. for more information, see:

Tagbar: a class outline viewer for Vim
<https://github.com/majutsushi/tagbar>

Currently, scoped tag generation is available only for VHDL.

## Authors:
* Yvain Thonnart

## Copyright & Licencse:
(c) 2009 - 2017 by the authors

The VIM LICENSE applies to vim-vlsi
(see vim copyright) except use vim-vlsi instead of "Vim".

NO WARRANTY, EXPRESS OR IMPLIED.  USE AT-YOUR-OWN-RISK.
