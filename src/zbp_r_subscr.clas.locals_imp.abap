*&---------------------------------------------------------------------*
*& Local Classes for Subscription Behavior
*& COMPOSITION: ParamGL01 is child entity (lifecycle managed by parent)
*&---------------------------------------------------------------------*
CLASS LHC_SUBSCRIPTION DEFINITION INHERITING FROM CL_ABAP_BEHAVIOR_HANDLER.
  PRIVATE SECTION.
    TYPES:
      TY_FAILED_SUB   TYPE TABLE FOR FAILED EARLY ZIR_DRS_SUBSCR,
      TY_REPORTED_SUB TYPE TABLE FOR REPORTED EARLY ZIR_DRS_SUBSCR.

    METHODS GET_GLOBAL_AUTHORIZATIONS FOR GLOBAL AUTHORIZATION
      IMPORTING REQUEST REQUESTED_AUTHORIZATIONS FOR Subscription RESULT RESULT.

    METHODS GET_INSTANCE_AUTHORIZATIONS FOR INSTANCE AUTHORIZATION
      IMPORTING KEYS REQUEST REQUESTED_AUTHORIZATIONS FOR Subscription RESULT RESULT.

    METHODS GET_INSTANCE_FEATURES FOR INSTANCE FEATURES
      IMPORTING KEYS REQUEST REQUESTED_FEATURES FOR Subscription RESULT RESULT.

    METHODS EARLYNUMBERING_CREATE FOR NUMBERING
      IMPORTING ENTITIES FOR CREATE Subscription.

    METHODS copySubscription FOR MODIFY
      IMPORTING KEYS FOR ACTION Subscription~copySubscription RESULT RESULT.

    " US-E3-008: Pause Subscription
    METHODS pauseSubscription FOR MODIFY
      IMPORTING KEYS FOR ACTION Subscription~pauseSubscription RESULT RESULT.

    " US-E3-009: Resume Subscription
    METHODS resumeSubscription FOR MODIFY
      IMPORTING KEYS FOR ACTION Subscription~resumeSubscription RESULT RESULT.

    " Determination: Set default status on create
    METHODS setDefaultStatus FOR DETERMINE ON MODIFY
      IMPORTING KEYS FOR Subscription~setDefaultStatus.

    " NOTE: cascadeDeleteParams removed - composition handles cascade delete automatically

    " Create Report Parameters - generic action based on ReportId
    METHODS createReportParams FOR MODIFY
      IMPORTING KEYS FOR ACTION Subscription~createReportParams RESULT RESULT.


    METHODS CleanupOnReportChange FOR DETERMINE ON MODIFY
      IMPORTING KEYS FOR Subscription~CleanupOnReportChange.
    METHODS validateDescription FOR VALIDATE ON SAVE
      IMPORTING KEYS FOR Subscription~validateDescription.

    METHODS validateReport FOR VALIDATE ON SAVE
      IMPORTING KEYS FOR Subscription~validateReportID.

*    METHODS report_error
*      IMPORTING
*        tky      TYPE abp_behv_tky
*        msg      TYPE string
*      CHANGING
*        failed   TYPE ty_failed_sub
*        reported TYPE ty_reported_sub.
ENDCLASS.


