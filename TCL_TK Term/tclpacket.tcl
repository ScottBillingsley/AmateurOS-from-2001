#!/usr/local/bin/wish8.0 -f
#!/bin/sh
# the next line restarts using wish\
#exec wish "$0" "$@" 

if {![info exists vTcl(sourcing)]} {
    switch $tcl_platform(platform) {
	windows {
	}
	default {
	    option add *Scrollbar.width 10
	}
    }
    
}
#################################################
#Change the settings below to match the platform and OS.....
#
#set serial_port "com1"
set serial_port "/dev/cuaa0"
set baudrate 9600
#
############################
# vTcl Code to Load Stock Fonts


if {![info exist vTcl(sourcing)]} {
set vTcl(fonts,counter) 0
proc vTcl:font:add_font {font_descr font_type newkey} {
     global vTcl

     incr vTcl(fonts,counter)
     set newfont [eval font create $font_descr]

     lappend vTcl(fonts,objects) $newfont

     # each font has its unique key so that when a project is
     # reloaded, the key is used to find the font description

     if {$newkey == ""} {
          set newkey vTcl:font$vTcl(fonts,counter)

          # let's find an unused font key
          while {[vTcl:font:get_font $newkey] != ""} {
             incr vTcl(fonts,counter)
             set newkey vTcl:font$vTcl(fonts,counter)
          }
     }

     set vTcl(fonts,$newfont,type)                      $font_type
     set vTcl(fonts,$newfont,key)                       $newkey
     set vTcl(fonts,$vTcl(fonts,$newfont,key),object)   $newfont

     lappend vTcl(fonts,$font_type) $newfont

     # in case caller needs it
     return $newfont
}

proc vTcl:font:get_font {key} {
    global vTcl
    if {[info exists vTcl(fonts,$key,object)]} then {
        return $vTcl(fonts,$key,object)
    } else {
        return ""
    }
}

vTcl:font:add_font \
    "-family helvetica -size 12 -weight normal -slant roman -underline 0 -overstrike 0" \
    stock \
    vTcl:font1
vTcl:font:add_font \
    "-family helvetica -size 12 -weight normal -slant roman -underline 1 -overstrike 0" \
    stock \
    underline
vTcl:font:add_font \
    "-family lucida -size 18 -weight normal -slant roman -underline 0 -overstrike 0" \
    stock \
    vTcl:font8
}
#############################################################################
# Visual Tcl v1.51 Project
#

#################################
# VTCL LIBRARY PROCEDURES
#

if {![info exists vTcl(sourcing)]} {
proc Window {args} {
    global vTcl
    set cmd     [lindex $args 0]
    set name    [lindex $args 1]
    set newname [lindex $args 2]
    set rest    [lrange $args 3 end]
    if {$name == "" || $cmd == ""} { return }
    if {$newname == ""} { set newname $name }
    if {$name == "."} { wm withdraw $name; return }
    set exists [winfo exists $newname]
    switch $cmd {
        show {
            if {$exists} { wm deiconify $newname; return }
            if {[info procs vTclWindow(pre)$name] != ""} {
                eval "vTclWindow(pre)$name $newname $rest"
            }
            if {[info procs vTclWindow$name] != ""} {
                eval "vTclWindow$name $newname $rest"
            }
            if {[info procs vTclWindow(post)$name] != ""} {
                eval "vTclWindow(post)$name $newname $rest"
            }
        }
        hide    { if $exists {wm withdraw $newname; return} }
        iconify { if $exists {wm iconify $newname; return} }
        destroy { if $exists {destroy $newname; return} }
    }
}

proc vTcl:WindowsCleanup {} {
    global vTcl
    if {[info exists vTcl(sourcing)]} { return }
    foreach w [winfo children .] {
    	wm protocol $w WM_DELETE_WINDOW { exit }
    }
}
}

