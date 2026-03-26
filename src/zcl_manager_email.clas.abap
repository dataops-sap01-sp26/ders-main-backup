CLASS zcl_manager_email DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC .

  PUBLIC SECTION.

    METHODS send_email
      IMPORTING iv_job_uuid      TYPE zdrs_job_config-job_uuid
                iv_report_id     TYPE zdrs_subscr-report_id
                iv_output_format TYPE zdrs_subscr-output_format
                iv_file_content  TYPE zdrs_file-file_content
                iv_file_name     TYPE zdrs_file-file_name
                iv_email_to      TYPE string
                iv_email_cc      TYPE string.

    CLASS-METHODS parse_emails
      IMPORTING iv_email_string  TYPE string
      RETURNING
                VALUE(rt_emails) TYPE string_table.

    METHODS refactor_file
      IMPORTING iv_file_content  TYPE zdrs_file-file_content
                iv_output_format TYPE zdrs_subscr-output_format
      EXPORTING
                ev_file_content  TYPE solix_tab
                ev_type          TYPE soodk-objtp.

  PROTECTED SECTION.
  PRIVATE SECTION.


ENDCLASS.



CLASS zcl_manager_email IMPLEMENTATION.

  METHOD send_email.
    " Logic will be implemented by someone else
    DATA: lo_send_request    TYPE REF TO cl_bcs,
          lo_document        TYPE REF TO cl_document_bcs,
          lo_recipient       TYPE REF TO if_recipient_bcs,
          lx_bcs             TYPE REF TO cx_bcs,
          lt_body            TYPE bcsy_text,
          lt_att_content_hex TYPE solix_tab,
          lv_att_type        TYPE soodk-objtp.

    TRY.
        lo_send_request = cl_bcs=>create_persistent( ).

        " Render email content
        DATA(lv_html_string) = zcl_template_email=>render_email( iv_job_uuid = iv_job_uuid ).
        lt_body = cl_document_bcs=>string_to_soli( lv_html_string ).


        " Create document for Email
        lo_document = cl_document_bcs=>create_document(
              i_type    = 'HTM'
              i_subject = |DERS-Fiori: { iv_report_id } Export Complete|
              i_text    = lt_body
            ).

        " Add attach file
        IF iv_file_content IS NOT INITIAL.
          me->refactor_file(
                            EXPORTING iv_file_content  = iv_file_content
                                      iv_output_format = iv_output_format
                            IMPORTING ev_file_content  = lt_att_content_hex
                                      ev_type          = lv_att_type )  .


          " Limited file name is 50 character
          DATA(lv_filename_50) = CONV sood-objdes( iv_file_name ).

          lo_document->add_attachment(
            i_attachment_type    = lv_att_type
            i_attachment_subject = lv_filename_50
            i_att_content_hex    = lt_att_content_hex
          ).
        ENDIF.

        lo_send_request->set_document( lo_document ).

        " Email To
*        DATA lv_user_email TYPE string VALUE 'hieunmse182322@fpt.edu.vn'.
        IF iv_email_to IS NOT INITIAL.  "iv_email_to

          DATA(lt_email_to) = parse_emails( iv_email_to ).

          LOOP AT lt_email_to INTO DATA(lv_to).
            lo_recipient = cl_cam_address_bcs=>create_internet_address( CONV #( lv_to ) ).
            lo_send_request->add_recipient( lo_recipient ).
          ENDLOOP.


        ENDIF.

        " Email CC
        IF iv_email_cc IS NOT INITIAL.

          DATA(lt_email_cc) = parse_emails( iv_email_cc ).

          LOOP AT lt_email_cc INTO DATA(lv_cc).
            DATA(lo_recipient_cc) = cl_cam_address_bcs=>create_internet_address( CONV #( lv_cc ) ).
            lo_send_request->add_recipient(
            i_recipient = lo_recipient_cc
            i_copy      = abap_true
          ).
            lo_send_request->add_recipient( lo_recipient ).
          ENDLOOP.

        ENDIF.

*        " Email BCC
*        IF iv_email_cc IS NOT INITIAL.
*          DATA(lo_recipient_bcc) = cl_cam_address_bcs=>create_internet_address( CONV #( iv_email_bcc ) ).
*          lo_send_request->add_recipient(
*            i_recipient = lo_recipient_bcc
*            i_blind_copy      = abap_true
*          ).
*        ENDIF.

        "Send email
        lo_send_request->set_sender( cl_sapuser_bcs=>create( sy-uname ) ).
        lo_send_request->set_send_immediately( abap_true ).

        DATA(lv_sent) = lo_send_request->send( ).


        IF lv_sent = abap_true.
          COMMIT WORK.
        ELSE.
          ROLLBACK WORK.
        ENDIF.

      CATCH cx_bcs INTO lx_bcs.

    ENDTRY.
  ENDMETHOD.

  METHOD parse_emails.

    " Convert semicolon to comma
    DATA(lv_string_to) = iv_email_string.
    REPLACE ALL OCCURRENCES OF ';' IN lv_string_to WITH ','.

    " Slit string email by comma
    SPLIT lv_string_to AT ',' INTO TABLE DATA(lt_temp).

    LOOP AT lt_temp INTO DATA(lv_email).
      CONDENSE lv_email.
      IF lv_email IS NOT INITIAL.
        APPEND lv_email TO rt_emails.
      ENDIF.
    ENDLOOP.

  ENDMETHOD.

  METHOD refactor_file.
    " Convert content XSTRING to HEX
    ev_file_content = cl_bcs_convert=>xstring_to_solix( iv_file_content ).

    " Format file
    DATA(lv_format_upper) = to_upper( iv_output_format ).

    IF lv_format_upper CS 'XLSX' OR lv_format_upper CS 'XLS'.
      ev_type = 'XLS'.
    ELSEIF lv_format_upper CS 'PDF'.
      ev_type = 'PDF'.
    ELSEIF lv_format_upper CS 'CSV'.
      ev_type = 'CSV'.
    ELSE.
      ev_type = 'BIN'.
    ENDIF.

  ENDMETHOD.

ENDCLASS.