CLASS LHC_SUBSCRIPTION IMPLEMENTATION.

  METHOD GET_GLOBAL_AUTHORIZATIONS.
    " ═══════════════════════════════════════════════════════════════════════════
    " GLOBAL AUTHORIZATION: Check if user can CREATE/UPDATE/DELETE subscriptions
    " LOGIC: User must have at least one report in ZDRS_REP authorization
    " NOTE: DCL handles row-level filtering (which subscriptions user can see)
    "       Global auth only checks if user has ANY report access at all
    " ═══════════════════════════════════════════════════════════════════════════

    " Allow all CRUD operations at global level
    " Row-level security is enforced by DCL (ZIR_DRS_SUBSCR access control)
    " Instance-level security is enforced by get_instance_authorizations
    RESULT = VALUE #( %CREATE = IF_ABAP_BEHV=>AUTH-ALLOWED
                      %UPDATE = IF_ABAP_BEHV=>AUTH-ALLOWED
                      %DELETE = IF_ABAP_BEHV=>AUTH-ALLOWED ).
  ENDMETHOD.


  METHOD GET_INSTANCE_AUTHORIZATIONS.
    " ═══════════════════════════════════════════════════════════════════════════
    " INSTANCE AUTHORIZATION: Check if user can UPDATE/DELETE specific subscriptions
    " CONDITIONS:
    "   1. User must be the creator (CreatedBy = current user)
    "   2. User must have access to the report (ZDRS_REP check)
    "   3. User must have access to the company code (F_BKPF_BUK check)
    " ═══════════════════════════════════════════════════════════════════════════

    " Read subscription data
    READ ENTITIES OF ZIR_DRS_SUBSCR IN LOCAL MODE
      ENTITY Subscription
        FIELDS ( SubscrUuid ReportId Bukrs CreatedBy )
        WITH CORRESPONDING #( KEYS )
      RESULT DATA(LT_SUBSCR)
      FAILED FAILED.

    " Check authorization for each subscription
    DATA LV_UPDATE_AUTH TYPE IF_ABAP_BEHV=>T_XFLAG.
    DATA LV_DELETE_AUTH TYPE IF_ABAP_BEHV=>T_XFLAG.
    DATA LV_CURRENT_USER TYPE SYUNAME.
    LV_CURRENT_USER = CL_ABAP_CONTEXT_INFO=>GET_USER_TECHNICAL_NAME( ).

    LOOP AT LT_SUBSCR ASSIGNING FIELD-SYMBOL(<LS_SUBSCR>).
      " For new drafts: fields are empty → allow editing so user can fill them
      IF <LS_SUBSCR>-CreatedBy IS INITIAL
        AND <LS_SUBSCR>-ReportId IS INITIAL.
        LV_UPDATE_AUTH = IF_ABAP_BEHV=>AUTH-ALLOWED.
        LV_DELETE_AUTH = IF_ABAP_BEHV=>AUTH-ALLOWED.

        " Condition 1: User must be creator (skip if CreatedBy not yet set)
      ELSEIF <LS_SUBSCR>-CreatedBy IS NOT INITIAL
        AND <LS_SUBSCR>-CreatedBy <> LV_CURRENT_USER.
        LV_UPDATE_AUTH = IF_ABAP_BEHV=>AUTH-UNAUTHORIZED.
        LV_DELETE_AUTH = IF_ABAP_BEHV=>AUTH-UNAUTHORIZED.

      ELSE.
        " Default: allow (covers case when CreatedBy matches current user)
        LV_UPDATE_AUTH = IF_ABAP_BEHV=>AUTH-ALLOWED.
        LV_DELETE_AUTH = IF_ABAP_BEHV=>AUTH-ALLOWED.

        " Condition 2: Check report access (only if ReportId is filled)
        IF <LS_SUBSCR>-ReportId IS NOT INITIAL.
          AUTHORITY-CHECK OBJECT 'ZDRS_REP'
            ID 'ZREP_ID' FIELD <LS_SUBSCR>-ReportId
            ID 'ACTVT'   FIELD '03'.
          IF SY-SUBRC <> 0.
            LV_UPDATE_AUTH = IF_ABAP_BEHV=>AUTH-UNAUTHORIZED.
            LV_DELETE_AUTH = IF_ABAP_BEHV=>AUTH-UNAUTHORIZED.
          ENDIF.
        ENDIF.

        " Condition 3: Check company code access (only if Bukrs is filled)
        IF LV_UPDATE_AUTH = IF_ABAP_BEHV=>AUTH-ALLOWED
          AND <LS_SUBSCR>-Bukrs IS NOT INITIAL.
          AUTHORITY-CHECK OBJECT 'F_BKPF_BUK'
            ID 'BUKRS' FIELD <LS_SUBSCR>-Bukrs
            ID 'ACTVT' FIELD '03'.
          IF SY-SUBRC <> 0.
            LV_UPDATE_AUTH = IF_ABAP_BEHV=>AUTH-UNAUTHORIZED.
            LV_DELETE_AUTH = IF_ABAP_BEHV=>AUTH-UNAUTHORIZED.
          ENDIF.
        ENDIF.
      ENDIF.

      " Add result
      APPEND VALUE #( %TKY = <LS_SUBSCR>-%TKY
                      %UPDATE = LV_UPDATE_AUTH
                      %DELETE = LV_DELETE_AUTH
                      " Actions inherit update authorization
                      %ACTION-pauseSubscription = LV_UPDATE_AUTH
                      %ACTION-resumeSubscription = LV_UPDATE_AUTH
                      %ACTION-copySubscription = LV_UPDATE_AUTH
                      %ACTION-createReportParams = LV_UPDATE_AUTH )
             TO RESULT.
    ENDLOOP.
  ENDMETHOD.

  METHOD GET_INSTANCE_FEATURES.
    " Read ReportID of Subscription
    READ ENTITIES OF ZIR_DRS_SUBSCR IN LOCAL MODE
      ENTITY Subscription
        FIELDS ( ReportId ) WITH CORRESPONDING #( KEYS )
      RESULT DATA(LT_SUBSCRIPTIONS).


    LOOP AT LT_SUBSCRIPTIONS ASSIGNING FIELD-SYMBOL(<FS_SUB>).
      DATA(LV_IS_LOCKED) = ABAP_FALSE.

      " Check if ReportID is created
      CASE <FS_SUB>-ReportId.
        WHEN 'GL-01'.
          READ ENTITIES OF ZIR_DRS_SUBSCR IN LOCAL MODE
            ENTITY Subscription BY \_ParamGL01
            FIELDS ( SubscrUuid ) WITH VALUE #( ( %TKY = <FS_SUB>-%TKY ) )
            RESULT DATA(LT_GL01).
          "if ReportID was created, lock ReportID field
          IF LT_GL01 IS NOT INITIAL. LV_IS_LOCKED = ABAP_TRUE. ENDIF.

        WHEN 'AR-01'.
          READ ENTITIES OF ZIR_DRS_SUBSCR IN LOCAL MODE
            ENTITY Subscription BY \_ParamAR01
            FIELDS ( SubscrUuid ) WITH VALUE #( ( %TKY = <FS_SUB>-%TKY ) )
            RESULT DATA(LT_AR01).
          "if ReportID was created, lock ReportID field
          IF LT_AR01 IS NOT INITIAL. LV_IS_LOCKED = ABAP_TRUE. ENDIF.

        WHEN 'AR-02'.
          READ ENTITIES OF ZIR_DRS_SUBSCR IN LOCAL MODE
            ENTITY Subscription BY \_ParamAR02
            FIELDS ( SubscrUuid ) WITH VALUE #( ( %TKY = <FS_SUB>-%TKY ) )
            RESULT DATA(LT_AR02).
          "if ReportID was created, lock ReportID field
          IF LT_AR02 IS NOT INITIAL. LV_IS_LOCKED = ABAP_TRUE. ENDIF.

        WHEN 'AR-03'.
          READ ENTITIES OF ZIR_DRS_SUBSCR IN LOCAL MODE
            ENTITY Subscription BY \_ParamAR03
            FIELDS ( SubscrUuid ) WITH VALUE #( ( %TKY = <FS_SUB>-%TKY ) )
            RESULT DATA(LT_AR03).
          "if ReportID was created, lock ReportID field
          IF LT_AR03 IS NOT INITIAL. LV_IS_LOCKED = ABAP_TRUE. ENDIF.

        WHEN 'AP-01'.
          READ ENTITIES OF ZIR_DRS_SUBSCR IN LOCAL MODE
            ENTITY Subscription BY \_ParamAP01
            FIELDS ( SubscrUuid ) WITH VALUE #( ( %TKY = <FS_SUB>-%TKY ) )
            RESULT DATA(LT_AP01).
          "if ReportID was created, lock ReportID field
          IF LT_AP01 IS NOT INITIAL. LV_IS_LOCKED = ABAP_TRUE. ENDIF.

        WHEN 'AP-02'.
          READ ENTITIES OF ZIR_DRS_SUBSCR IN LOCAL MODE
            ENTITY Subscription BY \_ParamAP02
            FIELDS ( SubscrUuid ) WITH VALUE #( ( %TKY = <FS_SUB>-%TKY ) )
            RESULT DATA(LT_AP02).
          "if ReportID was created, lock ReportID field
          IF LT_AP02 IS NOT INITIAL. LV_IS_LOCKED = ABAP_TRUE. ENDIF.

        WHEN 'AP-03'.
          READ ENTITIES OF ZIR_DRS_SUBSCR IN LOCAL MODE
            ENTITY Subscription BY \_ParamAP03
            FIELDS ( SubscrUuid ) WITH VALUE #( ( %TKY = <FS_SUB>-%TKY ) )
            RESULT DATA(LT_AP03).
          "if ReportID was created, lock ReportID field
          IF LT_AP03 IS NOT INITIAL. LV_IS_LOCKED = ABAP_TRUE. ENDIF.

      ENDCASE.

      " Render for UI (locking ReportID field)
      APPEND VALUE #(
        %TKY = <FS_SUB>-%TKY
        %FIELD-ReportId = COND #(
          WHEN LV_IS_LOCKED = ABAP_TRUE
          THEN IF_ABAP_BEHV=>FC-F-READ_ONLY
          ELSE IF_ABAP_BEHV=>FC-F-UNRESTRICTED
        )
      ) TO RESULT.

    ENDLOOP.
  ENDMETHOD.


  METHOD EARLYNUMBERING_CREATE.
    " Generate UUID and Subscription ID for new subscriptions
    DATA: LV_SUBSCR_ID TYPE N LENGTH 6,
          LV_UUID      TYPE SYSUUID_X16,
          LV_ID        TYPE N LENGTH 6.

    " Get max subscr_id from DB and increment
    SELECT MAX( SUBSCR_ID ) FROM ZDRS_SUBSCR INTO @DATA(LV_MAX_ID).
    LV_SUBSCR_ID = LV_MAX_ID + 1.

    " MUST return mapped for ALL entities (including draft)
    LOOP AT ENTITIES ASSIGNING FIELD-SYMBOL(<ENTITY>).
      " Generate UUID if not provided
      IF <ENTITY>-SubscrUuid IS INITIAL.
        LV_UUID = CL_SYSTEM_UUID=>CREATE_UUID_X16_STATIC( ).
      ELSE.
        LV_UUID = <ENTITY>-SubscrUuid.
      ENDIF.

      " Use provided SubscrId or generate new one
      IF <ENTITY>-SubscrId IS INITIAL.
        LV_ID = LV_SUBSCR_ID.
        LV_SUBSCR_ID = LV_SUBSCR_ID + 1.
      ELSE.
        LV_ID = <ENTITY>-SubscrId.
      ENDIF.

      " Assign to mapped response - include %is_draft for draft-enabled BO
      APPEND VALUE #( %CID       = <ENTITY>-%CID
                      %IS_DRAFT  = <ENTITY>-%IS_DRAFT
                      SubscrUuid = LV_UUID
                      SubscrId   = LV_ID )
             TO MAPPED-SUBSCRIPTION.
    ENDLOOP.
  ENDMETHOD.


  METHOD setDefaultStatus.
    " Set status to 'A' (Active) when subscription is created
    READ ENTITIES OF ZIR_DRS_SUBSCR IN LOCAL MODE
      ENTITY Subscription
        FIELDS ( Status ) WITH CORRESPONDING #( KEYS )
      RESULT DATA(LT_SUBSCR).

    " Filter only records without status
    DATA LT_UPDATE TYPE TABLE FOR UPDATE ZIR_DRS_SUBSCR.
    LOOP AT LT_SUBSCR ASSIGNING FIELD-SYMBOL(<SUBSCR>) WHERE Status IS INITIAL.
      APPEND VALUE #( %TKY = <SUBSCR>-%TKY   " Include %is_draft for draft-enabled BO
                      Status = 'A' )         " A = Active
             TO LT_UPDATE.
    ENDLOOP.

    IF LT_UPDATE IS NOT INITIAL.
      MODIFY ENTITIES OF ZIR_DRS_SUBSCR IN LOCAL MODE
        ENTITY Subscription
          UPDATE FIELDS ( Status ) WITH LT_UPDATE
        REPORTED DATA(LT_REPORTED).
    ENDIF.
  ENDMETHOD.


  METHOD pauseSubscription.
    " US-E3-008: Pause subscription (stops new job scheduling)
    " Subscription Status: A (Active) → P (Paused)

    " Read current subscriptions
    READ ENTITIES OF ZIR_DRS_SUBSCR IN LOCAL MODE
      ENTITY Subscription
        ALL FIELDS WITH CORRESPONDING #( KEYS )
      RESULT DATA(LT_SUBSCR)
      FAILED FAILED.

    " Build update table
    DATA LT_UPDATE TYPE TABLE FOR UPDATE ZIR_DRS_SUBSCR.
    LOOP AT LT_SUBSCR ASSIGNING FIELD-SYMBOL(<SUBSCR>).
      " Only pause if currently Active
      IF <SUBSCR>-Status = 'A'.
        APPEND VALUE #( %TKY   = <SUBSCR>-%TKY
                        Status = 'P' )  " P = Paused
               TO LT_UPDATE.
      ENDIF.
    ENDLOOP.

    " Execute update
    IF LT_UPDATE IS NOT INITIAL.
      MODIFY ENTITIES OF ZIR_DRS_SUBSCR IN LOCAL MODE
        ENTITY Subscription
          UPDATE FIELDS ( Status ) WITH LT_UPDATE
        REPORTED REPORTED.
    ENDIF.

    " Return result
    READ ENTITIES OF ZIR_DRS_SUBSCR IN LOCAL MODE
      ENTITY Subscription
        ALL FIELDS WITH CORRESPONDING #( KEYS )
      RESULT DATA(LT_RESULT).

    RESULT = VALUE #( FOR LS IN LT_RESULT
                      ( %TKY = LS-%TKY
                        %PARAM = CORRESPONDING #( LS ) ) ).
  ENDMETHOD.


  METHOD resumeSubscription.
    " US-E3-009: Resume subscription (allows new job scheduling)
    " Subscription Status: P (Paused) → A (Active)

    " Read current subscriptions
    READ ENTITIES OF ZIR_DRS_SUBSCR IN LOCAL MODE
      ENTITY Subscription
        ALL FIELDS WITH CORRESPONDING #( KEYS )
      RESULT DATA(LT_SUBSCR)
      FAILED FAILED.

    " Build update table
    DATA LT_UPDATE TYPE TABLE FOR UPDATE ZIR_DRS_SUBSCR.
    LOOP AT LT_SUBSCR ASSIGNING FIELD-SYMBOL(<SUBSCR>).
      " Only resume if currently Paused
      IF <SUBSCR>-Status = 'P'.
        APPEND VALUE #( %TKY   = <SUBSCR>-%TKY
                        Status = 'A' )  " A = Active
               TO LT_UPDATE.
      ENDIF.
    ENDLOOP.

    " Execute update
    IF LT_UPDATE IS NOT INITIAL.
      MODIFY ENTITIES OF ZIR_DRS_SUBSCR IN LOCAL MODE
        ENTITY Subscription
          UPDATE FIELDS ( Status ) WITH LT_UPDATE
        REPORTED REPORTED.
    ENDIF.

    " Return result
    READ ENTITIES OF ZIR_DRS_SUBSCR IN LOCAL MODE
      ENTITY Subscription
        ALL FIELDS WITH CORRESPONDING #( KEYS )
      RESULT DATA(LT_RESULT).

    RESULT = VALUE #( FOR LS IN LT_RESULT
                      ( %TKY = LS-%TKY
                        %PARAM = CORRESPONDING #( LS ) ) ).
  ENDMETHOD.


  METHOD copySubscription.
    " ═══════════════════════════════════════════════════════════════════════════
    " Copy existing subscription with its GL01 parameters
    " Uses composition - creates ParamGL01 via _ParamGL01 association
    " ═══════════════════════════════════════════════════════════════════════════

    " Read source subscriptions
    READ ENTITIES OF ZIR_DRS_SUBSCR IN LOCAL MODE
      ENTITY Subscription
        ALL FIELDS WITH CORRESPONDING #( KEYS )
      RESULT DATA(LT_SOURCE_SUBSCR)
      FAILED DATA(LT_FAILED).

    IF LT_FAILED IS NOT INITIAL.
      FAILED = CORRESPONDING #( DEEP LT_FAILED ).
      RETURN.
    ENDIF.

    " Read associated GL01 parameters via composition
    READ ENTITIES OF ZIR_DRS_SUBSCR IN LOCAL MODE
      ENTITY Subscription BY \_ParamGL01
        ALL FIELDS WITH CORRESPONDING #( KEYS )
      RESULT DATA(LT_SOURCE_GL01).

    " Get max subscr_id for new ID generation
    SELECT MAX( SUBSCR_ID ) FROM ZDRS_SUBSCR INTO @DATA(LV_MAX_ID).
    DATA(LV_NEW_SUBSCR_ID) = LV_MAX_ID + 1.

    " Create subscription copies with nested ParamGL01 via composition
    DATA LT_SUBSCR TYPE TABLE FOR CREATE ZIR_DRS_SUBSCR.
    DATA LT_PARAM_GL01 TYPE TABLE FOR CREATE ZIR_DRS_SUBSCR\_ParamGL01.

    DATA(LV_IDX) = 0.
    LOOP AT LT_SOURCE_SUBSCR ASSIGNING FIELD-SYMBOL(<SOURCE>).
      LV_IDX = LV_IDX + 1.
      DATA(LV_NEW_UUID) = CL_SYSTEM_UUID=>CREATE_UUID_X16_STATIC( ).
      DATA(LV_CID) = |COPY{ LV_IDX }|.

      " Create subscription
      APPEND VALUE #( %CID = LV_CID
                      SubscrUuid = LV_NEW_UUID
                      SubscrId = LV_NEW_SUBSCR_ID
                      SubscrName = |Copy of { <SOURCE>-SubscrName }|
                      ReportId = <SOURCE>-ReportId
                      Bukrs = <SOURCE>-Bukrs
                      OutputFormat = <SOURCE>-OutputFormat
                      EmailTo = <SOURCE>-EmailTo
                      EmailCc = <SOURCE>-EmailCc )
             TO LT_SUBSCR.

      " Create GL01 params via composition (keys inherited from parent)
      LOOP AT LT_SOURCE_GL01 ASSIGNING FIELD-SYMBOL(<GL01>)
           WHERE SubscrUuid = <SOURCE>-SubscrUuid.
        APPEND VALUE #( %CID_REF = LV_CID
                        %TARGET = VALUE #( (
                          %CID        = |GL01_{ LV_IDX }|
                          %IS_DRAFT   = <SOURCE>-%IS_DRAFT
                          CompanyCode = <GL01>-CompanyCode
