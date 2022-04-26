                Amateur OS
                writen by Scott Billingsley
                using NASM and Sphinx C--

July 20,2001:
        This is the first real release that will do more than
        shell commands. Included in the package is a simple
        Hello World program and a graphic demo program. At this
        time it only runs a flat binary file, offset 0x0000. If
        you write something and it won't run, try putting the
        data at the end instead of at the head....Still trying to
        figure that one out. If you try to load a com file, it
        will load an return to the shell. Still trying to get
        the 0x0100 offset right...Someting else to figureout
        on Sphinx.
        If you want to use Sphinx to write some, a quick note.
        Put you vars as the first include file. Sphinx is a
        single pass phraser...If you call it before it's declared
        it will give an error....Took a little time to figure
        that out too...Just love incomplete docs....
        Enjoy the program. Any feedback is welcome....

July 30,2001:
        Well...Here it is.. The first Beta release. This version
        will run a binary and a com file. The command line is
        copied to offset 80h. It will also run a program and
        load a file into memory. The file routines are more compact
        and now all use the same interrupt to load them.  New
        interrupts have been added, some are for the kernel only
        and will be marked that way in the docs.
        New programs are a simple text file reader, and ftest, a
        program to show how to read the command line and search
        for a file..

