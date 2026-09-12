----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    17:15:10 11/05/2025 
-- Design Name: 
-- Module Name:    refresh_divider - Behavioral 
-- Project Name: 
-- Target Devices: 
-- Tool versions: 
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

entity refresh_controller is
  Port ( 
    pixel_clk : in STD_LOGIC;
    rst : in STD_LOGIC;
    frame_tick : out STD_LOGIC
  );
end refresh_controller;

architecture Behavioral of refresh_controller is
  -- Counter for frame timing: 25MHz / 416666 ≈ 60Hz
  constant FRAME_PERIOD : integer := 416666;
  signal counter : integer range 0 to FRAME_PERIOD := 0;
  signal tick_signal : STD_LOGIC := '0';
begin
  process(pixel_clk, rst)
  begin
    if rst = '1' then 
      counter <= 0; 
      tick_signal <= '0';
    elsif rising_edge(pixel_clk) then
      if counter >= FRAME_PERIOD - 1 then 
        counter <= 0; 
        tick_signal <= not tick_signal;
      else 
        counter <= counter + 1; 
      end if;
    end if;
  end process;
  
  frame_tick <= tick_signal;
end Behavioral;

