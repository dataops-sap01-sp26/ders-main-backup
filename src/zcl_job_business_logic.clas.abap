CLASS ZCL_JOB_BUSINESS_LOGIC DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC .

  PUBLIC SECTION.
    " Interface for design-time parameter definition
    INTERFACES IF_APJ_DT_EXEC_OBJECT.
    " Interface for runtime execution
    INTERFACES IF_APJ_RT_EXEC_OBJECT.

  PROTECTED SECTION.
  PRIVATE SECTION.

    " Instance state
    DATA MV_UUID_STR TYPE STRING.                  " Job UUID (hex string)
    DATA MV_JOB_ID   TYPE ZDRS_JOB_CONFIG-JOB_ID.  " Job ID (fallback)
    DATA MV_JOB_UUID TYPE SYSUUID_X16.             " Job UUID (binary x16)
    DATA MV_SUBSCR_ID   TYPE N LENGTH 6.           " Subscription ID (user-selected)
    DATA MV_TMZONE   TYPE TIMEZONE.                " Job timezone
    DATA MV_DATE     TYPE D.                       " Execution date (local TZ)
    DATA MV_T_LOCAL  TYPE T.                       " Execution time (local TZ)

    " Step 1: Extract JOB_UUID and JOB_ID from job parameter list
    METHODS PARSE_PARAMETERS
      IMPORTING IT_PARAMETERS TYPE IF_APJ_RT_EXEC_OBJECT=>TT_TEMPL_VAL.

    " Step 2: Resolve job record from DB
    METHODS FIND_JOB_RECORD
      RETURNING VALUE(RV_FOUND) TYPE ABAP_BOOL.

    " Step 3: Query subscription params, create report, generate + store file
    METHODS PROCESS_SUBSCRSCRIPTION.

    " Step 3a: Factory — create report instance by report_id
    METHODS CREATE_REPORT
      IMPORTING IS_PARAMS        TYPE ZIF_REPORT=>TY_PARAMS
      RETURNING VALUE(RO_REPORT) TYPE REF TO ZIF_REPORT.

    " Step 3b: Duplicate check
    METHODS IS_DUPLICATE
      RETURNING VALUE(RV_RESULT) TYPE ABAP_BOOL.

    " Step 3c: Persist generated file
    METHODS STORE_FILE
      IMPORTING IV_XSTRING   TYPE XSTRING
                IV_EXTENSION TYPE STRING
                IV_MIME_TYPE TYPE STRING
                IV_PREFIX    TYPE STRING.

    " Step 3d: Send mail logic
    METHODS SEND_EMAIL
      IMPORTING IV_REPORT_ID TYPE ZDRS_SUBSCR-REPORT_ID
                IV_OUTPUT_FORMAT TYPE ZDRS_SUBSCR-OUTPUT_FORMAT
                IV_EMAIL_TO TYPE string
                IV_EMAIL_CC TYPE string.

ENDCLASS.


