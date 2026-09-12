----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    17:10:23 11/05/2025 
-- Design Name: 
-- Module Name:    pong_top - Behavioral 
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

entity pong_top is
  Port (
    clk : in STD_LOGIC;
    rst : in STD_LOGIC;
    SW0 : in STD_LOGIC;
    SW1 : in STD_LOGIC;
    SW2 : in STD_LOGIC;
    SW3 : in STD_LOGIC;
    H : out STD_LOGIC;
    V : out STD_LOGIC;
    DAC_CLK : out STD_LOGIC;
    Rout : out STD_LOGIC_VECTOR(7 downto 0);
    Gout : out STD_LOGIC_VECTOR(7 downto 0);
    Bout : out STD_LOGIC_VECTOR(7 downto 0)
  );
end pong_top;

architecture Structural of pong_top is
  --------------------------------------------------------------------
  -- Component declarations
  --------------------------------------------------------------------
  component vga_timing
    Port (
      clk : in STD_LOGIC;
      rst : in STD_LOGIC;
      frame_tick_in : in STD_LOGIC;
      ball_x_in : in INTEGER range 0 to 639;
      ball_y_in : in INTEGER range 0 to 479;
      p1_y_in : in INTEGER range 0 to 479;
      p2_y_in : in INTEGER range 0 to 479;
      pixel_clk : out STD_LOGIC;
      hsync : out STD_LOGIC;
      vsync : out STD_LOGIC;
      x : out INTEGER range 0 to 799;
      y : out INTEGER range 0 to 524;
      visible : out STD_LOGIC
    );
  end component;
  
  component refresh_controller
    Port (
      pixel_clk : in STD_LOGIC;
      rst : in STD_LOGIC;
      frame_tick : out STD_LOGIC
    );
  end component;
  
  component field_renderer
    Port (
      x_pos : in INTEGER range 0 to 799;
      y_pos : in INTEGER range 0 to 524;
      video_active : in STD_LOGIC;
      field_red : out STD_LOGIC_VECTOR(7 downto 0);
      field_green : out STD_LOGIC_VECTOR(7 downto 0);
      field_blue : out STD_LOGIC_VECTOR(7 downto 0)
    );
  end component;
  
  component player_movement
    Port (
      clk : in STD_LOGIC;
      rst : in STD_LOGIC;
      frame_tick : in STD_LOGIC;
      move_up : in STD_LOGIC;
      move_down : in STD_LOGIC;
      player_side : in STD_LOGIC;
      paddle_y_pos : out INTEGER range 0 to 479;
      x_pos : in INTEGER range 0 to 799;
      y_pos : in INTEGER range 0 to 524;
      video_active : in STD_LOGIC;
      player_red : out STD_LOGIC_VECTOR(7 downto 0);
      player_green : out STD_LOGIC_VECTOR(7 downto 0);
      player_blue : out STD_LOGIC_VECTOR(7 downto 0)
    );
  end component;
  
  component ball_physics
    Port (
      clk : in STD_LOGIC;
      rst : in STD_LOGIC;
      frame_tick : in STD_LOGIC;
      player1_y : in INTEGER range 0 to 479;
      player2_y : in INTEGER range 0 to 479;
      x_pos : in INTEGER range 0 to 799;
      y_pos : in INTEGER range 0 to 524;
      video_active : in STD_LOGIC;
      ball_x_out : out INTEGER range 0 to 639;  -- NEW: for ChipScope
      ball_y_out : out INTEGER range 0 to 479;  -- NEW: for ChipScope
      ball_red : out STD_LOGIC_VECTOR(7 downto 0);
      ball_green : out STD_LOGIC_VECTOR(7 downto 0);
      ball_blue : out STD_LOGIC_VECTOR(7 downto 0)
    );
  end component;
  
  --------------------------------------------------------------------
  -- Internal signals
  --------------------------------------------------------------------
  signal pxclk : STD_LOGIC;
  signal video_on : STD_LOGIC;
  signal tick : STD_LOGIC;
  signal x_coord : INTEGER range 0 to 799;
  signal y_coord : INTEGER range 0 to 524;
  
  signal p1_red, p1_green, p1_blue : STD_LOGIC_VECTOR(7 downto 0);
  signal p2_red, p2_green, p2_blue : STD_LOGIC_VECTOR(7 downto 0);
  signal b_red, b_green, b_blue : STD_LOGIC_VECTOR(7 downto 0);
  signal f_red, f_green, f_blue : STD_LOGIC_VECTOR(7 downto 0);
  
  signal p1_y_position : INTEGER range 0 to 479;
  signal p2_y_position : INTEGER range 0 to 479;
  
  -- NEW: Signals for ChipScope monitoring
  signal ball_x_pos : INTEGER range 0 to 639;
  signal ball_y_pos : INTEGER range 0 to 479;
  
