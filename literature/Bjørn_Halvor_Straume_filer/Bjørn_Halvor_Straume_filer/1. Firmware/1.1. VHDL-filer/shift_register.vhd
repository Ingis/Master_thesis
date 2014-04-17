library ieee;

use ieee.std_logic_1164.all;

use ieee.std_logic_unsigned.all;



entity shift_register is 

    

     port( areset   : in std_logic; 
           clk      : in std_logic;
           in_data  : in std_logic;
           d_enable : in std_logic;
           out_data : out std_logic);

end shift_register;



architecture archgray_n of shift_register is

signal int_data : std_logic;



begin 

out_data <= int_data;

      shift: process( clk, areset)

            begin

            if areset = '0' then      
                int_data <= '0' after 5 ns;
            elsif rising_edge(clk)  then
                if d_enable = '1' then
                  int_data <= in_data after 5 ns;
                else
                  int_data <= int_data after 5 ns;
                end if;
           end if;
        end process; 



end archgray_n;

