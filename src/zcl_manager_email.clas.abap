CLASS ZCL_MANAGER_EMAIL DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC .

  PUBLIC SECTION.

    METHODS SEND_EMAIL
      IMPORTING IV_JOB_UUID      TYPE ZDRS_JOB_CONFIG-JOB_UUID
                IV_REPORT_ID     TYPE ZDRS_SUBSCR-REPORT_ID
                IV_OUTPUT_FORMAT TYPE ZDRS_SUBSCR-OUTPUT_FORMAT
                IV_FILE_CONTENT  TYPE ZDRS_FILE-FILE_CONTENT
                IV_FILE_NAME     TYPE ZDRS_FILE-FILE_NAME
                IV_CREATED_BY    TYPE SYUNAME
                IV_EMAIL_TO      TYPE STRING
                IV_EMAIL_CC      TYPE STRING.

    CLASS-METHODS PARSE_EMAILS
      IMPORTING IV_EMAIL_STRING  TYPE STRING
      RETURNING
                VALUE(RT_EMAILS) TYPE STRING_TABLE.

    METHODS REFACTOR_FILE
      IMPORTING IV_FILE_CONTENT  TYPE ZDRS_FILE-FILE_CONTENT
                IV_OUTPUT_FORMAT TYPE ZDRS_SUBSCR-OUTPUT_FORMAT
      EXPORTING
                EV_FILE_CONTENT  TYPE SOLIX_TAB
                EV_TYPE          TYPE SOODK-OBJTP.

  PROTECTED SECTION.
  PRIVATE SECTION.
    METHODS GET_EMAIL_FROM_UNAME
      IMPORTING IV_UNAME        TYPE SYUNAME
      RETURNING VALUE(RV_EMAIL) TYPE AD_SMTPADR.

ENDCLASS.



CLASS ZCL_MANAGER_EMAIL IMPLEMENTATION.

  METHOD SEND_EMAIL.
    " Logic will be implemented by someone else
    DATA: LO_SEND_REQUEST    TYPE REF TO CL_BCS,
          LO_DOCUMENT        TYPE REF TO CL_DOCUMENT_BCS,
          LO_RECIPIENT       TYPE REF TO IF_RECIPIENT_BCS,
          LX_BCS             TYPE REF TO CX_BCS,
          LT_BODY            TYPE BCSY_TEXT,
          LT_ATT_CONTENT_HEX TYPE SOLIX_TAB,
          LV_ATT_TYPE        TYPE SOODK-OBJTP.

    TRY.
        LO_SEND_REQUEST = CL_BCS=>CREATE_PERSISTENT( ).

        " Render email content
        DATA(LV_HTML_STRING) = ZCL_TEMPLATE_EMAIL=>RENDER_EMAIL( IV_JOB_UUID = IV_JOB_UUID ).
        LT_BODY = CL_DOCUMENT_BCS=>STRING_TO_SOLI( LV_HTML_STRING ).


        " Create document for Email
        LO_DOCUMENT = CL_DOCUMENT_BCS=>CREATE_DOCUMENT(
              I_TYPE    = 'HTM'
              I_SUBJECT = |DERS-Fiori: { IV_REPORT_ID } Export Complete|
              I_TEXT    = LT_BODY
            ).

        " Add attach file
        IF IV_FILE_CONTENT IS NOT INITIAL.
          ME->REFACTOR_FILE(
                            EXPORTING IV_FILE_CONTENT  = IV_FILE_CONTENT
                                      IV_OUTPUT_FORMAT = IV_OUTPUT_FORMAT
                            IMPORTING EV_FILE_CONTENT  = LT_ATT_CONTENT_HEX
                                      EV_TYPE          = LV_ATT_TYPE )  .


          " Limited file name is 50 character
          DATA(LV_FILENAME_50) = CONV SOOD-OBJDES( IV_FILE_NAME ).

          LO_DOCUMENT->ADD_ATTACHMENT(
            I_ATTACHMENT_TYPE    = LV_ATT_TYPE
            I_ATTACHMENT_SUBJECT = LV_FILENAME_50
            I_ATT_CONTENT_HEX    = LT_ATT_CONTENT_HEX
          ).
        ENDIF.

        LO_SEND_REQUEST->SET_DOCUMENT( LO_DOCUMENT ).

        DATA(LV_USER_EMAIL) = GET_EMAIL_FROM_UNAME( IV_CREATED_BY ).

        IF LV_USER_EMAIL IS NOT INITIAL.
          DATA(LO_RECIPIENT_CREATOR) = CL_CAM_ADDRESS_BCS=>CREATE_INTERNET_ADDRESS( LV_USER_EMAIL  ).

          LO_SEND_REQUEST->ADD_RECIPIENT( I_RECIPIENT = LO_RECIPIENT_CREATOR ).
        ELSE.
          " Xử lý ngoại lệ nếu user không có email trong SU01 (Tùy chọn)
          " Có thể ghi log hoặc raise exception
        ENDIF.

        " Email To
