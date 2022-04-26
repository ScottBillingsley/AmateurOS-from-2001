# AmateurOS-from-2001
File from a basic operating system I wrote a long time ago...

Boot.asm &ensp;&ensp;&nbsp; The main bootloader for the 1.44 floppy drive  
Loader.asm &ensp;		Loads the splash screen and main kernel  
Kernel	&emsp;&emsp;&ensp;			The main files of the kernel

Orignal Readme Page...   

    On this page is the design specs for Amateur OS... For now it is only  
    in the 16 bit mode...I am writing it mainly to work with DSP so I don't  
    see this as a problem...On with the show....  
    
  1. What is the primary goal of my OS?  
     Real time to use for DSP and Amateur radio modes...  
     My goal is for no TSRs and a library of routines to  
     program into apps...Minamul kernel support...  
     ie...As few interrupts as possible..  
       
       
  2. What platforms will Amateur support?  
     i386 systems of 486 or above...  
     Standard hardware:  
     VGA video write to standard ports..  
     COM port standard, fossil driver..  
     Printer port for I/O..  
     Sound Blaster 16 for DSP..  
            
  3. Will it be multitasking?  
     No...Single user, single app...16 bit real mode  
     
  4. What file system will it use?  
     FAT 12 and FAT 16...Why reinvent the wheel..
     
  5. Why am I doing this????  
     Other that the fact that I've gone nuts??  
     I want to learn more about the computer...  
     I want to know why things do what they do...  
     
