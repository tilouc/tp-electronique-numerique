-- ============================================================================
-- tb_DecodeurIR.vhd : banc de test du decodeur IR complet (parties 3 a 6)
--
-- Le banc de test genere, comme une vraie telecommande, des messages au
-- protocole NEC (cf. paragraphe 2.2 du sujet) tels qu'ils arrivent sur la
-- patte Y15 du FPGA, c'est-a-dire INVERSES par le recepteur IR :
--    'burst' (lumiere)   -> IR_RX = '0'
--    espace  (pas de lumiere) -> IR_RX = '1'
--
-- Sequence simulee :
--    1) appui sur la touche '5'  (adresse 0x00, commande 0x05)
--    2) un code repetitif (touche maintenue) -> doit etre ignore
--    3) appui sur la touche 'A'  (adresse 0x00, commande 0x0F)
--
-- Verifications automatiques (messages dans la console) :
--    - Command[15..0] = (non commande) & commande  apres chaque message
--    - les LEDs vertes changent d'etat a chaque preambule detecte
-- ============================================================================
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity tb_DecodeurIR is
	generic (
		-- ecart de cadence de la telecommande par rapport a la norme NEC, en
		-- pour mille. La telecommande du TP est environ 0,5 % plus lente que
		-- la norme (remarque 1 du paragraphe 3.3, d'ou R-1 augmente de 0,5 %).
		ECART_POUR_MILLE : integer := 5;
		-- decalage du premier appui en us (change la phase d'echantillonnage)
		DEPHASAGE_US     : integer := 0
	);
end entity tb_DecodeurIR;

architecture sim of tb_DecodeurIR is

	constant CLK_PERIOD : time := 20 ns;       -- oscillateur 50 MHz
	-- duree d'un 'burst' NEC (562,5 us selon la norme)
	constant BURST      : time := 562.5 us * (1.0 + real(ECART_POUR_MILLE) / 1000.0);

	signal MainClk           : std_logic := '0';
	signal IR_RX             : std_logic := '1';   -- repos : pas de lumiere
	signal IR_RXCopy         : std_logic;
	signal SamplingEdge      : std_logic;
	signal StartEvent        : std_logic;
	signal AddressInProgress : std_logic;
	signal CommandInProgress : std_logic;
	signal LEDG0, LEDG1, LEDG2, LEDG3 : std_logic;
	signal Command           : std_logic_vector(15 downto 0);

	signal fin_simulation    : boolean := false;

	function hex(v : std_logic_vector) return string is
		constant digits : string(1 to 16) := "0123456789ABCDEF";
		variable r : string(1 to v'length / 4);
		variable n : integer;
	begin
		for i in r'range loop
			n := to_integer(unsigned(v(v'left - (i - 1) * 4 downto v'left - (i - 1) * 4 - 3)));
			r(i) := digits(n + 1);
		end loop;
		return r;
	end function;

begin

	-- ------------------------------------------------------------------------
	-- circuit teste (schema DecodeurIR.bdf)
	-- ------------------------------------------------------------------------
	dut : entity work.DecodeurIR
		port map (
			MainClk           => MainClk,
			IR_RX             => IR_RX,
			IR_RXCopy         => IR_RXCopy,
			SamplingEdge      => SamplingEdge,
			StartEvent        => StartEvent,
			AddressInProgress => AddressInProgress,
			CommandInProgress => CommandInProgress,
			LEDG0             => LEDG0,
			LEDG1             => LEDG1,
			LEDG2             => LEDG2,
			LEDG3             => LEDG3,
			Command15         => Command(15),
			Command14         => Command(14),
			Command13         => Command(13),
			Command12         => Command(12),
			Command11         => Command(11),
			Command10         => Command(10),
			Command9          => Command(9),
			Command8          => Command(8),
			Command7          => Command(7),
			Command6          => Command(6),
			Command5          => Command(5),
			Command4          => Command(4),
			Command3          => Command(3),
			Command2          => Command(2),
			Command1          => Command(1),
			Command0          => Command(0)
		);

	-- ------------------------------------------------------------------------
	-- horloge 50 MHz (patte Y2)
	-- ------------------------------------------------------------------------
	MainClk <= not MainClk after CLK_PERIOD / 2 when not fin_simulation else '0';

	-- ------------------------------------------------------------------------
	-- telecommande IR
	-- ------------------------------------------------------------------------
	telecommande : process

		-- impulsion lumineuse de n 'bursts' (sortie du recepteur a '0')
		procedure lumiere(n : positive) is
		begin
			IR_RX <= '0';
			wait for n * BURST;
		end procedure;

		-- espace de n 'bursts' (sortie du recepteur a '1')
		procedure espace(n : positive) is
		begin
			IR_RX <= '1';
			wait for n * BURST;
		end procedure;

		-- un octet, LSB transmis en premier
		procedure octet(v : std_logic_vector(7 downto 0)) is
		begin
			for i in 0 to 7 loop
				lumiere(1);
				if v(i) = '1' then
					espace(3);     -- '1' : 1 burst + 3 espaces
				else
					espace(1);     -- '0' : 1 burst + 1 espace
				end if;
			end loop;
		end procedure;

		-- message NEC complet (67,5 ms)
		procedure message(adresse, commande : std_logic_vector(7 downto 0)) is
		begin
			lumiere(16);              -- preambule 9 ms
			espace(8);                -- espace 4,5 ms
			octet(adresse);
			octet(not adresse);
			octet(commande);
			octet(not commande);
			lumiere(1);               -- impulsion finale
			IR_RX <= '1';
		end procedure;

		-- code repetitif (touche maintenue)
		procedure code_repetitif is
		begin
			lumiere(16);              -- preambule 9 ms
			espace(4);                -- espace 2,25 ms
			lumiere(1);               -- impulsion finale
			IR_RX <= '1';
		end procedure;

		procedure verifie(attendu : std_logic_vector(15 downto 0); led : std_logic; nom : string) is
		begin
			assert Command = attendu
				report "ERREUR " & nom & " : Command = 0x" & hex(Command) &
				       " (attendu 0x" & hex(attendu) & ")" severity error;
			assert LEDG0 = led and LEDG1 = led and LEDG2 = led and LEDG3 = led
				report "ERREUR " & nom & " : etat des LEDs vertes incorrect" severity error;
			if Command = attendu and LEDG0 = led then
				report "OK " & nom & " : Command = 0x" & hex(Command) &
				       "  (commande 0x" & hex(Command(7 downto 0)) & ")";
			end if;
		end procedure;

	begin
		IR_RX <= '1';
		wait for 2 ms + DEPHASAGE_US * 1 us;

		-- 1) touche '5' : code commande 0x05
		message(x"00", x"05");
		wait for 2 ms;
		verifie(x"FA05", '1', "touche 5");

		-- 2) touche maintenue : code repetitif ~40 ms apres le message
		wait for 38 ms;
		code_repetitif;
		wait for 2 ms;
		verifie(x"FA05", '1', "code repetitif");

		-- 3) touche 'A' : code commande 0x0F
		wait for 20 ms;
		message(x"00", x"0F");
		wait for 2 ms;
		verifie(x"F00F", '0', "touche A");

		report "FIN DE SIMULATION";
		fin_simulation <= true;
		wait;
	end process;

end architecture sim;
