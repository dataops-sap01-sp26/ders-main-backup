*&---------------------------------------------------------------------*
*& Local Classes for Subscription Behavior
*& COMPOSITION: ParamGL01 is child entity (lifecycle managed by parent)
*&---------------------------------------------------------------------*
CLASS lhc_subscription DEFINITION INHERITING FROM cl_abap_behavior_handler.
  PRIVATE SECTION.

    METHODS get_global_authorizations FOR GLOBAL AUTHORIZATION
      IMPORTING REQUEST requested_authorizations FOR Subscription RESULT result.

    METHODS earlynumbering_create FOR NUMBERING
      IMPORTING entities FOR CREATE Subscription.

    METHODS copySubscription FOR MODIFY
      IMPORTING keys FOR ACTION Subscription~copySubscription RESULT result.

    " US-E3-008: Pause Subscription
    METHODS pauseSubscription FOR MODIFY
      IMPORTING keys FOR ACTION Subscription~pauseSubscription RESULT result.

    " US-E3-009: Resume Subscription
    METHODS resumeSubscription FOR MODIFY
      IMPORTING keys FOR ACTION Subscription~resumeSubscription RESULT result.

    " Determination: Set default status on create
    METHODS setDefaultStatus FOR DETERMINE ON MODIFY
      IMPORTING keys FOR Subscription~setDefaultStatus.

    " NOTE: cascadeDeleteParams removed - composition handles cascade delete automatically

    " Create Report Parameters - generic action based on ReportId
    METHODS createReportParams FOR MODIFY
      IMPORTING keys FOR ACTION Subscription~createReportParams RESULT result.

ENDCLASS.


