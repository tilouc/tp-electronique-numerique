-- ============================================================================
-- DecodeurIR_rtl.vhd : traduction VHDL du schema DecodeurIR.bdf
--
-- Fichier genere par Quartus a partir du schema (equivalent du menu
-- File -> Create / Update -> Create HDL Design File from Current File),
-- utilise uniquement pour la simulation RTL sous ModelSim / Questa.
-- Le script ../../run.sh le regenere automatiquement a partir du schema.
--
-- Seule modification : les deux bascules DFFE (inst4 et inst8) demarrent a
-- '0', comme dans le FPGA a la mise sous tension (sinon elles resteraient a
-- 'U' en simulation car leur entree D depend de leur propre sortie).
-- ============================================================================
-- Copyright (C) 2019  Intel Corporation. All rights reserved.
-- Your use of Intel Corporation's design tools, logic functions 
-- and other software and tools, and any partner logic 
-- functions, and any output files from any of the foregoing 
-- (including device programming or simulation files), and any 
-- associated documentation or information are expressly subject 
-- to the terms and conditions of the Intel Program License 
-- Subscription Agreement, the Intel Quartus Prime License Agreement,
-- the Intel FPGA IP License Agreement, or other applicable license
-- agreement, including, without limitation, that your use is for
-- the sole purpose of programming logic devices manufactured by
-- Intel and sold by Intel or its authorized distributors.  Please
-- refer to the applicable agreement for further details, at
-- https://fpgasoftware.intel.com/eula.

-- PROGRAM		"Quartus Prime"
-- VERSION		"Version 19.1.0 Build 670 09/22/2019 SJ Lite Edition"
-- CREATED		"Wed Oct  7 10:42:33 2026"

LIBRARY ieee;
USE ieee.std_logic_1164.all; 

LIBRARY work;

ENTITY DecodeurIR IS 
	PORT
	(
		MainClk :  IN  STD_LOGIC;
		IR_RX :  IN  STD_LOGIC;
		SamplingEdge :  OUT  STD_LOGIC;
		IR_RXCopy :  OUT  STD_LOGIC;
		StartEvent :  OUT  STD_LOGIC;
		LEDG0 :  OUT  STD_LOGIC;
		LEDG1 :  OUT  STD_LOGIC;
		LEDG2 :  OUT  STD_LOGIC;
		LEDG3 :  OUT  STD_LOGIC;
		AddressInProgress :  OUT  STD_LOGIC;
		CommandInProgress :  OUT  STD_LOGIC;
		Command15 :  OUT  STD_LOGIC;
		Command14 :  OUT  STD_LOGIC;
		Command13 :  OUT  STD_LOGIC;
		Command12 :  OUT  STD_LOGIC;
		Command11 :  OUT  STD_LOGIC;
		Command10 :  OUT  STD_LOGIC;
		Command9 :  OUT  STD_LOGIC;
		Command8 :  OUT  STD_LOGIC;
		Command7 :  OUT  STD_LOGIC;
		Command6 :  OUT  STD_LOGIC;
		Command5 :  OUT  STD_LOGIC;
		Command4 :  OUT  STD_LOGIC;
		Command3 :  OUT  STD_LOGIC;
		Command2 :  OUT  STD_LOGIC;
		Command1 :  OUT  STD_LOGIC;
		Command0 :  OUT  STD_LOGIC
	);
END DecodeurIR;

ARCHITECTURE bdf_type OF DecodeurIR IS 

COMPONENT counter_nbits
	PORT(sclr : IN STD_LOGIC;
		 clock : IN STD_LOGIC;
		 q : OUT STD_LOGIC_VECTOR(14 DOWNTO 0)
	);
END COMPONENT;

COMPONENT countmod48
	PORT(sclr : IN STD_LOGIC;
		 clock : IN STD_LOGIC;
		 clk_en : IN STD_LOGIC;
		 q : OUT STD_LOGIC_VECTOR(5 DOWNTO 0)
	);
END COMPONENT;

COMPONENT compareto47
	PORT(dataa : IN STD_LOGIC_VECTOR(5 DOWNTO 0);
		 aeb : OUT STD_LOGIC
	);
END COMPONENT;

COMPONENT comp_maxvalue
	PORT(dataa : IN STD_LOGIC_VECTOR(14 DOWNTO 0);
		 aeb : OUT STD_LOGIC
	);
END COMPONENT;

