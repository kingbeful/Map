#!/bin/sh
# the next line restarts using wish \
exec wish "$0" "$@"

namespace eval Matrix {
    variable maincanvas
    variable Xmin 0
    variable Xmax 0
    variable Ymin 0
    variable Ymax 0
    variable boxwidth 20
    variable boxheight 20
    variable Layer_colour {red orange yellow green1 green4 blue cyan1 brown1 brown4 purple1 gold1 gray70 snow1}
    foreach script {
        const.tcl
    } {
        namespace inscope :: source $script
    }
}

proc Matrix::itemEnter {c x y} {
    global restoreCmd
#    global dash_id
    #global schematic

    if {[winfo depth $c] == 1} {
        set restoreCmd {}
        return
    }
    set type [$c type current]

#    if {(($type == "rectangle") || ($type == "oval") || ($type == "arc")) && ($fill == "")} {
#}
    if {$type == "rectangle" || $type == "polygon"} {
        $c config -cursor hand2
        set x [$c canvasx $x]
        set y [$c canvasx $y]
        set id [$c find closest $x $y]
        #set Matrix::status $schematic($id)
        #set coordlist [$c coords $id]

        #    set dash_id [$c create rectangle $coordlist -width 1 -outline red2 -dash {2 2}]
        set outline [lindex [$c itemconfig $id -outline] 4]
        set restoreCmd "$c itemconfig $id -outline $outline"
        $c itemconfig $id -outline red2
    } elseif {$type == "line"} {
        $c config -cursor hand2
        set x [$c canvasx $x]
        set y [$c canvasx $y]
        set id [$c find closest $x $y]
        #set Matrix::status $schematic($id)
        set fill [lindex [$c itemconfig $id -fill] 4]
        set restoreCmd "$c itemconfig $id -fill $fill"
        $c itemconfig $id -fill red2
    }
}

proc Matrix::itemLeave {c} {
    global restoreCmd
#    global dash_id
    $c config -cursor left_ptr
#    set dash_id -1
    eval $restoreCmd
}
proc Matrix::Matrixfit {} {
    variable maincanvas
    variable scale_rate
    variable Xmin
    variable Xmax
    variable Ymin
    variable Ymax
    set Xmin [lindex [$maincanvas bbox all] 0]
    set Ymin [lindex [$maincanvas bbox all] 1]
    set Xmax [lindex [$maincanvas bbox all] 2]
    set Ymax [lindex [$maincanvas bbox all] 3]
    puts [$maincanvas bbox all]

    set xAmount [expr $Xmin * -1]
    set yAmount [expr $Ymin * -1]
    set gm [split [wm geom .] "x+"]
    puts $gm
    set wd [lindex $gm 0]
    set ht [lindex $gm 1]
    #set wd [lindex [$maincanvas configure -width] 4]
    #set ht [lindex [$maincanvas configure -height] 4]
    $maincanvas move all $xAmount $yAmount
    set xAmount [expr {abs(double($Xmax) - double($Xmin))}]
    set yAmount [expr {abs(double($Ymax) - double($Ymin))}]

    set xRate [expr double($wd) / double($xAmount)]
    set yRate [expr double($ht) / double($yAmount)]
    puts "xAmount: $xAmount -- yAmount: $yAmount|| wd: $wd -- ht: $ht"
    puts "xRate: $xRate -- yRate: $yRate"
    if {[expr double($xRate) < double($yRate)]} {
        set Rate $xRate
    } else {
        set Rate $yRate
    }
    $maincanvas scale all 0 0 $Rate $Rate
    set scale_rate [expr $scale_rate * $Rate]
    $maincanvas move all [expr ($wd - $xAmount*$Rate)/2 ] 0
    set width [lindex [$maincanvas itemconfigure path -width] 4]
    if {$width == {}} {
    } else {
        puts "Old width: $width"
        set width [expr double($width) * $Rate]
    }
    $maincanvas itemconfigure path -width $width

    #set text_pos [$maincanvas coords text]
    #puts "text position: $text_pos"
    #set text
    #set sregion [lindex [$parent configure -scrollregion] 4]
    #puts -nonewline "Old: $sregion --> "
    #set sregX [expr [lindex $sregion 2] / 2]
    #set sregY [expr [lindex $sregion 3] / 2]
    #set sregion [lreplace $sregion 2 3 $sregX $sregY]
    #puts "New: $sregion"
    #$parent configure -scrollregion $sregion
}