CLASS lhc_subscription IMPLEMENTATION.

  METHOD get_global_authorizations.
    " Check if user has authorization for Subscription operations
    " For MVP, allow all operations
    result = VALUE #( %create = if_abap_behv=>auth-allowed
                      %update = if_abap_behv=>auth-allowed
                      %delete = if_abap_behv=>auth-allowed ).
  ENDMETHOD.


  METHOD earlynumbering_create.
    " Generate UUID and Subscription ID for new subscriptions
    DATA: lv_subscr_id TYPE n LENGTH 6,
          lv_uuid      TYPE sysuuid_x16,
          lv_id        TYPE n LENGTH 6.

    " Get max subscr_id from DB and increment
    SELECT MAX( subscr_id ) FROM zdrs_subscr INTO @DATA(lv_max_id).
    lv_subscr_id = lv_max_id + 1.

    " MUST return mapped for ALL entities (including draft)
    LOOP AT entities ASSIGNING FIELD-SYMBOL(<entity>).
      " Generate UUID if not provided
      IF <entity>-SubscrUuid IS INITIAL.
        lv_uuid = cl_system_uuid=>create_uuid_x16_static( ).
      ELSE.
        lv_uuid = <entity>-SubscrUuid.
      ENDIF.

      " Use provided SubscrId or generate new one
      IF <entity>-SubscrId IS INITIAL.
        lv_id = lv_subscr_id.
        lv_subscr_id = lv_subscr_id + 1.
      ELSE.
        lv_id = <entity>-SubscrId.
      ENDIF.

      " Assign to mapped response - include %is_draft for draft-enabled BO
      APPEND VALUE #( %cid       = <entity>-%cid
                      %is_draft  = <entity>-%is_draft
                      SubscrUuid = lv_uuid
                      SubscrId   = lv_id )
             TO mapped-subscription.
    ENDLOOP.
  ENDMETHOD.


  METHOD setDefaultStatus.
    " Set status to 'A' (Active) when subscription is created
    READ ENTITIES OF zir_drs_subscr IN LOCAL MODE
      ENTITY Subscription
        FIELDS ( Status ) WITH CORRESPONDING #( keys )
      RESULT DATA(lt_subscr).

    " Filter only records without status
    DATA lt_update TYPE TABLE FOR UPDATE zir_drs_subscr.
    LOOP AT lt_subscr ASSIGNING FIELD-SYMBOL(<subscr>) WHERE Status IS INITIAL.
      APPEND VALUE #( %tky = <subscr>-%tky   " Include %is_draft for draft-enabled BO
                      Status = 'A' )         " A = Active
             TO lt_update.
    ENDLOOP.

    IF lt_update IS NOT INITIAL.
      MODIFY ENTITIES OF zir_drs_subscr IN LOCAL MODE
        ENTITY Subscription
          UPDATE FIELDS ( Status ) WITH lt_update
        REPORTED DATA(lt_reported).
    ENDIF.
  ENDMETHOD.


  METHOD pauseSubscription.
    " US-E3-008: Pause subscription (stops new job scheduling)
    " Subscription Status: A (Active) → P (Paused)

    " Read current subscriptions
    READ ENTITIES OF zir_drs_subscr IN LOCAL MODE
      ENTITY Subscription
        ALL FIELDS WITH CORRESPONDING #( keys )
      RESULT DATA(lt_subscr)
      FAILED failed.

    " Build update table
    DATA lt_update TYPE TABLE FOR UPDATE zir_drs_subscr.
    LOOP AT lt_subscr ASSIGNING FIELD-SYMBOL(<subscr>).
      " Only pause if currently Active
      IF <subscr>-Status = 'A'.
        APPEND VALUE #( %tky   = <subscr>-%tky
                        Status = 'P' )  " P = Paused
               TO lt_update.
      ENDIF.
    ENDLOOP.

    " Execute update
    IF lt_update IS NOT INITIAL.
      MODIFY ENTITIES OF zir_drs_subscr IN LOCAL MODE
        ENTITY Subscription
          UPDATE FIELDS ( Status ) WITH lt_update
        REPORTED reported.
    ENDIF.

    " Return result
    READ ENTITIES OF zir_drs_subscr IN LOCAL MODE
      ENTITY Subscription
        ALL FIELDS WITH CORRESPONDING #( keys )
      RESULT DATA(lt_result).

    result = VALUE #( FOR ls IN lt_result
                      ( %tky = ls-%tky
                        %param = CORRESPONDING #( ls ) ) ).
  ENDMETHOD.


  METHOD resumeSubscription.
    " US-E3-009: Resume subscription (allows new job scheduling)
    " Subscription Status: P (Paused) → A (Active)

    " Read current subscriptions
    READ ENTITIES OF zir_drs_subscr IN LOCAL MODE
      ENTITY Subscription
        ALL FIELDS WITH CORRESPONDING #( keys )
      RESULT DATA(lt_subscr)
      FAILED failed.

    " Build update table
    DATA lt_update TYPE TABLE FOR UPDATE zir_drs_subscr.
    LOOP AT lt_subscr ASSIGNING FIELD-SYMBOL(<subscr>).
      " Only resume if currently Paused
      IF <subscr>-Status = 'P'.
        APPEND VALUE #( %tky   = <subscr>-%tky
                        Status = 'A' )  " A = Active
               TO lt_update.
      ENDIF.
    ENDLOOP.

    " Execute update
    IF lt_update IS NOT INITIAL.
      MODIFY ENTITIES OF zir_drs_subscr IN LOCAL MODE
        ENTITY Subscription
          UPDATE FIELDS ( Status ) WITH lt_update
        REPORTED reported.
    ENDIF.

    " Return result
    READ ENTITIES OF zir_drs_subscr IN LOCAL MODE
      ENTITY Subscription
        ALL FIELDS WITH CORRESPONDING #( keys )
      RESULT DATA(lt_result).

    result = VALUE #( FOR ls IN lt_result
                      ( %tky = ls-%tky
                        %param = CORRESPONDING #( ls ) ) ).
  ENDMETHOD.


  METHOD copySubscription.
    " ═══════════════════════════════════════════════════════════════════════════
    " Copy existing subscription with its GL01 parameters
    " Uses composition - creates ParamGL01 via _ParamGL01 association
    " ═══════════════════════════════════════════════════════════════════════════

    " Read source subscriptions
    READ ENTITIES OF zir_drs_subscr IN LOCAL MODE
      ENTITY Subscription
        ALL FIELDS WITH CORRESPONDING #( keys )
      RESULT DATA(lt_source_subscr)
      FAILED DATA(lt_failed).

    IF lt_failed IS NOT INITIAL.
      failed = CORRESPONDING #( DEEP lt_failed ).
      RETURN.
    ENDIF.

    " Read associated GL01 parameters via composition
    READ ENTITIES OF zir_drs_subscr IN LOCAL MODE
      ENTITY Subscription BY \_ParamGL01
        ALL FIELDS WITH CORRESPONDING #( keys )
      RESULT DATA(lt_source_gl01).

    " Get max subscr_id for new ID generation
    SELECT MAX( subscr_id ) FROM zdrs_subscr INTO @DATA(lv_max_id).
    DATA(lv_new_subscr_id) = lv_max_id + 1.

    " Create subscription copies with nested ParamGL01 via composition
    DATA lt_subscr TYPE TABLE FOR CREATE zir_drs_subscr.
    DATA lt_param_gl01 TYPE TABLE FOR CREATE zir_drs_subscr\_ParamGL01.

    DATA(lv_idx) = 0.
    LOOP AT lt_source_subscr ASSIGNING FIELD-SYMBOL(<source>).
      lv_idx = lv_idx + 1.
      DATA(lv_new_uuid) = cl_system_uuid=>create_uuid_x16_static( ).
      DATA(lv_cid) = |COPY{ lv_idx }|.

      " Create subscription
      APPEND VALUE #( %cid = lv_cid
                      SubscrUuid = lv_new_uuid
                      SubscrId = lv_new_subscr_id
                      SubscrName = |Copy of { <source>-SubscrName }|
                      ReportId = <source>-ReportId
                      Bukrs = <source>-Bukrs
                      OutputFormat = <source>-OutputFormat
                      EmailTo = <source>-EmailTo
                      EmailCc = <source>-EmailCc )
             TO lt_subscr.

      " Create GL01 params via composition (keys inherited from parent)
      LOOP AT lt_source_gl01 ASSIGNING FIELD-SYMBOL(<gl01>)
           WHERE SubscrUuid = <source>-SubscrUuid.
        APPEND VALUE #( %cid_ref = lv_cid
                        %target = VALUE #( (
                          %cid        = |GL01_{ lv_idx }|
                          %is_draft   = <source>-%is_draft
                          CompanyCode = <gl01>-CompanyCode
                          FiscalYear  = <gl01>-FiscalYear
                          FiscalPeriod = <gl01>-FiscalPeriod
                          Currency    = <gl01>-Currency
                          GlAccount   = <gl01>-GlAccount
                          MaxRows     = <gl01>-MaxRows ) ) )
               TO lt_param_gl01.
      ENDLOOP.

      lv_new_subscr_id = lv_new_subscr_id + 1.
    ENDLOOP.

    " Create subscriptions via RAP
    MODIFY ENTITIES OF zir_drs_subscr IN LOCAL MODE
      ENTITY Subscription
        CREATE FROM lt_subscr
        CREATE BY \_ParamGL01 FROM lt_param_gl01
      MAPPED DATA(lt_mapped)
      FAILED DATA(lt_create_failed)
      REPORTED DATA(lt_reported).

    " Return result - re-read source entities (action result = $self)
    READ ENTITIES OF zir_drs_subscr IN LOCAL MODE
      ENTITY Subscription
        ALL FIELDS WITH CORRESPONDING #( keys )
      RESULT DATA(lt_result).

    result = VALUE #( FOR ls IN lt_result
                      ( %tky = ls-%tky
                        %param = CORRESPONDING #( ls ) ) ).
  ENDMETHOD.


  METHOD createReportParams.
    " ═══════════════════════════════════════════════════════════════════════════
    " CREATE REPORT PARAMETERS: Generic action based on ReportId
    " Uses composition - creates ParamGL01 via _ParamGL01 association
    " GL-01 → _ParamGL01, GL-02 → _ParamGL02 (future), etc.
    " ═══════════════════════════════════════════════════════════════════════════

    " Read subscription data to get ReportId and Bukrs (for default CompanyCode)
    READ ENTITIES OF zir_drs_subscr IN LOCAL MODE
      ENTITY Subscription
        FIELDS ( SubscrUuid SubscrId ReportId Bukrs )
        WITH CORRESPONDING #( keys )
      RESULT DATA(lt_subscr)
      FAILED failed.

    " Read existing GL01 params via composition
    READ ENTITIES OF zir_drs_subscr IN LOCAL MODE
      ENTITY Subscription BY \_ParamGL01
        FIELDS ( SubscrUuid ) WITH CORRESPONDING #( keys )
      RESULT DATA(lt_existing_gl01).

    DATA lt_create_gl01 TYPE TABLE FOR CREATE zir_drs_subscr\_ParamGL01.

    "===================AR Report Parameter==================================
    " Read existing AR01 params via composition
    READ ENTITIES OF zir_drs_subscr IN LOCAL MODE
      ENTITY Subscription BY \_ParamAR01
        FIELDS ( SubscrUuid ) WITH CORRESPONDING #( keys )
      RESULT DATA(lt_existing_ar01).

    DATA lt_create_ar01 TYPE TABLE FOR CREATE zir_drs_subscr\_ParamAR01.

    " Read existing AR02 params via composition
    READ ENTITIES OF zir_drs_subscr IN LOCAL MODE
      ENTITY Subscription BY \_ParamAR02
        FIELDS ( SubscrUuid ) WITH CORRESPONDING #( keys )
      RESULT DATA(lt_existing_ar02).


    DATA lt_create_ar02 TYPE TABLE FOR CREATE zir_drs_subscr\_ParamAR02.

    " Read existing AR03 params via composition
    READ ENTITIES OF zir_drs_subscr IN LOCAL MODE
      ENTITY Subscription BY \_ParamAR03
        FIELDS ( SubscrUuid ) WITH CORRESPONDING #( keys )
      RESULT DATA(lt_existing_ar03).


    DATA lt_create_ar03 TYPE TABLE FOR CREATE zir_drs_subscr\_ParamAR03.
    "=======================================================================

    "===================AP Report Parameter==================================
    " Read existing AP01 params via composition
    READ ENTITIES OF zir_drs_subscr IN LOCAL MODE
      ENTITY Subscription BY \_ParamAP01
        FIELDS ( SubscrUuid ) WITH CORRESPONDING #( keys )
      RESULT DATA(lt_existing_ap01).

    DATA lt_create_ap01 TYPE TABLE FOR CREATE zir_drs_subscr\_ParamAP01.

    " Read existing AP02 params via composition
    READ ENTITIES OF zir_drs_subscr IN LOCAL MODE
      ENTITY Subscription BY \_ParamAP02
        FIELDS ( SubscrUuid ) WITH CORRESPONDING #( keys )
      RESULT DATA(lt_existing_ap02).


    DATA lt_create_ap02 TYPE TABLE FOR CREATE zir_drs_subscr\_ParamAP02.

    " Read existing AR03 params via composition
    READ ENTITIES OF zir_drs_subscr IN LOCAL MODE
      ENTITY Subscription BY \_ParamAP03
        FIELDS ( SubscrUuid ) WITH CORRESPONDING #( keys )
      RESULT DATA(lt_existing_ap03).


    DATA lt_create_ap03 TYPE TABLE FOR CREATE zir_drs_subscr\_ParamAP03.
    "=======================================================================


    LOOP AT lt_subscr ASSIGNING FIELD-SYMBOL(<subscr>).
      CASE <subscr>-ReportId.
        WHEN 'GL-01'.
          " Check if already exists
          READ TABLE lt_existing_gl01 WITH KEY SubscrUuid = <subscr>-SubscrUuid TRANSPORTING NO FIELDS.
          IF sy-subrc = 0.
            " Already exists - report info message
            APPEND VALUE #(
              %tky = CORRESPONDING #( <subscr> )
              %msg = new_message_with_text(
                severity = if_abap_behv_message=>severity-information
                text     = 'GL-01 parameters already exist for this subscription'
              )
            ) TO reported-subscription.
          ELSE.
            " Create via composition (keys inherited from parent, %cid required)
            " %is_draft MUST match parent to avoid ACTIVE/DRAFT mixture dump
            APPEND VALUE #(
              %tky = CORRESPONDING #( <subscr> )
              %target = VALUE #( (
                %cid        = |GL01_{ sy-tabix }|
                %is_draft   = <subscr>-%is_draft
                CompanyCode = <subscr>-Bukrs  " Default from subscription
                FiscalYear  = sy-datum(4)     " Current year
                MaxRows     = 1000 ) )        " Default max rows
            ) TO lt_create_gl01.
          ENDIF.
        "===================AR Report Parameter==================================
        WHEN 'AR-01'.
          " Check if already exists
          READ TABLE lt_existing_ar01 WITH KEY SubscrUuid = <subscr>-SubscrUuid TRANSPORTING NO FIELDS.
          IF sy-subrc = 0.
            " Already exists - report info message
            APPEND VALUE #(
              %tky = CORRESPONDING #( <subscr> )
              %msg = new_message_with_text(
                severity = if_abap_behv_message=>severity-information
                text     = 'AR-01 parameters already exist for this subscription'
              )
            ) TO reported-subscription.
          ELSE.
            " Create via composition (keys inherited from parent, %cid required)
            " %is_draft MUST match parent to avoid ACTIVE/DRAFT mixture dump
            APPEND VALUE #(
              %tky = CORRESPONDING #( <subscr> )
              %target = VALUE #( (
                %cid        = |AR01_{ sy-tabix }|
                %is_draft   = <subscr>-%is_draft
                CompanyCode = <subscr>-Bukrs  " Default from subscription
                MaxRows     = 1000 ) )        " Default max rows
            ) TO lt_create_ar01.
          ENDIF.
         WHEN 'AR-02'.
          " Check if already exists
          READ TABLE lt_existing_ar02 WITH KEY SubscrUuid = <subscr>-SubscrUuid TRANSPORTING NO FIELDS.
          IF sy-subrc = 0.
            " Already exists - report info message
            APPEND VALUE #(
              %tky = CORRESPONDING #( <subscr> )
              %msg = new_message_with_text(
                severity = if_abap_behv_message=>severity-information
                text     = 'AR-02 parameters already exist for this subscription'
              )
            ) TO reported-subscription.
          ELSE.
            " Create via composition (keys inherited from parent, %cid required)
            " %is_draft MUST match parent to avoid ACTIVE/DRAFT mixture dump
            APPEND VALUE #(
              %tky = CORRESPONDING #( <subscr> )
              %target = VALUE #( (
                %cid        = |AR02_{ sy-tabix }|
                %is_draft   = <subscr>-%is_draft
                CompanyCode = <subscr>-Bukrs  " Default from subscription
                MaxRows     = 1000 ) )        " Default max rows
            ) TO lt_create_ar02.
          ENDIF.
          WHEN 'AR-03'.
          " Check if already exists
          READ TABLE lt_existing_ar03 WITH KEY SubscrUuid = <subscr>-SubscrUuid TRANSPORTING NO FIELDS.
          IF sy-subrc = 0.
            " Already exists - report info message
            APPEND VALUE #(
              %tky = CORRESPONDING #( <subscr> )
              %msg = new_message_with_text(
                severity = if_abap_behv_message=>severity-information
                text     = 'AR-03 parameters already exist for this subscription'
              )
            ) TO reported-subscription.
          ELSE.
            " Create via composition (keys inherited from parent, %cid required)
            " %is_draft MUST match parent to avoid ACTIVE/DRAFT mixture dump
            APPEND VALUE #(
              %tky = CORRESPONDING #( <subscr> )
              %target = VALUE #( (
                %cid        = |AR03_{ sy-tabix }|
                %is_draft   = <subscr>-%is_draft
                CompanyCode = <subscr>-Bukrs  " Default from subscription
                MaxRows     = 1000 ) )        " Default max rows
            ) TO lt_create_ar03.
          ENDIF.
          "========================================================================

          "===================AP Report Parameter==================================
           WHEN 'AP-01'.
          " Check if already exists
          READ TABLE lt_existing_ap01 WITH KEY SubscrUuid = <subscr>-SubscrUuid TRANSPORTING NO FIELDS.
          IF sy-subrc = 0.
            " Already exists - report info message
            APPEND VALUE #(
              %tky = CORRESPONDING #( <subscr> )
              %msg = new_message_with_text(
                severity = if_abap_behv_message=>severity-information
                text     = 'AP-01 parameters already exist for this subscription'
              )
            ) TO reported-subscription.
          ELSE.
            " Create via composition (keys inherited from parent, %cid required)
            " %is_draft MUST match parent to avoid ACTIVE/DRAFT mixture dump
            APPEND VALUE #(
              %tky = CORRESPONDING #( <subscr> )
              %target = VALUE #( (
                %cid        = |AP01_{ sy-tabix }|
                %is_draft   = <subscr>-%is_draft
                CompanyCode = <subscr>-Bukrs  " Default from subscription
                MaxRows     = 1000 ) )        " Default max rows
            ) TO lt_create_ap01.
          ENDIF.
         WHEN 'AP-02'.
          " Check if already exists
          READ TABLE lt_existing_ap02 WITH KEY SubscrUuid = <subscr>-SubscrUuid TRANSPORTING NO FIELDS.
          IF sy-subrc = 0.
            " Already exists - report info message
            APPEND VALUE #(
              %tky = CORRESPONDING #( <subscr> )
              %msg = new_message_with_text(
                severity = if_abap_behv_message=>severity-information
                text     = 'AP-02 parameters already exist for this subscription'
              )
            ) TO reported-subscription.
          ELSE.
            " Create via composition (keys inherited from parent, %cid required)
            " %is_draft MUST match parent to avoid ACTIVE/DRAFT mixture dump
            APPEND VALUE #(
              %tky = CORRESPONDING #( <subscr> )
              %target = VALUE #( (
                %cid        = |AP02_{ sy-tabix }|
                %is_draft   = <subscr>-%is_draft
                CompanyCode = <subscr>-Bukrs  " Default from subscription
                MaxRows     = 1000 ) )        " Default max rows
            ) TO lt_create_ap02.
          ENDIF.
          WHEN 'AP-03'.
          " Check if already exists
          READ TABLE lt_existing_ap03 WITH KEY SubscrUuid = <subscr>-SubscrUuid TRANSPORTING NO FIELDS.
          IF sy-subrc = 0.
            " Already exists - report info message
            APPEND VALUE #(
              %tky = CORRESPONDING #( <subscr> )
              %msg = new_message_with_text(
                severity = if_abap_behv_message=>severity-information
                text     = 'AP-03 parameters already exist for this subscription'
              )
            ) TO reported-subscription.
          ELSE.
            " Create via composition (keys inherited from parent, %cid required)
            " %is_draft MUST match parent to avoid ACTIVE/DRAFT mixture dump
            APPEND VALUE #(
              %tky = CORRESPONDING #( <subscr> )
              %target = VALUE #( (
                %cid        = |AP03_{ sy-tabix }|
                %is_draft   = <subscr>-%is_draft
                CompanyCode = <subscr>-Bukrs  " Default from subscription
                MaxRows     = 1000 ) )        " Default max rows
            ) TO lt_create_ap03.
          ENDIF.
          "========================================================================
