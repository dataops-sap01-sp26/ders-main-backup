*&---------------------------------------------------------------------*
*& Local Handler Class Definition for Catalog Entity
*&---------------------------------------------------------------------*
CLASS lhc_catalog DEFINITION INHERITING FROM cl_abap_behavior_handler.
  PRIVATE SECTION.

    METHODS get_global_authorizations FOR GLOBAL AUTHORIZATION
      IMPORTING REQUEST requested_authorizations FOR Catalog RESULT result.

    " Custom Actions (US-E1-007)
    METHODS activateReport FOR MODIFY
      IMPORTING keys FOR ACTION Catalog~activateReport RESULT result.

    METHODS deactivateReport FOR MODIFY
      IMPORTING keys FOR ACTION Catalog~deactivateReport RESULT result.

    METHODS copyReport FOR MODIFY
      IMPORTING keys FOR ACTION Catalog~copyReport RESULT result.

    METHODS previewReport FOR MODIFY
      IMPORTING keys FOR ACTION Catalog~previewReport RESULT result.

    " Validations
    METHODS validateReportClass FOR VALIDATE ON SAVE
      IMPORTING keys FOR Catalog~validateReportClass.

    METHODS validateCdsView FOR VALIDATE ON SAVE
      IMPORTING keys FOR Catalog~validateCdsView.

    " Determinations
    METHODS setDefaults FOR DETERMINE ON MODIFY
      IMPORTING keys FOR Catalog~setDefaults.

ENDCLASS.

*"* use this source file for the implementation of your local
*"* classes

