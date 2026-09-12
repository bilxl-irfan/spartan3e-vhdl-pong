----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    17:16:00 11/05/2025 
-- Design Name: 
-- Module Name:    vga_timing - Behavioral 
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
----------------------------------------------------------------------------------
-- VGA TIMING GENERATOR + CHIPSCOP E ILA CONNECTIONS
-- Muhammad Wajeeh Ul Hassan | COE758 Project 2 | 640×480 @ 60 Hz (25 MHz pixel clk)
----------------------------------------------------------------------------------
-- VGA TIMING GENERATOR + CHIPSCOP E ILA CONNECTIONS
-- Muhammad Wajeeh Ul Hassan | COE758 Project 2 | 640×480 @ 60 Hz (25 MHz pixel clk)
----------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity vga_timing is
  Port (
    clk        : in  STD_LOGIC;
    rst        : in  STD_LOGIC;
    -- Game signals for ChipScope monitoring
    frame_tick_in : in STD_LOGIC;
    ball_x_in  : in INTEGER range 0 to 639;
    ball_y_in  : in INTEGER range 0 to 479;
    p1_y_in    : in INTEGER range 0 to 479;
    p2_y_in    : in INTEGER range 0 to 479;
    -- VGA outputs
    pixel_clk  : out STD_LOGIC;
    hsync      : out STD_LOGIC;
    vsync      : out STD_LOGIC;
    x          : out INTEGER range 0 to 799;
    y          : out INTEGER range 0 to 524;
    visible    : out STD_LOGIC
  );
end vga_timing;

architecture Behavioral of vga_timing is
  --------------------------------------------------------------------
  -- VGA 640×480 @ 60 Hz timing parameters
  --------------------------------------------------------------------
  constant H_DISPLAY : integer := 640;
  constant H_FRONT   : integer := 16;
  constant H_SYNC    : integer := 96;
  constant H_BACK    : integer := 48;
  constant H_TOTAL   : integer := 800;

  constant V_DISPLAY : integer := 480;
  constant V_FRONT   : integer := 10;
  constant V_SYNC    : integer := 2;
  constant V_BACK    : integer := 33;
  constant V_TOTAL   : integer := 525;

  --------------------------------------------------------------------
  -- Internal signals
  --------------------------------------------------------------------
  signal pix_clk     : STD_LOGIC := '0';
  signal h_counter   : integer range 0 to H_TOTAL-1 := 0;
  signal v_counter   : integer range 0 to V_TOTAL-1 := 0;
  signal hsync_int   : STD_LOGIC := '1';
  signal vsync_int   : STD_LOGIC := '1';
  signal visible_int : STD_LOGIC := '0';

  --------------------------------------------------------------------
  -- ChipScope ICON / ILA
  --------------------------------------------------------------------
  component icon
    port (CONTROL0 : inout std_logic_vector(35 downto 0));
  end component;

  component ila
    port (
      CONTROL : inout std_logic_vector(35 downto 0);
      CLK     : in std_logic;
      DATA    : in std_logic_vector(63 downto 0);  -- EXPANDED to 64 bits
      TRIG0   : in std_logic_vector(7 downto 0)
    );
  end component;

  signal control0 : std_logic_vector(35 downto 0);
  signal ila_data : std_logic_vector(63 downto 0);  -- EXPANDED
  signal trig0    : std_logic_vector(7 downto 0);

begin
  --------------------------------------------------------------------
  -- 25 MHz pixel clock divider
  --------------------------------------------------------------------
  process(clk)
  begin
    if rising_edge(clk) then
      pix_clk <= not pix_clk;
    end if;
  end process;

  pixel_clk <= pix_clk;

  --------------------------------------------------------------------
  -- Horizontal / Vertical counters
  --------------------------------------------------------------------
  process(pix_clk, rst)
  begin
    if rst = '1' then
      h_counter <= 0;
      v_counter <= 0;
    elsif rising_edge(pix_clk) then
      if h_counter = H_TOTAL - 1 then
        h_counter <= 0;
        if v_counter = V_TOTAL - 1 then
          v_counter <= 0;
        else
          v_counter <= v_counter + 1;
        end if;
      else
        h_counter <= h_counter + 1;
      end if;
    end if;
  end process;

  --------------------------------------------------------------------
  -- Sync pulses (active low)
  --------------------------------------------------------------------
  hsync_int <= '0' when (h_counter >= H_DISPLAY + H_FRONT and
                         h_counter <  H_DISPLAY + H_FRONT + H_SYNC)
               else '1';

  vsync_int <= '0' when (v_counter >= V_DISPLAY + V_FRONT and
                         v_counter <  V_DISPLAY + V_FRONT + V_SYNC)
               else '1';

  visible_int <= '1' when (h_counter < H_DISPLAY and v_counter < V_DISPLAY)
                 else '0';

  --------------------------------------------------------------------
  -- Outputs
  --------------------------------------------------------------------
  hsync   <= hsync_int;
  vsync   <= vsync_int;
  visible <= visible_int;
  x <= h_counter;
  y <= v_counter;

  --------------------------------------------------------------------
  -- ENHANCED ChipScope with Game Signals
  --------------------------------------------------------------------
  icon_inst : icon
    port map (CONTROL0 => control0);

  ila_inst : ila
    port map (
      CONTROL => control0,
      CLK     => clk,
      DATA    => ila_data,
      TRIG0   => trig0
    );

  -- ENHANCED ILA data mapping (64 bits)
  ila_data(9 downto 0)   <= std_logic_vector(to_unsigned(h_counter, 10));    -- H counter
  ila_data(19 downto 10) <= std_logic_vector(to_unsigned(v_counter, 10));    -- V counter
  ila_data(20) <= hsync_int;          -- HSYNC
  ila_data(21) <= vsync_int;          -- VSYNC
  ila_data(22) <= visible_int;        -- Visible region
  ila_data(23) <= pix_clk;            -- 25MHz pixel clock
  ila_data(24) <= frame_tick_in;      -- NEW: Frame update tick
  ila_data(25) <= rst;                -- NEW: Reset signal
  
  -- NEW: Game object positions for collision debugging
  ila_data(35 downto 26) <= std_logic_vector(to_unsigned(ball_x_in, 10));    -- Ball X
  ila_data(44 downto 36) <= std_logic_vector(to_unsigned(ball_y_in, 9));     -- Ball Y
  ila_data(53 downto 45) <= std_logic_vector(to_unsigned(p1_y_in, 9));       -- Player 1 Y
  ila_data(62 downto 54) <= std_logic_vector(to_unsigned(p2_y_in, 9));       -- Player 2 Y
  ila_data(63) <= '0';                -- Unused

  -- Trigger on VSYNC (captures one complete frame)
  trig0(0) <= vsync_int;
  trig0(1) <= frame_tick_in;
  trig0(7 downto 2) <= (others => '0');

end Behavioral;
