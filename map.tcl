#!/bin/sh
# the next line restarts using wish \
exec wish "$0" "$@"
namespace eval map {
    variable selected_type
    variable MapH
    variable MapW
    variable outputdir
    foreach script {
        const.tcl
    } {
        namespace inscope :: source $script
    }
}
proc map::gui {{parent {}}} {
    variable MapH 480
    variable MapW 850
    variable outputdir

    if {[string compare $parent ""] == 0} {
        set w .
    } else {
        set w $parent.dialog
        toplevel $w
    }

    wm title $w $const::start_title
    set f [frame $w.fmain ]
    grid $f -column 0 -row 0 -sticky news
    grid columnconfigure . 0 -weight 1
    grid rowconfigure . 0 -weight 1

#    set MapH {}
#    set MapW {}
    grid [label $f.lbl_size -text "Set Map Size : "] -column 0 -row 1  -sticky wens
    grid [entry $f.ent_size_h -textvariable map::MapH] -column 1 -row 1  -sticky wens
    grid [label $f.lbl_size_x -text " X "] -column 2 -row 1  -sticky wens
    grid [entry $f.ent_size_w -textvariable map::MapW] -column 3 -row 1  -sticky wens
    #grid [button $f.btn_cmd_browse -text "Browse" -command "map::fileBrowse $f $f.ent_cmd"] -column 3 -row 1 -sticky wens

    set outputdir "."
    grid [label $f.lbl_dir -text "Output Directory : "] -column 0 -row 2  -sticky wens
    grid [entry $f.ent_dir -textvariable map::outputdir] -column 1 -row 2 -columnspan 2 -sticky wens
    grid [button $f.btn_dir_browse -text "Browse" -command "map::select_dir $f.ent_dir"] -column 3 -row 2 -sticky wens

    #grid [button $f.btn_run -text "Run" -command "puts hello"] -column 2 -row 5 -sticky es
    grid [button $f.btn_run -text "OK" -command "map::transfer "] -column 2 -row 5 -sticky es
 #   grid [button $f.btn_run -text "Run" -command "map::transfer [$f.ent_cmd get] [$f.ent_dir get]"] -column 2 -row 5 -sticky es
    grid [button $f.btn_exit -text "Exit" -command "destroy $w" ] -column 3 -row 5 -sticky wens
    focus $f.ent_dir
}


proc map::fileBrowse {w ent} {
    variable selected_type
    #   Type names		Extension(s)	Mac File Type(s)
    #
    #---------------------------------------------------------
    set types {
	{"Cmd files"		{.cmd .rmcmd}	}
	{"All files"		*}
    }
    global selected_type
    if {![info exists selected_type]} {
        set selected_type "Cmd files"
    }
    if {$::tcl_version >= 8.5} {
	set file [tk_getOpenFile -filetypes $types -parent $w -typevariable selected_type -title "Open Cmd file"]
    } else {
        set file [tk_getOpenFile -filetypes $types -parent $w -title "Open Cmd file"]
    }
    if {[string compare $file ""]} {
	$ent delete 0 end
	$ent insert 0 $file
	$ent xview end
        focus $w.ent_dir
    } else {
        focus $ent
    }
}
proc map::select_dir {ent} {
    set dir [tk_chooseDirectory  -title "Choose a directory to save file"]
    if {$dir eq ""} {
        #$ent delete 0 end
        #$ent insert 0 "No directory selected"
    } else {
        $ent delete 0 end
        $ent insert 0 $dir
        $ent xview end
    }
}


map::gui
