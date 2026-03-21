"! ═══════════════════════════════════════════════════════════════════════════════
"! CLASS: ZCL_DRS_SETUP_DATA
"! PURPOSE: Initialize default/seed data for DRS system
"! USAGE: ZCL_DRS_SETUP_DATA=>RUN( ).
"! ═══════════════════════════════════════════════════════════════════════════════
CLASS zcl_drs_setup_data DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.
    INTERFACES if_oo_adt_classrun.

    "! Run all setup (modules, formats, catalog)
    CLASS-METHODS run
      RETURNING VALUE(rt_messages) TYPE string_table.

    "! Setup module value table
    CLASS-METHODS setup_modules
      RETURNING VALUE(rv_message) TYPE string.

    "! Setup format value table
    CLASS-METHODS setup_formats
      RETURNING VALUE(rv_message) TYPE string.

    "! Setup report catalog with GL-01
    CLASS-METHODS setup_catalog
      RETURNING VALUE(rv_message) TYPE string.
    "! Delete all catalog entries (use before re-running setup)
    CLASS-METHODS cleanup_catalog
      RETURNING VALUE(rv_message) TYPE string.
  PRIVATE SECTION.
    CLASS-DATA: gv_timestamp TYPE timestampl.

    CLASS-METHODS get_timestamp
      RETURNING VALUE(rv_ts) TYPE timestampl.

ENDCLASS.