*                          FiscalYear  = <gl01>-FiscalYear
*                          FiscalPeriod = <gl01>-FiscalPeriod
*                          Currency    = <gl01>-Currency
*                          GlAccount   = <gl01>-GlAccount
                          MaxRows     = <GL01>-MaxRows ) ) )
               TO LT_PARAM_GL01.
      ENDLOOP.

      LV_NEW_SUBSCR_ID = LV_NEW_SUBSCR_ID + 1.
    ENDLOOP.

    " Create subscriptions via RAP
    MODIFY ENTITIES OF ZIR_DRS_SUBSCR IN LOCAL MODE
      ENTITY Subscription
        CREATE FROM LT_SUBSCR
        CREATE BY \_ParamGL01 FROM LT_PARAM_GL01
      MAPPED DATA(LT_MAPPED)
      FAILED DATA(LT_CREATE_FAILED)
      REPORTED DATA(LT_REPORTED).

    " Return result - re-read source entities (action result = $self)
    READ ENTITIES OF ZIR_DRS_SUBSCR IN LOCAL MODE
      ENTITY Subscription
        ALL FIELDS WITH CORRESPONDING #( KEYS )
      RESULT DATA(LT_RESULT).

    RESULT = VALUE #( FOR LS IN LT_RESULT
                      ( %TKY = LS-%TKY
                        %PARAM = CORRESPONDING #( LS ) ) ).
  ENDMETHOD.


  METHOD createReportParams.
    " ═══════════════════════════════════════════════════════════════════════════
    " CREATE REPORT PARAMETERS: Generic action based on ReportId
    " Uses composition - creates ParamGL01 via _ParamGL01 association
    " GL-01 → _ParamGL01, GL-02 → _ParamGL02 (future), etc.
    " ═══════════════════════════════════════════════════════════════════════════

    " Read subscription data to get ReportId and Bukrs (for default CompanyCode)
    READ ENTITIES OF ZIR_DRS_SUBSCR IN LOCAL MODE
      ENTITY Subscription
        FIELDS ( SubscrUuid SubscrId ReportId Bukrs )
        WITH CORRESPONDING #( KEYS )
      RESULT DATA(LT_SUBSCR)
      FAILED FAILED.

    " Read existing GL01 params via composition
    READ ENTITIES OF ZIR_DRS_SUBSCR IN LOCAL MODE
      ENTITY Subscription BY \_ParamGL01
        FIELDS ( SubscrUuid ) WITH CORRESPONDING #( KEYS )
      RESULT DATA(LT_EXISTING_GL01).

    DATA LT_CREATE_GL01 TYPE TABLE FOR CREATE ZIR_DRS_SUBSCR\_ParamGL01.

    "===================AR Report Parameter==================================
    " Read existing AR01 params via composition
    READ ENTITIES OF ZIR_DRS_SUBSCR IN LOCAL MODE
      ENTITY Subscription BY \_ParamAR01
        FIELDS ( SubscrUuid ) WITH CORRESPONDING #( KEYS )
      RESULT DATA(LT_EXISTING_AR01).

    DATA LT_CREATE_AR01 TYPE TABLE FOR CREATE ZIR_DRS_SUBSCR\_ParamAR01.

    " Read existing AR02 params via composition
    READ ENTITIES OF ZIR_DRS_SUBSCR IN LOCAL MODE
      ENTITY Subscription BY \_ParamAR02
        FIELDS ( SubscrUuid ) WITH CORRESPONDING #( KEYS )
      RESULT DATA(LT_EXISTING_AR02).


    DATA LT_CREATE_AR02 TYPE TABLE FOR CREATE ZIR_DRS_SUBSCR\_ParamAR02.

    " Read existing AR03 params via composition
    READ ENTITIES OF ZIR_DRS_SUBSCR IN LOCAL MODE
      ENTITY Subscription BY \_ParamAR03
        FIELDS ( SubscrUuid ) WITH CORRESPONDING #( KEYS )
      RESULT DATA(LT_EXISTING_AR03).


    DATA LT_CREATE_AR03 TYPE TABLE FOR CREATE ZIR_DRS_SUBSCR\_ParamAR03.
    "=======================================================================

    "===================AP Report Parameter==================================
    " Read existing AP01 params via composition
    READ ENTITIES OF ZIR_DRS_SUBSCR IN LOCAL MODE
      ENTITY Subscription BY \_ParamAP01
        FIELDS ( SubscrUuid ) WITH CORRESPONDING #( KEYS )
      RESULT DATA(LT_EXISTING_AP01).

    DATA LT_CREATE_AP01 TYPE TABLE FOR CREATE ZIR_DRS_SUBSCR\_ParamAP01.

    " Read existing AP02 params via composition
    READ ENTITIES OF ZIR_DRS_SUBSCR IN LOCAL MODE
      ENTITY Subscription BY \_ParamAP02
        FIELDS ( SubscrUuid ) WITH CORRESPONDING #( KEYS )
      RESULT DATA(LT_EXISTING_AP02).


    DATA LT_CREATE_AP02 TYPE TABLE FOR CREATE ZIR_DRS_SUBSCR\_ParamAP02.

    " Read existing AR03 params via composition
    READ ENTITIES OF ZIR_DRS_SUBSCR IN LOCAL MODE
      ENTITY Subscription BY \_ParamAP03
        FIELDS ( SubscrUuid ) WITH CORRESPONDING #( KEYS )
      RESULT DATA(LT_EXISTING_AP03).


    DATA LT_CREATE_AP03 TYPE TABLE FOR CREATE ZIR_DRS_SUBSCR\_ParamAP03.
    "=======================================================================


    LOOP AT LT_SUBSCR ASSIGNING FIELD-SYMBOL(<SUBSCR>).
      CASE <SUBSCR>-ReportId.
        WHEN 'GL-01'.
          " Check if already exists
          READ TABLE LT_EXISTING_GL01 WITH KEY SubscrUuid = <SUBSCR>-SubscrUuid TRANSPORTING NO FIELDS.
          IF SY-SUBRC = 0.
            " Already exists - report info message
            APPEND VALUE #(
              %TKY = CORRESPONDING #( <SUBSCR> )
              %MSG = NEW_MESSAGE_WITH_TEXT(
                SEVERITY = IF_ABAP_BEHV_MESSAGE=>SEVERITY-INFORMATION
                TEXT     = 'GL-01 parameters already exist for this subscription'
              )
            ) TO REPORTED-SUBSCRIPTION.
          ELSE.
            " Create via composition (keys inherited from parent, %cid required)
            " %is_draft MUST match parent to avoid ACTIVE/DRAFT mixture dump
            APPEND VALUE #(
              %TKY = CORRESPONDING #( <SUBSCR> )
              %TARGET = VALUE #( (
                %CID        = |GL01_{ SY-TABIX }|
                %IS_DRAFT   = <SUBSCR>-%IS_DRAFT
                CompanyCode = <SUBSCR>-Bukrs  " Default from subscription
                MaxRows     = 1000 ) )        " Default max rows
            ) TO LT_CREATE_GL01.
          ENDIF.
          "===================AR Report Parameter==================================
        WHEN 'AR-01'.
          " Check if already exists
          READ TABLE LT_EXISTING_AR01 WITH KEY SubscrUuid = <SUBSCR>-SubscrUuid TRANSPORTING NO FIELDS.
          IF SY-SUBRC = 0.
            " Already exists - report info message
            APPEND VALUE #(
              %TKY = CORRESPONDING #( <SUBSCR> )
              %MSG = NEW_MESSAGE_WITH_TEXT(
                SEVERITY = IF_ABAP_BEHV_MESSAGE=>SEVERITY-INFORMATION
                TEXT     = 'AR-01 parameters already exist for this subscription'
              )
            ) TO REPORTED-SUBSCRIPTION.
          ELSE.
            " Create via composition (keys inherited from parent, %cid required)
            " %is_draft MUST match parent to avoid ACTIVE/DRAFT mixture dump
            APPEND VALUE #(
              %TKY = CORRESPONDING #( <SUBSCR> )
              %TARGET = VALUE #( (
                %CID        = |AR01_{ SY-TABIX }|
                %IS_DRAFT   = <SUBSCR>-%IS_DRAFT
                CompanyCode = <SUBSCR>-Bukrs  " Default from subscription
                MaxRows     = 1000 ) )        " Default max rows
            ) TO LT_CREATE_AR01.
          ENDIF.
        WHEN 'AR-02'.
          " Check if already exists
          READ TABLE LT_EXISTING_AR02 WITH KEY SubscrUuid = <SUBSCR>-SubscrUuid TRANSPORTING NO FIELDS.
          IF SY-SUBRC = 0.
            " Already exists - report info message
            APPEND VALUE #(
              %TKY = CORRESPONDING #( <SUBSCR> )
              %MSG = NEW_MESSAGE_WITH_TEXT(
                SEVERITY = IF_ABAP_BEHV_MESSAGE=>SEVERITY-INFORMATION
                TEXT     = 'AR-02 parameters already exist for this subscription'
              )
            ) TO REPORTED-SUBSCRIPTION.
          ELSE.
            " Create via composition (keys inherited from parent, %cid required)
            " %is_draft MUST match parent to avoid ACTIVE/DRAFT mixture dump
            APPEND VALUE #(
              %TKY = CORRESPONDING #( <SUBSCR> )
              %TARGET = VALUE #( (
                %CID        = |AR02_{ SY-TABIX }|
                %IS_DRAFT   = <SUBSCR>-%IS_DRAFT
                CompanyCode = <SUBSCR>-Bukrs  " Default from subscription
                MaxRows     = 1000 ) )        " Default max rows
            ) TO LT_CREATE_AR02.
          ENDIF.
        WHEN 'AR-03'.
          " Check if already exists
          READ TABLE LT_EXISTING_AR03 WITH KEY SubscrUuid = <SUBSCR>-SubscrUuid TRANSPORTING NO FIELDS.
          IF SY-SUBRC = 0.
            " Already exists - report info message
            APPEND VALUE #(
              %TKY = CORRESPONDING #( <SUBSCR> )
              %MSG = NEW_MESSAGE_WITH_TEXT(
                SEVERITY = IF_ABAP_BEHV_MESSAGE=>SEVERITY-INFORMATION
                TEXT     = 'AR-03 parameters already exist for this subscription'
              )
            ) TO REPORTED-SUBSCRIPTION.
          ELSE.
            " Create via composition (keys inherited from parent, %cid required)
            " %is_draft MUST match parent to avoid ACTIVE/DRAFT mixture dump
            APPEND VALUE #(
              %TKY = CORRESPONDING #( <SUBSCR> )
              %TARGET = VALUE #( (
                %CID        = |AR03_{ SY-TABIX }|
                %IS_DRAFT   = <SUBSCR>-%IS_DRAFT
                CompanyCode = <SUBSCR>-Bukrs  " Default from subscription
                MaxRows     = 1000 ) )        " Default max rows
            ) TO LT_CREATE_AR03.
          ENDIF.
          "========================================================================

          "===================AP Report Parameter==================================
        WHEN 'AP-01'.
          " Check if already exists
          READ TABLE LT_EXISTING_AP01 WITH KEY SubscrUuid = <SUBSCR>-SubscrUuid TRANSPORTING NO FIELDS.
          IF SY-SUBRC = 0.
            " Already exists - report info message
            APPEND VALUE #(
              %TKY = CORRESPONDING #( <SUBSCR> )
              %MSG = NEW_MESSAGE_WITH_TEXT(
                SEVERITY = IF_ABAP_BEHV_MESSAGE=>SEVERITY-INFORMATION
                TEXT     = 'AP-01 parameters already exist for this subscription'
              )
            ) TO REPORTED-SUBSCRIPTION.
          ELSE.
            " Create via composition (keys inherited from parent, %cid required)
            " %is_draft MUST match parent to avoid ACTIVE/DRAFT mixture dump
            APPEND VALUE #(
              %TKY = CORRESPONDING #( <SUBSCR> )
              %TARGET = VALUE #( (
                %CID        = |AP01_{ SY-TABIX }|
                %IS_DRAFT   = <SUBSCR>-%IS_DRAFT
                CompanyCode = <SUBSCR>-Bukrs  " Default from subscription
                MaxRows     = 1000 ) )        " Default max rows
            ) TO LT_CREATE_AP01.
          ENDIF.
        WHEN 'AP-02'.
          " Check if already exists
          READ TABLE LT_EXISTING_AP02 WITH KEY SubscrUuid = <SUBSCR>-SubscrUuid TRANSPORTING NO FIELDS.
          IF SY-SUBRC = 0.
            " Already exists - report info message
            APPEND VALUE #(
              %TKY = CORRESPONDING #( <SUBSCR> )
              %MSG = NEW_MESSAGE_WITH_TEXT(
                SEVERITY = IF_ABAP_BEHV_MESSAGE=>SEVERITY-INFORMATION
                TEXT     = 'AP-02 parameters already exist for this subscription'
              )
            ) TO REPORTED-SUBSCRIPTION.
          ELSE.
            " Create via composition (keys inherited from parent, %cid required)
            " %is_draft MUST match parent to avoid ACTIVE/DRAFT mixture dump
            APPEND VALUE #(
              %TKY = CORRESPONDING #( <SUBSCR> )
              %TARGET = VALUE #( (
                %CID        = |AP02_{ SY-TABIX }|
                %IS_DRAFT   = <SUBSCR>-%IS_DRAFT
                CompanyCode = <SUBSCR>-Bukrs  " Default from subscription
                MaxRows     = 1000 ) )        " Default max rows
            ) TO LT_CREATE_AP02.
          ENDIF.
        WHEN 'AP-03'.
          " Check if already exists
          READ TABLE LT_EXISTING_AP03 WITH KEY SubscrUuid = <SUBSCR>-SubscrUuid TRANSPORTING NO FIELDS.
          IF SY-SUBRC = 0.
            " Already exists - report info message
            APPEND VALUE #(
              %TKY = CORRESPONDING #( <SUBSCR> )
              %MSG = NEW_MESSAGE_WITH_TEXT(
                SEVERITY = IF_ABAP_BEHV_MESSAGE=>SEVERITY-INFORMATION
                TEXT     = 'AP-03 parameters already exist for this subscription'
              )
            ) TO REPORTED-SUBSCRIPTION.
          ELSE.
            " Create via composition (keys inherited from parent, %cid required)
            " %is_draft MUST match parent to avoid ACTIVE/DRAFT mixture dump
            APPEND VALUE #(
              %TKY = CORRESPONDING #( <SUBSCR> )
              %TARGET = VALUE #( (
                %CID        = |AP03_{ SY-TABIX }|
                %IS_DRAFT   = <SUBSCR>-%IS_DRAFT
                CompanyCode = <SUBSCR>-Bukrs  " Default from subscription
                MaxRows     = 1000 ) )        " Default max rows
            ) TO LT_CREATE_AP03.
          ENDIF.
          "========================================================================
