library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

library work;
use work.types_package.ALL;

entity mux_64bit_8x1 is
    port ( i_sel : in std_logic_vector(2 downto 0);
           i_ip : in regbank_mux_interface;
           o_op : out std_logic_vector(63 downto 0));
end mux_64bit_8x1;

architecture beh of mux_64bit_8x1 is
begin
    mux_proc:process(i_sel, i_ip)
    begin
        o_op <= i_ip(to_integer(unsigned(i_sel)));
    end process mux_proc;
end beh;

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

library work;
use work.types_package.ALL;

entity mux_64bit_2x1 is
    port ( i_sel : in std_logic;
           i_ip : in mux_2x1_interface;
           o_op : out std_logic_vector(63 downto 0));
end mux_64bit_2x1;

architecture beh of mux_64bit_2x1 is
begin
    mux_proc:process(i_sel, i_ip)
    begin
        if i_sel = '1' then
            o_op <= i_ip(1);
        else
            o_op <= i_ip(0);
        end if;
    end process mux_proc;
end beh;
