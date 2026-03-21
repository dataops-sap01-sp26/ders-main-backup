"! Class to debug DRS jobs - analyzes job config, subscription, parameters, files
"! Usage: Run with F9 in ADT (analyzes latest job automatically)
CLASS zcl_drs_job_debugger DEFINITION
  PUBLIC FINAL CREATE PUBLIC.

  PUBLIC SECTION.
    INTERFACES if_oo_adt_classrun.

ENDCLASS.


CLASS zcl_drs_job_debugger IMPLEMENTATION.

  METHOD if_oo_adt_classrun~main.
    " Debug latest job automatically
    SELECT job_uuid, job_id FROM zdrs_job_config
      ORDER BY created_at DESCENDING
      INTO @DATA(ls_job_key)
      UP TO 1 ROWS.
    ENDSELECT.

    IF sy-subrc <> 0.
      out->write( 'ERROR: No jobs found in ZDRS_JOB_CONFIG' ).
      RETURN.
    ENDIF.

    out->write( |===== JOB ANALYSIS: { ls_job_key-job_id } =====| ).
    out->write( | | ).

    " 1. Get job from ZDRS_JOB_CONFIG
    SELECT SINGLE * FROM zdrs_job_config
      WHERE job_uuid = @ls_job_key-job_uuid
      INTO @DATA(ls_job).

    IF sy-subrc <> 0.
      out->write( |ERROR: Job UUID not found in ZDRS_JOB_CONFIG| ).

      " Show recent jobs for comparison
      out->write( | | ).
      out->write( |Recent jobs (last 5):| ).
      SELECT job_id, job_status, job_status_text, created_at
        FROM zdrs_job_config
        ORDER BY created_at DESCENDING
        INTO TABLE @DATA(lt_recent)
        UP TO 5 ROWS.

      LOOP AT lt_recent INTO DATA(ls_recent).
        out->write( |  { ls_recent-job_id } - Status:{ ls_recent-job_status } ({ ls_recent-job_status_text }) - { ls_recent-created_at }| ).
      ENDLOOP.

      RETURN.
    ENDIF.

    " 2. Display Job Config Info
    out->write( |[JOB CONFIG]| ).
    out->write( |  Job ID: { ls_job-job_id }| ).
    out->write( |  Job UUID: { ls_job-job_uuid }| ).
    out->write( |  Job Name (BG): { ls_job-job_name }| ).
    out->write( |  Job Count: { ls_job-job_count }| ).
    out->write( |  Status: { ls_job-job_status } ({ ls_job-job_status_text })| ).
    out->write( |  Message: { ls_job-message }| ).
    out->write( |  Subscription UUID: { ls_job-subscr_uuid }| ).
    out->write( |  Created: { ls_job-created_at } by { ls_job-created_by }| ).
    out->write( |  Changed: { ls_job-last_changed_at } by { ls_job-last_changed_by }| ).
    out->write( | | ).

    " 3. Check Background Job in TBTCO
    IF ls_job-job_name IS NOT INITIAL.
      out->write( |[BACKGROUND JOB (TBTCO)]| ).
      SELECT SINGLE * FROM tbtco
        WHERE jobname = @ls_job-job_name
          AND jobcount = @ls_job-job_count
        INTO @DATA(ls_tbtco).

      IF sy-subrc = 0.
        out->write( |  Job Name: { ls_tbtco-jobname }| ).
        out->write( |  Job Count: { ls_tbtco-jobcount }| ).
        out->write( |  Status: { ls_tbtco-status } (A=Scheduled, R=Running, F=Finished, S=Released, X=Aborted)| ).
        out->write( |  Start: { ls_tbtco-strtdate } { ls_tbtco-strttime }| ).
        out->write( |  End: { ls_tbtco-enddate } { ls_tbtco-endtime }| ).
        out->write( |  Scheduled by: { ls_tbtco-sdluname }| ).
      ELSE.
        out->write( |  Job not found in TBTCO (not yet scheduled?)| ).
      ENDIF.
      out->write( | | ).
    ELSE.
      out->write( |[BACKGROUND JOB]| ).
      out->write( |  WARNING: job_name is empty - job not scheduled yet!| ).
      out->write( |  Action: Click "Schedule Job" button in Fiori app| ).
      out->write( | | ).
    ENDIF.

    " 4. Check Subscription
    out->write( |[SUBSCRIPTION]| ).
    IF ls_job-subscr_uuid IS NOT INITIAL.
      SELECT SINGLE * FROM zdrs_subscr
        WHERE subscr_uuid = @ls_job-subscr_uuid
        INTO @DATA(ls_subscr).

      IF sy-subrc = 0.
        out->write( |  Subscription UUID: { ls_subscr-subscr_uuid }| ).
        out->write( |  Subscription ID: { ls_subscr-subscr_id }| ).
        out->write( |  Name: { ls_subscr-subscr_name }| ).
        out->write( |  Report ID: { ls_subscr-report_id }| ).
        out->write( |  Company Code: { ls_subscr-bukrs }| ).
        out->write( |  Output Format: { ls_subscr-output_format }| ).
        out->write( |  Status: { ls_subscr-status } (A=Active, P=Paused, I=Inactive)| ).
        out->write( |  Email To: { ls_subscr-email_to }| ).
        out->write( |  Email Cc: { ls_subscr-email_cc }| ).
        out->write( |  Created: { ls_subscr-created_at } by { ls_subscr-created_by }| ).
      ELSE.
        out->write( |  ERROR: Subscription not found!| ).
      ENDIF.
    ELSE.
      out->write( |  WARNING: subscr_uuid is empty in job config!| ).
    ENDIF.
    out->write( | | ).

    " 5. Check Parameters (GL01)
    IF ls_job-subscr_uuid IS NOT INITIAL.
      out->write( |[PARAMETERS - GL01]| ).
      SELECT SINGLE * FROM zdrs_param_gl01
        WHERE subscr_uuid = @ls_job-subscr_uuid
        INTO @DATA(ls_gl01).

      IF sy-subrc = 0.
        out->write( |  Company Code: { ls_gl01-company_code }| ).
        out->write( |  Fiscal Year: { ls_gl01-fiscal_year }| ).
        out->write( |  Fiscal Period: { ls_gl01-fiscal_period }| ).
        out->write( |  Currency: { ls_gl01-currency }| ).
        out->write( |  GL Account: { ls_gl01-gl_account }| ).
        out->write( |  Max Rows: { ls_gl01-max_rows }| ).
      ELSE.
        out->write( |  No GL01 parameters found for this subscription| ).
      ENDIF.
      out->write( | | ).
    ENDIF.

    " 6. Check Report Registry
    IF ls_subscr-report_id IS NOT INITIAL.
      out->write( |[REPORT REGISTRY]| ).
      SELECT SINGLE * FROM zdrs_rp_registry
        WHERE report_id = @ls_subscr-report_id
        INTO @DATA(ls_registry).

      IF sy-subrc = 0.
        out->write( |  Report ID: { ls_registry-report_id }| ).
        out->write( |  Report Class: { ls_registry-report_class }| ).
        out->write( |  Report Category: { ls_registry-report_category }| ).
        out->write( |  Param Structure: { ls_registry-param_structure_type }| ).
        out->write( |  Is Active: { ls_registry-is_active }| ).
        out->write( |  Description: { ls_registry-description }| ).
      ELSE.
        out->write( |  ERROR: Report ID '{ ls_subscr-report_id }' not found in registry!| ).
      ENDIF.
      out->write( | | ).
    ENDIF.

    " 7. Check Files Generated (using job_uuid)
    out->write( |[FILES GENERATED]| ).
    SELECT * FROM zdrs_file
      WHERE job_uuid = @ls_job-job_uuid
      INTO TABLE @DATA(lt_files).

    IF lt_files IS INITIAL.
      out->write( |  No files found for this job_uuid| ).

      " Check total files
      SELECT COUNT(*) FROM zdrs_file INTO @DATA(lv_file_count).
      out->write( |  Total files in ZDRS_FILE: { lv_file_count }| ).

      " Show last file record
      SELECT * FROM zdrs_file
        ORDER BY created_at DESCENDING
        INTO TABLE @DATA(lt_recent_files)
        UP TO 1 ROWS.
      IF lt_recent_files IS NOT INITIAL.
        READ TABLE lt_recent_files INDEX 1 INTO DATA(ls_recent_file).
        out->write( |  Last file record:| ).
        out->write( |    File UUID: { ls_recent_file-file_uuid }| ).
        out->write( |    Job UUID in FILE: { ls_recent_file-job_uuid }| ).
        out->write( |    Job UUID expected: { ls_job-job_uuid }| ).
        out->write( |    Match: { COND string( WHEN ls_recent_file-job_uuid = ls_job-job_uuid THEN 'YES' ELSE 'NO - MISMATCH!' ) }| ).
        out->write( |    FileName: { ls_recent_file-file_name }| ).
        out->write( |    CreatedAt: { ls_recent_file-created_at }| ).
      ENDIF.
    ELSE.
      out->write( |  Files: { lines( lt_files ) }| ).
      LOOP AT lt_files INTO DATA(ls_file).
        out->write( |  - { ls_file-file_name }| ).
        out->write( |    File UUID: { ls_file-file_uuid }| ).
        out->write( |    Size: { ls_file-file_size } bytes| ).
        out->write( |    MIME Type: { ls_file-mime_type }| ).
        out->write( |    Created: { ls_file-created_at }| ).
      ENDLOOP.
    ENDIF.
    out->write( | | ).

    " 8. Test CDS Query (if registry exists and class is ZCL_REPORT_GL01)
    IF ls_registry-report_class IS NOT INITIAL AND ls_gl01 IS NOT INITIAL.
      out->write( |[CDS QUERY TEST]| ).
      DATA(lv_cds) = 'ZI_DRS_GL01'.  " GL01 report uses this CDS

      TRY.
          cl_abap_typedescr=>describe_by_name(
            EXPORTING  p_name         = lv_cds
            RECEIVING  p_descr_ref    = DATA(lo_d)
            EXCEPTIONS type_not_found = 1 ).

          IF sy-subrc = 0.
            DATA(lo_tbl) = cl_abap_tabledescr=>create(
              p_line_type = CAST cl_abap_structdescr( lo_d ) ).
            DATA lr_test TYPE REF TO data.
            CREATE DATA lr_test TYPE HANDLE lo_tbl.
            FIELD-SYMBOLS <lt_test> TYPE STANDARD TABLE.
            ASSIGN lr_test->* TO <lt_test>.

            " Build WHERE clause based on GL01 params
            DATA(lv_where) = |CompanyCode = '{ ls_gl01-company_code }'|
                          && | AND FiscalYear = '{ ls_gl01-fiscal_year }'|.

            out->write( |  CDS View: { lv_cds }| ).
            out->write( |  WHERE: { lv_where }| ).

            SELECT * FROM (lv_cds) WHERE (lv_where)
              INTO TABLE @<lt_test> UP TO 5 ROWS.

            out->write( |  Test SELECT returned: { lines( <lt_test> ) } row(s) (max 5)| ).
            IF lines( <lt_test> ) = 0.
              out->write( |  WARNING: CDS view returns 0 rows - check parameters or authorization!| ).
            ENDIF.
          ELSE.
            out->write( |  ERROR: CDS view '{ lv_cds }' not found!| ).
          ENDIF.
        CATCH cx_root INTO DATA(lx_err).
          out->write( |  ERROR running test query: { lx_err->get_text( ) }| ).
      ENDTRY.
      out->write( | | ).
    ENDIF.

    " 9. Check for ABAP dumps
    out->write( |[RECENT ABAP DUMPS (ST22)]| ).
    SELECT COUNT(*) FROM snap
      WHERE uname = @sy-uname
        AND datum >= @( sy-datum - 1 )
      INTO @DATA(lv_dump_count).

    IF lv_dump_count > 0.
      out->write( |  WARNING: Found { lv_dump_count } dumps in last 24h for user { sy-uname }| ).
      out->write( |  Check transaction ST22 for details| ).
    ELSE.
      out->write( |  No recent dumps found for user { sy-uname }| ).
    ENDIF.

    out->write( | | ).
    out->write( |===== ANALYSIS COMPLETE =====| ).
  ENDMETHOD.

ENDCLASS.