*        WHEN 'GL-02'.
*          " TODO: Implement GL-02 parameter creation via _ParamGL02

        WHEN OTHERS.
          APPEND VALUE #(
            %tky = CORRESPONDING #( <subscr> )
            %msg = new_message_with_text(
              severity = if_abap_behv_message=>severity-warning
              text     = |Report type { <subscr>-ReportId } does not have configurable parameters|
            )
          ) TO reported-subscription.
      ENDCASE.
    ENDLOOP.

    " Create GL01 params via composition
    IF lt_create_gl01 IS NOT INITIAL.
      MODIFY ENTITIES OF zir_drs_subscr IN LOCAL MODE
        ENTITY Subscription
          CREATE BY \_ParamGL01 FROM lt_create_gl01
        MAPPED DATA(lt_mapped)
        FAILED DATA(lt_create_failed)
        REPORTED DATA(lt_create_reported).

      " Add success/failure messages
      IF lt_create_failed-paramgl01 IS INITIAL.
        LOOP AT lt_create_gl01 ASSIGNING FIELD-SYMBOL(<created>).
          APPEND VALUE #(
            %tky = <created>-%tky
            %msg = new_message_with_text(
              severity = if_abap_behv_message=>severity-success
              text     = 'GL-01 parameters created successfully'
            )
          ) TO reported-subscription.
        ENDLOOP.
      ENDIF.
    ENDIF.

    "===================AR Report Parameter==================================
    " Create AR01 params via composition
    IF lt_create_ar01 IS NOT INITIAL.
      MODIFY ENTITIES OF zir_drs_subscr IN LOCAL MODE
        ENTITY Subscription
          CREATE BY \_ParamAR01 FROM lt_create_ar01
        MAPPED DATA(lt_mapped_ar01)
        FAILED DATA(lt_failed_ar01)
        REPORTED DATA(lt_reported_ar01).

      " Add success/failure messages
      IF lt_failed_ar01-paramar01 IS INITIAL.
        LOOP AT lt_create_ar01 ASSIGNING FIELD-SYMBOL(<created_ar01>).
          APPEND VALUE #(
            %tky = <created_ar01>-%tky
            %msg = new_message_with_text(
              severity = if_abap_behv_message=>severity-success
              text     = 'AR-01 parameters created successfully'
            )
          ) TO reported-subscription.
        ENDLOOP.
      ENDIF.
    ENDIF.

    " Create AR02 params via composition
    IF lt_create_ar02 IS NOT INITIAL.
      MODIFY ENTITIES OF zir_drs_subscr IN LOCAL MODE
        ENTITY Subscription
          CREATE BY \_ParamAR02 FROM lt_create_ar02
        MAPPED DATA(lt_mapped_ar02)
        FAILED DATA(lt_failed_ar02)
        REPORTED DATA(lt_reported_ar02).

      " Add success/failure messages
      IF lt_failed_ar02-paramar02 IS INITIAL.
        LOOP AT lt_create_ar02 ASSIGNING FIELD-SYMBOL(<created_ar02>).
          APPEND VALUE #(
            %tky = <created_ar02>-%tky
            %msg = new_message_with_text(
              severity = if_abap_behv_message=>severity-success
              text     = 'AR-02 parameters created successfully'
            )
          ) TO reported-subscription.
        ENDLOOP.
      ENDIF.
    ENDIF.

    " Create AR03 params via composition
    IF lt_create_ar03 IS NOT INITIAL.
      MODIFY ENTITIES OF zir_drs_subscr IN LOCAL MODE
        ENTITY Subscription
          CREATE BY \_ParamAR03 FROM lt_create_ar03
        MAPPED DATA(lt_mapped_ar03)
        FAILED DATA(lt_failed_ar03)
        REPORTED DATA(lt_reported_ar03).

      " Add success/failure messages
      IF lt_failed_ar03-paramar03 IS INITIAL.
        LOOP AT lt_create_ar03 ASSIGNING FIELD-SYMBOL(<created_ar03>).
          APPEND VALUE #(
            %tky = <created_ar03>-%tky
            %msg = new_message_with_text(
              severity = if_abap_behv_message=>severity-success
              text     = 'AR-03 parameters created successfully'
            )
          ) TO reported-subscription.
        ENDLOOP.
      ENDIF.
    ENDIF.
    "========================================================================

    "===================AP Report Parameter==================================
    " Create AP01 params via composition
    IF lt_create_ap01 IS NOT INITIAL.
      MODIFY ENTITIES OF zir_drs_subscr IN LOCAL MODE
        ENTITY Subscription
          CREATE BY \_ParamAP01 FROM lt_create_ap01
        MAPPED DATA(lt_mapped_ap01)
        FAILED DATA(lt_failed_ap01)
        REPORTED DATA(lt_reported_ap01).

      " Add success/failure messages
      IF lt_failed_ap01-paramap01 IS INITIAL.
        LOOP AT lt_create_ap01 ASSIGNING FIELD-SYMBOL(<created_ap01>).
          APPEND VALUE #(
            %tky = <created_ap01>-%tky
            %msg = new_message_with_text(
              severity = if_abap_behv_message=>severity-success
              text     = 'AP-01 parameters created successfully'
            )
          ) TO reported-subscription.
        ENDLOOP.
      ENDIF.
    ENDIF.

    " Create AP02 params via composition
    IF lt_create_ap02 IS NOT INITIAL.
      MODIFY ENTITIES OF zir_drs_subscr IN LOCAL MODE
        ENTITY Subscription
          CREATE BY \_ParamAP02 FROM lt_create_ap02
        MAPPED DATA(lt_mapped_ap02)
        FAILED DATA(lt_failed_ap02)
        REPORTED DATA(lt_reported_ap02).

      " Add success/failure messages
      IF lt_failed_ap02-paramap02 IS INITIAL.
        LOOP AT lt_create_ap02 ASSIGNING FIELD-SYMBOL(<created_ap02>).
          APPEND VALUE #(
            %tky = <created_ap02>-%tky
            %msg = new_message_with_text(
              severity = if_abap_behv_message=>severity-success
              text     = 'AP-02 parameters created successfully'
            )
          ) TO reported-subscription.
        ENDLOOP.
      ENDIF.
    ENDIF.

    " Create AP03 params via composition
    IF lt_create_ap03 IS NOT INITIAL.
      MODIFY ENTITIES OF zir_drs_subscr IN LOCAL MODE
        ENTITY Subscription
          CREATE BY \_ParamAP03 FROM lt_create_ap03
        MAPPED DATA(lt_mapped_ap03)
        FAILED DATA(lt_failed_ap03)
        REPORTED DATA(lt_reported_ap03).

      " Add success/failure messages
      IF lt_failed_ap03-paramap03 IS INITIAL.
        LOOP AT lt_create_ap03 ASSIGNING FIELD-SYMBOL(<created_ap03>).
          APPEND VALUE #(
            %tky = <created_ap03>-%tky
            %msg = new_message_with_text(
              severity = if_abap_behv_message=>severity-success
              text     = 'AP-03 parameters created successfully'
            )
          ) TO reported-subscription.
        ENDLOOP.
      ENDIF.
    ENDIF.
    "========================================================================

    " Return result - re-read to get fresh data
    READ ENTITIES OF zir_drs_subscr IN LOCAL MODE
      ENTITY Subscription
        ALL FIELDS WITH CORRESPONDING #( keys )
      RESULT DATA(lt_result).

    result = VALUE #( FOR ls IN lt_result
                      ( %tky = ls-%tky
                        %param = CORRESPONDING #( ls ) ) ).
  ENDMETHOD.

ENDCLASS.
