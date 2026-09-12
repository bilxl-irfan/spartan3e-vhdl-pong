----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    18:08:00 11/05/2025 
-- Design Name: 
-- Module Name:    ball_physics - Behavioral 
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

entity ball_physics is
  Port (
    clk : in STD_LOGIC;
    rst : in STD_LOGIC;
    frame_tick : in STD_LOGIC;
    player1_y : in INTEGER range 0 to 479;
    player2_y : in INTEGER range 0 to 479;
    x_pos : in INTEGER range 0 to 799;
    y_pos : in INTEGER range 0 to 524;
    video_active : in STD_LOGIC;
    -- ChipScope outputs (for monitoring)
    ball_x_out : out INTEGER range 0 to 639;
    ball_y_out : out INTEGER range 0 to 479;
    -- VGA outputs
    ball_red : out STD_LOGIC_VECTOR(7 downto 0);
    ball_green : out STD_LOGIC_VECTOR(7 downto 0);
    ball_blue : out STD_LOGIC_VECTOR(7 downto 0)
  );
end ball_physics;

architecture Behavioral of ball_physics is
  --------------------------------------------------------------------
  -- Ball parameters
  --------------------------------------------------------------------
  constant BALL_SIZE      : integer := 12;     -- Ball diameter
  constant BALL_SPEED     : integer := 4;      -- Pixels per frame
  
  --------------------------------------------------------------------
  -- Border parameters (must match field_renderer)
  --------------------------------------------------------------------
  constant BORDER_INSET : integer := 30;
  constant BORDER_THICK : integer := 10;
  
  constant TOP_WALL       : integer := BORDER_INSET + BORDER_THICK;           -- 40
  constant BOTTOM_WALL    : integer := 480 - BORDER_INSET - BORDER_THICK;    -- 440
  
  --------------------------------------------------------------------
  -- Paddle parameters (must match player_movement)
  --------------------------------------------------------------------
  constant PADDLE_WIDTH   : integer := 16;
  constant PADDLE_HEIGHT  : integer := 90;
  
  -- Paddle X positions (must match player_movement exactly)
  constant LEFT_PADDLE_X  : integer := BORDER_INSET + BORDER_THICK + 8;      -- 48
  constant RIGHT_PADDLE_X : integer := 640 - BORDER_INSET - BORDER_THICK - PADDLE_WIDTH - 8;  -- 576
  
  --------------------------------------------------------------------
  -- Goal parameters
  --------------------------------------------------------------------
  constant GOAL_TOP       : integer := 150;
  constant GOAL_BOTTOM    : integer := 350;
  constant LEFT_GOAL_X    : integer := BORDER_INSET + BORDER_THICK;          -- 40
  constant RIGHT_GOAL_X   : integer := 640 - BORDER_INSET - BORDER_THICK;   -- 600
  
  --------------------------------------------------------------------
  -- Ball state variables
  --------------------------------------------------------------------
  signal ball_x : integer range 0 to 639 := 320;
  signal ball_y : integer range 0 to 479 := 240;
  signal velocity_x : integer := 1;   -- 1 = right, -1 = left
  signal velocity_y : integer := 1;   -- 1 = down, -1 = up
  signal goal_scored : STD_LOGIC := '0';
  signal respawn_counter : integer range 0 to 100 := 0;
  signal prev_tick : STD_LOGIC := '0';
  
