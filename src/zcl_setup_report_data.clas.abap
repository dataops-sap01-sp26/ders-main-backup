CLASS ZCL_SETUP_REPORT_DATA DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC .

  PUBLIC SECTION.
    INTERFACES IF_OO_ADT_CLASSRUN.

    CLASS-METHODS INSERT_SUBSCRIPTIONS
      IMPORTING
        IO_OUT TYPE REF TO IF_OO_ADT_CLASSRUN_OUT OPTIONAL.

    CLASS-METHODS DELETE_ALL
      IMPORTING
        IO_OUT TYPE REF TO IF_OO_ADT_CLASSRUN_OUT OPTIONAL.
  PROTECTED SECTION.
  PRIVATE SECTION.
ENDCLASS.



CLASS ZCL_SETUP_REPORT_DATA IMPLEMENTATION.
  METHOD IF_OO_ADT_CLASSRUN~MAIN.
    " Delete existing data first, then re-insert fresh test data
    DELETE_ALL( IO_OUT = OUT ).
    INSERT_SUBSCRIPTIONS( IO_OUT = OUT ).
  ENDMETHOD.


  METHOD INSERT_SUBSCRIPTIONS.
    DATA LV_TS   TYPE TIMESTAMPL.
    DATA LV_USER TYPE UNAME.
    GET TIME STAMP FIELD LV_TS.
    LV_USER = CL_ABAP_CONTEXT_INFO=>GET_USER_TECHNICAL_NAME( ).

    " ---------------------------------------------------------
    " 1. Setup Configuration Registries
    " ---------------------------------------------------------
    DATA LT_REP_REG TYPE TABLE OF ZDRS_RP_REGISTRY.
    DATA LT_FMT_REG TYPE TABLE OF ZDRS_FM_REGISTRY.

    LT_REP_REG = VALUE #(
      ( REPORT_ID = 'GL-01' REPORT_CLASS = 'ZCL_REPORT_GL01'        IS_ACTIVE = ABAP_TRUE CREATED_BY = LV_USER CREATED_AT = LV_TS )
    ).

    LT_FMT_REG = VALUE #(
      ( OUTPUT_FORMAT = 'CSV'  FORMATTER_CLASS = 'ZCL_CSV_FORMATTER'  IS_ACTIVE = ABAP_TRUE CREATED_BY = LV_USER CREATED_AT = LV_TS )
      ( OUTPUT_FORMAT = 'XLSX' FORMATTER_CLASS = 'ZCL_XLSX_FORMATTER' IS_ACTIVE = ABAP_TRUE CREATED_BY = LV_USER CREATED_AT = LV_TS )
    ).

    INSERT ZDRS_RP_REGISTRY FROM TABLE @LT_REP_REG.
    INSERT ZDRS_FM_REGISTRY FROM TABLE @LT_FMT_REG.

    " ---------------------------------------------------------
    " 2. Generate UUIDs
    " ---------------------------------------------------------
    DATA(LV_UUID1) = CL_SYSTEM_UUID=>CREATE_UUID_X16_STATIC( ).
    DATA(LV_UUID2) = CL_SYSTEM_UUID=>CREATE_UUID_X16_STATIC( ).

    " ---------------------------------------------------------
    " 3. Seed Subscription Data
    " ---------------------------------------------------------
    DATA LT_SUB_HDR  TYPE TABLE OF ZDRS_SUBSCR.
    DATA LT_PARAM_GL01 TYPE TABLE OF ZDRS_PARAM_GL01.

    APPEND VALUE #(
      SUBSCR_UUID           = LV_UUID1
      SUBSCR_ID             = '000001'
      SUBSCR_NAME           = 'G/L Balances - VNM - Period 05'
      REPORT_ID             = 'GL-01'
      BUKRS                 = 'VNM'
      OUTPUT_FORMAT         = 'XLSX'
      EMAIL_TO              = 'finance-bot@test.com'
      EMAIL_CC              = 'gl_accountant@test.com'
      STATUS                = 'A'
      CREATED_BY            = LV_USER
      CREATED_AT            = LV_TS
      LAST_CHANGED_BY       = LV_USER
      LAST_CHANGED_AT       = LV_TS
      LOCAL_LAST_CHANGED_AT = LV_TS
    ) TO LT_SUB_HDR.

    APPEND VALUE #(
      SUBSCR_UUID           = LV_UUID2
      SUBSCR_ID             = '000002'
      SUBSCR_NAME           = 'G/L Balances - FI12 - Period 12'
      REPORT_ID             = 'GL-01'
      BUKRS                 = 'FI12'
      OUTPUT_FORMAT         = 'CSV'
      STATUS                = 'A'
      EMAIL_TO              = 'finance-bot@test.com'
      EMAIL_CC              = 'gl_accountant@test.com'
      CREATED_BY            = LV_USER
      CREATED_AT            = LV_TS
      LAST_CHANGED_BY       = LV_USER
      LAST_CHANGED_AT       = LV_TS
      LOCAL_LAST_CHANGED_AT = LV_TS
    ) TO LT_SUB_HDR.

    APPEND VALUE #(
      SUBSCR_UUID      = LV_UUID1
      SUBSCR_ID             = '000001'
      COMPANY_CODE  = 'VNM'
      FISCAL_YEAR   = '2025'
      FISCAL_PERIOD = '005'
      CURRENCY      = 'VND'
      GL_ACCOUNT    = '0000200000'
      MAX_ROWS      = 100
    ) TO LT_PARAM_GL01.

    APPEND VALUE #(
      SUBSCR_UUID      = LV_UUID2
      SUBSCR_ID             = '000002'
      COMPANY_CODE  = 'FI12'
      FISCAL_YEAR   = '2025'
      FISCAL_PERIOD = '012'
      CURRENCY      = 'VND'
      GL_ACCOUNT    = '0000200000'
      MAX_ROWS      = 100
    ) TO LT_PARAM_GL01.

    " ---------------------------------------------------------
    " 4. Process Database
    " ---------------------------------------------------------
    INSERT ZDRS_SUBSCR FROM TABLE @LT_SUB_HDR.
    INSERT ZDRS_PARAM_GL01 FROM TABLE @LT_PARAM_GL01.

    IF SY-SUBRC = 0.
      COMMIT WORK.
      IF IO_OUT IS BOUND.
        IO_OUT->WRITE( |Successfully inserted { LINES( LT_SUB_HDR ) } subscriptions.| ).
      ENDIF.
    ELSE.
      ROLLBACK WORK.
      IF IO_OUT IS BOUND.
        IO_OUT->WRITE( |INSERT failed. sy-subrc = { SY-SUBRC }| ).
      ENDIF.
    ENDIF.
  ENDMETHOD.

  METHOD DELETE_ALL.
    DELETE FROM ZDRS_SUBSCR.
    DELETE FROM ZDRS_PARAM_GL01.
    DELETE FROM ZDRS_RP_REGISTRY.
    DELETE FROM ZDRS_FM_REGISTRY.

    COMMIT WORK.
    IF IO_OUT IS BOUND.
      IO_OUT->WRITE( |Cleanup complete.| ).
    ENDIF.
  ENDMETHOD.
ENDCLASS.
