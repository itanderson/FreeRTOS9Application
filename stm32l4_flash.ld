/*
*****************************************************************************
**
**  File        : WXg2.ld
**
**  Abstract    : linker script for Weather Station STM32L475
**
**                Set heap size, stack size and stack location according
**                to application requirements.
**
**                Set QSPI bank area and size if external memory is used.
**
**  Target      : STM32L475xE
**
**  Environment : Atollic TrueSTUDIO(R)
**
**  Distribution: The file is distributed "as is", without any warranty
**                of any kind.
**
**  (c)Copyright Atollic AB.
**  You may use this file as-is or modify it according to the needs of your
**  project. This file may only be built (assembled or compiled and linked)
**  using the Atollic TrueSTUDIO(R) product. The use of this file together
**  with other tools than Atollic TrueSTUDIO(R) is not permitted.
**
*****************************************************************************
*/

/* Entry Point */
ENTRY(Reset_Handler)

/* Highest address of the user mode stack */
_estack = 0x20017C00;    	/* end of RAM (below bitband area) */

/* Generate a link error if heap and stack don't fit into RAM */
_Min_Heap_Size = 0x2000;    /* required amount of heap  */
_Min_Stack_Size = 0x400;	/* required amount of stack */

/* Specify the memory areas
**
** the top 1KB of SRAM1 is reserved for bit flags
**		 base = 0x22000000 + (0x17C00 * 0x20), 8K flags (1KB)
*/
MEMORY
{
  BOOT (rx)       : ORIGIN = 0x00000000, LENGTH = 512K
  SRAM2 (rwx)	  : ORIGIN = 0x10000000, LENGTH = 32K
  OTP_BLOCKS (rw) : ORIGIN = 0x1FFF7000, LENGTH = 1K
  SRAM1 (rw)      : ORIGIN = 0x20000000, LENGTH = 95K
  
  SRAMBB (rw)	  : ORIGIN = 0x222F8000, LENGTH = 32K
  
  BKPREG (rw)	  : ORIGIN = 0x40002850, LENGTH = 128
  
  FLASH (rwx)     : ORIGIN = 0x08000000, LENGTH = 512K
  FLASH_B1 (rw)   : ORIGIN = 0x08080000, LENGTH = 512K
  
  FLASH_QSPI (rw) : ORIGIN = 0x90000000, LENGTH = 8M
}