COMPONENT framedecoder
	PORT(reset : IN STD_LOGIC;
		 clock : IN STD_LOGIC;
		 ClockEnable : IN STD_LOGIC;
		 StartEvent : IN STD_LOGIC;
		 CounterIs47 : IN STD_LOGIC;
		 AddressInProgress : OUT STD_LOGIC;
		 CommandInProgress : OUT STD_LOGIC;
		 ResetCounter : OUT STD_LOGIC
	);
END COMPONENT;

COMPONENT count2bits
	PORT(sclr : IN STD_LOGIC;
		 clock : IN STD_LOGIC;
		 clk_en : IN STD_LOGIC;
		 q : OUT STD_LOGIC_VECTOR(1 DOWNTO 0)
	);
END COMPONENT;

COMPONENT shiftreg16bits
	PORT(clock : IN STD_LOGIC;
		 enable : IN STD_LOGIC;
		 shiftin : IN STD_LOGIC;
		 q : OUT STD_LOGIC_VECTOR(15 DOWNTO 0)
	);
END COMPONENT;

COMPONENT shiftreg24bits
	PORT(clock : IN STD_LOGIC;
		 enable : IN STD_LOGIC;
		 shiftin : IN STD_LOGIC;
		 q : OUT STD_LOGIC_VECTOR(23 DOWNTO 0)
	);
END COMPONENT;

COMPONENT compleadpulse
	PORT(dataa : IN STD_LOGIC_VECTOR(23 DOWNTO 0);
		 aeb : OUT STD_LOGIC
	);
END COMPONENT;

SIGNAL	CommandInProgress_ALTERA_SYNTHESIZED :  STD_LOGIC;
SIGNAL	CounterIs47 :  STD_LOGIC;
SIGNAL	CountOut :  STD_LOGIC_VECTOR(5 DOWNTO 0);
SIGNAL	ResetCounter :  STD_LOGIC;
SIGNAL	SamplingClk :  STD_LOGIC;
SIGNAL	SpaceCount :  STD_LOGIC_VECTOR(1 DOWNTO 0);
SIGNAL	SpaceCountIs3 :  STD_LOGIC;
SIGNAL	StartEvent_ALTERA_SYNTHESIZED :  STD_LOGIC;
SIGNAL	SYNTHESIZED_WIRE_0 :  STD_LOGIC_VECTOR(14 DOWNTO 0);
SIGNAL	SYNTHESIZED_WIRE_1 :  STD_LOGIC;
SIGNAL	SYNTHESIZED_WIRE_2 :  STD_LOGIC;
SIGNAL	SYNTHESIZED_WIRE_3 :  STD_LOGIC;
SIGNAL	SYNTHESIZED_WIRE_4 :  STD_LOGIC;
SIGNAL	DFFE_inst4 :  STD_LOGIC := '0';
SIGNAL	SYNTHESIZED_WIRE_5 :  STD_LOGIC;
SIGNAL	SYNTHESIZED_WIRE_6 :  STD_LOGIC;
SIGNAL	SYNTHESIZED_WIRE_7 :  STD_LOGIC;
SIGNAL	SYNTHESIZED_WIRE_8 :  STD_LOGIC_VECTOR(23 DOWNTO 0);
SIGNAL	SYNTHESIZED_WIRE_9 :  STD_LOGIC;
SIGNAL	SYNTHESIZED_WIRE_10 :  STD_LOGIC;
SIGNAL	SYNTHESIZED_WIRE_26 :  STD_LOGIC := '0';
SIGNAL	SYNTHESIZED_WIRE_27 :  STD_LOGIC_VECTOR(15 DOWNTO 0);


BEGIN 
SamplingEdge <= DFFE_inst4;
LEDG0 <= SYNTHESIZED_WIRE_26;
LEDG1 <= SYNTHESIZED_WIRE_26;
LEDG2 <= SYNTHESIZED_WIRE_26;
LEDG3 <= SYNTHESIZED_WIRE_26;
Command15 <= SYNTHESIZED_WIRE_27(15);
Command14 <= SYNTHESIZED_WIRE_27(14);
Command13 <= SYNTHESIZED_WIRE_27(13);
Command12 <= SYNTHESIZED_WIRE_27(12);
Command11 <= SYNTHESIZED_WIRE_27(11);
Command10 <= SYNTHESIZED_WIRE_27(10);
Command9 <= SYNTHESIZED_WIRE_27(9);
Command8 <= SYNTHESIZED_WIRE_27(8);
Command7 <= SYNTHESIZED_WIRE_27(7);
Command6 <= SYNTHESIZED_WIRE_27(6);
Command5 <= SYNTHESIZED_WIRE_27(5);
Command4 <= SYNTHESIZED_WIRE_27(4);
Command3 <= SYNTHESIZED_WIRE_27(3);
Command2 <= SYNTHESIZED_WIRE_27(2);
Command1 <= SYNTHESIZED_WIRE_27(1);
Command0 <= SYNTHESIZED_WIRE_27(0);
SYNTHESIZED_WIRE_1 <= '0';
SYNTHESIZED_WIRE_10 <= '1';