proc Matrix::box_create {startX startY width height {sharp 0}} {
    variable maincanvas
    variable select_color
    variable select_stipple
    variable stippledata
    #variable Layer_colour
    #set c [lindex $Layer_colour $layer]
    #set coord "$startX $startY "
    if {$sharp == "0"} {
        set filename [lindex [lsearch -index 0 -inline $stippledata $select_stipple] 1]
        set filename [string trim $filename "\""]
        puts "====> $filename"
        set id [$maincanvas create poly $startX $startY \
                                        [expr $startX + $width] $startY \
                                        [expr $startX + $width] [expr $startY + $height] \
                                        $startX  [expr $startY + $height] \
        -width 1 -outline $select_color -stipple @[file join [pwd] images $filename] -fill $select_color -tags "box"]
    } else {
        $maincanvas create poly $startX $startY \
                                [expr $startX + $width] $startY \
                                [expr $startX + $width] [expr $startY + $height] \
                                $startX  [expr $startY + $height] \
        -width 1 -outline yellow2 -fill {} -tags "select_sharp"
    }
    
}
proc Matrix::line_create {sname coord {layer 0} {width 1}} {
    variable maincanvas
    variable Layer_colour
    set c [lindex $Layer_colour $layer]
    set id [$maincanvas create line $coord -width $width -cap butt -join miter -stipple @[file join [pwd] images gray25.xbm] -fill $c -tags "item path $sname"]
}
proc Matrix::text_create {sname txt coord {layer 0}} {
    variable maincanvas
    variable Layer_colour
    set c [lindex $Layer_colour $layer]
    set id [$maincanvas create text $coord -text $txt -fill $c -tags "item text $sname" ]
}
proc Matrix::Matrixcreate {} {
    variable maincanvas
    #set str_num [expr [llength $GDSIIReader::streamdata] - 4]
    set str [lrange $GDSIIReader::streamdata 4 end]
    set str_num [llength $str]
    set i 0
    while { $i < $str_num } {
        set str_data [lindex $str $i]
        set sname [lindex $str_data 2]
        set ele_list [lrange $str_data 3 end]
        foreach ele $ele_list {
            set ele_name [lindex $ele 0]
            set ele_data [lrange $ele 1 end]
            if {[string compare $ele_name "boundary"] == 0} {
                foreach data $ele_data {
                    set flag [lindex $data 0]
                    switch -- $flag {
                        XY {
                            set coordlist [lindex $data 1]
                            set coordxUNIT [Matrix::recalc_coord $coordlist]
                        }
                        L {
                            set layer [lindex $data 1]
                            set layer [expr $layer % 13]
                        }
                    }
                }
                puts "$ele_name: $coordxUNIT"
                Matrix::boundary_box_create $sname $coordxUNIT $layer
            } elseif {[string compare $ele_name "box"] == 0} {
                foreach data $ele_data {
                    set flag [lindex $data 0]
                    switch -- $flag {
                        XY {
                            set coordlist [lindex $data 1]
                            set coordxUNIT [Matrix::recalc_coord $coordlist]
                        }
                        L {
                            set layer [lindex $data 1]
                            set layer [expr $layer % 13]
                        }
                    }
                }
                puts "$ele_name: $coordxUNIT"
                Matrix::boundary_box_create $sname $coordxUNIT $layer
            } elseif {[string compare $ele_name "path"] == 0} {
                foreach data $ele_data {
                    set flag [lindex $data 0]
                    switch -- $flag {
                        XY {
                            set coordlist [lindex $data 1]
                            set coordxUNIT [Matrix::recalc_coord $coordlist]
                        }
                        L {
                            set layer [lindex $data 1]
                        }
                        W {
                            set width [expr [lindex $data 1] * $GDSIIReader::user_unit]
                            #puts "Path width: $width"
                            #set width 2
                        }
                    }
                }
                puts "$ele_name: $coordxUNIT"
                Matrix::path_create $sname $coordxUNIT $layer $width
            } elseif {[string compare $ele_name "text"] == 0} {
                set layer 0
                foreach data $ele_data {
                    set flag [lindex $data 0]
                    switch -- $flag {
                        XY {
                            set coordlist [lindex $data 1]
                            set coordxUNIT [Matrix::recalc_coord $coordlist]
                        }
                        L {
                            set layer [lindex $data 1]
                            set layer [expr $layer % 13]
                        }
                        S {
                            set txt [lindex $data 1]
                        }
                    }
                }
                puts "$ele_name: $coordxUNIT"
                Matrix::text_create $sname $txt $coordxUNIT $layer
            } elseif {[string compare $ele_name "sref"] == 0} {
                foreach data $ele_data {
                    set flag [lindex $data 0]
                    switch -- $flag {
                        XY {
                            set coordlist [lindex $data 1]
                            set coordxUNIT [Matrix::recalc_coord $coordlist]
                        }
                        SN {
                            set str_name [lindex $data 1]
                        }
                    }
                }
                puts "$ele_name: $coordxUNIT"
                Matrix::sref_create $str_name $coordxUNIT
            } else {
                puts "====== The structure $ele_name is not finished yet. ======"
            }
        }
        incr i
    }
}
proc Matrix::CreateImage {} {
    variable colordata
    variable stippledata

    variable colorlist {}
    variable stipplelist {}

    Matrix::GetColorData [file join [pwd] color.csv]
    foreach color_filename $colordata {

        set color [lindex $color_filename 0]
        set filename [lindex $color_filename 1]
        set color [string trim $color "\""]
        set filename [string trim $filename "\""]
        puts $color
        puts $filename
        image create photo $color\_layer -file [file join [pwd] images $filename]
        lappend colorlist $color
    }
    Matrix::GetStippleData [file join [pwd] stipple.csv]
    foreach id_filename $stippledata {
        set id [lindex $id_filename 0]
        set filename [lindex $id_filename 1]
        set id [string trim $id "\""]
        set filename [string trim $filename "\""]
        image create bitmap stipple_$id -foreground black -background white -file [file join [pwd] images $filename]
        lappend stipplelist $id
    }
}
proc Matrix::GetColorData {filename} {
    variable colordata {}
    set infile [open $filename r]
    while { [gets $infile line] >= 0 } {
        set data [split $line ,]
        lappend colordata $data
    }
    close $infile
}