begin
  --------------------------------------------------------------------
  -- Ball movement and collision detection
  --------------------------------------------------------------------
  process(clk, rst)
  begin
    if rst = '1' then 
      ball_x <= 320;
      ball_y <= 240;
      velocity_x <= 1;
      velocity_y <= 1;
      goal_scored <= '0';
      respawn_counter <= 0;
      prev_tick <= '0';
      
    elsif rising_edge(clk) then
      -- Only update on rising edge of frame_tick
      if frame_tick = '1' and prev_tick = '0' then
        
        if goal_scored = '0' then
          --------------------------------------------------------------
          -- MOVE THE BALL
          --------------------------------------------------------------
          ball_x <= ball_x + (velocity_x * BALL_SPEED);
          ball_y <= ball_y + (velocity_y * BALL_SPEED);
          
          --------------------------------------------------------------
          -- TOP/BOTTOM WALL COLLISION
          --------------------------------------------------------------
          if ball_y <= TOP_WALL then 
            velocity_y <= 1;   -- Bounce down
          elsif ball_y + BALL_SIZE >= BOTTOM_WALL then 
            velocity_y <= -1;  -- Bounce up
          end if;

          --------------------------------------------------------------
          -- SIDE WALL COLLISION (above/below goal areas)
          -- Ball bounces off white borders outside goal openings
          --------------------------------------------------------------
          if velocity_x < 0 then
            -- Moving left: check left wall
            if (ball_x <= LEFT_GOAL_X) and 
               (ball_y <= GOAL_TOP or ball_y + BALL_SIZE >= GOAL_BOTTOM) then
              velocity_x <= 1;  -- Bounce right
            end if;
          else
            -- Moving right: check right wall
            if (ball_x + BALL_SIZE >= RIGHT_GOAL_X) and 
               (ball_y <= GOAL_TOP or ball_y + BALL_SIZE >= GOAL_BOTTOM) then
              velocity_x <= -1;  -- Bounce left
            end if;
          end if;

          --------------------------------------------------------------
          -- LEFT PADDLE COLLISION (edge detection)
          --------------------------------------------------------------
          if velocity_x < 0 then
            -- Only check when ball is moving left
            if (ball_x <= LEFT_PADDLE_X + PADDLE_WIDTH) and
               (ball_x > LEFT_PADDLE_X + PADDLE_WIDTH - BALL_SPEED - 2) and
               (ball_y + BALL_SIZE >= player1_y) and 
               (ball_y <= player1_y + PADDLE_HEIGHT) then
              velocity_x <= 1;  -- Bounce right
            end if;
          end if;

          --------------------------------------------------------------
          -- RIGHT PADDLE COLLISION (edge detection)
          --------------------------------------------------------------
          if velocity_x > 0 then
            -- Only check when ball is moving right
            if (ball_x + BALL_SIZE >= RIGHT_PADDLE_X) and
               (ball_x + BALL_SIZE < RIGHT_PADDLE_X + BALL_SPEED + 2) and
               (ball_y + BALL_SIZE >= player2_y) and 
               (ball_y <= player2_y + PADDLE_HEIGHT) then
              velocity_x <= -1;  -- Bounce left
            end if;
          end if;

          --------------------------------------------------------------
          -- GOAL DETECTION
          -- Ball enters goal area (between Y=150 and Y=350)
          --------------------------------------------------------------
          if (ball_x < LEFT_GOAL_X and 
              ball_y > GOAL_TOP and 
              ball_y < GOAL_BOTTOM) or
             (ball_x + BALL_SIZE > RIGHT_GOAL_X and 
              ball_y > GOAL_TOP and 
              ball_y < GOAL_BOTTOM) then
            goal_scored <= '1';
            respawn_counter <= 0;
          end if;

        else
          --------------------------------------------------------------
          -- RESPAWN DELAY after scoring
          --------------------------------------------------------------
          if respawn_counter < 90 then
            respawn_counter <= respawn_counter + 1;
          else
            -- Respawn at center
            ball_x <= 320;
            ball_y <= 240;
            -- Reverse direction for fairness
            velocity_x <= -velocity_x;
            goal_scored <= '0';
          end if;
        end if;
      end if;
      
      prev_tick <= frame_tick;
    end if;
  end process;

  --------------------------------------------------------------------
  -- ChipScope outputs (for debugging)
  --------------------------------------------------------------------
  ball_x_out <= ball_x;
  ball_y_out <= ball_y;

  --------------------------------------------------------------------
  -- Ball rendering (round shape using distance calculation)
  --------------------------------------------------------------------
  process(x_pos, y_pos, video_active, ball_x, ball_y, goal_scored)
    variable dx, dy, dist2 : integer;
    variable radius_sq : integer;
  begin
    ball_red   <= "00000000";
    ball_green <= "00000000";
    ball_blue  <= "00000000";
    
    if video_active = '1' then
      -- Calculate distance from pixel to ball center
      dx := x_pos - (ball_x + BALL_SIZE/2);
      dy := y_pos - (ball_y + BALL_SIZE/2);
      dist2 := dx*dx + dy*dy;
      radius_sq := (BALL_SIZE/2) * (BALL_SIZE/2);

      -- Draw circular ball if within radius
      if dist2 <= radius_sq then
        if goal_scored = '0' then
          -- Yellow ball during normal play
          ball_red   <= "11111111";
          ball_green <= "11111111";
          ball_blue  <= "00000000";
        else
          -- Red ball when scored
          ball_red   <= "11111111";
          ball_green <= "00000000";
          ball_blue  <= "00000000";
        end if;
      end if;
    end if;
  end process;
  
end Behavioral;