----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 10/05/2021 10:02:53 PM
-- Design Name: 
-- Module Name: fft_dit - Behavioral
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

library work;
use work.types_package.ALL;

entity fft_hw_sw is
    generic( word_len : integer := 32;
             frac_len : integer := 29);
    Port ( clk : in std_logic;
           rst : in std_logic;
           o_bram_addr : out std_logic_vector (23 downto 0);
           i_bram_data : in std_logic_vector ((2 * word_len) - 1  downto 0);
           o_bram_data : out std_logic_vector ((2 * word_len) - 1 downto 0);
           o_bram_en : out std_logic;
           o_bram_wen : out std_logic;
           i_start_addr : in std_logic_vector (23 downto 0);
           i_arm_data_muxsel : in std_logic_vector(23 downto 0);
           i_arm_twiddle_muxsel : in std_logic_vector(11 downto 0);
           i_start_op : in std_logic;
           i_end_op : in std_logic;
           i_start_stage : in std_logic;
           o_stage_flag : out std_logic_vector(1 downto 0);
           i_debug_regbank_addr : in std_logic_vector(2 downto 0);
           o_debug_regbank_data_real : out std_logic_vector(word_len - 1 downto 0);
           o_debug_regbank_data_imag : out std_logic_vector(word_len - 1 downto 0));
end fft_hw_sw;