proc Matrix::GetStippleData {filename} {
    variable stippledata {}
    set infile [open $filename r]
    while { [gets $infile line] >= 0 } {
        set data [split $line ,]
        lappend stippledata $data
    }
    close $infile
}

proc Matrix::Matrixinit {parent w h} {
    variable maincanvas
    variable mode normal
    variable scale_rate 1

###########
    Matrix::CreateImage
    #variable select_rdy 0
    #variable area_sel 0
    #set frm [frame $parent.f]
    #set sw    [ScrolledWindow $frame.sw -relief flat -borderwidth 2]
    set maincanvas [canvas $parent.can -bg black -borderwidth 0 -width $w -height $h]
    #set maincanvas [canvas $parent.can -bg black -borderwidth 0 \
                  -xscrollcommand "$parent.hscroll set" \
                  -yscrollcommand "$parent.vscroll set" ]
    #-scrollregion {0 0 800 600} -width 800 -height 600
    #set vscr [scrollbar $parent.vscroll -command "$maincanvas yview" -width 10]
    #set hscr [scrollbar $parent.hscroll -orient horiz -command "$maincanvas xview" -width 10]

    grid $maincanvas -in $parent -row 0 -column 0  
#-sticky news
    #grid $vscr -row 0 -column 1 -columnspan 1 -sticky news
    #grid $hscr -row 1 -column 0  -sticky news

    grid rowconfig    $parent 0 -weight 1 -minsize 0
    grid columnconfig $parent 0 -weight 1 -minsize 0

    #$maincanvas bind item <Any-Enter> "Matrix::itemEnter $maincanvas %x %y"
    #$maincanvas bind item <Any-Leave> "Matrix::itemLeave $maincanvas"
    #set m [menu .popupMenu]