if {![info exists vTcl(sourcing)]} {
proc {vTcl:DefineAlias} {target alias widgetProc top_or_alias cmdalias} {
    global widget

    set widget($alias) $target
    set widget(rev,$target) $alias

    if {$cmdalias} {
        interp alias {} $alias {} $widgetProc $target
    }

    if {$top_or_alias != ""} {
        set widget($top_or_alias,$alias) $target

        if {$cmdalias} {
            interp alias {} $top_or_alias.$alias {} $widgetProc $target
        }
    }
}

proc {vTcl:Toplevel:WidgetProc} {w args} {
    if {[llength $args] == 0} {
        return -code error "wrong # args: should be \"$w option ?arg arg ...?\""
    }

    ## The first argument is a switch, they must be doing a configure.
    if {[string index $args 0] == "-"} {
        set command configure

        ## There's only one argument, must be a cget.
        if {[llength $args] == 1} {
            set command cget
        }
    } else {
        set command [lindex $args 0]
        set args [lrange $args 1 end]
    }

    switch -- $command {
        "hide" -
        "Hide" {
            Window hide $w
        }

        "show" -
        "Show" {
            Window show $w
        }

        "ShowModal" {
            Window show $w
            raise $w
            grab $w
            tkwait window $w
            grab release $w
        }

        default {
            eval $w $command $args
        }
    }
}

proc {vTcl:WidgetProc} {w args} {
    if {[llength $args] == 0} {
        return -code error "wrong # args: should be \"$w option ?arg arg ...?\""
    }

    ## The first argument is a switch, they must be doing a configure.
    if {[string index $args 0] == "-"} {
        set command configure

        ## There's only one argument, must be a cget.
        if {[llength $args] == 1} {
            set command cget
        }
    } else {
        set command [lindex $args 0]
        set args [lrange $args 1 end]
    }

    eval $w $command $args
}
}

if {[info exists vTcl(sourcing)]} {
proc vTcl:project:info {} {
    namespace eval ::widgets::.top21 {
        array set save {-background 1}
    }
    namespace eval ::widgets::.top21.men25 {
        array set save {-activebackground 1 -background 1 -font 1 -height 1 -menu 1 -padx 1 -pady 1 -text 1 -width 1}
    }
    namespace eval ::widgets::.top21.men25.m {
        array set save {-activeborderwidth 1 -borderwidth 1 -font 1}
    }
    namespace eval ::widgets::.top21.fra31 {
        array set save {-background 1 -borderwidth 1 -height 1 -relief 1 -width 1}
    }
    namespace eval ::widgets::.top21.fra31.tex32 {
        array set save {-font 1 -foreground 1 -height 1 -width 1 -wrap 1 -yscrollcommand 1}
    }
    namespace eval ::widgets::.top21.fra31.scr33 {
        array set save {-background 1 -command 1 -troughcolor 1}
    }
    namespace eval ::widgets::.top21.fra35 {
        array set save {-background 1 -borderwidth 1 -height 1 -relief 1 -width 1}
    }
    namespace eval ::widgets::.top21.fra35.tex36 {
        array set save {-font 1 -height 1 -width 1 -wrap 1 -yscrollcommand 1}
    }
    namespace eval ::widgets::.top21.fra35.scr37 {
        array set save {-command 1}
    }
    namespace eval ::widgets::.top21.men22 {
        array set save {-background 1 -font 1 -height 1 -menu 1 -padx 1 -pady 1 -text 1 -width 1}
    }
    namespace eval ::widgets::.top21.men22.m {
        array set save {-activeborderwidth 1 -borderwidth 1 -font 1}
    }
    namespace eval ::widgets::.top24 {
        array set save {}
    }
    namespace eval ::widgets::.top24.mes25 {
        array set save {-font 1 -padx 1 -pady 1 -text 1 -width 1}
    }
    namespace eval ::widgets::.top24.mes26 {
        array set save {-font 1 -padx 1 -pady 1 -text 1 -width 1}
    }
    namespace eval ::widgets::.top24.mes27 {
        array set save {-font 1 -padx 1 -pady 1 -text 1 -width 1}
    }
    namespace eval ::widgets::.top24.mes28 {
        array set save {-padx 1 -pady 1 -text 1 -width 1}
    }
    namespace eval ::widgets::.top24.mes29 {
        array set save {-padx 1 -pady 1 -text 1 -width 1}
    }
    namespace eval ::widgets::.top24.but30 {
        array set save {-command 1 -height 1 -pady 1 -text 1 -width 1}
    }
    namespace eval ::widgets_bindings {
        set tagslist {}
    }
}
}
#################################
# USER DEFINED PROCEDURES
#

