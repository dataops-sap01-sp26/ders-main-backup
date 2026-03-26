CLASS ZCL_FORMATTER_FACTORY DEFINITION PUBLIC FINAL CREATE PUBLIC.
  PUBLIC SECTION.
    CLASS-METHODS CREATE
      IMPORTING IV_REPORT_ID         TYPE ZDRS_SUBSCR-REPORT_ID
                IV_OUTPUT_FORMAT     TYPE ZDRS_SUBSCR-OUTPUT_FORMAT
                IS_PARAMS            TYPE ZIF_REPORT=>TY_PARAMS OPTIONAL
      RETURNING VALUE(RO_FORMATTER)  TYPE REF TO ZIF_FILE_FORMATTER.

ENDCLASS.


CLASS ZCL_FORMATTER_FACTORY IMPLEMENTATION.

  METHOD CREATE.
    " ----------------------------------------------------------------
    " CSV: always auto-resolved, skip DB entirely
    " ----------------------------------------------------------------
    IF IV_OUTPUT_FORMAT = 'CSV'.
      RO_FORMATTER = NEW ZCL_CSV_FORMATTER( ).
      RETURN.
    ENDIF.

    " ----------------------------------------------------------------
    " Non-CSV: 2-level lookup with fallback
    " ----------------------------------------------------------------
    DATA LV_CLASS_NAME TYPE CLASSNAME.
    DATA LO_OBJ        TYPE REF TO OBJECT.

    " --- Step 1: report-specific class from ZDRS_FM_REGISTRY ----------
    SELECT SINGLE FORMATTER_CLASS
      FROM ZDRS_FM_REGISTRY
      WHERE REPORT_ID     = @IV_REPORT_ID
        AND OUTPUT_FORMAT = @IV_OUTPUT_FORMAT
        AND IS_ACTIVE     = @ABAP_TRUE
      INTO @LV_CLASS_NAME.

    IF SY-SUBRC = 0 AND LV_CLASS_NAME IS NOT INITIAL.
      TRY.
          CREATE OBJECT LO_OBJ TYPE (LV_CLASS_NAME)
            EXPORTING IS_PARAMS = IS_PARAMS.
          RO_FORMATTER ?= LO_OBJ.
          RETURN.                       " success → done
        CATCH CX_SY_CREATE_OBJECT_ERROR.
          " class registered but not yet activated → fall through to default
          CLEAR LV_CLASS_NAME.
      ENDTRY.
    ENDIF.

    " --- Step 2: generic default from ZDRS_FM_DEFAULT -----------------
    SELECT SINGLE FORMATTER_CLASS
      FROM ZDRS_FM_DEFAULT
      WHERE OUTPUT_FORMAT = @IV_OUTPUT_FORMAT
        AND IS_ACTIVE     = @ABAP_TRUE
      INTO @LV_CLASS_NAME.

    IF LV_CLASS_NAME IS INITIAL.
      RETURN.                           " nothing configured → unbound
    ENDIF.

    TRY.
        CREATE OBJECT LO_OBJ TYPE (LV_CLASS_NAME).
      CATCH CX_SY_CREATE_OBJECT_ERROR.
        RETURN.                         " even default class broken → unbound
    ENDTRY.

    RO_FORMATTER ?= LO_OBJ.
  ENDMETHOD.


ENDCLASS.

