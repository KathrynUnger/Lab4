library ieee;
  use ieee.std_logic_1164.all;
  use ieee.numeric_std.all;


-- Lab 4
entity top_basys3 is
    port(
        -- inputs
        clk     :   in std_logic; -- native 100MHz FPGA clock
        sw      :   in std_logic_vector(15 downto 0);
        btnU    :   in std_logic; -- master_reset
        btnL    :   in std_logic; -- clk_reset
        btnR    :   in std_logic; -- fsm_reset
        
        -- outputs
        led :   out std_logic_vector(15 downto 0);
        -- 7-segment display segments (active-low cathodes)
        seg :   out std_logic_vector(6 downto 0);
        -- 7-segment display active-low enables (anodes)
        an  :   out std_logic_vector(3 downto 0)
    );
end top_basys3;

architecture top_basys3_arch of top_basys3 is

    -- signal declarations
    signal w_floor1 : std_logic_vector(3 downto 0);
    signal w_floor2 : std_logic_vector(3 downto 0);
    signal slow_clk : std_logic;
    signal o_seg1 : std_logic_vector(6 downto 0);
    signal o_seg2 : std_logic_vector(6 downto 0);
    signal master_reset : std_logic;
    signal clk_reset : std_logic;
    signal fsm_reset : std_logic;
    signal reset_clkdiv : std_logic;
    signal reset_fsm_clk : std_logic;
    signal tdm_clk : std_logic;
    signal slow1 : std_logic;
    signal slow2 : std_logic;
  
	-- component declarations
    component sevenseg_decoder is
        port (
            i_Hex : in STD_LOGIC_VECTOR (3 downto 0);
            o_seg_n : out STD_LOGIC_VECTOR (6 downto 0)
        );
    end component sevenseg_decoder;
    
    component elevator_controller_fsm is
		Port (
            i_clk        : in  STD_LOGIC;
            i_reset      : in  STD_LOGIC;
            is_stopped   : in  STD_LOGIC;
            go_up_down   : in  STD_LOGIC;
            o_floor : out STD_LOGIC_VECTOR (3 downto 0)		   
		 );
	end component elevator_controller_fsm;
	
	component TDM4 is
		generic ( constant k_WIDTH : natural  := 4); -- bits in input and output
        Port ( i_clk		: in  STD_LOGIC;
           i_reset		: in  STD_LOGIC; -- asynchronous
           i_D3 		: in  STD_LOGIC_VECTOR (k_WIDTH - 1 downto 0);
		   i_D2 		: in  STD_LOGIC_VECTOR (k_WIDTH - 1 downto 0);
		   i_D1 		: in  STD_LOGIC_VECTOR (k_WIDTH - 1 downto 0);
		   i_D0 		: in  STD_LOGIC_VECTOR (k_WIDTH - 1 downto 0);
		   o_data		: out STD_LOGIC_VECTOR (k_WIDTH - 1 downto 0);
		   o_sel		: out STD_LOGIC_VECTOR (3 downto 0)	-- selected data line (one-cold)
	   );
    end component TDM4;
     
	component clock_divider is
        generic ( constant k_DIV : natural := 2	); -- How many clk cycles until slow clock toggles
                                                   -- Effectively, you divide the clk double this 
                                                   -- number (e.g., k_DIV := 2 --> clock divider of 4)
        port ( 	i_clk    : in std_logic;
                i_reset  : in std_logic;		   -- asynchronous
                o_clk    : out std_logic		   -- divided (slow) clock
        );
    end component clock_divider;
    
	
begin

    master_reset <= btnU;
    clk_reset <= btnL;
    fsm_reset <= btnR;
    
    reset_clkdiv <= clk_reset or master_reset;
    reset_fsm_clk <= fsm_reset or master_reset;
    
    
	-- PORT MAPS ----------------------------------------
	elevator_controller1_inst : elevator_controller_fsm
	port map (
	   i_clk => slow_clk,
	   i_reset => reset_fsm_clk,
	   is_stopped => sw(0),
	   go_up_down => sw(1),
	   o_floor => w_floor1
	);
	
	elevator_controller2_inst : elevator_controller_fsm
	port map (
	   i_clk => slow_clk,
	   i_reset => reset_fsm_clk,
	   is_stopped => sw(14),
	   go_up_down => sw(15),
	   o_floor => w_floor2
	);
	
	clk_div_inst: clock_divider
	generic map (k_DIV => 25000000)
	port map (
	   i_reset => reset_clkdiv,
	   i_clk => clk,
	   o_clk => slow_clk
    );
    
    clk_div_tdm_inst : clock_divider
    generic map (k_DIV => 50000)
    port map (
        i_reset => reset_clkdiv,
        i_clk => clk,
        o_clk => tdm_clk
    );
    
    sevenseg1_inst: sevenseg_decoder
    port map (
        i_Hex => w_floor1,
        o_seg_n => o_seg1
    );
    
    sevenseg2_inst: sevenseg_decoder
    port map (
        i_Hex => w_floor2,
        o_seg_n => o_seg2
    );
    
    TDM4_inst: TDM4
    generic map (k_WIDTH => 7)
    port map (
        i_clk => tdm_clk,
        i_reset => master_reset,
        i_D0 => o_seg1,
        i_D1 => "0001110",
        i_D2 => o_seg2,
        i_D3 => "0001110",
        o_data => seg,
        o_sel => an
    );

	   
    	
	
	-- CONCURRENT STATEMENTS ----------------------------
	
	-- LED 15 gets the FSM slow clock signal. The rest are grounded.
	led(15) <= slow_clk;
	led(14 downto 0) <= (others=>'0');
	
	-- leave unused switches UNCONNECTED. Ignore any warnings this causes.
	
	-- reset signals
	
end top_basys3_arch;