CLASS ZCL_JOB_BUSINESS_LOGIC IMPLEMENTATION.

  METHOD IF_APJ_DT_EXEC_OBJECT~GET_PARAMETERS.
    ET_PARAMETER_DEF = VALUE #(
      DATATYPE       = 'C'
      CHANGEABLE_IND = ABAP_TRUE
      ( SELNAME       = 'JOB_UUID'
        KIND          = IF_APJ_DT_EXEC_OBJECT=>PARAMETER
        PARAM_TEXT    = 'Job UUID'
        LENGTH        = 32
        LOWERCASE_IND = ABAP_TRUE
        MANDATORY_IND = ABAP_FALSE )
      ( SELNAME       = 'JOB_ID'
        KIND          = IF_APJ_DT_EXEC_OBJECT=>PARAMETER
        PARAM_TEXT    = 'Job ID'
        LENGTH        = 12
        LOWERCASE_IND = ABAP_FALSE
        MANDATORY_IND = ABAP_FALSE )
    ).
  ENDMETHOD.


  METHOD IF_APJ_RT_EXEC_OBJECT~EXECUTE.
    " STEP 1: Parse job parameters
    PARSE_PARAMETERS( IT_PARAMETERS ).

    " STEP 2: Resolve job record from DB
    IF FIND_JOB_RECORD( ) = ABAP_FALSE.
      RETURN.
    ENDIF.

    " STEP 3: Resolve local date/time for file naming
    DATA LV_TS_NOW TYPE TIMESTAMPL.
    GET TIME STAMP FIELD LV_TS_NOW.
    CONVERT TIME STAMP LV_TS_NOW TIME ZONE MV_TMZONE
      INTO DATE MV_DATE TIME MV_T_LOCAL.

    " STEP 4: Query subscription → create report → generate + store file
    PROCESS_SUBSCRSCRIPTION( ).
  ENDMETHOD.


  METHOD PARSE_PARAMETERS.
    LOOP AT IT_PARAMETERS INTO DATA(LS_PARAMETER).
      CASE LS_PARAMETER-SELNAME.
        WHEN 'JOB_UUID'. MV_UUID_STR = LS_PARAMETER-LOW.
        WHEN 'JOB_ID'.   MV_JOB_ID   = LS_PARAMETER-LOW.
      ENDCASE.
    ENDLOOP.
  ENDMETHOD.


  METHOD FIND_JOB_RECORD.
    " Primary lookup by UUID
    IF MV_UUID_STR IS NOT INITIAL.
      TRY.
          MV_JOB_UUID = CONV #( MV_UUID_STR ).
        CATCH CX_ROOT.
          CLEAR MV_JOB_UUID.
      ENDTRY.

      IF MV_JOB_UUID IS NOT INITIAL.
        SELECT SINGLE SUBSCR_ID, TMZONE
          FROM ZDRS_JOB_CONFIG
          WHERE JOB_UUID = @MV_JOB_UUID
          INTO ( @MV_SUBSCR_ID, @MV_TMZONE ).
      ENDIF.
    ENDIF.

    " Fallback lookup by JOB_ID
    IF MV_JOB_UUID IS INITIAL AND MV_JOB_ID IS NOT INITIAL.
      SELECT SINGLE JOB_UUID, SUBSCR_ID, TMZONE
        FROM ZDRS_JOB_CONFIG
        WHERE JOB_ID = @MV_JOB_ID
        INTO ( @MV_JOB_UUID, @MV_SUBSCR_ID, @MV_TMZONE ).
    ENDIF.

    IF MV_TMZONE IS INITIAL.
      MV_TMZONE = 'UTC'.
    ENDIF.

    RV_FOUND = COND #( WHEN MV_JOB_UUID IS NOT INITIAL
                       THEN ABAP_TRUE ELSE ABAP_FALSE ).
  ENDMETHOD.


  METHOD PROCESS_SUBSCRSCRIPTION.
    " 1. Query the generic subscription header linked to this job
    SELECT SINGLE REPORT_ID, OUTPUT_FORMAT, EMAIL_CC, EMAIL_TO, SUBSCR_UUID
      FROM ZDRS_SUBSCR
      WHERE SUBSCR_ID = @MV_SUBSCR_ID
      INTO @DATA(LS_SUBSCR).

    IF SY-SUBRC <> 0.
      RETURN. " No generic subscription found
    ENDIF.

    " 2. Only pass context parameters to the factory
    DATA LS_PARAMS TYPE ZIF_REPORT=>TY_PARAMS.
    LS_PARAMS-SUBSCR_UUID  = LS_SUBSCR-SUBSCR_UUID.
    LS_PARAMS-REPORT_ID = LS_SUBSCR-REPORT_ID.
    LS_PARAMS-OUTPUT_FORMAT = LS_SUBSCR-OUTPUT_FORMAT.

    " Create the report class matching the report_id
    DATA(LO_REPORT) = CREATE_REPORT( LS_PARAMS ).
    IF LO_REPORT IS NOT BOUND.
      RETURN. " Unknown report_id
    ENDIF.

    " Idempotency check
    IF IS_DUPLICATE( ) = ABAP_TRUE.
      RETURN.
    ENDIF.

    " Execute report → generate file
    DATA(LS_RESULT) = LO_REPORT->EXECUTE( ).

    " Persist the generated file
    STORE_FILE(
      IV_XSTRING   = LS_RESULT-XSTRING
      IV_EXTENSION = LS_RESULT-EXTENSION
      IV_MIME_TYPE = LS_RESULT-MIME_TYPE
      IV_PREFIX    = LS_RESULT-FILE_NAME_PREFIX
    ).

    " Send email
    SEND_EMAIL(
      IV_REPORT_ID     = LS_SUBSCR-REPORT_ID
      IV_OUTPUT_FORMAT = LS_SUBSCR-OUTPUT_FORMAT
      IV_EMAIL_CC = CONV #( LS_SUBSCR-EMAIL_CC )
      IV_EMAIL_TO   = CONV #( LS_SUBSCR-EMAIL_TO )
    ).
  ENDMETHOD.


  METHOD CREATE_REPORT.
    ro_report = zcl_report_factory=>create(
      iv_report_id = CONV #( is_params-report_id )
      is_params    = is_params
    ).
  ENDMETHOD.


  METHOD IS_DUPLICATE.
    " Block retries within 30 seconds for this job
    DATA LV_CUTOFF TYPE TIMESTAMPL.
    GET TIME STAMP FIELD LV_CUTOFF.
    LV_CUTOFF = CL_ABAP_TSTMP=>SUBTRACTSECS(
                  TSTMP = LV_CUTOFF
                  SECS  = 30 ).

    DATA LV_COUNT TYPE I.
    SELECT COUNT(*) FROM ZDRS_FILE
      WHERE JOB_UUID = @MV_JOB_UUID
        AND CREATED_AT  >= @LV_CUTOFF
      INTO @LV_COUNT.

    RV_RESULT = COND #( WHEN LV_COUNT > 0 THEN ABAP_TRUE ELSE ABAP_FALSE ).
  ENDMETHOD.


  METHOD SEND_EMAIL.
    " Logic will be implemented by someone else
     " Logic will be implemented by someone else
    DATA: lo_send_request TYPE REF TO cl_bcs,
          lo_document     TYPE REF TO cl_document_bcs,
          lo_recipient    TYPE REF TO if_recipient_bcs,
          lx_bcs          TYPE REF TO cx_bcs,
          lt_body         TYPE bcsy_text,
          lt_att_content_hex TYPE solix_tab,
          lv_att_type        TYPE soodk-objtp.

    " Get job from Table Jobhist
    SELECT SINGLE * FROM zdrs_job_config
      WHERE job_uuid = @mv_uuid_str
      INTO @DATA(ls_job).

    IF sy-subrc <> 0.
      RETURN. " Return if data not found
    ENDIF.

    " Get file from zdrs_file
    SELECT SINGLE * FROM zdrs_file
      WHERE job_uuid = @mv_uuid_str
      INTO @DATA(ls_file).

    TRY.
        lo_send_request = cl_bcs=>create_persistent( ).

        " Render email content
        DATA(lv_html_string) = zcl_template_email=>render_email( is_job = ls_job ).
        lt_body = cl_document_bcs=>string_to_soli( lv_html_string ).

        " Create document for Email
        lo_document = cl_document_bcs=>create_document(
              i_type    = 'HTM'
              i_subject = |DERS-Fiori: { iv_report_id } Export Complete|
              i_text    = lt_body
            ).

        " =========================================================
        " === THÊM ATTACHMENT (NẾU CÓ FILE VÀ CÓ DỮ LIỆU FILE) ====
        " =========================================================
        IF ls_file IS NOT INITIAL AND ls_file-file_content IS NOT INITIAL.

          " Chuyển nội dung XSTRING sang dạng bảng HEX
          lt_att_content_hex = cl_bcs_convert=>xstring_to_solix( ls_file-file_content ).

          " Xác định loại File (Chỉ được 3 ký tự)
          DATA(lv_format_upper) = to_upper( iv_output_format ).

          IF lv_format_upper CS 'XLSX' OR lv_format_upper CS 'XLS'.
            lv_att_type = 'XLS'. " SAP map XLSX vào dạng XLS
          ELSEIF lv_format_upper CS 'PDF'.
            lv_att_type = 'PDF'.
          ELSEIF lv_format_upper CS 'CSV'.
            lv_att_type = 'CSV'.
          ELSE.
            lv_att_type = 'BIN'. " Binary format cho các file khác
          ENDIF.

          " Giới hạn tên file 50 ký tự để tránh Dump
          DATA(lv_filename_50) = CONV sood-objdes( ls_file-file_name ).

          lo_document->add_attachment(
            i_attachment_type    = lv_att_type
            i_attachment_subject = lv_filename_50
            i_att_content_hex    = lt_att_content_hex
          ).
        ENDIF.
        " =========================================================

        lo_send_request->set_document( lo_document ).

        " Email To
