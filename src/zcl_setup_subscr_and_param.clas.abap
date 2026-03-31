CLASS ZCL_SETUP_SUBSCR_AND_PARAM DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.
    INTERFACES IF_OO_ADT_CLASSRUN.

    CLASS-METHODS INSERT_SUBSCRIPTIONS
      IMPORTING IO_OUT TYPE REF TO IF_OO_ADT_CLASSRUN_OUT OPTIONAL.

    CLASS-METHODS DELETE_ALL
      IMPORTING IO_OUT TYPE REF TO IF_OO_ADT_CLASSRUN_OUT OPTIONAL.

  PRIVATE SECTION.
ENDCLASS.


CLASS ZCL_SETUP_SUBSCR_AND_PARAM IMPLEMENTATION.

  METHOD IF_OO_ADT_CLASSRUN~MAIN.
    DELETE_ALL( IO_OUT = OUT ).
    INSERT_SUBSCRIPTIONS( IO_OUT = OUT ).
  ENDMETHOD.


  METHOD INSERT_SUBSCRIPTIONS.
    DATA LV_TS   TYPE TIMESTAMPL.
    DATA LV_USER TYPE UNAME.
    GET TIME STAMP FIELD LV_TS.
    LV_USER = CL_ABAP_CONTEXT_INFO=>GET_USER_TECHNICAL_NAME( ).

    " -----------------------------------------------------------------
    " 1.  Generate Subscription UUIDs
    " -----------------------------------------------------------------
    " GL01
    DATA LV_UUID1 TYPE SYSUUID_X16.
    DATA LV_UUID2 TYPE SYSUUID_X16.

    " AR01
    DATA LV_UUID3 TYPE SYSUUID_X16.
    DATA LV_UUID4 TYPE SYSUUID_X16.

    " AR02
    DATA LV_UUID5 TYPE SYSUUID_X16.
    DATA LV_UUID6 TYPE SYSUUID_X16.

    TRY.
        LV_UUID1 = CL_SYSTEM_UUID=>CREATE_UUID_X16_STATIC( ).
        LV_UUID2 = CL_SYSTEM_UUID=>CREATE_UUID_X16_STATIC( ).
        LV_UUID3 = CL_SYSTEM_UUID=>CREATE_UUID_X16_STATIC( ).
        LV_UUID4 = CL_SYSTEM_UUID=>CREATE_UUID_X16_STATIC( ).
        LV_UUID5 = CL_SYSTEM_UUID=>CREATE_UUID_X16_STATIC( ).
        LV_UUID6 = CL_SYSTEM_UUID=>CREATE_UUID_X16_STATIC( ).
      CATCH CX_UUID_ERROR INTO DATA(LX_UUID).
        IF IO_OUT IS BOUND.
          IO_OUT->WRITE( |UUID generation failed: { LX_UUID->GET_TEXT( ) }| ).
        ENDIF.
        RETURN.
    ENDTRY.
    " -----------------------------------------------------------------
    " 2.  Subscription Headers  (ZDRS_SUBSCR)
    " -----------------------------------------------------------------
    DATA LT_SUB_HDR TYPE TABLE OF ZDRS_SUBSCR.

    APPEND VALUE #(
      SUBSCR_UUID           = LV_UUID1
      SUBSCR_ID             = '000001'
      SUBSCR_NAME           = 'G/L Balances - VNM - Period 05'
      REPORT_ID             = 'GL-01'
      BUKRS                 = 'VNM'
      OUTPUT_FORMAT         = 'XLSX'
      EMAIL_TO              = 'finance-bot@test.com'
      EMAIL_CC              = 'gl_accountant@test.com'
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
      EMAIL_TO              = 'finance-bot@test.com'
      EMAIL_CC              = 'gl_accountant@test.com'
      CREATED_BY            = LV_USER
      CREATED_AT            = LV_TS
      LAST_CHANGED_BY       = LV_USER
      LAST_CHANGED_AT       = LV_TS
      LOCAL_LAST_CHANGED_AT = LV_TS
    ) TO LT_SUB_HDR.

    APPEND VALUE #(
     SUBSCR_UUID           = LV_UUID3
     SUBSCR_ID             = '000003'
     SUBSCR_NAME           = 'Vendor Open Items - US00'
     REPORT_ID             = 'AR-01'
     BUKRS                 = 'US00'
     OUTPUT_FORMAT         = 'XLSX'
     EMAIL_TO              = 'finance-bot@test.com'
     EMAIL_CC              = 'gl_accountant@test.com'
     CREATED_BY            = LV_USER
     CREATED_AT            = LV_TS
     LAST_CHANGED_BY       = LV_USER
     LAST_CHANGED_AT       = LV_TS
     LOCAL_LAST_CHANGED_AT = LV_TS
   ) TO LT_SUB_HDR.

    APPEND VALUE #(
      SUBSCR_UUID           = LV_UUID4
      SUBSCR_ID             = '000004'
      SUBSCR_NAME           = 'Vendor Open Items - VNM'
      REPORT_ID             = 'AR-01'
      BUKRS                 = 'VNM'
      OUTPUT_FORMAT         = 'CSV'
      EMAIL_TO              = 'finance-bot@test.com'
      EMAIL_CC              = 'gl_accountant@test.com'
      CREATED_BY            = LV_USER
      CREATED_AT            = LV_TS
      LAST_CHANGED_BY       = LV_USER
      LAST_CHANGED_AT       = LV_TS
      LOCAL_LAST_CHANGED_AT = LV_TS
    ) TO LT_SUB_HDR.



    INSERT ZDRS_SUBSCR FROM TABLE @LT_SUB_HDR.

    " -----------------------------------------------------------------
    " 3.  Report-specific Parameters  (ZDRS_PARAM_GL01)
    " -----------------------------------------------------------------
    " GL01 - GL ACCOUNT BALANCES REPORT
    DATA LT_PARAM_GL01 TYPE TABLE OF ZDRS_PARAM_GL01.

    APPEND VALUE #(
      SUBSCR_UUID   = LV_UUID1
      SUBSCR_ID     = '000001'
      COMPANY_CODE  = 'VNM'
      FISCAL_YEAR   = '2025'
      FISCAL_PERIOD = '005'
      CURRENCY      = 'VND'
      GL_ACCOUNT    = '0000200000'
      MAX_ROWS      = 100
    ) TO LT_PARAM_GL01.

    APPEND VALUE #(
      SUBSCR_UUID   = LV_UUID2
      SUBSCR_ID     = '000002'
      COMPANY_CODE  = 'FI12'
      FISCAL_YEAR   = '2025'
      FISCAL_PERIOD = '012'
      CURRENCY      = 'VND'
      GL_ACCOUNT    = '0000200000'
      MAX_ROWS      = 100
    ) TO LT_PARAM_GL01.

    INSERT ZDRS_PARAM_GL01 FROM TABLE @LT_PARAM_GL01.

    " AR01 - VENDOR OPEN ITEMS REPORT
    DATA LT_PARAM_AR01 TYPE TABLE OF ZDRS_PARAM_AR01.

    APPEND VALUE #(
      SUBSCR_UUID   = LV_UUID3
      SUBSCR_ID     = '000003'
      COMPANY_CODE  = 'US00'
      CUSTOMER = '129997'
      KEY_DATE      = SY-DATUM
      MAX_ROWS      = 100
    ) TO LT_PARAM_AR01.

    APPEND VALUE #(
      SUBSCR_UUID   = LV_UUID4
      SUBSCR_ID     = '000004'
      COMPANY_CODE  = 'US00'
      CUSTOMER = '129999'
      KEY_DATE      = SY-DATUM
      MAX_ROWS      = 100
    ) TO LT_PARAM_AR01.

    INSERT ZDRS_PARAM_AR01 FROM TABLE @LT_PARAM_AR01.

    " -----------------------------------------------------------------
    " 4.  Commit / Rollback
    " -----------------------------------------------------------------
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
    DELETE FROM ZDRS_PARAM_AR01.
    COMMIT WORK.
    IF IO_OUT IS BOUND.
      IO_OUT->WRITE( |Cleanup complete.| ).
    ENDIF.
  ENDMETHOD.

ENDCLASS.

