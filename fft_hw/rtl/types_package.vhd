library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

package types_package is 
    type regbank_mux_interface is array(0 to 7) of std_logic_vector(63 downto 0);
    type mux_2x1_interface is array(0 to 1) of std_logic_vector(63 downto 0);
end package;