*        DATA lv_user_email TYPE string VALUE 'hieunmse182322@fpt.edu.vn'.
        IF iv_email_to IS NOT INITIAL.  "iv_email_to
          lo_recipient = cl_cam_address_bcs=>create_internet_address( CONV #( iv_email_to ) ).
          lo_send_request->add_recipient( lo_recipient ).
        ENDIF.

        "Send email
        lo_send_request->set_sender( cl_sapuser_bcs=>create( sy-uname ) ).
        lo_send_request->set_send_immediately( abap_true ).

        DATA(lv_sent) = lo_send_request->send( ).

        " Sau khi send thành công thì mới Commit
        IF lv_sent = abap_true.
          COMMIT WORK.
        ELSE.
          ROLLBACK WORK.
        ENDIF.

      CATCH cx_bcs INTO lx_bcs.

    ENDTRY.
  ENDMETHOD.


  METHOD STORE_FILE.
    DATA(LV_HHMM)     = |{ MV_T_LOCAL+0(2) }{ MV_T_LOCAL+2(2) }|.
    DATA(LV_FILE_NAME) = |{ IV_PREFIX }_{ MV_DATE }_{ LV_HHMM }_{ MV_TMZONE }.{ IV_EXTENSION }|.

    DATA LV_TIMESTAMP TYPE TIMESTAMPL.
    GET TIME STAMP FIELD LV_TIMESTAMP.

    " CREATE_UUID_X16_STATIC raises CX_UUID_ERROR if the UUID
    " generator is unavailable — catch it to avoid an unhandled exception.
    DATA LV_FILE_UUID TYPE SYSUUID_X16.
    TRY.
        LV_FILE_UUID = CL_SYSTEM_UUID=>CREATE_UUID_X16_STATIC( ).
      CATCH CX_UUID_ERROR.
        RETURN. " Cannot generate UUID — skip storing the file
    ENDTRY.

    DATA(LS_FILE) = VALUE ZDRS_FILE(
      FILE_UUID    = LV_FILE_UUID
      JOB_UUID     = MV_JOB_UUID
      FILE_NAME    = LV_FILE_NAME
      MIME_TYPE    = IV_MIME_TYPE
      FILE_SIZE    = XSTRLEN( IV_XSTRING )
      FILE_CONTENT = IV_XSTRING
      CREATED_BY   = CL_ABAP_CONTEXT_INFO=>GET_USER_TECHNICAL_NAME( )
      CREATED_AT   = LV_TIMESTAMP
    ).

    INSERT ZDRS_FILE FROM @LS_FILE.
    COMMIT WORK.
  ENDMETHOD.

ENDCLASS.