architecture rtl_fft of fft_hw_sw is

    function reverse_vector (a: in std_logic_vector) return std_logic_vector is
      variable result: std_logic_vector(a'RANGE);
      alias aa: std_logic_vector(a'REVERSE_RANGE) is a;
    begin
      for i in aa'RANGE loop
        result(i) := aa(i);
      end loop;
      return result;
    end;
    
    type state is (idle, wait_for_BRAM, load_data, wait_for_arm, wait_for_stage, store_result);
    signal curr_state : state := idle;
    
    signal s_reg_bank, s_regmux_op, s_bram_demux : regbank_mux_interface := (others => x"0000000000000000");
    signal s_mem_index, s_mem_index_bit_reversed : unsigned(2 downto 0) := (others => '0');
    signal s_bram_out_sel : std_logic_vector(2 downto 0) := (others => '0');
    signal s_twiddle_reg : regbank_mux_interface := ("0010000000000000000000000000000000000000000000000000000000000000", 
                                                     "0001011010100000100111100110011011101001010111110110000110011010",
                                                     "0000000000000000000000000000000011100000000000000000000000000000",
                                                     "1110100101011111011000011001101011101001010111110110000110011010",
                                                     "1110000000000000000000000000000000000000000000000000000000000000",
                                                     "1110100101011111011000011001101000010110101000001001111001100110",
                                                     "0000000000000000000000000000000000100000000000000000000000000000",
                                                     "0001011010100000100111100110011000010110101000001001111001100110");
                                                     
    signal s_butterfly_op : regbank_mux_interface := (others => x"0000000000000000");
    
    signal s_bram_addr, s_start_addr_reg : unsigned(23 downto 0) := (others => '0');
    signal s_data_count : unsigned(3 downto 0) := (others => '0');
    
    type twiddle_mux_op  is array(0 to 3) of std_logic_vector((2 * word_len) - 1 downto 0);
    signal s_twiddle_muxsw_op : twiddle_mux_op;
    
    type stage_out is array(0 to 7) of std_logic_vector((2 * word_len) - 1 downto 0);
    signal s_muxsw_op, s_muxsw_pipeline_reg : stage_out := (others => x"0000000000000000");
    
    signal s_loadip, s_regwrite_en, s_wait_counter : std_logic := '0';
    signal s_start_stage_reg : std_logic := '0';
begin

    debug_regbank_mux: entity work.mux_64bit_8x1
                       port map( i_sel => i_debug_regbank_addr,
                                 i_ip => s_reg_bank,
                                 o_op(63 downto 32) => o_debug_regbank_data_real,
                                 o_op(31 downto 0) => o_debug_regbank_data_imag);

    -- BUTTEFLY INPUT MUX CROSSSWITCH
    mux_switch: for i in 0 to 7 generate
        crosssw_mux_block: entity work.mux_64bit_8x1
                        port map( i_sel => i_arm_data_muxsel(3 * i + 2 downto 3 * i),
                                  i_ip => s_reg_bank,
                                  o_op => s_muxsw_op(i));
    end generate mux_switch;
    
    -- REGBANK INPUT MUXES
    regbank_ip_muxes: for i in 0 to 7 generate
        regbank_mux_block: entity work.mux_64bit_2x1
                        port map( i_sel => s_loadip,
                                  i_ip(0) => s_butterfly_op(i),     -- Sel line input and selected lines are mismatched :|
                                  i_ip(1) => s_bram_demux(i),
                                  o_op => s_regmux_op(i));
    end generate regbank_ip_muxes;
    
    -- BRAM OUTPUT MUX
    o_bram_out_mux: entity work.mux_64bit_8x1
                    port map ( i_sel => s_bram_out_sel,
                                i_ip => s_reg_bank,
                                o_op => o_bram_data);
    
    -- REGISTER BANK PROC
    regbank_proc: process(clk, rst)
    begin
        if rising_edge(clk) then
            if rst = '1' then
                s_reg_bank <= (others => x"0000000000000000");
            elsif s_regwrite_en = '1' then
                s_reg_bank <= s_regmux_op;
            end if;
        end if;
    end process regbank_proc;
    
    -- TWIDDLE MUX CROSSSWITCH
    twiddle_mux_switch: for i in 0 to 3 generate
        crosssw_mux_block: entity work.mux_64bit_8x1
                        port map( i_sel => i_arm_twiddle_muxsel(3 * i + 2 downto 3 * i),
                                  i_ip => s_twiddle_reg,
                                  o_op => s_twiddle_muxsw_op(i));
    end generate twiddle_mux_switch;
    
    -- FFT STRUCTURE
    butterfly_stage: for i in 0 to 3 generate
        butterfly_block: entity work.butterfly
                          port map( clk => clk,
                                    rst => rst,
                                    i_a => s_muxsw_op(2 * i),
                                    i_b => s_muxsw_op(2 * i + 1),
                                    i_twiddle => s_twiddle_muxsw_op(i),
                                    o_out1 => s_butterfly_op(2 * i),
                                    o_out2 => s_butterfly_op(2 * i + 1));   
    end generate butterfly_stage;
    
    -- CONTROL FSM
    s_mem_index_bit_reversed <= unsigned(reverse_vector(std_logic_vector(s_mem_index)));
    o_bram_addr <= std_logic_vector(s_bram_addr);
    
    fsm_proc: process(clk)
    begin
        if rising_edge(clk) then
            s_start_stage_reg <= i_start_stage;
            if curr_state = idle then
                s_wait_counter <= '0'; 
                if i_start_op = '1' then
                    s_start_addr_reg <= unsigned(i_start_addr);
                    s_bram_addr <= unsigned(i_start_addr);
                    curr_state <= wait_for_BRAM;
                end if;
            elsif curr_state = wait_for_BRAM then
                s_wait_counter <= '0'; 
                curr_state <= load_data;
                s_bram_addr <= s_bram_addr + 1;
            elsif curr_state = load_data then
                s_wait_counter <= '0'; 
                if s_data_count < 8 then
                    s_data_count <= s_data_count + 1; 
                    s_bram_addr <= s_bram_addr + 1;
                    s_mem_index <= s_mem_index + 1;
                    s_bram_demux(to_integer(s_mem_index_bit_reversed)) <= i_bram_data;    -- Probably synthesizes to a bank of registers. Has to be modified.
                else
                    s_data_count <= to_unsigned(0, 4);
                    s_bram_addr <= to_unsigned(0, 24);
                    s_mem_index <= to_unsigned(0, 3);
                    curr_state <= wait_for_arm;
                end if;
            elsif curr_state = wait_for_arm then
                s_wait_counter <= '0'; 
                if i_end_op = '1' then
                    curr_state <= store_result;
                    s_bram_out_sel <= std_logic_vector(to_unsigned(0, 3));
                elsif i_start_stage = '1' and s_start_stage_reg = '0' then
                    curr_state <= wait_for_stage;
                else
                    curr_state <= wait_for_arm;
                end if;   
            elsif curr_state = wait_for_stage then 
                if s_wait_counter = '0' then
                    s_wait_counter <= '1';
                    curr_state <= wait_for_stage;
                else
                    s_wait_counter <= '0';    
                    curr_state <= wait_for_arm;
                end if;
            elsif curr_state = store_result then
                s_wait_counter <= '0'; 
                if s_data_count < 8 then
                    s_bram_out_sel <= std_logic_vector(unsigned(s_bram_out_sel) + 1);
                    s_bram_addr <= s_bram_addr + 1;     -- Do reordering of output using software on ARM core
                    s_mem_index <= s_mem_index + 1;
                    s_data_count <= s_data_count + 1;
                else
                    s_data_count <= to_unsigned(0, 4);
                    s_mem_index <= to_unsigned(0, 3);
                    s_bram_addr <= to_unsigned(0, 24);
                    curr_state <= idle;
                end if;
            end if;
        end if;     
    end process fsm_proc;   
    
    reg_write_en_proc: process(s_wait_counter, curr_state)
    begin
        if s_wait_counter = '1' or curr_state = load_data then 
            s_regwrite_en <= '1';
        else
            s_regwrite_en <= '0';
        end if;
    end process reg_write_en_proc;
    
    fsm_output_proc: process(curr_state)
    begin       
        if curr_state = idle then
            s_loadip <= '0';
            o_bram_en <= '0';
            o_bram_wen <= '0';
            o_stage_flag <= '0' & '0';      --  o_stage_flag[1] -> Busy, o_stage_flag[0] -> Ready
        elsif curr_state = wait_for_BRAM then
            s_loadip <= '0';
            o_bram_en <= '1';
            o_bram_wen <= '0';
            o_stage_flag <= '0' & '0';
        elsif curr_state = load_data then 
            s_loadip <= '1';
            o_bram_en <= '1';
            o_bram_wen <= '0';
            o_stage_flag <= '0' & '0';
        elsif curr_state = wait_for_arm then
            s_loadip <= '0';
            o_bram_en <= '0';
            o_bram_wen <= '0'; 
            o_stage_flag <= '0' & '1';
        elsif curr_state = wait_for_stage then
            s_loadip <= '0';
            o_bram_en <= '0';
            o_bram_wen <= '0';
            o_stage_flag <= '1' & '0'; 
        elsif curr_state = store_result then 
            s_loadip <= '0';
            o_bram_en <= '1';
            o_bram_wen <= '1';
            o_stage_flag <= '1' & '0';
        else
            s_loadip <= '0';
            o_bram_en <= '0';
            o_bram_wen <= '0';
            o_stage_flag <= '0' & '0';
        end if;
    end process fsm_output_proc; 
end rtl_fft;