proc {ExitProgram} {exitvalue} {
global widget
exit $exitvalue
}

proc {read_byte} {} {
global widget
global serID

	set value [read $serID 5]
	
	rx insert end $value
	rx yview scroll 1 unit
}

proc {read_key} {} {
global widget
global text
	global line_number
	global column_number
	global serID

	set cursor_pos [tx index insert]

	set line_number [string range $cursor_pos 0  [string first "." $cursor_pos]]

        set column_number [string range $cursor_pos  [expr [string first "." $cursor_pos] + 1]  [string length $cursor_pos]]
	set cursor_current [string trim "$line_number [expr $column_number - 1]" " "]

	set key [tx get $cursor_current]

	if {$key == "\n" } {
	set line_start [expr $cursor_pos - 1.0]
	set text [tx get $line_start $cursor_current]

#	rx insert end $text
	tx yview scroll 1 unit
	puts -nonewline $serID $text
#	flush $serID

	}
}

proc {setup} {} {
global widget
	global serial_port
        global serID
	global baudrate
if [catch "open $serial_port RDWR" serID ] {
	puts stdout "Problems opening serial port: $serial_port"
	puts stderr "Could not open serial port"
	ExitProgram 1
}

 #Set the baudrate and asynchronous format
if [catch "fconfigure $serID -mode $baudrate,n,8,1 -blocking 0  -translation {auto cr} -buffering none"] {
	puts stdout "Problems attempting to set baudrate"
	puts stderr "Could not set baudrate"
	ExitProgram 1
}
fileevent $serID readable read_byte
}

proc {main} {argc argv} {
## This will clean up and call exit properly on Windows.
vTcl:WindowsCleanup
#--------	Set the serial port
#
#
#
global serID
global serial_port
global baudrate
global line_number
global column_number
global text
#
#set serial_port "com1"
#set baudrate 9600
#
set line_number 1
set column_number 0
set text ""
#
#######################
#	Start the comport....
setup
#
#######################
#	Read a key from the keyboard if one is pressed....
bind .top21.fra35.tex36 <KeyRelease> {
  read_key
    }
########################
# Reenter the command mode....
bind all <Control-c> {
    puts -nonewline $serID "\x03"
    }
########################
bind all <Alt-d> {
   puts -nonewline $serID "\x03" 
   puts -nonewline $serID "disconnect"
   }
}

proc init {argc argv} {

}

init $argc $argv

#################################
# VTCL GENERATED GUI PROCEDURES
#

proc vTclWindow. {base {container 0}} {
    if {$base == ""} {
        set base .
    }
    ###################
    # CREATING WIDGETS
    ###################
    if {!$container} {
    wm focusmodel $base passive
    wm geometry $base 200x200+168+168; update
    wm maxsize $base 2052 747
    wm minsize $base 148 1
    wm overrideredirect $base 0
    wm resizable $base 1 1
    wm withdraw $base
    wm title $base "vtcl"
    bindtags $base "$base Vtcl all"
    }
    ###################
    # SETTING GEOMETRY
    ###################
}

