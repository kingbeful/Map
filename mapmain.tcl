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
    variable linewidth 1
    foreach script {
        const.tcl
        map.tcl
    } {
        namespace inscope :: source $script
    }
}

proc Matrix::box_create {startX startY width height {sharp 0}} {
    variable maincanvas
    variable select_color
    variable select_stipple
    variable stippledata
    variable cmdlist

    if {$sharp == "0"} {
        set filename [lindex [lsearch -index 0 -inline $stippledata $select_stipple] 1]
        set filename [string trim $filename "\""]
        puts "====> $filename"
        set id [$maincanvas create poly $startX $startY \
                                        [expr $startX + $width] $startY \
                                        [expr $startX + $width] [expr $startY + $height] \
                                        $startX  [expr $startY + $height] \
        -width 1 -outline $select_color -stipple @[file join [pwd] images $filename] -fill $select_color -tags "box"]
        set cmd "box $select_stipple $startX $startY \
                                        [expr $startX + $width] $startY \
                                        [expr $startX + $width] [expr $startY + $height] \
                                        $startX  [expr $startY + $height] \
                -width 1 -outline $select_color -fill $select_color "
        puts $cmd
        lappend cmdlist $cmd
    } else {
        $maincanvas create poly $startX $startY \
                                [expr $startX + $width] $startY \
                                [expr $startX + $width] [expr $startY + $height] \
                                $startX  [expr $startY + $height] \
        -width 1 -outline yellow2 -fill {} -tags "select_sharp"
    }
    
}
proc Matrix::line_sharp_create {x0 y0 x1 y1} {
    variable maincanvas
    #variable line_coord
    if {($x0 != $x1) || ($y0 != $y1)} {
        $maincanvas delete line_sharp
        $maincanvas create line $x0 $y0 $x1 $y1 -fill yellow2 -tags "line_sharp"
        $maincanvas delete text_coord
        Matrix::text_coord $x1 $y1 
    }
}
proc Matrix::line_create {coord {width 1}} {
    variable maincanvas
    variable select_color
    variable select_dash
    variable dashdata
    variable cmdlist

    set pat [lindex [lsearch -index 0 -inline $dashdata $select_dash] 1]
    set pat [string trim $pat "\""]
    puts "====> $pat"
    if {$pat == "0"} {
        $maincanvas create line $coord -width $width -cap butt -join miter -fill $select_color -tags "line"
    } else {
        $maincanvas create line $coord -width $width -cap butt -join miter -dash $pat -fill $select_color -tags "line"
    }
    set cmd "line $select_dash $coord -width $width -cap butt -join miter -fill $select_color"
    puts $cmd
    lappend cmdlist $cmd
}
################################################KKKKKKKKKKKKKKKKKKKK
proc Matrix::text_coord {x y} {
    variable maincanvas
    set intx [expr int($x)]
    set inty [expr int($y)] 
    $maincanvas create text $x [expr $y-10] -text "($intx,$inty)" -fill yellow2 -tags "text_coord" -anchor sw
}
proc Matrix::text_create {sname txt coord {layer 0}} {
    variable maincanvas
    variable Layer_colour
    set c [lindex $Layer_colour $layer]
    set id [$maincanvas create text $coord -text $txt -fill $c -tags "item text $sname" ]
}
proc Matrix::Matrixcreate {} {
    variable maincanvas

}
proc Matrix::CreateImage {} {
    variable colordata
    variable stippledata
    variable dashdata

    variable colorlist {}
    variable stipplelist {}
    variable dashlist {}

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
    Matrix::GetDashData [file join [pwd] dash.csv]
    foreach id_pat $dashdata {
        set id [lindex $id_pat 0]
        set pat [lindex $id_pat 1]
        set id [string trim $id "\""]
        set pat [string trim $pat "\""]
        image create bitmap dash_$id -foreground black -background white -file [file join [pwd] images $filename]
        lappend dashlist $id
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
proc Matrix::GetDashData {filename} {
    variable dashdata {}
    set infile [open $filename r]
    while { [gets $infile line] >= 0 } {
        set data [split $line ,]
        lappend dashdata $data
    }
    close $infile
}

proc Matrix::Matrixinit {parent w h} {
    variable maincanvas
    variable mode normal
    variable scale_rate 1

###########
    Matrix::CreateImage

    set maincanvas [canvas $parent.can -bg black -borderwidth 0 -width $w -height $h]
    
    grid $maincanvas -in $parent -row 0 -column 0  
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
    bind $maincanvas <Double-ButtonPress-1> "Matrix::double_click_1 %x %y"
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
    bind . <Key-p> "Matrix::create_line_setting"
    bind . <Key-b> "Matrix::create_box_setting"
    bind . <Control-Key-l> "Matrix::load_map"
    bind . <Control-Key-s> "Matrix::save_map"
}
proc Matrix::load_map {} {
    variable maincanvas
    variable stippledata
    variable dashdata
    set infile [open map.dat r]
    while { [gets $infile line] >= 0 } {
        set type [lindex $line 0]
        set style [lindex $line 1]
        set parameter [lrange $line 2 end]
        switch -exact -- $type {
            box {
                set filename [lindex [lsearch -index 0 -inline $stippledata $style] 1]
                set filename [string trim $filename "\""]
                #puts "====> $filename"
                set cmd [concat $maincanvas create poly $parameter "-stipple @[file join [pwd] images $filename]" -tags "box"]
                puts $cmd
                eval $cmd
            }
            line {
                set pat [lindex [lsearch -index 0 -inline $dashdata $style] 1]
                set pat [string trim $pat "\""]
                puts "====> $pat"
                if {$pat == "0"} {
                    set cmd [concat $maincanvas create line $parameter -tags "line"]
                } else {
                    set cmd [concat $maincanvas create line $parameter -tags "line" -dash $pat]
                }
                puts $cmd
                eval $cmd
            }
        }
    }
    close $infile
}
proc Matrix::save_map {} {
    variable cmdlist
    set outfile [open map.dat a]
    foreach line $cmdlist {
        puts $outfile $line
    }
    close $outfile
}
proc Matrix::create_box_setting {}  {
    variable boxwidth
    variable boxheight
    
    variable colorlist
    variable stipplelist

    set w .boxdiag
    toplevel $w
    wm title $w "Create Box Setting"
    set f [frame $w.f -width 150 -height 70]
    grid $f -column 0 -row 0 -sticky news
    grid columnconfigure . 0 -weight 1
    grid rowconfigure . 0 -weight 1

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
    grid $color_mb -column 1 -row 2 -sticky news
    
    grid [label $f.lbl_stipple -text "Stipple :"] -column 0 -row 3  -sticky wens
    set stipple_mb [menubutton $f.smb -image stipple_0 -text 0 -compound left -direction below -menu $f.smb.m -relief raised -indicatoron yes]
    set sm [menu $stipple_mb.m -tearoff 0]
    foreach s $stipplelist {
        set stipple stipple_$s
        puts "stipple = $stipple"
        $sm add command -image $stipple -compound left -command "$stipple_mb configure -image $stipple -text $s"
    }
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
proc Matrix::create_line_setting {} {
    variable linewidth
    variable colorlist
    variable dashlist

    puts "path sel"
    set w .linediag
    toplevel $w
    wm title $w "Create Box Setting"
    set f [frame $w.f -width 150 -height 70]
    grid $f -column 0 -row 0 -sticky news
    grid columnconfigure . 0 -weight 1
    grid rowconfigure . 0 -weight 1

    grid [label $f.lbl_size -text "Width :"] -column 0 -row 1  -sticky wens
    grid [entry $f.ent_wd -width 8 -textvariable Matrix::linewidth ] -column 1 -row 1  -sticky wens
    grid [label $f.lbl_size_x -text " px"] -column 2 -row 1  -sticky wens

    grid [label $f.lbl_color -text "Color :"] -column 0 -row 2  -sticky wens
    
    set color_mb [menubutton $f.cmb -image red_layer -text red -compound left -direction below -menu $f.cmb.m -relief raised -indicatoron yes]
    set cm [menu $color_mb.m -tearoff 0]
    foreach c $colorlist {
        set layer $c\_layer
        puts "layer = $layer"
        $cm add command -image $layer -compound left -command "$color_mb configure -image $layer -text $c"
    }
    grid $color_mb -column 1 -row 2 -sticky news
    
    grid [label $f.lbl_dash -text "Dash :"] -column 0 -row 3  -sticky wens
    set dash_mb [menubutton $f.smb -image dash_0 -text 0 -compound left -direction below -menu $f.smb.m -relief raised -indicatoron yes]
    set sm [menu $dash_mb.m -tearoff 0]
    foreach s $dashlist {
        set dash dash_$s
        puts "dash = $dash"
        $sm add command -image $dash -compound left -command "$dash_mb configure -image $dash -text $s"
    }
    grid $dash_mb -column 1 -row 3 -sticky news

    grid [button $f.btn_ok -text "OK" -command "Matrix::SetLineProperty $w $color_mb $dash_mb"] -column 0 -row 4 -sticky es
    grid [button $f.btn_exit -text "Cancel" -command "destroy $w" ] -column 1 -row 4 -sticky wens
    
}
proc Matrix::SetLineProperty {w cmb smb} {

    variable select_color red
    variable select_dash 0
    set select_color [lindex [$cmb configure -text] 4]
    set select_dash [lindex [$smb configure -text] 4]
    puts "select_color: $select_color | select_dash : $select_dash"
    Matrix::set_mode create_line_enable
    destroy $w
}
proc Matrix::set_mode {m} {
    variable mode
    variable bk_mode
    set mode $m
    set bk_mode $m
    puts "$mode"
}
proc Matrix::double_click_1 {x y} {
    variable line_coord
    variable linewidth
    variable maincanvas
    variable mode
    variable lastX
    variable lastY
    #set startX [$maincanvas canvasx $x]
    #set startY [$maincanvas canvasx $y]
    set lastX [$maincanvas canvasx $x]
    set lastY [$maincanvas canvasy $y]
    switch -exact -- $mode {
        create_line_sharp {
            set mode finished
            lappend line_coord $lastX
            lappend line_coord $lastY
            $maincanvas delete line_sharp
            $maincanvas delete line_sharp_rdy
            #$maincanvas delete text_coord
            $maincanvas delete text_coord_line
            Matrix::line_create $line_coord $linewidth           
            set line_coord {}
        }
        normal {

            puts "double click"
        }
    }
}
proc Matrix::coordmark {x y} {
    variable boxwidth
    variable boxheight
    variable line_coord

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
            Matrix::text_coord $lastX $lastY
            Matrix::box_create $lastX $lastY $boxwidth $boxheight 1
            set mode create_box_sharp
        }
        create_box_sharp {
            $maincanvas delete select_sharp
            $maincanvas delete text_coord
            Matrix::box_create $lastX $lastY $boxwidth $boxheight 0
            set mode normal
        }
        create_line_enable {
            lappend line_coord $lastX
            lappend line_coord $lastY
            $maincanvas addtag text_coord_line withtag text_coord
            $maincanvas dtag text_coord 
            #Matrix::text_coord $lastX $lastY
            set mode create_line_sharp
        }
        create_line_sharp {
            lappend line_coord $lastX
            lappend line_coord $lastY
            $maincanvas delete line_sharp
            $maincanvas delete line_sharp_rdy
            $maincanvas addtag text_coord_line withtag text_coord
            $maincanvas dtag text_coord
            $maincanvas create line $line_coord -fill yellow2 -tags "line_sharp_rdy"
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
            $maincanvas move text_coord [expr {$x-$lastX}] [expr {$y-$lastY}]
            set intx [expr int($x)]
            set inty [expr int($y)]
            $maincanvas itemconfigure text_coord -text "($intx,$inty)"
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
        create_line_enable {
            $maincanvas delete text_coord
            Matrix::text_coord $x $y
        }
        create_line_sharp {
            Matrix::line_sharp_create $lastX $lastY $x $y
        }
        normal {

        }
        
    }
}

proc Matrix::main {{w 850} {h 480}} {

    wm withdraw .
    wm title . "X-Ray out-Man"

    wm deiconify .
    wm geom . 850x480+0+0
    
    raise .
    #focus -force .
    set f [frame .f]
    pack $f -fill both -expand yes
    Matrix::Matrixinit $f $w $h
    #GDSIIReader::readfile example.cal
#    GDSIIReader::readfile and.gds
    #GDSIIReader::readfile FAtuning.gds2
#    Matrix::Matrixcreate

}

Matrix::main 850 480
