CLASS ZCL_REPORT_GL01 DEFINITION
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
                ET_COL_META TYPE ZIF_FILE_FORMATTER=>TT_COL_META.

    METHODS BUILD_COL_META
      IMPORTING IO_STRUCT        TYPE REF TO CL_ABAP_STRUCTDESCR
      RETURNING VALUE(RT_RESULT) TYPE ZIF_FILE_FORMATTER=>TT_COL_META.

    " Resolve formatter via ZCL_FORMATTER_FACTORY.
    " Raises CX_SY_CREATE_OBJECT_ERROR when no formatter is available
    " (not registered, or class not yet activated).
    METHODS CREATE_FORMATTER
      RETURNING VALUE(RO_FORMATTER) TYPE REF TO ZIF_FILE_FORMATTER
      RAISING   CX_SY_CREATE_OBJECT_ERROR.
ENDCLASS.


CLASS ZCL_REPORT_GL01 IMPLEMENTATION.

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
        RAISE EXCEPTION LX.
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
    RS_RESULT-FILE_NAME_PREFIX = |G/L_Balances_{ MS_PARAMS-REPORT_ID }|.
  ENDMETHOD.


  METHOD QUERY_DATA.
    SELECT SINGLE * FROM ZDRS_PARAM_GL01
      WHERE SUBSCR_UUID = @MS_PARAMS-SUBSCR_UUID
      INTO @DATA(LS_SPEC_PARAM).

    DATA(LV_MAX) = COND I( WHEN LS_SPEC_PARAM-MAX_ROWS > 0 THEN LS_SPEC_PARAM-MAX_ROWS ELSE 5000 ).

    SELECT FROM ZIR_DRS_GL01
      FIELDS CompanyCode,
             FiscalYear,
             Period,
             GLAccount,
             GLAccountName,
             LocalCurrency,
             DebitAmount,
             CreditAmount,
             BalanceAmount
      WHERE ( @LS_SPEC_PARAM-COMPANY_CODE = '' OR CompanyCode = @LS_SPEC_PARAM-COMPANY_CODE )
        AND ( @LS_SPEC_PARAM-FISCAL_YEAR  = '' OR FiscalYear  = @LS_SPEC_PARAM-FISCAL_YEAR )
        AND ( @LS_SPEC_PARAM-FISCAL_PERIOD = '' OR Period      = @LS_SPEC_PARAM-FISCAL_PERIOD )
        AND ( @LS_SPEC_PARAM-GL_ACCOUNT    = '' OR GLAccount   = @LS_SPEC_PARAM-GL_ACCOUNT )
      ORDER BY CompanyCode, GLAccount
      INTO TABLE @DATA(LT_GL01)
      UP TO @LV_MAX ROWS.

    CREATE DATA ER_DATA LIKE LT_GL01.
    FIELD-SYMBOLS <LT_OUT> TYPE STANDARD TABLE.
    ASSIGN ER_DATA->* TO <LT_OUT>.
    <LT_OUT> = LT_GL01.

    DATA(LO_STRUCT) = CAST CL_ABAP_STRUCTDESCR(
      CL_ABAP_TYPEDESCR=>DESCRIBE_BY_DATA( VALUE #( LT_GL01[ 1 ] OPTIONAL ) ) ).
    ET_COL_META = BUILD_COL_META( LO_STRUCT ).
  ENDMETHOD.


  METHOD BUILD_COL_META.
    DATA(LT_COMP) = IO_STRUCT->GET_COMPONENTS( ).
    LOOP AT LT_COMP INTO DATA(LS_C).
      DATA(LS_M) = VALUE ZIF_FILE_FORMATTER=>TY_COL_META( NAME = LS_C-NAME ).
      IF LS_C-NAME CP '*AMOUNT'.
        LS_M-IS_NUM  = ABAP_TRUE.
        LS_M-IS_BOLD = ABAP_TRUE.
        LS_M-ALIGN   = 'right'.
      ENDIF.
      APPEND LS_M TO RT_RESULT.
    ENDLOOP.
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
*      RAISE EXCEPTION TYPE CX_SY_CREATE_OBJECT_ERROR
*        MESSAGE e001(00) WITH MS_PARAMS-REPORT_ID MS_PARAMS-OUTPUT_FORMAT.
    ENDIF.
  ENDMETHOD.

ENDCLASS.