#$m add command -label "Example 1" 
#$m add command -label "Example 2"
#bind . <3> "tk_popup $m %X %Y"


#    bind . <Key-Z> "Matrix::zoomoutX2 all"
#    bind . <Control-Key-z> "Matrix::zoominX2 all"
    bind $maincanvas <ButtonPress-1> "Matrix::coordmark %x %y"
#    bind $maincanvas <ButtonRelease-1> "Matrix::select_item %x %y"
#    bind $maincanvas <B1-Motion> "Matrix::mouse_drag %x %y"
    bind $maincanvas <Motion> "Matrix::mouse_move %x %y"
#    bind . <Key-Up> "$maincanvas move all 0 -50"
#    bind . <Key-Down> "$maincanvas move all 0 50"
#    bind . <Key-Left> "$maincanvas move all -50 0"
#    bind . <Key-Right> "$maincanvas move all 50 0"
#    bind . <Key-m> "Matrix::set_mode movelayer"
#    bind . <Key-r> "Matrix::set_mode rectangle"
#    bind . <Key-k> "Matrix::set_mode ruler"
#    bind . <Key-c> "Matrix::set_mode copylayer"
#    bind . <Key-o> "Matrix::set_mode rotatelayer"
#    bind . <Control-Key-k> "Matrix::clean_ruler"
#    bind . <Key-f> "Matrix::Matrixfit"
    bind . <Escape> "Matrix::set_mode normal"