begin
  --------------------------------------------------------------------
  -- VGA timing generator (with ChipScope)
  --------------------------------------------------------------------
  timing_gen : vga_timing
    port map (
      clk => clk,
      rst => rst,
      frame_tick_in => tick,
      ball_x_in => ball_x_pos,
      ball_y_in => ball_y_pos,
      p1_y_in => p1_y_position,
      p2_y_in => p2_y_position,
      pixel_clk => pxclk,
      hsync => H,
      vsync => V,
      x => x_coord,
      y => y_coord,
      visible => video_on
    );
  
  DAC_CLK <= pxclk;
  
  --------------------------------------------------------------------
  -- Refresh rate controller
  --------------------------------------------------------------------
  refresh_ctrl : refresh_controller
    port map (
      pixel_clk => pxclk,
      rst => rst,
      frame_tick => tick
    );
  
  --------------------------------------------------------------------
  -- Field renderer
  --------------------------------------------------------------------
  field_gen : field_renderer
    port map (
      x_pos => x_coord,
      y_pos => y_coord,
      video_active => video_on,
      field_red => f_red,
      field_green => f_green,
      field_blue => f_blue
    );
  
  --------------------------------------------------------------------
  -- Player 1 (left, blue)
  --------------------------------------------------------------------
  player1_ctrl : player_movement
    port map (
      clk => clk,
      rst => rst,
      frame_tick => tick,
      move_up => SW0,
      move_down => SW1,
      player_side => '1',
      paddle_y_pos => p1_y_position,
      x_pos => x_coord,
      y_pos => y_coord,
      video_active => video_on,
      player_red => p1_red,
      player_green => p1_green,
      player_blue => p1_blue
    );
  
  --------------------------------------------------------------------
  -- Player 2 (right, pink)
  --------------------------------------------------------------------
  player2_ctrl : player_movement
    port map (
      clk => clk,
      rst => rst,
      frame_tick => tick,
      move_up => SW2,
      move_down => SW3,
      player_side => '0',
      paddle_y_pos => p2_y_position,
      x_pos => x_coord,
      y_pos => y_coord,
      video_active => video_on,
      player_red => p2_red,
      player_green => p2_green,
      player_blue => p2_blue
    );
  
  --------------------------------------------------------------------
  -- Ball controller
  --------------------------------------------------------------------
  ball_ctrl : ball_physics
    port map (
      clk => clk,
      rst => rst,
      frame_tick => tick,
      player1_y => p1_y_position,
      player2_y => p2_y_position,
      x_pos => x_coord,
      y_pos => y_coord,
      video_active => video_on,
      ball_x_out => ball_x_pos,
      ball_y_out => ball_y_pos,
      ball_red => b_red,
      ball_green => b_green,
      ball_blue => b_blue
    );
  
  --------------------------------------------------------------------
  -- Color priority multiplexer (Ball > Players > Field)
  --------------------------------------------------------------------
  process(f_red, f_green, f_blue, p1_red, p1_green, p1_blue, 
          p2_red, p2_green, p2_blue, b_red, b_green, b_blue)
  begin
    -- Default to field
    Rout <= f_red;
    Gout <= f_green;
    Bout <= f_blue;
    
    -- Player 1 overrides field
    if p1_red /= "00000000" or p1_green /= "00000000" or p1_blue /= "00000000" then 
      Rout <= p1_red;
      Gout <= p1_green;
      Bout <= p1_blue;
    end if;
    
    -- Player 2 overrides player 1 and field
    if p2_red /= "00000000" or p2_green /= "00000000" or p2_blue /= "00000000" then 
      Rout <= p2_red;
      Gout <= p2_green;
      Bout <= p2_blue; 
    end if;
    
    -- Ball has highest priority
    if b_red /= "00000000" or b_green /= "00000000" or b_blue /= "00000000" then 
      Rout <= b_red;
      Gout <= b_green;
      Bout <= b_blue; 
    end if;
  end process;
  
end Structural;
