module handlers

  use iso_c_binding
  use gtk_hl
  use gtk, only: gtk_builder_add_from_file, gtk_builder_connect_signals, gtk_buil&
       &der_get_object, gtk_builder_new, gtk_main, gtk_main_quit, &
       & gtk_widget_show, gtk_init, gtk_entry_get_text_length, &
       & gtk_entry_get_text, gtk_text_iter_get_text
  use g, only: g_object_unref

  implicit none

  type(c_ptr) ::  win, zedt, contain, qbut, box, entry, box2, &
       & abut, ibut, clbut, infobut

contains
  subroutine my_destroy(widget, gdata) bind(c)
    type(c_ptr), value :: widget, gdata
    print *, "Exit called"
!    call gtk_widget_destroy(win)
    call gtk_main_quit ()
  end subroutine my_destroy

  subroutine tv_change(widget, gdata) bind(c)
    type(c_ptr), value :: widget, gdata

    integer(kind=c_int) :: nl, nc
    integer(kind=c_int), dimension(:), allocatable :: ncl

    print *, "CHANGED event"

    call hl_gtk_text_view_get_info(C_NULL_PTR, buffer=widget, nlines=nl, &
         & nchars=nc, ncline=ncl)
    print *, nl, nc
    print *, ncl
    deallocate(ncl)

  end subroutine tv_change
  subroutine tv_ins(widget,iter, text, nins, gdata) bind(c)
    type(c_ptr), value :: widget, gdata
    type(c_ptr), value :: iter, text
    integer(kind=c_int), value :: nins

    integer(kind=c_int) :: nl, nc
    integer(kind=c_int), dimension(:), allocatable :: ncl

    character(kind=c_char), dimension(:), pointer :: cf_text
    character(len=100), dimension(:), allocatable :: f_text

    print *, "INSERT event", nins
    call c_f_pointer(text, cf_text, (/ int(nins) /))
    call convert_c_string(cf_text, f_text)

    print "(a)", f_text
!!$    deallocate(f_text)

    call hl_gtk_text_view_get_info(C_NULL_PTR, buffer=widget, nlines=nl, &
         & nchars=nc, ncline=ncl)
    print *, nl, nc
    print *, ncl
!!$    deallocate(ncl)

  end subroutine tv_ins

  subroutine tv_del(widget, s_iter, e_iter, gdata) bind(c)
    type(c_ptr), value :: widget, gdata
    type(c_ptr), value :: s_iter, e_iter

    type(c_ptr) :: ctext
    character(len=100), dimension(:), allocatable :: ftext
    integer(kind=c_int) :: dlen

    print *, "DELETE event"
    dlen = gtk_text_iter_get_offset(e_iter) - &
         & gtk_text_iter_get_offset(s_iter)

    ctext = gtk_text_iter_get_text(s_iter, e_iter)
    call convert_c_string(ctext, int(dlen), ftext)

    print "(A)", ftext
    deallocate(ftext)
  end subroutine tv_del

  subroutine tv_append(widget, gdata) bind(c)
    type(c_ptr), value :: widget, gdata

    character(len=40) :: ftext

    call hl_gtk_entry_get_text(entry, ftext) 
    call hl_gtk_text_view_insert(zedt, (/ trim(ftext) /))

  end subroutine tv_append
  subroutine tv_insert(widget, gdata) bind(c)
    type(c_ptr), value :: widget, gdata

    character(len=40) :: ftext

    call hl_gtk_entry_get_text(entry, ftext)
    call hl_gtk_text_view_insert(zedt, (/ trim(ftext) /), at_cursor=TRUE)

  end subroutine tv_insert

  subroutine tv_clr(widget, gdata) bind(c)
    type(c_ptr), value :: widget, gdata

    call hl_gtk_text_view_delete(zedt)
  end subroutine tv_clr

  subroutine tv_info(widget, gdata) bind(c)
    type(c_ptr), value :: widget, gdata

    integer(kind=c_int), dimension(3) :: cursor, s_start, s_end
    integer(kind=c_int) :: is_modified, has_select

    cursor = hl_gtk_text_view_get_cursor(zedt)
    has_select = hl_gtk_text_view_get_selection(zedt, &
         & s_start, s_end)
    is_modified = hl_gtk_text_view_get_modified(zedt)

    print *, "Cursor: Line",cursor(1),"Column",cursor(2),"Offset",cursor(3)
    if (has_select == TRUE) then
       print *, "Selection Start: Line",s_start(1),"Column",s_start(2), &
            & "Offset",s_start(3)
       print *, "Selection End: Line",s_end(1),"Column",s_end(2),"Offset", &
            & s_end(3)
    else
       print *, "No Selection"
    end if
    if (is_modified == TRUE) then 
       print *, "Modified"
    else
       print *, "Not modified"
    end if
    call hl_gtk_text_view_set_modified(zedt, FALSE)
  end subroutine tv_info

  subroutine entry_text(widget, gdata) bind(c)
    type(c_ptr), value :: widget, gdata

    integer(kind=c_int16_t) :: ntext

    ntext = gtk_entry_get_text_length(widget)
    if (ntext > 0) then
       call gtk_widget_set_sensitive(abut, TRUE)
       call gtk_widget_set_sensitive(ibut, TRUE)
    else
       call gtk_widget_set_sensitive(abut, FALSE)
       call gtk_widget_set_sensitive(ibut, FALSE)
    end if

  end subroutine entry_text

