vim-vlsi : useful scripts for VLSI design
=========================================

The VLSI plugin defines module yank & paste, keeping a list of registered
modules in memory.

Each module is defined by:
    - its name
    - a set of generic parameters with their types and default value
    - a set of input and output ports, with their direction and range

Currently, the only available language is VHDL.
Yet, plugin architecture is modular with respect to filetype, so that
other VLSI module formats may be supported in the future, e.g. Verilog.

## Commands
`:VlsiYank`                            Yank the module containing the cursor
                                       default mapping: `<M-F6>`

`:VlsiList`                            Display the available module list
                                       default mapping: not mapped

`:VlsiDefineNew`                       Interactively capture a new module
                                       default mapping: `<M-S-F6>`

`:VlsiPasteAsEntity [{modulename}]`    Paste module definition
                                       default mapping: `<S-F6>`

`:VlsiPasteAsComponent [{modulename}]` Paste module interface
                                       default mapping: `<C-F6>`

`:VlsiPasteAsInstance [{modulename}]`  Paste module as bound instance
                                       default mapping: `<F6>`

## Authors:
* Yvain Thonnart

## Copyright & Licencse:
(c) 2009 - 2017 by the authors

The VIM LICENSE applies to vim-vlsi
(see vim copyright) except use vim-vlsi instead of "Vim".

NO WARRANTY, EXPRESS OR IMPLIED.  USE AT-YOUR-OWN-RISK.
