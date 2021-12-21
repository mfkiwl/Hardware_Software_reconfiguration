----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 10/12/2021 06:16:21 PM
-- Design Name: 
-- Module Name: butterfly - Behavioral
-- Project Name: 
-- Target Devices: 
-- Tool Versions: 
-- Description: 
-- 
-- Dependencies: 
-- 
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
-- 
----------------------------------------------------------------------------------


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity butterfly is
    generic( word_len : integer := 32;
             frac_len : integer := 29);
    Port ( clk : in std_logic;
           rst : in std_logic;
           i_a : in std_logic_vector (63 downto 0);
           i_b : in std_logic_vector (63 downto 0);
           i_twiddle : in std_logic_vector (63 downto 0);
           o_out1 : out std_logic_vector (63 downto 0);
           o_out2 : out std_logic_vector (63 downto 0));
end butterfly;

architecture rtl of butterfly is

    component mac_stage1 IS
        PORT (
            A : in std_logic_vector(31 DOWNTO 0);
            B : in std_logic_vector(31 DOWNTO 0);
            C : in std_logic_vector(63 DOWNTO 0);
            SUBTRACT : in std_logic;
            P : out std_logic_vector(64 DOWNTO 0);
            PCOUT : out std_logic_vector(47 DOWNTO 0)
        );
    end component;
    
    component mac_stage2 IS
        PORT (
            A : in std_logic_vector(31 DOWNTO 0);
            B : in std_logic_vector(31 DOWNTO 0);
            C : in std_logic_vector(64 DOWNTO 0);
            SUBTRACT : in std_logic;
            P : out std_logic_vector(65 DOWNTO 0);
            PCOUT : out std_logic_vector(47 DOWNTO 0)
        );
    end component;
    
    signal s_out1, s_out2 : std_logic_vector(63 downto 0);
    
    signal s_a_real, s_a_imag, s_b_real, s_b_imag, s_twiddle_real, s_twiddle_imag : std_logic_vector(31 downto 0) := (others => '0'); 
    signal s_a_real_extended, s_a_imag_extended : std_logic_vector(63 downto 0) := (others => '0');
    signal s_op1_real_mac1_op, s_op1_imag_mac1_op, s_op2_real_mac1_op, s_op2_imag_mac1_op : std_logic_vector(64 downto 0) := (others => '0');
    signal s_op1_real_unrounded, s_op1_imag_unrounded, s_op2_real_unrounded, s_op2_imag_unrounded : std_logic_vector(65 downto 0) := (others => '0');
    signal s_mac_op1_real_unrounded_2comp, s_mac_op1_imag_unrounded_2comp, s_mac_op2_real_unrounded_2comp, s_mac_op2_imag_unrounded_2comp : std_logic_vector(64 downto 0) := (others => '0');
    signal s_op1_real_mac1_op_reg, s_op1_imag_mac1_op_reg, s_op2_real_mac1_op_reg, s_op2_imag_mac1_op_reg : std_logic_vector(64 downto 0) := (others => '0');   
begin

    s_a_real <= i_a(63 downto 32);
    s_a_imag <= i_a(31 downto 0);
    
    s_b_real <= i_b(63 downto 32);
    s_b_imag <= i_b(31 downto 0);
    
    s_twiddle_real <= i_twiddle(63 downto 32);
    s_twiddle_imag <= i_twiddle(31 downto 0);

    s_a_real_extended(63 downto 29) <= std_logic_vector(resize(signed(s_a_real(31 downto 29)), 2 * (word_len - frac_len))) & s_a_real(28 downto 0);
    s_a_real_extended(28 downto 0) <= (others => '0');
    
    s_a_imag_extended(63 downto 29) <= std_logic_vector(resize(signed(s_a_imag(31 downto 29)), 2 * (word_len - frac_len))) & s_a_imag(28 downto 0);
    s_a_imag_extended(28 downto 0) <= (others => '0');
    
    -- MAC UNITS FOR OUTPUT 1
    mac_op1_real_1: mac_stage1
             port map(  A => s_b_real,
                        B => s_twiddle_real,
                        C => s_a_real_extended,
                        SUBTRACT => '0',
                        P => s_op1_real_mac1_op,
                        PCOUT => open);
    
    mac_op1_real_2: mac_stage2
             port map(  A => s_b_imag,
                        B => s_twiddle_imag,
                        C => s_op1_real_mac1_op_reg,
                        SUBTRACT => '1',
                        P => s_op1_real_unrounded,
                        PCOUT => open);
                        
    mac_op1_imag_1: mac_stage1
             port map(  A => s_b_real,
                        B => s_twiddle_imag,
                        C => s_a_imag_extended,
                        SUBTRACT => '0',
                        P => s_op1_imag_mac1_op,
                        PCOUT => open);
    
    mac_op1_imag_2: mac_stage2
             port map(  A => s_b_imag,
                        B => s_twiddle_real,
                        C => s_op1_imag_mac1_op_reg,
                        SUBTRACT => '1',
                        P => s_op1_imag_unrounded,
                        PCOUT => open);
                          
    -- MAC UNITS FOR OUTPUT 2
    mac_op2_real_1: mac_stage1
             port map(  A => s_b_real,
                        B => s_twiddle_real,
                        C => s_a_real_extended,
                        SUBTRACT => '1',
                        P => s_op2_real_mac1_op,
                        PCOUT => open);
    
    mac_op2_real_2: mac_stage2
             port map(  A => s_b_imag,
                        B => s_twiddle_imag,
                        C => s_op2_real_mac1_op_reg,
                        SUBTRACT => '0',
                        P => s_op2_real_unrounded,
                        PCOUT => open);
                        
    mac_op2_imag_1: mac_stage1
             port map(  A => s_b_real,
                        B => s_twiddle_imag,
                        C => s_a_imag_extended,
                        SUBTRACT => '1',
                        P => s_op2_imag_mac1_op,
                        PCOUT => open);
    
    mac_op2_imag_2: mac_stage2
             port map(  A => s_b_imag,
                        B => s_twiddle_real,
                        C => s_op2_imag_mac1_op_reg,
                        SUBTRACT => '1',
                        P => s_op2_imag_unrounded,
                        PCOUT => open);     
                        
    pipeline_reg_proc: process(clk, rst)
    begin
        if rst = '1' then
            s_op1_real_mac1_op_reg <= (others => '0'); 
            s_op1_imag_mac1_op_reg <= (others => '0'); 
            s_op2_real_mac1_op_reg <= (others => '0'); 
            s_op2_imag_mac1_op_reg <= (others => '0'); 
        elsif rising_edge(clk) then
            s_op1_real_mac1_op_reg <= s_op1_real_mac1_op;
            s_op1_imag_mac1_op_reg <= s_op1_imag_mac1_op;
            s_op2_real_mac1_op_reg <= s_op2_real_mac1_op;
            s_op2_imag_mac1_op_reg <= s_op2_imag_mac1_op;
        end if;
    end process pipeline_reg_proc;
    -- TRUNCATION (NOT SURE HOW THIS PART IS WORKING :/)
    s_out1 <= s_op1_real_unrounded(60 downto 29) & s_op1_imag_unrounded(60 downto 29);  
    s_out2 <= s_op2_real_unrounded(60 downto 29) & s_op2_imag_unrounded(60 downto 29);
    o_out1 <= s_op1_real_unrounded(60 downto 29) & s_op1_imag_unrounded(60 downto 29); 
    o_out2 <= s_op2_real_unrounded(60 downto 29) & s_op2_imag_unrounded(60 downto 29);
                        