CLASS lhc_catalog IMPLEMENTATION.

  METHOD get_global_authorizations.
    " Authorization check for Catalog operations
    " In production, check S_TCODE or custom auth object
    result = VALUE #( %create = if_abap_behv=>auth-allowed
                      %update = if_abap_behv=>auth-allowed
                      %delete = if_abap_behv=>auth-allowed ).
  ENDMETHOD.


  METHOD activateReport.
    "=====================================================================
    " US-E1-007: Activate Report - Set IS_ACTIVE = 'X'
    "=====================================================================

    " Read current state
    READ ENTITIES OF zir_drs_catalog IN LOCAL MODE
      ENTITY Catalog
        FIELDS ( ReportId IsActive )
        WITH CORRESPONDING #( keys )
      RESULT DATA(lt_catalogs)
      FAILED DATA(lt_read_failed).

    IF lt_read_failed IS NOT INITIAL.
      failed = CORRESPONDING #( DEEP lt_read_failed ).
      RETURN.
    ENDIF.

    " Update to Active
    MODIFY ENTITIES OF zir_drs_catalog IN LOCAL MODE
      ENTITY Catalog
        UPDATE FIELDS ( IsActive )
        WITH VALUE #( FOR catalog IN lt_catalogs
                      ( %tky = catalog-%tky
                        IsActive = abap_true ) )
      FAILED DATA(lt_update_failed)
      REPORTED DATA(lt_update_reported).

    " Return result
    READ ENTITIES OF zir_drs_catalog IN LOCAL MODE
      ENTITY Catalog
        ALL FIELDS WITH CORRESPONDING #( keys )
      RESULT DATA(lt_result).

    result = VALUE #( FOR ls_result IN lt_result
                      ( %tky = ls_result-%tky
                        %param = ls_result ) ).

    " Report success message
    LOOP AT lt_result ASSIGNING FIELD-SYMBOL(<result>).
      APPEND VALUE #( %tky = <result>-%tky
                      %msg = new_message_with_text(
                               severity = if_abap_behv_message=>severity-success
                               text = |Report { <result>-ReportId } activated| ) )
             TO reported-catalog.
    ENDLOOP.
  ENDMETHOD.


  METHOD deactivateReport.
    "=====================================================================
    " US-E1-007: Deactivate Report - Set IS_ACTIVE = ''
    "=====================================================================

    " Read current state
    READ ENTITIES OF zir_drs_catalog IN LOCAL MODE
      ENTITY Catalog
        FIELDS ( ReportId IsActive )
        WITH CORRESPONDING #( keys )
      RESULT DATA(lt_catalogs)
      FAILED DATA(lt_read_failed).

    IF lt_read_failed IS NOT INITIAL.
      failed = CORRESPONDING #( DEEP lt_read_failed ).
      RETURN.
    ENDIF.

    " Update to Inactive
    MODIFY ENTITIES OF zir_drs_catalog IN LOCAL MODE
      ENTITY Catalog
        UPDATE FIELDS ( IsActive )
        WITH VALUE #( FOR catalog IN lt_catalogs
                      ( %tky = catalog-%tky
                        IsActive = abap_false ) )
      FAILED DATA(lt_update_failed)
      REPORTED DATA(lt_update_reported).

    " Return result
    READ ENTITIES OF zir_drs_catalog IN LOCAL MODE
      ENTITY Catalog
        ALL FIELDS WITH CORRESPONDING #( keys )
      RESULT DATA(lt_result).

    result = VALUE #( FOR ls_result IN lt_result
                      ( %tky = ls_result-%tky
                        %param = ls_result ) ).

    " Report success message
    LOOP AT lt_result ASSIGNING FIELD-SYMBOL(<result>).
      APPEND VALUE #( %tky = <result>-%tky
                      %msg = new_message_with_text(
                               severity = if_abap_behv_message=>severity-success
                               text = |Report { <result>-ReportId } deactivated| ) )
             TO reported-catalog.
    ENDLOOP.
  ENDMETHOD.


  METHOD copyReport.
    "=====================================================================
    " Copy Report Configuration to a new entry
    "=====================================================================
    DATA: lt_create TYPE TABLE FOR CREATE zir_drs_catalog.

    " Read source
    READ ENTITIES OF zir_drs_catalog IN LOCAL MODE
      ENTITY Catalog
        ALL FIELDS WITH CORRESPONDING #( keys )
      RESULT DATA(lt_source)
      FAILED DATA(lt_read_failed).

    IF lt_read_failed IS NOT INITIAL.
      failed = CORRESPONDING #( DEEP lt_read_failed ).
      RETURN.
    ENDIF.

    " Create copies with new ID
    LOOP AT lt_source ASSIGNING FIELD-SYMBOL(<source>).
      DATA(lv_new_id) = |{ <source>-ReportId }_COPY|.

      " Check if copy already exists
      SELECT SINGLE @abap_true FROM zdrs_catalog
        WHERE report_id = @lv_new_id
        INTO @DATA(lv_exists).

      IF lv_exists = abap_true.
        " Add timestamp suffix - convert to string first since packed type doesn't allow substring
        DATA(lv_ts_str) = |{ sy-datum }{ sy-uzeit }|.
        lv_new_id = |{ <source>-ReportId(6) }_{ lv_ts_str+8(6) }|.
      ENDIF.

      APPEND VALUE #( %cid              = |COPY{ sy-tabix }|
                      ReportId          = lv_new_id
                      ModuleId          = <source>-ModuleId
                      ReportName        = |Copy of { <source>-ReportName }|
                      Description       = <source>-Description
                      LongText          = <source>-LongText
                      CdsViewName       = <source>-CdsViewName
                      ReportClass       = <source>-ReportClass
                      IsActive          = abap_false  " New copy is inactive
                      SortOrder         = <source>-SortOrder )
             TO lt_create.
    ENDLOOP.

    " Execute creation
    MODIFY ENTITIES OF zir_drs_catalog IN LOCAL MODE
      ENTITY Catalog
        CREATE FROM lt_create
      MAPPED DATA(lt_mapped)
      FAILED DATA(lt_create_failed)
      REPORTED DATA(lt_create_reported).

    " Return result - read the new entities
    READ ENTITIES OF zir_drs_catalog IN LOCAL MODE
      ENTITY Catalog
        ALL FIELDS WITH CORRESPONDING #( lt_mapped-catalog )
      RESULT DATA(lt_result).

    result = VALUE #( FOR ls_result IN lt_result
                      ( %tky = keys[ 1 ]-%tky  " Return original key
                        %param = ls_result ) ).
  ENDMETHOD.


  METHOD validateReportClass.
    "=====================================================================
    " Validate Report Class exists
    "=====================================================================
    READ ENTITIES OF zir_drs_catalog IN LOCAL MODE
      ENTITY Catalog
        FIELDS ( ReportId ReportClass )
        WITH CORRESPONDING #( keys )
      RESULT DATA(lt_catalogs).

    LOOP AT lt_catalogs ASSIGNING FIELD-SYMBOL(<catalog>)
         WHERE ReportClass IS NOT INITIAL.

      " Check if class exists in the system
      SELECT SINGLE @abap_true FROM seoclass
        WHERE clsname = @<catalog>-ReportClass
        INTO @DATA(lv_exists).

      IF lv_exists <> abap_true.
        " Class does not exist - add warning (not error, may be created later)
        APPEND VALUE #( %tky = <catalog>-%tky
                        %state_area = 'REPORTCLASS'
                        %msg = new_message_with_text(
                                 severity = if_abap_behv_message=>severity-warning
                                 text = |Class { <catalog>-ReportClass } not found in system| )
                        %element-ReportClass = if_abap_behv=>mk-on )
               TO reported-catalog.
      ENDIF.
    ENDLOOP.
  ENDMETHOD.


  METHOD validateCdsView.
    "=====================================================================
    " Validate CDS View exists
    "=====================================================================
    READ ENTITIES OF zir_drs_catalog IN LOCAL MODE
      ENTITY Catalog
        FIELDS ( ReportId CdsViewName )
        WITH CORRESPONDING #( keys )
      RESULT DATA(lt_catalogs).

    LOOP AT lt_catalogs ASSIGNING FIELD-SYMBOL(<catalog>)
         WHERE CdsViewName IS NOT INITIAL.

      " Check if CDS view exists
      SELECT SINGLE @abap_true FROM ddddlsrc
        WHERE ddlname = @<catalog>-CdsViewName
        INTO @DATA(lv_exists).

      IF lv_exists <> abap_true.
        APPEND VALUE #( %tky = <catalog>-%tky
                        %state_area = 'CDSVIEW'
                        %msg = new_message_with_text(
                                 severity = if_abap_behv_message=>severity-warning
                                 text = |CDS View { <catalog>-CdsViewName } not found| )
                        %element-CdsViewName = if_abap_behv=>mk-on )
               TO reported-catalog.
      ENDIF.
    ENDLOOP.
  ENDMETHOD.


  METHOD setDefaults.
    "=====================================================================
    " Set default values on create
    "=====================================================================
    READ ENTITIES OF zir_drs_catalog IN LOCAL MODE
      ENTITY Catalog
        FIELDS ( IsActive )
        WITH CORRESPONDING #( keys )
      RESULT DATA(lt_catalogs).

    MODIFY ENTITIES OF zir_drs_catalog IN LOCAL MODE
      ENTITY Catalog
        UPDATE FIELDS ( IsActive )
        WITH VALUE #( FOR catalog IN lt_catalogs
                      ( %tky = catalog-%tky
                        IsActive = abap_false ) )  " New catalogs are inactive by default
      REPORTED DATA(lt_reported).
  ENDMETHOD.


  METHOD previewReport.
    "=====================================================================
    " Preview Report - Return current entity with CDS info for navigation
    " Frontend uses CdsViewName to determine which preview to show
    "=====================================================================

    " Read the report catalog entry
    READ ENTITIES OF zir_drs_catalog IN LOCAL MODE
      ENTITY Catalog
        ALL FIELDS WITH CORRESPONDING #( keys )
      RESULT DATA(lt_catalogs)
      FAILED DATA(lt_read_failed).

    IF lt_read_failed IS NOT INITIAL.
      failed = CORRESPONDING #( DEEP lt_read_failed ).
      RETURN.
    ENDIF.

    " Return result with success message
    result = VALUE #( FOR catalog IN lt_catalogs
                      ( %tky = catalog-%tky
                        %param = catalog ) ).

    " Report info message showing which CDS to preview
    LOOP AT lt_catalogs ASSIGNING FIELD-SYMBOL(<catalog>).
      IF <catalog>-CdsViewName IS NOT INITIAL.
        APPEND VALUE #( %tky = <catalog>-%tky
                        %msg = new_message_with_text(
                                 severity = if_abap_behv_message=>severity-success
                                 text = |Preview CDS: { <catalog>-CdsViewName }| ) )
               TO reported-catalog.
      ELSE.
        APPEND VALUE #( %tky = <catalog>-%tky
                        %msg = new_message_with_text(
                                 severity = if_abap_behv_message=>severity-warning
                                 text = |No CDS View configured for { <catalog>-ReportId }| ) )
               TO reported-catalog.
      ENDIF.
    ENDLOOP.
  ENDMETHOD.

ENDCLASS.
