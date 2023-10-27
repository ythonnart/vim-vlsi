--------------------------------------------------------------------------------
-- Expected values that match test_ctags_vhd.vim/s:expected_tags_fields
--------------------------------------------------------------------------------


library ieee;
use ieee.std_logic_1164.all;

entity mod1 is
    generic(
        mod1gen1 : natural := 1;
        mod1gen2 : natural := 2
    );
    port (
        mod1port1 : in std_logic;
        mod1port2 : out std_logic;
        mod1port3 : inout std_logic
    );
end entity;

architecture mod1_arch1 of mod1 is
    
   component comp1 is
       generic (
           comp1gen1 : natural := 1;
           comp1gen2 : natural := 2
       );
       port (
           comp1port1 : in    std_logic;
           comp1port2 : out   std_logic;
           comp1port3 : inout std_logic
       );
   end component comp1;
   
  -- interface signals for mod1
      signal arch1sig1 : std_logic;
      signal arch1sig2 : std_logic;
      signal arch1sig3 : std_logic;
  -- end of signals for mod1
BEGIN
    
   u_comp1 : comp1
       generic map (
           comp1gen1 => 1,
           comp1gen2 => 2
       )
       port map (
             comp1port1 => arch1sig1,
             comp1port2 => arch1sig2,
             comp1port3 => arch1sig3
       );
   -- end instance u_mod1
   

end architecture;



--------------------------------------------------------------------------------
-- Crashtest part
--------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
-- begin minimal
entity minimal is
end entity;
-- end minimal

library ieee;
use ieee.std_logic_1164.all;
-- begin generic1
entity generic1 is generic (
    param1 : natural := 4);
end entity;
-- end generic1

library ieee;
use ieee.std_logic_1164.all;
-- begin generic1a
entity generic1a is generic (param1 : natural := 4);
end entity;
-- end generic1a

library ieee;
use ieee.std_logic_1164.all;
-- begin generic1b
entity generic1b is generic (
    param1 : natural := 4
);
end entity;
-- end generic1b

library ieee;
use ieee.std_logic_1164.all;
-- begin generics_multi
entity generics_multi is generic (
    truc : natural := 4;
    --unused comment
    machin : natural := 33;
    chose : natural := 10 ; --hello
    thing : natural := 8 -- unused comment
); 
end entity;
-- end generics_multi

--------------------------------------------------------------------------------
-- Ports test (fully qualified)
--------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
-- begin port1
entity port1 is port (
    port1 : in std_logic);
end entity;
-- end port1

library ieee;
use ieee.std_logic_1164.all;
-- begin port1a
entity port1a is port (port1 : in std_logic);
end entity;
-- end port1a

library ieee;
use ieee.std_logic_1164.all;
-- begin port1b
entity port1b is port (
    port1 : in std_logic
);
end entity;
-- end port1b

library ieee;
use ieee.std_logic_1164.all;
-- begin ports_multi
entity ports_multi is port (
    port1 : in std_logic;
    port2 : out std_logic;
    port3 : inout std_logic
);
end entity;
-- end ports_multi



--------------------------------------------------------------------------------
-- Ports and generics test (typedef type)
--------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
-- begin pg1
entity pg1 is generic (
    param1 : natural := 4); port (
    port1 : out std_logic
    );
end entity;
-- end pg1

library ieee;
use ieee.std_logic_1164.all;
-- begin pg1a
entity pg1a is generic (param1 : natural := 4); port (port1 : in std_logic);
end entity;
-- end pg1a

library ieee;
use ieee.std_logic_1164.all;
-- begin pg1b
entity pg1b is generic (
    param1 : natural := 4
); port (port1 : in std_logic);
end entity;
-- end pg1b

library ieee;
use ieee.std_logic_1164.all;
-- begin pgs_multi
entity pgs_multi is generic (
    truc : natural := 4;
    --unused comment
    machin : natural := 33;
    chose : natural := 10 ; --hello
    thing : natural := 8 -- unused comment
); port(
    port1 : in std_logic;
    port2 : out std_logic;
    port3 : inout std_logic
);
end entity;
-- end pgs_multi

--------------------------------------------------------------------------------
-- Ports with range
--------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
-- begin pr1
entity pr1 is generic (
    BUS_WIDTH : natural := 32
    ); port (
    bus1  : in std_logic_vector(BUS_WIDTH-1 downto 0);
    bus2 : in std_logic_vector(31 downto 0)
);
end entity;
-- end pr1

--------------------------------------------------------------------------------
-- Ports with default type
--------------------------------------------------------------------------------

-- no such thing exist in vhdl
--
library ieee;
use ieee.std_logic_1164.all;
-- begin pdt1
entity pdt1 is port (
    port1, port2 : in std_logic;
    port3        : out std_logic;
    port4        : inout std_logic
);
end entity;
-- end pdt1

library ieee;
use ieee.std_logic_1164.all;
-- begin pdt2
entity pdt2 is  port (
    port1, port2 : in std_logic; port3        : out std_logic; port4        : inout std_logic
);
end entity;
-- end pdt2

--------------------------------------------------------------------------------
-- Scratchpad, don't remove marker
--------------------------------------------------------------------------------

-- begin scratchpad

-- end scratchpad