*        WHEN 'GL-02'.
*          " TODO: Implement GL-02 parameter creation via _ParamGL02

        WHEN OTHERS.
          APPEND VALUE #(
            %TKY = CORRESPONDING #( <SUBSCR> )
            %MSG = NEW_MESSAGE_WITH_TEXT(
              SEVERITY = IF_ABAP_BEHV_MESSAGE=>SEVERITY-WARNING
              TEXT     = |Report type { <SUBSCR>-ReportId } does not have configurable parameters|
            )
          ) TO REPORTED-SUBSCRIPTION.
      ENDCASE.
    ENDLOOP.

    " Create GL01 params via composition
    IF LT_CREATE_GL01 IS NOT INITIAL.
      MODIFY ENTITIES OF ZIR_DRS_SUBSCR IN LOCAL MODE
        ENTITY Subscription
          CREATE BY \_ParamGL01 FROM LT_CREATE_GL01
        MAPPED DATA(LT_MAPPED)
        FAILED DATA(LT_CREATE_FAILED)
        REPORTED DATA(LT_CREATE_REPORTED).

      " Add success/failure messages
      IF LT_CREATE_FAILED-PARAMGL01 IS INITIAL.
        LOOP AT LT_CREATE_GL01 ASSIGNING FIELD-SYMBOL(<CREATED>).
          APPEND VALUE #(
            %TKY = <CREATED>-%TKY
            %MSG = NEW_MESSAGE_WITH_TEXT(
              SEVERITY = IF_ABAP_BEHV_MESSAGE=>SEVERITY-SUCCESS
              TEXT     = 'GL-01 parameters created successfully'
            )
          ) TO REPORTED-SUBSCRIPTION.
        ENDLOOP.
      ENDIF.
    ENDIF.

    "===================AR Report Parameter==================================
    " Create AR01 params via composition
    IF LT_CREATE_AR01 IS NOT INITIAL.
      MODIFY ENTITIES OF ZIR_DRS_SUBSCR IN LOCAL MODE
        ENTITY Subscription
          CREATE BY \_ParamAR01 FROM LT_CREATE_AR01
        MAPPED DATA(LT_MAPPED_AR01)
        FAILED DATA(LT_FAILED_AR01)
        REPORTED DATA(LT_REPORTED_AR01).

      " Add success/failure messages
      IF LT_FAILED_AR01-PARAMAR01 IS INITIAL.
        LOOP AT LT_CREATE_AR01 ASSIGNING FIELD-SYMBOL(<CREATED_AR01>).
          APPEND VALUE #(
            %TKY = <CREATED_AR01>-%TKY
            %MSG = NEW_MESSAGE_WITH_TEXT(
              SEVERITY = IF_ABAP_BEHV_MESSAGE=>SEVERITY-SUCCESS
              TEXT     = 'AR-01 parameters created successfully'
            )
          ) TO REPORTED-SUBSCRIPTION.
        ENDLOOP.
      ENDIF.
    ENDIF.

    " Create AR02 params via composition
    IF LT_CREATE_AR02 IS NOT INITIAL.
      MODIFY ENTITIES OF ZIR_DRS_SUBSCR IN LOCAL MODE
        ENTITY Subscription
          CREATE BY \_ParamAR02 FROM LT_CREATE_AR02
        MAPPED DATA(LT_MAPPED_AR02)
        FAILED DATA(LT_FAILED_AR02)
        REPORTED DATA(LT_REPORTED_AR02).

      " Add success/failure messages
      IF LT_FAILED_AR02-PARAMAR02 IS INITIAL.
        LOOP AT LT_CREATE_AR02 ASSIGNING FIELD-SYMBOL(<CREATED_AR02>).
          APPEND VALUE #(
            %TKY = <CREATED_AR02>-%TKY
            %MSG = NEW_MESSAGE_WITH_TEXT(
              SEVERITY = IF_ABAP_BEHV_MESSAGE=>SEVERITY-SUCCESS
              TEXT     = 'AR-02 parameters created successfully'
            )
          ) TO REPORTED-SUBSCRIPTION.
        ENDLOOP.
      ENDIF.
    ENDIF.

    " Create AR03 params via composition
    IF LT_CREATE_AR03 IS NOT INITIAL.
      MODIFY ENTITIES OF ZIR_DRS_SUBSCR IN LOCAL MODE
        ENTITY Subscription
          CREATE BY \_ParamAR03 FROM LT_CREATE_AR03
        MAPPED DATA(LT_MAPPED_AR03)
        FAILED DATA(LT_FAILED_AR03)
        REPORTED DATA(LT_REPORTED_AR03).

      " Add success/failure messages
      IF LT_FAILED_AR03-PARAMAR03 IS INITIAL.
        LOOP AT LT_CREATE_AR03 ASSIGNING FIELD-SYMBOL(<CREATED_AR03>).
          APPEND VALUE #(
            %TKY = <CREATED_AR03>-%TKY
            %MSG = NEW_MESSAGE_WITH_TEXT(
              SEVERITY = IF_ABAP_BEHV_MESSAGE=>SEVERITY-SUCCESS
              TEXT     = 'AR-03 parameters created successfully'
            )
          ) TO REPORTED-SUBSCRIPTION.
        ENDLOOP.
      ENDIF.
    ENDIF.
    "========================================================================

    "===================AP Report Parameter==================================
    " Create AP01 params via composition
    IF LT_CREATE_AP01 IS NOT INITIAL.
      MODIFY ENTITIES OF ZIR_DRS_SUBSCR IN LOCAL MODE
        ENTITY Subscription
          CREATE BY \_ParamAP01 FROM LT_CREATE_AP01
        MAPPED DATA(LT_MAPPED_AP01)
        FAILED DATA(LT_FAILED_AP01)
        REPORTED DATA(LT_REPORTED_AP01).

      " Add success/failure messages
      IF LT_FAILED_AP01-PARAMAP01 IS INITIAL.
        LOOP AT LT_CREATE_AP01 ASSIGNING FIELD-SYMBOL(<CREATED_AP01>).
          APPEND VALUE #(
            %TKY = <CREATED_AP01>-%TKY
            %MSG = NEW_MESSAGE_WITH_TEXT(
              SEVERITY = IF_ABAP_BEHV_MESSAGE=>SEVERITY-SUCCESS
              TEXT     = 'AP-01 parameters created successfully'
            )
          ) TO REPORTED-SUBSCRIPTION.
        ENDLOOP.
      ENDIF.
    ENDIF.

    " Create AP02 params via composition
    IF LT_CREATE_AP02 IS NOT INITIAL.
      MODIFY ENTITIES OF ZIR_DRS_SUBSCR IN LOCAL MODE
        ENTITY Subscription
          CREATE BY \_ParamAP02 FROM LT_CREATE_AP02
        MAPPED DATA(LT_MAPPED_AP02)
        FAILED DATA(LT_FAILED_AP02)
        REPORTED DATA(LT_REPORTED_AP02).

      " Add success/failure messages
      IF LT_FAILED_AP02-PARAMAP02 IS INITIAL.
        LOOP AT LT_CREATE_AP02 ASSIGNING FIELD-SYMBOL(<CREATED_AP02>).
          APPEND VALUE #(
            %TKY = <CREATED_AP02>-%TKY
            %MSG = NEW_MESSAGE_WITH_TEXT(
              SEVERITY = IF_ABAP_BEHV_MESSAGE=>SEVERITY-SUCCESS
              TEXT     = 'AP-02 parameters created successfully'
            )
          ) TO REPORTED-SUBSCRIPTION.
        ENDLOOP.
      ENDIF.
    ENDIF.

    " Create AP03 params via composition
    IF LT_CREATE_AP03 IS NOT INITIAL.
      MODIFY ENTITIES OF ZIR_DRS_SUBSCR IN LOCAL MODE
        ENTITY Subscription
          CREATE BY \_ParamAP03 FROM LT_CREATE_AP03
        MAPPED DATA(LT_MAPPED_AP03)
        FAILED DATA(LT_FAILED_AP03)
        REPORTED DATA(LT_REPORTED_AP03).

      " Add success/failure messages
      IF LT_FAILED_AP03-PARAMAP03 IS INITIAL.
        LOOP AT LT_CREATE_AP03 ASSIGNING FIELD-SYMBOL(<CREATED_AP03>).
          APPEND VALUE #(
            %TKY = <CREATED_AP03>-%TKY
            %MSG = NEW_MESSAGE_WITH_TEXT(
              SEVERITY = IF_ABAP_BEHV_MESSAGE=>SEVERITY-SUCCESS
              TEXT     = 'AP-03 parameters created successfully'
            )
          ) TO REPORTED-SUBSCRIPTION.
        ENDLOOP.
      ENDIF.
    ENDIF.
    "========================================================================

    " Return result - re-read to get fresh data
    READ ENTITIES OF ZIR_DRS_SUBSCR IN LOCAL MODE
      ENTITY Subscription
        ALL FIELDS WITH CORRESPONDING #( KEYS )
      RESULT DATA(LT_RESULT).

    RESULT = VALUE #( FOR LS IN LT_RESULT
                      ( %TKY = LS-%TKY
                        %PARAM = CORRESPONDING #( LS ) ) ).
  ENDMETHOD.

  METHOD CleanupOnReportChange.

    DATA: LT_DEL_CUS TYPE TABLE FOR DELETE ZIR_DRS_SUBSCR\\Customers,
          LT_DEL_VEN TYPE TABLE FOR DELETE ZIR_DRS_SUBSCR\\Vendors.

    "Get newest ReportID
    READ ENTITIES OF ZIR_DRS_SUBSCR IN LOCAL MODE
     ENTITY Subscription
        FIELDS ( ReportID ) WITH CORRESPONDING #( KEYS )
     RESULT DATA(LT_SUBSCRIPTIONS).

    LOOP AT LT_SUBSCRIPTIONS INTO DATA(LS_SUB).

      " Convert Report ID to AP -> Remove all Customer
      IF LS_SUB-ReportId CP 'AP*'.

        " Read all Customer in association
        READ ENTITIES OF ZIR_DRS_SUBSCR IN LOCAL MODE
          ENTITY Subscription BY \_Customers
            ALL FIELDS WITH VALUE #( ( %TKY = LS_SUB-%TKY ) )
          RESULT DATA(LT_CUSTOMERS).

        " Push key into delete customer list
        LT_DEL_CUS = CORRESPONDING #( BASE ( LT_DEL_CUS  ) LT_CUSTOMERS ).

        " Convert Report ID to AR -> Remove all Vendor
      ELSEIF LS_SUB-ReportId CP 'AR*'.

        " Read all Vendor in association
        READ ENTITIES OF ZIR_DRS_SUBSCR IN LOCAL MODE
          ENTITY Subscription BY \_Vendors
            ALL FIELDS WITH VALUE #( ( %TKY = LS_SUB-%TKY ) )
          RESULT DATA(LT_VENDORS).

        " Push key into delete vendor list
        LT_DEL_VEN = CORRESPONDING #( BASE ( LT_DEL_VEN ) LT_VENDORS ).

      ENDIF.
    ENDLOOP.

    " 4. Thực thi lệnh Xóa (Chỉ gọi 1 lần để tối ưu hiệu suất Database)
    IF LT_DEL_CUS  IS NOT INITIAL.
      MODIFY ENTITIES OF ZIR_DRS_SUBSCR IN LOCAL MODE
        ENTITY Customers
          DELETE FROM LT_DEL_CUS .
    ENDIF.

    IF LT_DEL_VEN IS NOT INITIAL.
      MODIFY ENTITIES OF ZIR_DRS_SUBSCR IN LOCAL MODE
        ENTITY Vendors
          DELETE FROM LT_DEL_VEN.
    ENDIF.


  ENDMETHOD.



  METHOD validateDescription.
    " Read entities
    READ ENTITIES OF ZIR_DRS_SUBSCR IN LOCAL MODE
      ENTITY Subscription
      FIELDS ( SUBSCRNAME )
      WITH CORRESPONDING #( KEYS )
      RESULT DATA(LT_SUBS).

    LOOP AT LT_SUBS INTO DATA(LS_SUB).
      IF LS_SUB-SubscrName IS INITIAL.
        APPEND VALUE #( %TKY = LS_SUB-%TKY ) TO FAILED-Subscription.
        APPEND VALUE #( %TKY = LS_SUB-%TKY
          %MSG = NEW_MESSAGE_WITH_TEXT(
            SEVERITY = IF_ABAP_BEHV_MESSAGE=>SEVERITY-ERROR
            TEXT = 'Description is required' )
          %ELEMENT-SubscrName = IF_ABAP_BEHV=>MK-ON )
        TO REPORTED-Subscription.
      ENDIF.
    ENDLOOP.
  ENDMETHOD.

  METHOD validateReport.
    " Read entities
    READ ENTITIES OF ZIR_DRS_SUBSCR IN LOCAL MODE
    ENTITY Subscription FIELDS ( ReportId ) WITH CORRESPONDING #( KEYS )
    RESULT DATA(LT_SUBS).

    LOOP AT LT_SUBS INTO DATA(LS_SUB).
      IF LS_SUB-ReportID IS INITIAL.
        APPEND VALUE #( %TKY = LS_SUB-%TKY ) TO FAILED-Subscription.
        APPEND VALUE #( %TKY = LS_SUB-%TKY
          %MSG = NEW_MESSAGE_WITH_TEXT(
            SEVERITY = IF_ABAP_BEHV_MESSAGE=>SEVERITY-ERROR
            TEXT = 'The report is yet to be generated' )
          %ELEMENT-ReportID = IF_ABAP_BEHV=>MK-ON )
        TO REPORTED-Subscription.

      ENDIF.


      "Validate Parameters
      CASE LS_SUB-ReportId.
        WHEN 'GL-01'.
          READ ENTITIES OF ZIR_DRS_SUBSCR IN LOCAL MODE
            ENTITY Subscription BY \_ParamGL01 ALL FIELDS WITH CORRESPONDING #( KEYS ) RESULT DATA(lt_gl01).
        IF lt_gl01 IS INITIAL OR
           lt_gl01[ 1 ]-CompanyCode IS INITIAL OR lt_gl01[ 1 ]-FiscalYear IS INITIAL OR
           lt_gl01[ 1 ]-FiscalPeriodFr IS INITIAL OR lt_gl01[ 1 ]-FiscalPeriodTo IS INITIAL.