--    s_mac_op1_real_unrounded_2comp <= std_logic_vector(unsigned(not s_op1_real_unrounded) + 1);
--    s_mac_op2_real_unrounded_2comp <= std_logic_vector(unsigned(not s_op2_real_unrounded) + 1);   
--    s_mac_op1_imag_unrounded_2comp <= std_logic_vector(unsigned(not s_op1_imag_unrounded) + 1);
--    s_mac_op2_imag_unrounded_2comp <= std_logic_vector(unsigned(not s_op2_imag_unrounded) + 1);                        
    
--    round_proc: process(i_a, i_b, i_twiddle, s_mac_op1_unrounded, s_mac_op2_unrounded, s_mac_op1_unrounded_2comp, s_mac_op2_unrounded_2comp)
--    begin
--        if s_op1_real_unrounded(64) = '0' then
--            s_op1_real_add1 <= std_logic_vector(unsigned(s_op1_real_unrounded) + "00000000000000000000000000000000100000000000000000000000000000000");
--            --s_mac_op1_rounded <= s_mac_op1_add1(64 downto 33);
--        else    
--            s_op1_real_add1 <= std_logic_vector(unsigned(s_mac_op1_real_unrounded_2comp) + "00000000000000000000000000000000100000000000000000000000000000000");
--            --s_mac_op1_rounded <= std_logic_vector(not unsigned(s_mac_op1_add1(64 downto 33)) + 1);
--            --s_mac_op1_add1_2comp <= std_logic_vector(not unsigned(s_mac_op1_add1(64 downto 33)) + 1);
--            --s_mac_op1_rounded <= s_mac_op1_add1_2comp(64 downto 33);
--        end if;
        
--        if s_op1_imag_unrounded(64) = '0' then
--            s_op1_imag_add1 <= std_logic_vector(unsigned(s_op1_imag_unrounded) + "00000000000000000000000000000000100000000000000000000000000000000");
--        else    
--            s_op1_imag_add1 <= std_logic_vector(unsigned(s_mac_op1_imag_unrounded_2comp) + "00000000000000000000000000000000100000000000000000000000000000000");
--        end if;
        
--        if s_op2_real_unrounded(64) = '0' then
--            s_op2_real_add1 <= std_logic_vector(unsigned(s_op2_real_unrounded) + "00000000000000000000000000000000100000000000000000000000000000000");
--        else    
--            s_op2_real_add1 <= std_logic_vector(unsigned(s_mac_op2_real_unrounded_2comp) + "00000000000000000000000000000000100000000000000000000000000000000");
--        end if;
        
--        if s_op2_imag_unrounded(64) = '0' then
--            s_op2_imag_add1 <= std_logic_vector(unsigned(s_op2_imag_unrounded) + "00000000000000000000000000000000100000000000000000000000000000000");
--        else    
--            s_op2_imag_add1 <= std_logic_vector(unsigned(s_mac_op2_imag_unrounded_2comp) + "00000000000000000000000000000000100000000000000000000000000000000");
--        end if;
--    end process;
    
--    with s_mac_op1_unrounded(64) select
--        o_out1 <= s_mac_op1_add1(64 downto 33) when '0',
--                  std_logic_vector(not unsigned(s_mac_op1_add1(64 downto 33)) + 1) when others; 
                  
--    with s_mac_op2_unrounded(64) select
--        o_out2 <= s_mac_op2_add1(64 downto 33) when '0',
--                  std_logic_vector(not unsigned(s_mac_op2_add1(64 downto 33)) + 1) when others;  
--    o_out2 <= s_mac_op2_rounded;
end rtl;