b2v_inst : counter_nbits
PORT MAP(sclr => SamplingClk,
		 clock => MainClk,
		 q => SYNTHESIZED_WIRE_0);

IR_RXCopy <= IR_RX;



b2v_inst16 : countmod48
PORT MAP(sclr => ResetCounter,
		 clock => MainClk,
		 clk_en => SamplingClk,
		 q => CountOut);


b2v_inst17 : compareto47
PORT MAP(dataa => CountOut,
		 aeb => CounterIs47);



b2v_inst2 : comp_maxvalue
PORT MAP(dataa => SYNTHESIZED_WIRE_0,
		 aeb => SamplingClk);


b2v_inst20 : framedecoder
PORT MAP(reset => SYNTHESIZED_WIRE_1,
		 clock => MainClk,
		 ClockEnable => SamplingClk,
		 StartEvent => StartEvent_ALTERA_SYNTHESIZED,
		 CounterIs47 => CounterIs47,
		 AddressInProgress => AddressInProgress,
		 CommandInProgress => CommandInProgress_ALTERA_SYNTHESIZED,
		 ResetCounter => ResetCounter);


b2v_inst21 : count2bits
PORT MAP(sclr => SYNTHESIZED_WIRE_2,
		 clock => MainClk,
		 clk_en => SamplingClk,
		 q => SpaceCount);


SYNTHESIZED_WIRE_4 <= NOT(CommandInProgress_ALTERA_SYNTHESIZED);



SYNTHESIZED_WIRE_3 <= NOT(IR_RX);



SYNTHESIZED_WIRE_2 <= SYNTHESIZED_WIRE_3 OR SYNTHESIZED_WIRE_4;


SpaceCountIs3 <= SpaceCount(1) AND SpaceCount(0);


SYNTHESIZED_WIRE_7 <= NOT(DFFE_inst4);



SYNTHESIZED_WIRE_6 <= SYNTHESIZED_WIRE_5 AND CommandInProgress_ALTERA_SYNTHESIZED AND SamplingClk;


b2v_inst31 : shiftreg16bits
PORT MAP(clock => MainClk,
		 enable => SYNTHESIZED_WIRE_6,
		 shiftin => SpaceCountIs3,
		 q => SYNTHESIZED_WIRE_27);


SYNTHESIZED_WIRE_5 <= NOT(IR_RX);



PROCESS(MainClk)
BEGIN
IF (RISING_EDGE(MainClk)) THEN
	IF (SamplingClk = '1') THEN
	DFFE_inst4 <= SYNTHESIZED_WIRE_7;
	END IF;
END IF;
END PROCESS;


b2v_inst5 : shiftreg24bits
PORT MAP(clock => MainClk,
		 enable => SamplingClk,
		 shiftin => IR_RX,
		 q => SYNTHESIZED_WIRE_8);


b2v_inst6 : compleadpulse
PORT MAP(dataa => SYNTHESIZED_WIRE_8,
		 aeb => StartEvent_ALTERA_SYNTHESIZED);



PROCESS(StartEvent_ALTERA_SYNTHESIZED)
BEGIN
IF (RISING_EDGE(StartEvent_ALTERA_SYNTHESIZED)) THEN
	IF (SYNTHESIZED_WIRE_10 = '1') THEN
	SYNTHESIZED_WIRE_26 <= SYNTHESIZED_WIRE_9;
	END IF;
END IF;
END PROCESS;


SYNTHESIZED_WIRE_9 <= NOT(SYNTHESIZED_WIRE_26);


StartEvent <= StartEvent_ALTERA_SYNTHESIZED;
CommandInProgress <= CommandInProgress_ALTERA_SYNTHESIZED;

END bdf_type;