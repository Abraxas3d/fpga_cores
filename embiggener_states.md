# State Diagram for Embiggener

This VHDL entity translates a 32-bit-wide AXI-S interface (DMA) to the 128-bit-wide interface (similar to AXI-S) expected by the DAC FIFO in the Analog Devices ADRV9371-ZC706 reference design.

```mermaid
stateDiagram-v2
state "Empty:\nNo input data in the output register\ns_tready = 1\nm_tvalid = 0" as empty
state "Load0:\nStrobing input data into the LS bits of output register\ns_tready = 0\nm_tvalid = 0" as load0
state "Have0:\nOne word in the output register, awaiting second word\ns_tready = 1\nm_tvalid = 0" as have0
state "Load1:\nStrobing input data into the next bits of output register\ns_tready = 0\nm_tvalid = 0" as load1
state "Have1:\nTwo words in the output register, awaiting third word\ns_tready = 1\nm_tvalid = 0" as have1
state "Load2:\nStrobing input data into the next bits of output register\ns_tready = 0\nm_tvalid = 0" as load2
state "Have2:\nThree words in the output register, awaiting fourth word\ns_tready = 1\nm_tvalid = 0" as have2
state "Load3:\nStrobing input data into the MS bits of output register\ns_tready = 0\nm_tvalid = 0" as load3
state "Have3:\nOutput register full, awaiting consumer\ns_tready = 0\nm_tvalid = 1" as have3

[*] --> empty: Reset
empty --> load0: s_tvalid high
load0 --> have0
have0 --> load1: s_tvalid high
load1 --> have1
have1 --> load2: s_tvalid high
load2 --> have2
have2 --> load3: s_tvalid high
load3 --> have3
have3 --> empty: m_tready high

```