#    bind . <Key-p> "Matrix::path_para_window"
    bind . <Key-b> "Matrix::create_box_setting"
   
}
proc Matrix::create_box_setting {}  {
    variable boxwidth
    variable boxheight
    
    variable colorlist
    variable stipplelist

    set w .diag
    toplevel $w
    wm title $w "Create Box Setting"
    set f [frame $w.f -width 150 -height 70]
    grid $f -column 0 -row 0 -sticky news
    grid columnconfigure . 0 -weight 1
    grid rowconfigure . 0 -weight 1

####### create data
#    image create photo red_layer -file [file join [pwd] images red.gif]
#    image create photo green_layer -file [file join [pwd] images green.gif]
#    image create photo yellow_layer -file [file join [pwd] images yellow.gif]
#    image create bitmap strip_0 -foreground black -background white -file [file join [pwd] images gray25.xbm]
#    image create bitmap strip_1 -foreground black -background white -file [file join [pwd] images gray10.xbm]
#    image create bitmap strip_2 -foreground black -background white -file [file join [pwd] images slash.xbm]
###### end


    grid [label $f.lbl_size -text "Size :"] -column 0 -row 1  -sticky wens
    grid [entry $f.ent_wd -width 8 -textvariable Matrix::boxwidth ] -column 1 -row 1  -sticky wens
    grid [label $f.lbl_size_x -text " X"] -column 2 -row 1  -sticky wens
    grid [entry $f.ent_ht -width 8 -textvariable Matrix::boxheight ] -column 3 -row 1  -sticky wens
    grid [label $f.lbl_color -text "Color :"] -column 0 -row 2  -sticky wens
    
    set color_mb [menubutton $f.cmb -image red_layer -text red -compound left -direction below -menu $f.cmb.m -relief raised -indicatoron yes]
    set cm [menu $color_mb.m -tearoff 0]
    foreach c $colorlist {
        set layer $c\_layer
        puts "layer = $layer"
        $cm add command -image $layer -compound left -command "$color_mb configure -image $layer -text $c"
    }
#    $cm add command -image red_layer -compound left -command "$color_mb configure -image red_layer"
#    $cm add command -image green_layer -compound left -command "$color_mb configure -image green_layer"
#    $cm add command -image yellow_layer -compound left -command "$color_mb configure -image yellow_layer"
    grid $color_mb -column 1 -row 2 -sticky news
    
    grid [label $f.lbl_stipple -text "Stipple :"] -column 0 -row 3  -sticky wens
    set stipple_mb [menubutton $f.smb -image stipple_0 -text 0 -compound left -direction below -menu $f.smb.m -relief raised -indicatoron yes]
    set sm [menu $stipple_mb.m -tearoff 0]
    foreach s $stipplelist {
        set stipple stipple_$s
        puts "stipple = $stipple"
        $sm add command -image $stipple -compound left -command "$stipple_mb configure -image $stipple -text $s"
    }
#    $sm add command -image strip_0 -compound left -command "$color_mb configure -image strip_0"
#    $sm add command -image strip_1 -compound left -command "$color_mb configure -image strip_1"
#    $sm add command -image strip_2 -compound left -command "$color_mb configure -image strip_2"
    grid $stipple_mb -column 1 -row 3 -sticky news

    grid [button $f.btn_ok -text "OK" -command "Matrix::SetBoxProperty $w $color_mb $stipple_mb"] -column 0 -row 4 -sticky es
    grid [button $f.btn_exit -text "Cancel" -command "destroy $w" ] -column 1 -row 4 -sticky wens
}
proc Matrix::SetBoxProperty {w cmb smb} {
    variable select_color red
    variable select_stipple 0
    set select_color [lindex [$cmb configure -text] 4]
    set select_stipple [lindex [$smb configure -text] 4]
    puts "select_color: $select_color | select_stipple : $select_stipple"
    Matrix::set_mode create_box_enable
    destroy $w
}
proc Matrix::set_mode {m} {
    variable mode
    variable bk_mode
    set mode $m
    set bk_mode $m
    puts "$mode"
}
proc Matrix::coordmark {x y} {
    variable boxwidth
    variable boxheight


    variable maincanvas
    variable mode
    variable bk_mode
    #variable area_sel
    #variable select_rdy
    variable restore_cmd
    variable startX
    variable startY
    variable lastX
    variable lastY
    #set startX [$maincanvas canvasx $x]
    #set startY [$maincanvas canvasx $y]
    set lastX [$maincanvas canvasx $x]
    set lastY [$maincanvas canvasy $y]
    switch -exact -- $mode {
        copylayer -
        rotatelayer -
        movelayer {
            set mode sel_layer
            set startX $lastX
            set startY $lastY
        }
        area_sel_rdy {
            set mode $bk_mode\_enable
            set startX $lastX
            set startY $lastY
        }
        rotatelayer_enable {
            $maincanvas delete select_sharp
            Matrix::rotate_selected $startX $startY
            $maincanvas dtag selected
            set mode finished
        }
        copylayer_enable {
            $maincanvas delete select_sharp
            Matrix::dup_selected
            $maincanvas move selected [expr $lastX - $startX] [expr $lastY - $startY]
            $maincanvas dtag selected
            set mode finished
        }
        movelayer_enable {
            #if { $restore_cmd != {} } {
            #    puts $restore_cmd
            #    foreach cmd $restore_cmd {
            #        eval $cmd
            #    }
            #    set restore_cmd {}
            #}
            $maincanvas delete select_sharp
            #KKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKK
            $maincanvas move selected [expr $lastX - $startX] [expr $lastY - $startY]        
            $maincanvas dtag selected
            set mode finished
        }
        rectangle {
            set mode $bk_mode\_enable
        }
        rectangle_enable {
            $maincanvas addtag item withtag rect
            $maincanvas dtag rect
            set mode finished
        }
        ruler {
            set mode $bk_mode\_enable
        }
        ruler_enable {
            set mode finished
            $maincanvas addtag ruler_rdy withtag ruler
            $maincanvas dtag ruler 
        }
        create_box_enable {
            #puts "Matrix::box_create $lastX $lastY $boxwidth $boxheight 0"
            Matrix::box_create $lastX $lastY $boxwidth $boxheight 1
            set mode create_box_sharp
        }
        create_box_sharp {
            $maincanvas delete select_sharp
            Matrix::box_create $lastX $lastY $boxwidth $boxheight 0
            set mode normal
        }

    }
}
proc Matrix::create_sel_sharp {tag} {
    variable maincanvas
    set coord [$maincanvas coords $tag]
    set type [$maincanvas type $tag]
    if { $type == "text" } {
        set txt [lindex [$maincanvas itemconfigure $tag -text] 4]
        $maincanvas creat $type $coord -fill yellow2 -text $txt -tag select_sharp
    } elseif { $type == "line" } {
        $maincanvas creat $type $coord -fill yellow2 -tag select_sharp
    } else {
        $maincanvas creat $type $coord -outline yellow2 -fill {} -tag select_sharp
    }
}
proc Matrix::select_item {x y} {
    variable maincanvas
    variable mode
    variable bk_mode
    #variable select_rdy
    #variable area_sel
    variable restore_cmd
    set x [$maincanvas canvasx $x]
    set y [$maincanvas canvasx $y]
    switch -exact -- $mode {
        area_sel {
            set restore_cmd {}
            set cmd [concat $maincanvas addtag selected enclosed [$maincanvas bbox select_box] ]
            eval $cmd
            #$maincanvas dtag  select_box
            $maincanvas delete select_box
            set sel_list [$maincanvas find withtag selected]
            #$maincanvas dtag  selected
            foreach sel $sel_list {

                 Matrix::create_sel_sharp $sel
                 #set type [$maincanvas type $sel]
                 #if { $type == "text" || $type == "line" } {
                 #    set fillcolor [lindex [$maincanvas itemconfigure $sel -fill] 4]
                 #    lappend restore_cmd [list $maincanvas itemconfigure $sel -fill $fillcolor]
                 #    $maincanvas itemconfigure $sel -fill yellow2
                 #} else {
                 #    set outlinecolor [lindex [$maincanvas itemconfigure $sel -outline] 4]
                 #    lappend restore_cmd [list $maincanvas itemconfigure $sel -outline $outlinecolor]
                 #    $maincanvas itemconfigure $sel -outline yellow2
                 #}
            }
            if { $sel_list == {} } {
                set mode $bk_mode
            } else {
                set mode area_sel_rdy
            }
        } 
        sel_layer {
            set type [$maincanvas type current]
            if {$type != {} } {
                set sel [$maincanvas find closest $x $y]
                $maincanvas addtag selected withtag $sel
                Matrix::create_sel_sharp $sel
                #if { $type == "text" || $type == "line" } {
                #    set fillcolor [lindex [$maincanvas itemconfigure $sel -fill] 4]
                #    lappend restore_cmd [list $maincanvas itemconfigure $sel -fill $fillcolor]
                #    $maincanvas itemconfigure $sel -fill yellow2
                #    $maincanvas addtag selected withtag $sel
                #} else {
                #    set outlinecolor [lindex [$maincanvas itemconfigure $sel -outline] 4]
                #    lappend restore_cmd [list $maincanvas itemconfigure $sel -outline $outlinecolor]
                #    $maincanvas itemconfigure $sel -outline yellow2
                #    $maincanvas addtag selected withtag $sel
                #}
                set mode $bk_mode\_enable
            } else {
                set mode $bk_mode
            }
        }
        finished {
            set mode $bk_mode
        }
        #rect_finished {
        #    set mode rectangle
        #}
        #rectangle {
        #    set mode rect_enable
        #}
        #ruler_end {
        #    set mode ruler
        #}
    }
}
proc Matrix::mouse_drag {x y} {
    variable maincanvas
    #variable select_rdy
    #variable area_sel
    variable mode
    variable restore_cmd
    variable lastX
    variable lastY
    set x [$maincanvas canvasx $x]
    set y [$maincanvas canvasy $y]
    switch -exact -- $mode {
        sel_layer -
        area_sel {
            if {($lastX != $x) && ($lastY != $y)} {
                $maincanvas delete select_box
                $maincanvas addtag select_box withtag [$maincanvas create rect $lastX $lastY $x $y -outline yellow2 -dash .]
                set mode area_sel
            }
        }
        movelayer_enable {
            #if { $restore_cmd != {} } {
            #    puts $restore_cmd
            #    foreach cmd $restore_cmd {
            #        eval $cmd
            #    }
            #    set restore_cmd {}
            #}
            $maincanvas delete select_sharp
            $maincanvas dtag selected
            set mode area_sel
        }
        
        normal {

        }
    }
}
proc Matrix::mouse_move {x y} {
    variable maincanvas
    variable select_rdy
    variable mode
    variable lastX
    variable lastY
    set x [$maincanvas canvasx $x]
    set y [$maincanvas canvasy $y]
    switch -exact -- $mode {
        create_box_sharp -
        copylayer_enable -
        movelayer_enable {
            $maincanvas move select_sharp [expr {$x-$lastX}] [expr {$y-$lastY}]
            set lastX $x
            set lastY $y
        }
        rectangle_enable {
            if {($lastX != $x) && ($lastY != $y)} {
                $maincanvas delete rect
                $maincanvas addtag rect withtag [$maincanvas create rect $lastX $lastY $x $y -outline gray70 -stipple @[file join [pwd] images gray25.xbm] -fill gray70]
            }
        }
        ruler_enable {
            Matrix::creat_ruler $lastX $lastY $x $y
        }
        normal {

        }
        
    }
}
proc Matrix::path_para_window {} {
    puts "path sel"
    set w .diag
    toplevel $w
    #wm withdraw $w
    #wm protocol $w WM_DELETE_WINDOW {
        # don't kill me
    #}
    #wm resizable $w 0 0 
    wm title $w "Create Path"
    #wm transient $w .
    set f [frame $w.f -width 150 -height 70] 
    grid $f -column 0 -row 0 -sticky news
    grid columnconfigure . 0 -weight 1
    grid rowconfigure . 0 -weight 1
    #pack $f -fill both -expand yes
    grid [label $f.lbl_wd -text "Width :"] -column 0 -row 1  -sticky wens
    grid [entry $f.ent_wd -width 8 -textvariable width ] -column 1 -row 1  -sticky wens
    grid [label $f.lbl_ly -text "Layer :"] -column 0 -row 2  -sticky wens
    
    image create photo red_layer -file [file join [pwd] images red.gif]
    image create photo green_layer -file [file join [pwd] images green.gif]
    image create photo yellow_layer -file [file join [pwd] images yellow.gif]
set bmpdata {
#define sss_xbm_width 16
#define sss_xbm_height 16

static unsigned char sss_xbm_bits[] = {
 0x11, 0x11, 0x44, 0x44, 0x11, 0x11, 0x44, 0x44, 0x11, 0x11, 0x44, 0x44,
 0x11, 0x11, 0x44, 0x44, 0x11, 0x11, 0x44, 0x44, 0x11, 0x11, 0x44, 0x44,
 0x11, 0x11, 0x44, 0x44, 0x11, 0x11, 0x44, 0x44 };
}
    image create bitmap strip_0 -foreground blue -background white -data $bmpdata
  
    set mb [menubutton $f.ly -text "nwell" -image red_layer -compound left -direction below -menu $f.ly.m -relief raised -indicatoron yes]
    set m [menu $f.ly.m -tearoff 0]
    $m add command -label "nwell" -image red_layer -compound left -command "$mb configure -image red_layer -text nwell"
    $m add command -label "poly1" -image green_layer -compound left -command "$mb configure -image green_layer -text poly1"
    $m add command -label "metal2" -image yellow_layer -compound left -command "$mb configure -image yellow_layer -text metal2"
    $m add command -label "metal1" -image strip_0 -compound left -command "$mb configure -image strip_0 -text metal1"
    grid $mb -column 1 -row 2 -sticky news
    
    
      
    
    #set btn_ok [button $f.ok -text "OK" ]
    #set btn_cancel [button $f.cancel -text "Cancel" -command "destroy $w" ]
    #pack $btn_ok $btn_cancel -side left
    
}
proc Matrix::main {{w 850} {h 450}} {

    wm withdraw .
    wm title . "X-Ray out-Man"

    wm deiconify .
    wm geom . 850x450+0+0
    raise .
    #focus -force .
    set f [frame .f]
    pack $f -fill both -expand yes
    Matrix::Matrixinit $f $w $h
    #GDSIIReader::readfile example.cal
#    GDSIIReader::readfile and.gds
    #GDSIIReader::readfile FAtuning.gds2
#    Matrix::Matrixcreate
#    Matrix::Matrixfit
}

Matrix::main 850 450
