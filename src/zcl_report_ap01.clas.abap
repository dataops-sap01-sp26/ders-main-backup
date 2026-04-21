CLASS ZCL_REPORT_AP01 DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.
    INTERFACES ZIF_REPORT.

    METHODS CONSTRUCTOR
      IMPORTING IS_PARAMS TYPE ZIF_REPORT=>TY_PARAMS.

  PRIVATE SECTION.
    DATA MS_PARAMS TYPE ZIF_REPORT=>TY_PARAMS.

    METHODS QUERY_DATA
      EXPORTING ER_DATA     TYPE REF TO DATA
                ET_COL_META TYPE ZIF_FILE_FORMATTER=>TT_COL_META
      RAISING   CX_APJ_RT.

    METHODS BUILD_COL_META
      IMPORTING IO_STRUCT        TYPE REF TO CL_ABAP_STRUCTDESCR
      RETURNING VALUE(RT_RESULT) TYPE ZIF_FILE_FORMATTER=>TT_COL_META
      RAISING   CX_APJ_RT.

    " Resolve formatter via ZCL_FORMATTER_FACTORY.
    " Raises CX_SY_CREATE_OBJECT_ERROR when no formatter is available
    " (not registered, or class not yet activated).
    METHODS CREATE_FORMATTER
      RETURNING VALUE(RO_FORMATTER) TYPE REF TO ZIF_FILE_FORMATTER
      RAISING   CX_APJ_RT.
ENDCLASS.


CLASS ZCL_REPORT_AP01 IMPLEMENTATION.

  METHOD CONSTRUCTOR.
    MS_PARAMS = IS_PARAMS.
  ENDMETHOD.


  METHOD ZIF_REPORT~EXECUTE.
    DATA LR_DATA     TYPE REF TO DATA.
    DATA LT_COL_META TYPE ZIF_FILE_FORMATTER=>TT_COL_META.

    " 1. Fetch data
    QUERY_DATA( IMPORTING ER_DATA = LR_DATA ET_COL_META = LT_COL_META ).

    " 2. Resolve formatter — propagate error up if unresolvable
    DATA LO_FORMATTER TYPE REF TO ZIF_FILE_FORMATTER.
    TRY.
        LO_FORMATTER = CREATE_FORMATTER( ).
      CATCH CX_SY_CREATE_OBJECT_ERROR INTO DATA(LX).
        " Configuration error: no formatter registered for this report.
        " Re-raise so the job layer (ZCL_JOB_BUSINESS_LOGIC) can log and skip.
        " Message: File formatter class is missing or inactive for report &1
        RAISE EXCEPTION TYPE CX_APJ_RT
          MESSAGE ID 'ZMSG_DRS_SP26_SAP01'
          TYPE 'E'
          NUMBER '038'
          WITH MS_PARAMS-REPORT_ID.
    ENDTRY.

    " 3. Generate file
    DATA(LS_FMT) = LO_FORMATTER->GENERATE(
      IR_DATA     = LR_DATA
      IT_COL_META = LT_COL_META
    ).

    " 4. Return result
    RS_RESULT-XSTRING          = LS_FMT-XSTRING.
    RS_RESULT-EXTENSION        = LS_FMT-EXTENSION.
    RS_RESULT-MIME_TYPE        = LS_FMT-MIME_TYPE.
    RS_RESULT-FILE_NAME_PREFIX = |Vendor_Open_Items_{ MS_PARAMS-REPORT_ID }|.
  ENDMETHOD.


  METHOD QUERY_DATA.
    SELECT SINGLE FROM ZDRS_PARAM_AP01
      FIELDS COMPANY_CODE,
             KEY_DATE,
             MAX_ROWS,
             VENDOR_FROM,
             VENDOR_TO
      WHERE SUBSCR_UUID = @MS_PARAMS-SUBSCR_UUID
      INTO @DATA(LS_SPEC_PARAM).

    IF SY-SUBRC <> 0.
      " Message: Report parameters not found for report ID &1
      RAISE EXCEPTION TYPE CX_APJ_RT
        MESSAGE ID 'ZMSG_DRS_SP26_SAP01'
        TYPE 'E'
        NUMBER '039'
        WITH MS_PARAMS-REPORT_ID.
    ENDIF.

    DATA(LV_MAX) = COND I( WHEN LS_SPEC_PARAM-MAX_ROWS > 0 THEN LS_SPEC_PARAM-MAX_ROWS ELSE 5000 ).

    " 1. Declare range table for Supplier (Vendor)
    DATA LT_SUPPLIER_RANGE TYPE RANGE OF MD_SUPPLIER.

    " 2. Fill the range table using from/to fields
    IF LS_SPEC_PARAM-VENDOR_FROM IS NOT INITIAL.
      APPEND VALUE #(
        SIGN   = 'I'
        OPTION = COND #( WHEN LS_SPEC_PARAM-VENDOR_TO IS INITIAL THEN 'EQ' ELSE 'BT' )
        LOW    = LS_SPEC_PARAM-VENDOR_FROM
        HIGH   = LS_SPEC_PARAM-VENDOR_TO
      ) TO LT_SUPPLIER_RANGE.
    ENDIF.

    " 3. Update the SELECT
    SELECT FROM ZI_RPT_AP01
      FIELDS COMPANYCODE,
             SUPPLIER,
             SUPPLIERNAME,
             NETDUEDATE,
             TOTALOPENAMOUNT,
             LOCALCURRENCY,
             MAXDAYSOVERDUE
      WHERE COMPANYCODE = @LS_SPEC_PARAM-COMPANY_CODE
        AND SUPPLIER    IN @LT_SUPPLIER_RANGE
        AND NETDUEDATE <= @LS_SPEC_PARAM-KEY_DATE
      ORDER BY COMPANYCODE, SUPPLIER
      INTO TABLE @DATA(LT_AP01)
      UP TO @LV_MAX ROWS.

    IF SY-SUBRC <> 0.
       " Message: Not found data for Report ID &1
      MESSAGE ID 'ZMSG_DRS_SP26_SAP01'
      TYPE 'E'
      NUMBER '040'
      WITH MS_PARAMS-REPORT_ID.
    ENDIF.

    CREATE DATA ER_DATA LIKE LT_AP01.
    FIELD-SYMBOLS <LT_OUT> TYPE STANDARD TABLE.
    ASSIGN ER_DATA->* TO <LT_OUT>.
    <LT_OUT> = LT_AP01.