proc vTclWindow.top21 {base {container 0}} {
    if {$base == ""} {
        set base .top21
    }
    if {[winfo exists $base] && (!$container)} {
        wm deiconify $base; return
    }

    global widget
    vTcl:DefineAlias "$base" "Toplevel1" vTcl:Toplevel:WidgetProc "" 1
    vTcl:DefineAlias "$base.fra31" "Frame3" vTcl:WidgetProc "Toplevel1" 1
    vTcl:DefineAlias "$base.fra31.scr33" "rxs" vTcl:WidgetProc "Toplevel1" 1
    vTcl:DefineAlias "$base.fra31.tex32" "rx" vTcl:WidgetProc "Toplevel1" 1
    vTcl:DefineAlias "$base.fra35" "Frame4" vTcl:WidgetProc "Toplevel1" 1
    vTcl:DefineAlias "$base.fra35.scr37" "txs" vTcl:WidgetProc "Toplevel1" 1
    vTcl:DefineAlias "$base.fra35.tex36" "tx" vTcl:WidgetProc "Toplevel1" 1
    vTcl:DefineAlias "$base.men22" "Menubutton2" vTcl:WidgetProc "Toplevel1" 1
    vTcl:DefineAlias "$base.men25" "Menubutton1" vTcl:WidgetProc "Toplevel1" 1

    ###################
    # CREATING WIDGETS
    ###################
    if {!$container} {
    toplevel $base -class Toplevel \
        -background #8aa0e6 
    wm focusmodel $base passive
    wm geometry $base 640x480+86+143; update
    wm maxsize $base 640 480
    wm minsize $base 150 2
    wm overrideredirect $base 0
    wm resizable $base 0 0
    wm deiconify $base
    wm title $base "TCL Packet (KB5RYO)"
    }
    menubutton $base.men25 \
        -background #8aa0e6 \
        -font [vTcl:font:get_font "underline"] -height 25 \
        -menu "$base.men25.m" -padx 5 -pady 4 -text File -width 60 
    menu $base.men25.m \
        -activeborderwidth 1 -borderwidth 1 -font {Arial 12}  -tearoff 0 
    $base.men25.m add command \
        -accelerator {} -command {ExitProgram 0} -font {} -image {} \
        -label Exit 
    frame $base.fra31 \
        -background #8aa0e6 -borderwidth 2 -height 275 -relief sunken \
        -width 640 
    text $base.fra31.tex32 \
        -font [vTcl:font:get_font "vTcl:font1"] -foreground #0000ff \
        -height 263 -width 606 -wrap word -yscrollcommand {rxs set} 
    scrollbar $base.fra31.scr33 \
        -background #8aa0e6 -command {rx yview} -troughcolor #c0c0c0c0c0c0 
    frame $base.fra35 \
        -background #8aa0e6 -borderwidth 2 -height 110 -relief sunken \
        -width 640 
    text $base.fra35.tex36 \
        -font [vTcl:font:get_font "vTcl:font1"] -height 98 -width 606 \
        -wrap word -yscrollcommand {txs set} 
    bind $base.fra35.tex36 <KeyRelease> {
        read_key
    }
    scrollbar $base.fra35.scr37 \
        -command {tx yview} 
    menubutton $base.men22 \
        -background #8aa0e6 -font [vTcl:font:get_font "underline"] -height 25 \
        -menu "$base.men22.m" -padx 5 -pady 4 -text About -width 50 
    menu $base.men22.m \
        -activeborderwidth 1 -borderwidth 1 -font {Arial 12}  -tearoff 0 
    $base.men22.m add command \
        -accelerator {} -command {Window show .top24} -font {} -image {} \
        -label About
     ###################
    # SETTING GEOMETRY
    ###################
    place $base.men25 \
        -x 10 -y 0 -width 60 -height 25 -anchor nw -bordermode ignore 
    place $base.fra31 \
        -x 0 -y 30 -width 640 -height 275 -anchor nw -bordermode ignore 
    place $base.fra31.tex32 \
        -x 5 -y 5 -width 606 -height 263 -anchor nw -bordermode ignore 
    place $base.fra31.scr33 \
        -x 610 -y 5 -width 21 -height 263 -anchor nw -bordermode ignore 
    place $base.fra35 \
        -x -1 -y 339 -width 640 -height 110 -anchor nw -bordermode ignore 
    place $base.fra35.tex36 \
        -x 5 -y 5 -width 606 -height 98 -anchor nw -bordermode ignore 
    place $base.fra35.scr37 \
        -x 610 -y 5 -width 21 -height 98 -anchor nw -bordermode ignore 
    place $base.men22 \
        -x 565 -y 0 -width 50 -height 25 -anchor nw -bordermode ignore 
}