end module handlers

program ztext
  ! ZTEXT
  ! Simple multiline text box example

  use handlers

  implicit none


  ! Initialize pilib
  call gtk_init()

  ! Make a window and a vertical box
  win = hl_gtk_window_new("Scrolling text"//c_null_char, destroy=c_funloc(my_destroy))
  box = hl_gtk_box_new()
  call gtk_container_add(win, box)

  ! Make a scrolling text box and put it in the box
  zedt = hl_gtk_text_view_new(contain, editable=TRUE, &
       & changed=c_funloc(tv_change), &
       & insert_text=c_funloc(tv_ins), &
       & delete_range=c_funloc(tv_del), &
       & ssize=(/350_c_int, 200_c_int/), tooltip = &
       & "Try typing, pasting or cutting text in here"//c_null_char)
  call hl_gtk_box_pack(box, contain)

  ! Make a single line text entry, and buttons to append or place at cursor.

  entry = hl_gtk_entry_new(60_c_int, editable=TRUE, tooltip = &
       & "Enter text here, then click 'append' or 'insert'"//c_null_char, &
       & changed=c_funloc(entry_text))
  call hl_gtk_box_pack(box, entry, expand=FALSE)

  box2 = hl_gtk_box_new(horizontal=TRUE)
  call hl_gtk_box_pack(box, box2, expand=FALSE)

  abut = hl_gtk_button_new("Append"//c_null_char, clicked=c_funloc(tv_append), &
       & tooltip = "Add contents of entry box at end"//c_null_char, sensitive=FALSE)
  call hl_gtk_box_pack(box2, abut)
  ibut = hl_gtk_button_new("Insert"//c_null_char, clicked=c_funloc(tv_insert), &
       & tooltip = "Add contents of entry box at cursor"//c_null_char, &
       & sensitive=FALSE)
  call hl_gtk_box_pack(box2, ibut)

  ! And a clear button, and an info button
  infobut = hl_gtk_button_new("Information"//c_null_char, clicked=c_funloc(tv_info))
  call hl_gtk_box_pack(box, infobut, expand=FALSE)
  clbut = hl_gtk_button_new("Clear"//c_null_char, clicked=c_funloc(tv_clr))
  call hl_gtk_box_pack(box, clbut, expand=FALSE)

  ! Make a quit button and put that in the box, then
  ! put the box in the window.
  qbut = hl_gtk_button_new("Quit"//c_null_char, clicked=c_funloc(my_destroy))
  call hl_gtk_box_pack(box, qbut, expand=FALSE)

  ! Realize the window
  call gtk_widget_show_all(win)

  ! Event loop
  call gtk_main()

end program ztext