/* Define output sections */
SECTIONS
{
  /* The startup code loads at fixed address */
  .isr_vector :
  {
    . = ALIGN(0x200);
    _sflash0 = .;					/* start of application image */
    KEEP(*(.isr_vector))		 	/* application vector table, startup code */
    . = ALIGN(4);
    *(.progid .progid.*)			/* firmware ID */
    . = ALIGN(4);
    *(.dict*)		   				/* object dictionary */
    . = ALIGN(4);
    *(.startup)						/* runtime startup */
  } >FLASH

 /* The program code and other data goes into flash */
  .text :
  {
  	_stext = .;
    . = ALIGN(4);
    *(.text)           				/* .text sections (code) */
    *(.text*)          				/* .text* sections (code) */
    *(.glue_7)         				/* glue arm to thumb code */
    *(.glue_7t)       				/* glue thumb to arm code */
    *(.eh_frame)

    KEEP (*(.init))
    KEEP (*(.fini))

    . = ALIGN(4);
    _etext = .;        				/* define a global symbols at end of code */
    _eflash0 = .;					/* checksum area for code and const */
    _sflash1 = .;					/* start of area for RAM init */
  } >FLASH

  /* Constant data goes into FLASH */
  .rodata :
  {
    . = ALIGN(4);
    *(.rodata)         				/* .rodata sections (constants, strings, etc.) */
    *(.rodata*)        				/* .rodata* sections (constants, strings, etc.) */
    . = ALIGN(4);
  } >FLASH

  .ARM.extab   : { *(.ARM.extab* .gnu.linkonce.armextab.*) } >FLASH
  .ARM : {
  __exidx_start = .;
    *(.ARM.exidx*)
    __exidx_end = .;
  } >FLASH

  .preinit_array :
  {
    PROVIDE_HIDDEN (__preinit_array_start = .);
    KEEP (*(.preinit_array*))
    PROVIDE_HIDDEN (__preinit_array_end = .);
  } >FLASH
  .init_array :
  {
    PROVIDE_HIDDEN (__init_array_start = .);
    KEEP (*(SORT(.init_array.*)))
    KEEP (*(.init_array*))
    PROVIDE_HIDDEN (__init_array_end = .);
  } >FLASH
  .fini_array :
  {
    PROVIDE_HIDDEN (__fini_array_start = .);
    KEEP (*(SORT(.fini_array.*)))
    KEEP (*(.fini_array*))
    PROVIDE_HIDDEN (__fini_array_end = .);
  } >FLASH

  /* used by the startup to initialize data */
  _sidata = LOADADDR(.data);

  /* Initialized data sections goes into SRAM1 */
  .data :
  {
    . = ALIGN(4);
    _sdata = .;        				/* create a global symbol at data start */
    *(.data)           				/* .data sections */
    *(.data*)          				/* .data* sections */
	. = ALIGN(4);	   				/* word align, follows runtime init */ 
    _edata = .;        				/* define a global symbol at data end */
  } >SRAM1 AT> FLASH
  
  /* Infomem configuration parameters into SRAM1 (not preserved across reset) */
  .infomem :
  {
    . = ALIGN(4);
	_sinfomem = .;		   		    /* start working configuration parameters */
	*(.infomem*)	   				/* default field parameters */
	. = ALIGN(4);	   				/* word align for fast init */
	_einfomem = .;		   		    /* end working config parameters (exact byte count) */
  } >SRAM1 AT> FLASH
  
  /* mark end of flash image */
  _eflash0 = LOADADDR(.top);
  .top :
  {
    . = ALIGN(4);
    *(.top)           				/* mark end of flash image */
  } >FLASH
		
  /* User_heap_stack section, used to check that there is enough SRAM1 left */
  ._user_heap_stack :
  {
    . = ALIGN(4);
    _sheap = .;
    *(.heap*)	   				/* default field parameters */
    . = . + _Min_Heap_Size;
    . = . + _Min_Stack_Size;
    . = ALIGN(4);
  } >SRAM1
  	_eheap = ABSOLUTE(0x20017000);		/* end of heap, 3KB for system stack */	
	_sptop = ABSOLUTE(0x20017C00);		/* system SP on reset, 1KB for flags */
	
  /* Uninitialized data section, DMA buffers in SRAM2 */
  .bss (NOLOAD) :
  {
    /* This is used by the startup in order to initialize the .bss secion */
     . = ALIGN(4);
    _sbss = .;         				/* define a global symbol at bss start */
    __bss_start__ = _sbss;
    *(.bss)
    *(.bss*)
    *(COMMON)
    . = ALIGN(4);
    _ebss = .;         				/* define a global symbol at bss end */
    __bss_end__ = _ebss;
    
    . = ALIGN(8);
    *(.dma)
  } >SRAM2

  PROVIDE ( end = _ebss );
  PROVIDE ( _end = _ebss );

/* The SNMP section is used for non-volatile counters, preserved across resets in SRAM2 */
  . = ALIGN(4);
  .snmp (NOLOAD) :
  {
	. = ALIGN(4);					/* word align for fast init */
	_ssnmp = .;
	*(.snmp)						/* statistical objects */
	. = ALIGN(4);					/* word align for init */
	_esnmp = .;
  } > SRAM2

/* the BKPREG section references persistent RTC backup registers */
  .bkpreg (NOLOAD) :
  {
	. = ALIGN(4);					/* RTC backup registers */ 
	_sbkpreg = .;
	*(.bkpreg*)						/* persistent RAM storage */
	. = ALIGN(4);
	_ebkpreg = .;
  } > BKPREG
	
/* the OTP region is used for indelible parameters */
  .otp (NOLOAD) :
  {
	. = ALIGN(4);					/* write once flash */ 
	_sotp = .;
	*(.otp*)						/* update records */
	_eotp = .;
  } > OTP_BLOCKS
	
/* the RAMBB section is used to allocate SRAM bit flags as words */
  .rambb (NOLOAD) :
  {
		. = ALIGN(4);				/* word align BitBand alias start */ 
		_srambb = .;
		*(.rambb*)					/* volatile boolean flags */
		. = ALIGN(4);				/* word align for init */
		_erambb = .;
  } > SRAMBB

  /* Remove information from the standard libraries */
  /DISCARD/ :
  {
    libc.a ( * )
    libm.a ( * )
    libgcc.a ( * )
  }

  .ARM.attributes 0 : { *(.ARM.attributes) }
}