*        DATA lv_user_email TYPE string VALUE 'hieunmse182322@fpt.edu.vn'.
        IF IV_EMAIL_TO IS NOT INITIAL.  "iv_email_to

          DATA(LT_EMAIL_TO) = PARSE_EMAILS( IV_EMAIL_TO ).

          LOOP AT LT_EMAIL_TO INTO DATA(LV_TO).
            LO_RECIPIENT = CL_CAM_ADDRESS_BCS=>CREATE_INTERNET_ADDRESS( CONV #( LV_TO ) ).
            LO_SEND_REQUEST->ADD_RECIPIENT( LO_RECIPIENT ).
          ENDLOOP.


        ENDIF.

        " Email CC
        IF IV_EMAIL_CC IS NOT INITIAL.

          DATA(LT_EMAIL_CC) = PARSE_EMAILS( IV_EMAIL_CC ).

          LOOP AT LT_EMAIL_CC INTO DATA(LV_CC).
            DATA(LO_RECIPIENT_CC) = CL_CAM_ADDRESS_BCS=>CREATE_INTERNET_ADDRESS( CONV #( LV_CC ) ).
            LO_SEND_REQUEST->ADD_RECIPIENT(
            I_RECIPIENT = LO_RECIPIENT_CC
            I_COPY      = ABAP_TRUE
          ).
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
        LO_SEND_REQUEST->SET_SENDER( CL_SAPUSER_BCS=>CREATE( SY-UNAME ) ).
        LO_SEND_REQUEST->SET_SEND_IMMEDIATELY( ABAP_TRUE ).

        DATA(LV_SENT) = LO_SEND_REQUEST->SEND( ).


        IF LV_SENT = ABAP_TRUE.
          COMMIT WORK.
        ELSE.
          ROLLBACK WORK.
        ENDIF.

      CATCH CX_BCS INTO LX_BCS.

    ENDTRY.
  ENDMETHOD.

  METHOD PARSE_EMAILS.

    " Convert semicolon to comma
    DATA(LV_STRING_TO) = IV_EMAIL_STRING.
    REPLACE ALL OCCURRENCES OF ';' IN LV_STRING_TO WITH ','.

    " Slit string email by comma
    SPLIT LV_STRING_TO AT ',' INTO TABLE DATA(LT_TEMP).

    LOOP AT LT_TEMP INTO DATA(LV_EMAIL).
      CONDENSE LV_EMAIL.
      IF LV_EMAIL IS NOT INITIAL.
        APPEND LV_EMAIL TO RT_EMAILS.
      ENDIF.
    ENDLOOP.

  ENDMETHOD.

  METHOD REFACTOR_FILE.
    " Convert content XSTRING to HEX
    EV_FILE_CONTENT = CL_BCS_CONVERT=>XSTRING_TO_SOLIX( IV_FILE_CONTENT ).

    " Format file
    DATA(LV_FORMAT_UPPER) = TO_UPPER( IV_OUTPUT_FORMAT ).

    IF LV_FORMAT_UPPER CS 'XLSX' OR LV_FORMAT_UPPER CS 'XLS'.
      EV_TYPE = 'XLS'.
    ELSEIF LV_FORMAT_UPPER CS 'PDF'.
      EV_TYPE = 'PDF'.
    ELSEIF LV_FORMAT_UPPER CS 'CSV'.
      EV_TYPE = 'CSV'.
    ELSE.
      EV_TYPE = 'BIN'.
    ENDIF.

  ENDMETHOD.

  METHOD GET_EMAIL_FROM_UNAME.
*    " Get email from User Profile (SU01)
*    DATA: LT_RETURN TYPE TABLE OF BAPIRET2,
*          LT_SMTP   TYPE TABLE OF BAPIADSMTP.
*
*    CALL FUNCTION 'BAPI_USER_GET_DETAIL'
*      EXPORTING
*        USERNAME = IV_UNAME
*      TABLES
*        RETURN   = LT_RETURN
*        ADDSMTP  = LT_SMTP.
*
*    READ TABLE LT_SMTP INTO DATA(LS_SMTP) INDEX 1.
*    IF SY-SUBRC = 0.
*      RV_EMAIL = LS_SMTP-E_MAIL.
*    ENDIF.

    SELECT SINGLE A~SMTP_ADDR
        FROM USR21 AS U
        INNER JOIN ADR6 AS A ON U~ADDRNUMBER = A~ADDRNUMBER
                      AND U~PERSNUMBER = A~PERSNUMBER
        WHERE U~BNAME = @IV_UNAME
        INTO @RV_EMAIL.
  ENDMETHOD.

ENDCLASS.
