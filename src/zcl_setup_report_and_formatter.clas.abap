CLASS ZCL_SETUP_REPORT_AND_FORMATTER DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC .

  PUBLIC SECTION.
    INTERFACES IF_OO_ADT_CLASSRUN.

    CLASS-METHODS INSERT_SUBSCRIPTIONS
      IMPORTING IO_OUT TYPE REF TO IF_OO_ADT_CLASSRUN_OUT OPTIONAL.

    CLASS-METHODS DELETE_ALL
      IMPORTING IO_OUT TYPE REF TO IF_OO_ADT_CLASSRUN_OUT OPTIONAL.
  PROTECTED SECTION.
  PRIVATE SECTION.
ENDCLASS.



CLASS ZCL_SETUP_REPORT_AND_FORMATTER IMPLEMENTATION.
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
    " 1.  Report Registry  (ZDRS_RP_REGISTRY)
    "     Maps REPORT_ID → implementation class
    " -----------------------------------------------------------------
    DATA LT_REP_REG TYPE TABLE OF ZDRS_RP_REGISTRY.

    LT_REP_REG = VALUE #(
      ( REPORT_ID    = 'GL-01'
        REPORT_CLASS = 'ZCL_REPORT_GL01'
        IS_ACTIVE    = ABAP_TRUE
        CREATED_BY   = LV_USER
        CREATED_AT   = LV_TS )

        ( REPORT_ID    = 'AR-01'
        REPORT_CLASS = 'ZCL_REPORT_AR01'
        IS_ACTIVE    = ABAP_TRUE
        CREATED_BY   = LV_USER
        CREATED_AT   = LV_TS )

        ( REPORT_ID    = 'AR-02'
        REPORT_CLASS = 'ZCL_REPORT_AR02'
        IS_ACTIVE    = ABAP_TRUE
        CREATED_BY   = LV_USER
        CREATED_AT   = LV_TS )

        ( REPORT_ID    = 'AR-03'
        REPORT_CLASS = 'ZCL_REPORT_AR03'
        IS_ACTIVE    = ABAP_TRUE
        CREATED_BY   = LV_USER
        CREATED_AT   = LV_TS )

        ( REPORT_ID    = 'AP-01'
        REPORT_CLASS = 'ZCL_REPORT_AP01'
        IS_ACTIVE    = ABAP_TRUE
        CREATED_BY   = LV_USER
        CREATED_AT   = LV_TS )

        ( REPORT_ID    = 'AP-02'
        REPORT_CLASS = 'ZCL_REPORT_AP02'
        IS_ACTIVE    = ABAP_TRUE
        CREATED_BY   = LV_USER
        CREATED_AT   = LV_TS )

        ( REPORT_ID    = 'AP-03'
        REPORT_CLASS = 'ZCL_REPORT_AP03'
        IS_ACTIVE    = ABAP_TRUE
        CREATED_BY   = LV_USER
        CREATED_AT   = LV_TS )
    ).

    " -----------------------------------------------------------------
    " 2a. Formatter Registry — report-specific overrides (ZDRS_FM_REGISTRY)
    "
    "     Key: REPORT_ID + OUTPUT_FORMAT
    "     Only populate when a specific report needs its own formatter.
    "     Leave empty to fall through to ZDRS_FM_DEFAULT.
    " -----------------------------------------------------------------
    DATA LT_FMT_REG TYPE TABLE OF ZDRS_FM_REGISTRY.

    LT_FMT_REG = VALUE #(
      " Example — uncomment when ZCL_XLSX_FORMATTER_GL01 is activated:
       ( REPORT_ID       = 'GL-01'
         OUTPUT_FORMAT   = 'XLSX'
         FORMATTER_CLASS = 'ZCL_XLSX_FORMATTER_GL01'
         IS_ACTIVE       = ABAP_TRUE
         DESCRIPTION     = 'GL-01 custom XLSX: styled header + currency format'
         CREATED_BY      = LV_USER
         CREATED_AT      = LV_TS )

         ( REPORT_ID     = 'AR-01'
         OUTPUT_FORMAT   = 'XLSX'
         FORMATTER_CLASS = 'ZCL_XLSX_FORMATTER_AR01'
         IS_ACTIVE       = ABAP_TRUE
         DESCRIPTION     = 'AR-01 custom XLSX: styled header + currency format'
         CREATED_BY      = LV_USER
         CREATED_AT      = LV_TS )

         ( REPORT_ID     = 'AR-02'
         OUTPUT_FORMAT   = 'XLSX'
         FORMATTER_CLASS = 'ZCL_XLSX_FORMATTER_AR02'
         IS_ACTIVE       = ABAP_TRUE
         DESCRIPTION     = 'AR-02 custom XLSX: styled header + currency format'
         CREATED_BY      = LV_USER
         CREATED_AT      = LV_TS )

          ( REPORT_ID    = 'AR-03'
         OUTPUT_FORMAT   = 'XLSX'
         FORMATTER_CLASS = 'ZCL_XLSX_FORMATTER_AR03'
         IS_ACTIVE       = ABAP_TRUE
         DESCRIPTION     = 'AR-03 custom XLSX: styled header + currency format'
         CREATED_BY      = LV_USER
         CREATED_AT      = LV_TS )

          ( REPORT_ID    = 'AP-01'
         OUTPUT_FORMAT   = 'XLSX'
         FORMATTER_CLASS = 'ZCL_XLSX_FORMATTER_AP01'
         IS_ACTIVE       = ABAP_TRUE
         DESCRIPTION     = 'AP-01 custom XLSX: styled header + currency format'
         CREATED_BY      = LV_USER
         CREATED_AT      = LV_TS )

          ( REPORT_ID    = 'AP-02'
         OUTPUT_FORMAT   = 'XLSX'
         FORMATTER_CLASS = 'ZCL_XLSX_FORMATTER_AP02'
         IS_ACTIVE       = ABAP_TRUE
         DESCRIPTION     = 'AP-02 custom XLSX: styled header + currency format'
         CREATED_BY      = LV_USER
         CREATED_AT      = LV_TS )

          ( REPORT_ID    = 'AP-03'
         OUTPUT_FORMAT   = 'XLSX'
         FORMATTER_CLASS = 'ZCL_XLSX_FORMATTER_AP03'
         IS_ACTIVE       = ABAP_TRUE
         DESCRIPTION     = 'AP-03 custom XLSX: styled header + currency format'
         CREATED_BY      = LV_USER
         CREATED_AT      = LV_TS )
    ).

    " -----------------------------------------------------------------
    " 2b. Default Formatter Registry (ZDRS_FM_DEFAULT)
    "
    "     Key: OUTPUT_FORMAT only — no REPORT_ID concept.
    "     Used as fallback when no specific entry exists in ZDRS_FM_REGISTRY.
    "     CSV entry is optional (factory resolves CSV without DB lookup).
    " -----------------------------------------------------------------
    DATA LT_FMT_DEFAULT TYPE TABLE OF ZDRS_FM_DEFAULT.

    LT_FMT_DEFAULT = VALUE #(
      ( OUTPUT_FORMAT   = 'CSV'
        FORMATTER_CLASS = 'ZCL_CSV_FORMATTER'
        MIME_TYPE       = 'text/csv'
        IS_ACTIVE       = ABAP_TRUE
        DESCRIPTION     = 'Default CSV formatter'
        CREATED_BY      = LV_USER
        CREATED_AT      = LV_TS )

      ( OUTPUT_FORMAT   = 'XLSX'
        FORMATTER_CLASS = 'ZCL_XLSX_FORMATTER'
        MIME_TYPE       = 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet'
        IS_ACTIVE       = ABAP_TRUE
        DESCRIPTION     = 'Default XLSX formatter — fallback for all reports'
        CREATED_BY      = LV_USER
        CREATED_AT      = LV_TS )
    ).

    INSERT ZDRS_RP_REGISTRY FROM TABLE @LT_REP_REG.
    INSERT ZDRS_FM_REGISTRY FROM TABLE @LT_FMT_REG.
    INSERT ZDRS_FM_DEFAULT  FROM TABLE @LT_FMT_DEFAULT.
    " -----------------------------------------------------------------
    " 4.  Commit / Rollback
    " -----------------------------------------------------------------
    IF SY-SUBRC = 0.
      COMMIT WORK.
      IF IO_OUT IS BOUND.
        IO_OUT->WRITE( |Successfully inserted { LINES( LT_REP_REG ) } reports.| ).
        IO_OUT->WRITE( |Successfully inserted { LINES( LT_FMT_REG ) } formatters.| ).
        IO_OUT->WRITE( |Successfully inserted { LINES( LT_FMT_DEFAULT ) } formatters.| ).
      ENDIF.
    ELSE.
      ROLLBACK WORK.
      IF IO_OUT IS BOUND.
        IO_OUT->WRITE( |INSERT failed. sy-subrc = { SY-SUBRC }| ).
      ENDIF.
    ENDIF.
  ENDMETHOD.


  METHOD DELETE_ALL.
    DELETE FROM ZDRS_RP_REGISTRY.
    DELETE FROM ZDRS_FM_REGISTRY.
    DELETE FROM ZDRS_FM_DEFAULT.
    COMMIT WORK.
    IF IO_OUT IS BOUND.
      IO_OUT->WRITE( |Cleanup complete.| ).
    ENDIF.
  ENDMETHOD.

ENDCLASS.
