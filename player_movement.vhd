----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    18:06:46 11/05/2025 
-- Design Name: 
-- Module Name:    player_movement - Behavioral 
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

entity player_movement is
  Port (
    clk : in STD_LOGIC;
    rst : in STD_LOGIC;
    frame_tick : in STD_LOGIC;
    move_up : in STD_LOGIC;
    move_down : in STD_LOGIC;
    player_side : in STD_LOGIC;  -- '1' for left, '0' for right
    paddle_y_pos : out INTEGER range 0 to 479;
    x_pos : in INTEGER range 0 to 799;
    y_pos : in INTEGER range 0 to 524;
    video_active : in STD_LOGIC;
    player_red : out STD_LOGIC_VECTOR(7 downto 0);
    player_green : out STD_LOGIC_VECTOR(7 downto 0);
    player_blue : out STD_LOGIC_VECTOR(7 downto 0)
  );
end player_movement;

architecture Behavioral of player_movement is
  ------------------------------------------------------------
  -- Paddle dimensions
  ------------------------------------------------------------
  constant PADDLE_WIDTH  : integer := 16;
  constant PADDLE_HEIGHT : integer := 90;
  constant PADDLE_SPEED  : integer := 4;
  
  ------------------------------------------------------------
  -- Border parameters (must match field_renderer)
  ------------------------------------------------------------
  constant BORDER_INSET : integer := 30;
  constant BORDER_THICK : integer := 10;
  
  ------------------------------------------------------------
  -- Calculated positions for perfect alignment
  ------------------------------------------------------------
  -- Paddle X positions: Just inside the border
  constant LEFT_X  : integer := BORDER_INSET + BORDER_THICK + 8;  -- 48 pixels from left edge
  constant RIGHT_X : integer := 640 - BORDER_INSET - BORDER_THICK - PADDLE_WIDTH - 8;  -- Symmetric
  
  -- Movement limits: Stay within borders
  constant TOP_LIMIT    : integer := BORDER_INSET + BORDER_THICK;      -- 40
  constant BOTTOM_LIMIT : integer := 480 - BORDER_INSET - BORDER_THICK - PADDLE_HEIGHT;  -- 350
  
  ------------------------------------------------------------
  -- Paddle state
  ------------------------------------------------------------
  signal paddle_y : integer range 0 to 479 := 210;  -- Centered vertically
  signal prev_tick : STD_LOGIC := '0';
  
begin
  ------------------------------------------------------------
  -- Paddle movement control (edge-triggered on frame_tick)
  ------------------------------------------------------------
  process(clk, rst)
  begin
    if rst = '1' then 
      paddle_y <= 210;  -- Center position
      prev_tick <= '0';
    elsif rising_edge(clk) then
      -- Detect rising edge of frame_tick
      if frame_tick = '1' and prev_tick = '0' then
        if move_up = '1' and paddle_y > TOP_LIMIT then 
          paddle_y <= paddle_y - PADDLE_SPEED;
        elsif move_down = '1' and paddle_y < BOTTOM_LIMIT then 
          paddle_y <= paddle_y + PADDLE_SPEED;
        end if;
      end if;
      prev_tick <= frame_tick;
    end if;
  end process;
  
  paddle_y_pos <= paddle_y;
  
  ------------------------------------------------------------
  -- Paddle rendering with rounded corners (optional polish)
  ------------------------------------------------------------
  process(x_pos, y_pos, video_active, paddle_y, player_side)
    variable x_start, x_end : integer;
    variable y_start, y_end : integer;
    variable dx, dy : integer;
  begin
    player_red   <= (others => '0');
    player_green <= (others => '0');
    player_blue  <= (others => '0');
    
    if video_active = '1' then
      -- Determine paddle X position
      if player_side = '1' then 
        x_start := LEFT_X; 
      else 
        x_start := RIGHT_X; 
      end if;
      x_end := x_start + PADDLE_WIDTH;
      y_start := paddle_y;
      y_end := paddle_y + PADDLE_HEIGHT;
      
      -- Check if current pixel is within paddle bounds
      if (x_pos >= x_start and x_pos < x_end and 
          y_pos >= y_start and y_pos < y_end) then
        
        -- Optional: Rounded corners (comment out for square paddles)
        dx := 0;
        dy := 0;
        
        -- Top-left corner
        if (x_pos < x_start + 3 and y_pos < y_start + 3) then
          dx := x_start + 3 - x_pos;
          dy := y_start + 3 - y_pos;
          if (dx*dx + dy*dy > 9) then
            -- Skip this pixel (outside rounded corner)
          else
            -- Draw paddle color
            if player_side = '1' then
              -- Left paddle: Blue
              player_blue <= (others => '1');
            else
              -- Right paddle: Pink (Red + Blue)
              player_red  <= (others => '1');
              player_blue <= (others => '1');
            end if;
          end if;
        -- Top-right corner
        elsif (x_pos >= x_end - 3 and y_pos < y_start + 3) then
          dx := x_pos - (x_end - 3);
          dy := y_start + 3 - y_pos;
          if (dx*dx + dy*dy > 9) then
            -- Skip
          else
            if player_side = '1' then
              player_blue <= (others => '1');
            else
              player_red  <= (others => '1');
              player_blue <= (others => '1');
            end if;
          end if;
        -- Bottom-left corner
        elsif (x_pos < x_start + 3 and y_pos >= y_end - 3) then
          dx := x_start + 3 - x_pos;
          dy := y_pos - (y_end - 3);
          if (dx*dx + dy*dy > 9) then
            -- Skip
          else
            if player_side = '1' then
              player_blue <= (others => '1');
            else
              player_red  <= (others => '1');
              player_blue <= (others => '1');
            end if;
          end if;
        -- Bottom-right corner
        elsif (x_pos >= x_end - 3 and y_pos >= y_end - 3) then
          dx := x_pos - (x_end - 3);
          dy := y_pos - (y_end - 3);
          if (dx*dx + dy*dy > 9) then
            -- Skip
          else
            if player_side = '1' then
              player_blue <= (others => '1');
            else
              player_red  <= (others => '1');
              player_blue <= (others => '1');
            end if;
          end if;
        else
          -- Normal paddle area (not corners)
          if player_side = '1' then
            player_blue <= (others => '1');
          else
            player_red  <= (others => '1');
            player_blue <= (others => '1');
          end if;
        end if;
      end if;
    end if;
  end process;
end Behavioral;