*          APPEND VALUE #( %tky = ls_sub-%tky ) TO failed-subscription.
*          APPEND VALUE #( %tky = ls_sub-%tky
*                          %msg = new_message_with_text( severity = if_abap_behv_message=>severity-error
*                                                        text     = 'Tham số GL-01 không hợp lệ hoặc thiếu thông tin bắt buộc' )
*                        ) TO reported-subscription.
*        ENDIF.

            APPEND VALUE #( %TKY = LS_SUB-%TKY ) TO FAILED-Subscription.
            APPEND VALUE #( %TKY = LS_SUB-%TKY
              %MSG = NEW_MESSAGE_WITH_TEXT(
                SEVERITY = IF_ABAP_BEHV_MESSAGE=>SEVERITY-ERROR
                TEXT = 'GL Report has not been prepared' )
              %ELEMENT-ReportID = IF_ABAP_BEHV=>MK-ON )
            TO REPORTED-Subscription.
*           me->report_error( EXPORTING tky = ls_sub-%tky msg = 'Thiếu tham số bắt buộc cho GL-01' CHANGING failed = failed reported = reported ).
          ENDIF.

        WHEN 'AR-01' OR 'AR-03' OR 'AP-01' OR 'AP-03'.
          " Các báo cáo dùng KeyDate (Dựa trên list của bạn)
          " Bạn cần tạo các biến READ tương ứng cho từng association ở đây
          " Ví dụ cho AR-01:
          READ ENTITIES OF ZIR_DRS_SUBSCR IN LOCAL MODE
            ENTITY Subscription BY \_ParamAR01 ALL FIELDS WITH CORRESPONDING #( KEYS ) RESULT DATA(LT_AR01).

*        IF lt_ar01 IS INITIAL OR lt_ar01[ 1 ]-CompanyCode IS INITIAL OR lt_ar01[ 1 ]-KeyDate IS INITIAL.
*           me->report_error( EXPORTING tky = ls_sub-%tky msg = |Báo cáo { ls_sub-ReportId } thiếu Company Code hoặc Key Date| CHANGING failed = failed reported = reported ).
*        ENDIF.

        WHEN 'AR-02' OR 'AP-02'.
          " Các báo cáo dùng FiscalYear
          " Tương tự: READ ENTITY ... BY \_ParamAR02 ...
      ENDCASE.
    ENDLOOP.

  ENDMETHOD.

*  METHOD report_error.
*    APPEND VALUE #( %tky = tky ) TO failed.
*    APPEND VALUE #( %tky = tky
*                    %msg = new_message_with_text(
*                             severity = if_abap_behv_message=>severity-error
*                             text     = msg )
*                  ) TO reported.
*  ENDMETHOD.
ENDCLASS.