CLASS zcl_drs_setup_data IMPLEMENTATION.

  METHOD if_oo_adt_classrun~main.
    " Execute setup and output results to console
    LOOP AT run( ) INTO DATA(lv_msg).
      out->write( lv_msg ).
    ENDLOOP.
  ENDMETHOD.


  METHOD run.
    " Run all setup methods
    APPEND setup_modules( ) TO rt_messages.
    APPEND setup_formats( ) TO rt_messages.
    APPEND setup_catalog( ) TO rt_messages.

    COMMIT WORK AND WAIT.
    APPEND |Setup completed| TO rt_messages.
  ENDMETHOD.


  METHOD get_timestamp.
    IF gv_timestamp IS INITIAL.
      GET TIME STAMP FIELD gv_timestamp.
    ENDIF.
    rv_ts = gv_timestamp.
  ENDMETHOD.


  METHOD setup_modules.
    " Check if data exists
    SELECT COUNT(*) FROM zdrs_vt_module INTO @DATA(lv_count).
    IF lv_count > 0.
      rv_message = |ZDRS_VT_MODULE: { lv_count } records exist - skipped|.
      RETURN.
    ENDIF.

    DATA(lv_ts) = get_timestamp( ).
    DATA lt_data TYPE STANDARD TABLE OF zdrs_vt_module.

    lt_data = VALUE #(
      ( mandt = sy-mandt  module_id = 'FI'  module_name = 'Financial Accounting'
        description = 'G/L, AR, AP, Asset Accounting, Bank'
        icon_name = 'sap-icon://money-bills'  sort_order = 10  is_active = abap_true
        created_by = sy-uname  created_at = lv_ts  last_changed_by = sy-uname  last_changed_at = lv_ts )
      ( mandt = sy-mandt  module_id = 'CO'  module_name = 'Controlling'
        description = 'Cost Center, Profit Center, Internal Orders'
        icon_name = 'sap-icon://manager-insight'  sort_order = 20  is_active = abap_true
        created_by = sy-uname  created_at = lv_ts  last_changed_by = sy-uname  last_changed_at = lv_ts )
      ( mandt = sy-mandt  module_id = 'SD'  module_name = 'Sales & Distribution'
        description = 'Sales Orders, Deliveries, Billing'
        icon_name = 'sap-icon://sales-order'  sort_order = 30  is_active = abap_true
        created_by = sy-uname  created_at = lv_ts  last_changed_by = sy-uname  last_changed_at = lv_ts )
      ( mandt = sy-mandt  module_id = 'MM'  module_name = 'Materials Management'
        description = 'Purchasing, Inventory, Invoice Verification'
        icon_name = 'sap-icon://inventory'  sort_order = 40  is_active = abap_true
        created_by = sy-uname  created_at = lv_ts  last_changed_by = sy-uname  last_changed_at = lv_ts )
    ).

    INSERT zdrs_vt_module FROM TABLE @lt_data.
    rv_message = COND #( WHEN sy-subrc = 0
                         THEN |ZDRS_VT_MODULE: Inserted { lines( lt_data ) } records|
                         ELSE |ZDRS_VT_MODULE: Insert FAILED| ).
  ENDMETHOD.


  METHOD setup_formats.
    SELECT COUNT(*) FROM zdrs_vt_format INTO @DATA(lv_count).
    IF lv_count > 0.
      rv_message = |ZDRS_VT_FORMAT: { lv_count } records exist - skipped|.
      RETURN.
    ENDIF.

    DATA(lv_ts) = get_timestamp( ).
    DATA lt_data TYPE STANDARD TABLE OF zdrs_vt_format.

    lt_data = VALUE #(
      ( mandt = sy-mandt  format_id = 'XLSX'  format_name = 'Excel Workbook'
        mime_type = 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet'
        file_ext = 'xlsx'  icon_name = 'sap-icon://excel-attachment'
        sort_order = 10  is_active = abap_true
        created_by = sy-uname  created_at = lv_ts  last_changed_by = sy-uname  last_changed_at = lv_ts )
      ( mandt = sy-mandt  format_id = 'CSV'  format_name = 'CSV (Comma-Separated)'
        mime_type = 'text/csv'  file_ext = 'csv'
        icon_name = 'sap-icon://attachment-text-file'
        sort_order = 20  is_active = abap_true
        created_by = sy-uname  created_at = lv_ts  last_changed_by = sy-uname  last_changed_at = lv_ts )
      ( mandt = sy-mandt  format_id = 'PDF'  format_name = 'PDF Document'
        mime_type = 'application/pdf'  file_ext = 'pdf'
        icon_name = 'sap-icon://pdf-attachment'
        sort_order = 30  is_active = abap_true
        created_by = sy-uname  created_at = lv_ts  last_changed_by = sy-uname  last_changed_at = lv_ts )
    ).

    INSERT zdrs_vt_format FROM TABLE @lt_data.
    rv_message = COND #( WHEN sy-subrc = 0
                         THEN |ZDRS_VT_FORMAT: Inserted { lines( lt_data ) } records|
                         ELSE |ZDRS_VT_FORMAT: Insert FAILED| ).
  ENDMETHOD.


  METHOD setup_catalog.
    " Auto-cleanup: Delete existing data before re-inserting
    DELETE FROM zdrs_catalog.
    DATA(lv_deleted) = sy-dbcnt.

    DATA(lv_ts) = get_timestamp( ).
    DATA lt_data TYPE STANDARD TABLE OF zdrs_catalog.

    lt_data = VALUE #(
      ( mandt = sy-mandt
        report_id     = 'GL-01'
        module_id     = 'FI'
        report_name   = 'G/L Account Balances'
        description   = 'General Ledger balances by Company Code, Fiscal Year, Period'
        long_text     = |G/L Account Balance Report| &&
                        |\n\nDisplays G/L balances aggregated by Company, Year, Period, Account.|
        cds_view_name = 'ZI_DRS_GL01'
        report_class  = 'ZCL_DRS_REPORT_GL01'
        is_active     = abap_true
        sort_order    = 10
        created_by    = sy-uname
        created_at    = lv_ts
        last_changed_by = sy-uname
        last_changed_at = lv_ts
        local_last_changed_at = lv_ts )
    ).

    INSERT zdrs_catalog FROM TABLE @lt_data.
    rv_message = COND #( WHEN sy-subrc = 0
                         THEN |ZDRS_CATALOG: Deleted { lv_deleted }, Inserted { lines( lt_data ) } records|
                         ELSE |ZDRS_CATALOG: Insert FAILED| ).
  ENDMETHOD.


  METHOD cleanup_catalog.
    DELETE FROM zdrs_catalog.
    COMMIT WORK AND WAIT.
    rv_message = |ZDRS_CATALOG: Deleted all records (sy-dbcnt = { sy-dbcnt })|.
  ENDMETHOD.

ENDCLASS.

