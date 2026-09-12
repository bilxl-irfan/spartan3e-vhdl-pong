----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    17:14:29 11/05/2025 
-- Design Name: 
-- Module Name:    field_renderer - Behavioral 
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
--  FIELD RENDERER
--  Creates green field, dashed white midline, thick borders, and open black goals
----------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity field_renderer is
  Port ( 
    x_pos        : in INTEGER range 0 to 799;
    y_pos        : in INTEGER range 0 to 524;
    video_active : in STD_LOGIC;
    field_red    : out STD_LOGIC_VECTOR(7 downto 0);
    field_green  : out STD_LOGIC_VECTOR(7 downto 0);
    field_blue   : out STD_LOGIC_VECTOR(7 downto 0)
  );
end field_renderer;

architecture Behavioral of field_renderer is
  --------------------------------------------------------------------
  -- Border parameters
  --------------------------------------------------------------------
  constant BORDER_INSET : integer := 30;
  constant BORDER_THICK : integer := 10;
  
  -- Calculated boundaries
  constant LEFT_EDGE   : integer := BORDER_INSET;
  constant RIGHT_EDGE  : integer := 640 - BORDER_INSET;
  constant TOP_EDGE    : integer := BORDER_INSET;
  constant BOTTOM_EDGE : integer := 480 - BORDER_INSET;
  
  constant LEFT_BORDER_END   : integer := LEFT_EDGE + BORDER_THICK;
  constant RIGHT_BORDER_START : integer := RIGHT_EDGE - BORDER_THICK;
  constant TOP_BORDER_END    : integer := TOP_EDGE + BORDER_THICK;
  constant BOTTOM_BORDER_START : integer := BOTTOM_EDGE - BORDER_THICK;
  
  -- Goal opening parameters
  constant GOAL_TOP    : integer := 150;
  constant GOAL_BOTTOM : integer := 350;
  
  --------------------------------------------------------------------
  -- CENTER LINE parameters (perfectly calculated)
  --------------------------------------------------------------------
  constant MID_X1 : integer := 318;
  constant MID_X2 : integer := 322;
  
  -- Playing field height (excluding borders)
  constant FIELD_HEIGHT : integer := BOTTOM_BORDER_START - TOP_BORDER_END;  -- 400 pixels
  
  -- Dash parameters for perfect symmetry
  constant DASH_LENGTH : integer := 35;    -- Each dash is 35 pixels
  constant DASH_GAP    : integer := 30;    -- Gap between dashes is 30 pixels
  constant DASH_PERIOD : integer := DASH_LENGTH + DASH_GAP;  -- 65 pixels per cycle
  
  -- Number of complete dashes that fit: 400 / 65 = 6.15
  -- So we use 6 dashes with equal spacing
  constant NUM_DASHES  : integer := 6;
  
  -- Calculate starting position for perfect centering
  -- Total space needed: 6 dashes (210px) + 5 gaps (150px) = 360px
  -- Remaining space: 400 - 360 = 40px (20px margin top and bottom)
  constant DASH_START_Y : integer := TOP_BORDER_END + 20;
  
begin
  process(x_pos, y_pos, video_active)
    variable is_white_border : boolean;
    variable dash_index : integer;
    variable dash_y_start : integer;
    variable dash_y_end : integer;
  begin
    field_red   <= (others => '0');
    field_green <= (others => '0');
    field_blue  <= (others => '0');

    if video_active = '1' then
      --------------------------------------------------------------------
      -- Default: Green playing field
      --------------------------------------------------------------------
      field_green <= (others => '1');

      is_white_border := false;

      --------------------------------------------------------------------
      -- TOP BORDER (complete, including corners)
      --------------------------------------------------------------------
      if (y_pos >= TOP_EDGE and y_pos < TOP_BORDER_END) and
         (x_pos >= LEFT_EDGE and x_pos < RIGHT_EDGE) then
        is_white_border := true;
      end if;

      --------------------------------------------------------------------
      -- BOTTOM BORDER (complete, including corners)
      --------------------------------------------------------------------
      if (y_pos >= BOTTOM_BORDER_START and y_pos < BOTTOM_EDGE) and
         (x_pos >= LEFT_EDGE and x_pos < RIGHT_EDGE) then
        is_white_border := true;
      end if;

      --------------------------------------------------------------------
      -- LEFT BORDER (excluding goal opening)
      --------------------------------------------------------------------
      if (x_pos >= LEFT_EDGE and x_pos < LEFT_BORDER_END) and
         (y_pos >= TOP_BORDER_END and y_pos < BOTTOM_BORDER_START) then
        if (y_pos < GOAL_TOP or y_pos >= GOAL_BOTTOM) then
          is_white_border := true;
        end if;
      end if;

      --------------------------------------------------------------------
      -- RIGHT BORDER (excluding goal opening)
      --------------------------------------------------------------------
      if (x_pos >= RIGHT_BORDER_START and x_pos < RIGHT_EDGE) and
         (y_pos >= TOP_BORDER_END and y_pos < BOTTOM_BORDER_START) then
        if (y_pos < GOAL_TOP or y_pos >= GOAL_BOTTOM) then
          is_white_border := true;
        end if;
      end if;

      --------------------------------------------------------------------
      -- Apply white border color
      --------------------------------------------------------------------
      if is_white_border then
        field_red   <= (others => '1');
        field_green <= (others => '1');
        field_blue  <= (others => '1');
      end if;

      --------------------------------------------------------------------
      -- CENTER DASHED LINE (black, symmetric, equal-length dashes)
      --------------------------------------------------------------------
      if (x_pos >= MID_X1 and x_pos <= MID_X2) then
        -- Check each of the 6 dashes
        for i in 0 to NUM_DASHES-1 loop
          dash_y_start := DASH_START_Y + (i * DASH_PERIOD);
          dash_y_end   := dash_y_start + DASH_LENGTH;
          
          if (y_pos >= dash_y_start and y_pos < dash_y_end) then
            -- Draw black dash
            field_red   <= (others => '0');
            field_green <= (others => '0');
            field_blue  <= (others => '0');
            exit;  -- No need to check other dashes
          end if;
        end loop;
      end if;
    end if;
  end process;
end Behavioral;