*    DATA(LO_STRUCT) = CAST CL_ABAP_STRUCTDESCR(
*      CL_ABAP_TYPEDESCR=>DESCRIBE_BY_DATA( VALUE #( LT_ap01[ 1 ] OPTIONAL ) ) ).
*    ET_COL_META = BUILD_COL_META( LO_STRUCT ).
  ENDMETHOD.


  METHOD BUILD_COL_META.
*    DATA(LT_COMP) = IO_STRUCT->GET_COMPONENTS( ).

  ENDMETHOD.


  METHOD CREATE_FORMATTER.
    " ----------------------------------------------------------------
    " Delegate entirely to ZCL_FORMATTER_FACTORY.
    " The factory handles:
    "   - CSV       → ZCL_CSV_FORMATTER (always, no DB lookup)
    "   - XLSX etc. → report-specific class, or generic fallback class
    " ----------------------------------------------------------------
    RO_FORMATTER = ZCL_FORMATTER_FACTORY=>CREATE(
      IV_REPORT_ID     = MS_PARAMS-REPORT_ID
      IV_OUTPUT_FORMAT = MS_PARAMS-OUTPUT_FORMAT
      IS_PARAMS        = MS_PARAMS
    ).

    " Guard: factory returns unbound ref when:
    "   (a) the report+format combo is not in ZDRS_FM_REGISTRY, or
    "   (b) the registered class name has not been activated yet.
    " Both are configuration errors — raise so the caller can react.
    IF RO_FORMATTER IS NOT BOUND.
      " Message: File formatter class is missing or inactive for Report ID &1
      RAISE EXCEPTION TYPE CX_APJ_RT
        MESSAGE ID 'ZMSG_DRS_SP26_SAP01'
        TYPE 'E'
        NUMBER '038'
        WITH MS_PARAMS-REPORT_ID.
    ENDIF.
  ENDMETHOD.

ENDCLASS.