proc vTclWindow.top24 {base {container 0}} {
    if {$base == ""} {
        set base .top24
    }
    if {[winfo exists $base] && (!$container)} {
        wm deiconify $base; return
    }

    global widget
    vTcl:DefineAlias "$base" "Toplevel2" vTcl:Toplevel:WidgetProc "" 1
    vTcl:DefineAlias "$base.but30" "Button2" vTcl:WidgetProc "Toplevel2" 1
    vTcl:DefineAlias "$base.mes25" "Message1" vTcl:WidgetProc "Toplevel2" 1
    vTcl:DefineAlias "$base.mes26" "Message2" vTcl:WidgetProc "Toplevel2" 1
    vTcl:DefineAlias "$base.mes27" "Message3" vTcl:WidgetProc "Toplevel2" 1
    vTcl:DefineAlias "$base.mes28" "Message4" vTcl:WidgetProc "Toplevel2" 1
    vTcl:DefineAlias "$base.mes29" "Message5" vTcl:WidgetProc "Toplevel2" 1

    ###################
    # CREATING WIDGETS
    ###################
    if {!$container} {
    toplevel $base -class Toplevel
    wm withdraw .top24
    wm focusmodel $base passive
    wm geometry $base 251x240+247+222; update
    wm maxsize $base 2054 749
    wm minsize $base 150 2
    wm overrideredirect $base 0
    wm resizable $base 0 0
    wm title $base "About TCL Packet"
    }
    message $base.mes25 \
        -font [vTcl:font:get_font "vTcl:font8"] -padx 5 -pady 2 \
        -text {TCL Packet} -width 206 
    message $base.mes26 \
        -font [vTcl:font:get_font "vTcl:font1"] -padx 5 -pady 2 \
        -text {Writen by KB5RYO} -width 246 
    message $base.mes27 \
        -font [vTcl:font:get_font "vTcl:font1"] -padx 5 -pady 2 \
        -text {Scott Billingsley} -width 186 
    message $base.mes28 \
        -padx 5 -pady 2 -text {Using Visual Tcl 1.5.1} -width 196 
    message $base.mes29 \
        -padx 5 -pady 2 -text {Free for Amateur radio use.} -width 186 
    button $base.but30 \
        -command {Window hide .top24} -height 26 -pady 0 -text OK -width 55 
    ###################
    # SETTING GEOMETRY
    ###################
    place $base.mes25 \
        -x 21 -y 20 -width 206 -height 41 -anchor nw -bordermode ignore 
    place $base.mes26 \
        -x 5 -y 50 -width 246 -height 41 -anchor nw -bordermode ignore 
    place $base.mes27 \
        -x 30 -y 80 -width 186 -height 31 -anchor nw -bordermode ignore 
    place $base.mes28 \
        -x 20 -y 110 -width 196 -height 21 -anchor nw -bordermode ignore 
    place $base.mes29 \
        -x 30 -y 130 -width 186 -height 21 -anchor nw -bordermode ignore 
    place $base.but30 \
        -x 95 -y 180 -width 55 -height 26 -anchor nw -bordermode ignore 
}

Window show .
Window show .top21
Window show .top24

main $argc $argv
