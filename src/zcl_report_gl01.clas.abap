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

    " Query GL line items using subscription params as SELECT conditions
    METHODS QUERY_DATA
      EXPORTING ER_DATA     TYPE REF TO DATA
                ET_COL_META TYPE ZIF_FILE_FORMATTER=>TT_COL_META.

    " Build column metadata from a sample structure
    METHODS BUILD_COL_META
      IMPORTING IO_STRUCT        TYPE REF TO CL_ABAP_STRUCTDESCR
      RETURNING VALUE(RT_RESULT) TYPE ZIF_FILE_FORMATTER=>TT_COL_META.

    " Factory: create the appropriate formatter for the file type
    METHODS CREATE_FORMATTER
      RETURNING VALUE(RO_FORMATTER) TYPE REF TO ZIF_FILE_FORMATTER.
ENDCLASS.

CLASS ZCL_REPORT_GL01 IMPLEMENTATION.

  METHOD CONSTRUCTOR.
    MS_PARAMS = IS_PARAMS.
  ENDMETHOD.

  METHOD ZIF_REPORT~EXECUTE.
    DATA LR_DATA     TYPE REF TO DATA.
    DATA LT_COL_META TYPE ZIF_FILE_FORMATTER=>TT_COL_META.

    " 1. Lấy dữ liệu tổng hợp từ CDS View
    QUERY_DATA( IMPORTING ER_DATA = LR_DATA ET_COL_META = LT_COL_META ).

    " 2. Khởi tạo formatter (XLSX hoặc CSV)
    DATA(LO_FORMATTER) = CREATE_FORMATTER( ).
    DATA(LS_FMT) = LO_FORMATTER->GENERATE(
      IR_DATA     = LR_DATA
      IT_COL_META = LT_COL_META
    ).

    " 3. Trả kết quả file
    RS_RESULT-XSTRING          = LS_FMT-XSTRING.
    RS_RESULT-EXTENSION        = LS_FMT-EXTENSION.
    RS_RESULT-MIME_TYPE        = LS_FMT-MIME_TYPE.
    RS_RESULT-FILE_NAME_PREFIX = |G/L_Balances_{ MS_PARAMS-REPORT_ID }|.
  ENDMETHOD.

  METHOD QUERY_DATA.
    " Lấy tham số chi tiết từ table zder_param_gl01 dựa trên UUID của subscription
    SELECT SINGLE * FROM ZDRS_PARAM_GL01
      WHERE SUBSCR_UUID = @MS_PARAMS-SUBSCR_UUID
      INTO @DATA(LS_SPEC_PARAM).

    DATA(LV_MAX) = COND I( WHEN LS_SPEC_PARAM-MAX_ROWS > 0 THEN LS_SPEC_PARAM-MAX_ROWS ELSE 5000 ).

    " Query từ CDS View - Lưu ý: CDS đã SUM sẵn Debit/Credit/Balance
    SELECT FROM ZI_DRS_GL01
      FIELDS CompanyCode,
             FiscalYear,
             FiscalPeriod,
             GLAccount,
             GLAccountName,
             LocalCurrency,
             DebitAmount,
             CreditAmount,
             BalanceAmount
      WHERE ( @LS_SPEC_PARAM-COMPANY_CODE = '' OR CompanyCode = @LS_SPEC_PARAM-COMPANY_CODE )
        AND ( @LS_SPEC_PARAM-FISCAL_YEAR  = '' OR FiscalYear  = @LS_SPEC_PARAM-FISCAL_YEAR )
        AND ( @LS_SPEC_PARAM-FISCAL_PERIOD = '' OR FiscalPeriod = @LS_SPEC_PARAM-FISCAL_PERIOD )
        AND ( @LS_SPEC_PARAM-GL_ACCOUNT    = '' OR GLAccount   = @LS_SPEC_PARAM-GL_ACCOUNT )
      ORDER BY CompanyCode, GLAccount
      INTO TABLE @DATA(LT_BALANCES)
      UP TO @LV_MAX ROWS.

    " Đưa dữ liệu vào Heap (Dynamic Data)
    CREATE DATA ER_DATA LIKE LT_BALANCES.
    FIELD-SYMBOLS <LT_OUT> TYPE STANDARD TABLE.
    ASSIGN ER_DATA->* TO <LT_OUT>.
    <LT_OUT> = LT_BALANCES.

    " Tạo Metadata cho cột
    DATA(LO_STRUCT) = CAST CL_ABAP_STRUCTDESCR(
      CL_ABAP_TYPEDESCR=>DESCRIBE_BY_DATA( VALUE #( LT_BALANCES[ 1 ] OPTIONAL ) ) ).
    ET_COL_META = BUILD_COL_META( LO_STRUCT ).
  ENDMETHOD.

  METHOD BUILD_COL_META.
    DATA(LT_COMP) = IO_STRUCT->GET_COMPONENTS( ).
    " Format file
    LOOP AT LT_COMP INTO DATA(LS_C).
      DATA(LS_M) = VALUE ZIF_FILE_FORMATTER=>TY_COL_META( NAME = LS_C-NAME ).

      " Logic định dạng: Bold cho các cột số tiền
      IF LS_C-NAME CP '*AMOUNT'.
        LS_M-IS_NUM = ABAP_TRUE.
        LS_M-IS_BOLD = ABAP_TRUE.
        LS_M-ALIGN = 'right'.
      ENDIF.

      APPEND LS_M TO RT_RESULT.
    ENDLOOP.
  ENDMETHOD.

  METHOD CREATE_FORMATTER.
    " Logic chọn định dạng file dựa trên cấu hình subscription
    RO_FORMATTER = COND #( WHEN MS_PARAMS-OUTPUT_FORMAT = 'XLSX'
                           THEN NEW ZCL_XLSX_FORMATTER(  )
                           ELSE NEW ZCL_CSV_FORMATTER( ) ).
  ENDMETHOD.

ENDCLASS.
