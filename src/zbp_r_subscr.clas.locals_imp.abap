*&---------------------------------------------------------------------*
*& Local Classes for Subscription Behavior
*& COMPOSITION: ParamGL01 is child entity (lifecycle managed by parent)
*&---------------------------------------------------------------------*
CLASS LHC_SUBSCRIPTION DEFINITION INHERITING FROM CL_ABAP_BEHAVIOR_HANDLER.
  PRIVATE SECTION.

    CONSTANTS GC_MSG_CLASS TYPE SYMSGID VALUE 'ZMSG_DRS_SP26_SAP01'.

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
    METHODS setDefaultValue FOR DETERMINE ON MODIFY
      IMPORTING KEYS FOR Subscription~setDefaultValue.

    " NOTE: cascadeDeleteParams removed - composition handles cascade delete automatically

    " Create Report Parameters - generic action based on ReportId
    METHODS createReportParams FOR MODIFY
      IMPORTING KEYS FOR ACTION Subscription~createReportParams RESULT RESULT.


    METHODS CleanupOnReportChange FOR DETERMINE ON MODIFY
      IMPORTING KEYS FOR Subscription~CleanupOnReportChange.

    METHODS validateDescription FOR VALIDATE ON SAVE
      IMPORTING KEYS FOR Subscription~validateDescription.

    METHODS validateReport FOR VALIDATE ON SAVE
      IMPORTING KEYS FOR Subscription~validateReport.

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


  METHOD setDefaultValue.
    " Set status to 'A' (Active) when subscription is created
    READ ENTITIES OF ZIR_DRS_SUBSCR IN LOCAL MODE
      ENTITY Subscription
        FIELDS ( Status OutputFormat ) WITH CORRESPONDING #( KEYS )
      RESULT DATA(LT_SUBSCR).

    DATA LT_UPDATE TYPE TABLE FOR UPDATE ZIR_DRS_SUBSCR.

    LOOP AT LT_SUBSCR INTO DATA(LS_SUBSCR).

      IF LS_SUBSCR-Status IS INITIAL OR LS_SUBSCR-OutputFormat IS INITIAL.

        APPEND VALUE #(
            %TKY          = LS_SUBSCR-%TKY
            Status        = COND #( WHEN LS_SUBSCR-Status IS INITIAL THEN 'A' ELSE LS_SUBSCR-Status )
            OutputFormat  = COND #( WHEN LS_SUBSCR-OutputFormat IS INITIAL THEN 'XLSX' ELSE LS_SUBSCR-OutputFormat )
            %CONTROL-Status       = IF_ABAP_BEHV=>MK-ON
            %CONTROL-OutputFormat = IF_ABAP_BEHV=>MK-ON
        ) TO LT_UPDATE.

      ENDIF.
    ENDLOOP.

    IF LT_UPDATE IS NOT INITIAL.
      MODIFY ENTITIES OF ZIR_DRS_SUBSCR IN LOCAL MODE
        ENTITY Subscription
          UPDATE FIELDS ( Status OutputFormat ) WITH LT_UPDATE
        REPORTED DATA(LT_REPORTED)
        FAILED DATA(LT_FAILED_MODIFY).
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

    " Read associated parameters via composition
    READ ENTITIES OF ZIR_DRS_SUBSCR IN LOCAL MODE
        ENTITY Subscription BY \_ParamGL01 ALL FIELDS WITH CORRESPONDING #( KEYS ) RESULT DATA(LT_SOURCE_GL01)
        ENTITY Subscription BY \_ParamAR01 ALL FIELDS WITH CORRESPONDING #( KEYS ) RESULT DATA(LT_SOURCE_AR01)
        ENTITY Subscription BY \_ParamAR02 ALL FIELDS WITH CORRESPONDING #( KEYS ) RESULT DATA(LT_SOURCE_AR02)
        ENTITY Subscription BY \_ParamAR03 ALL FIELDS WITH CORRESPONDING #( KEYS ) RESULT DATA(LT_SOURCE_AR03)
        ENTITY Subscription BY \_ParamAP01 ALL FIELDS WITH CORRESPONDING #( KEYS ) RESULT DATA(LT_SOURCE_AP01)
        ENTITY Subscription BY \_ParamAP02 ALL FIELDS WITH CORRESPONDING #( KEYS ) RESULT DATA(LT_SOURCE_AP02)
        ENTITY Subscription BY \_ParamAP03 ALL FIELDS WITH CORRESPONDING #( KEYS ) RESULT DATA(LT_SOURCE_AP03).

    " Get max subscr_id for new ID generation
    SELECT MAX( SUBSCR_ID ) FROM ZDRS_SUBSCR INTO @DATA(LV_MAX_ID).
    DATA(LV_NEW_SUBSCR_ID) = LV_MAX_ID + 1.

    " Data declarations for creating composition nodes
    DATA LT_SUBSCR     TYPE TABLE FOR CREATE ZIR_DRS_SUBSCR.
    DATA LT_PARAM_GL01 TYPE TABLE FOR CREATE ZIR_DRS_SUBSCR\_ParamGL01.
    DATA LT_PARAM_AR01 TYPE TABLE FOR CREATE ZIR_DRS_SUBSCR\_ParamAR01.
    DATA LT_PARAM_AR02 TYPE TABLE FOR CREATE ZIR_DRS_SUBSCR\_ParamAR02.
    DATA LT_PARAM_AR03 TYPE TABLE FOR CREATE ZIR_DRS_SUBSCR\_ParamAR03.
    DATA LT_PARAM_AP01 TYPE TABLE FOR CREATE ZIR_DRS_SUBSCR\_ParamAP01.
    DATA LT_PARAM_AP02 TYPE TABLE FOR CREATE ZIR_DRS_SUBSCR\_ParamAP02.
    DATA LT_PARAM_AP03 TYPE TABLE FOR CREATE ZIR_DRS_SUBSCR\_ParamAP03.

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

      " --- GL01 Params (Updated based on image) ---
      IF LT_SOURCE_GL01 IS NOT INITIAL.
        LOOP AT LT_SOURCE_GL01 ASSIGNING FIELD-SYMBOL(<GL01>) WHERE SubscrUuid = <SOURCE>-SubscrUuid.
          APPEND VALUE #( %CID_REF = LV_CID
                          %TARGET = VALUE #( (
                            %CID           = |GL01_{ LV_IDX }|
                            %IS_DRAFT      = <SOURCE>-%IS_DRAFT
                            CompanyCode    = <GL01>-CompanyCode
                            GlAccountFr    = <GL01>-GlAccountFr
                            GlAccountTo    = <GL01>-GlAccountTo
                            FiscalPeriodFr = <GL01>-FiscalPeriodFr
                            FiscalPeriodTo = <GL01>-FiscalPeriodTo
                            FiscalYearFr   = <GL01>-FiscalYearFr
                            FiscalYearTo   = <GL01>-FiscalYearTo
                            MaxRows        = <GL01>-MaxRows ) ) )
                 TO LT_PARAM_GL01.
        ENDLOOP.
      ENDIF.

      " --- AR01 Params ---
      IF LT_SOURCE_AR01 IS NOT INITIAL.
        LOOP AT LT_SOURCE_AR01 ASSIGNING FIELD-SYMBOL(<AR01>) WHERE SubscrUuid = <SOURCE>-SubscrUuid.
          APPEND VALUE #( %CID_REF = LV_CID
                          %TARGET = VALUE #( (
                            %CID          = |AR01_{ LV_IDX }|
                            %IS_DRAFT     = <SOURCE>-%IS_DRAFT
                            CompanyCode   = <AR01>-CompanyCode
                            CustomerFrom  = <AR01>-CustomerFrom
                            CustomerTo    = <AR01>-CustomerTo
                            KeyDate       = <AR01>-KeyDate
                            MaxRows       = <AR01>-MaxRows ) ) )
                 TO LT_PARAM_AR01.
        ENDLOOP.
      ENDIF.

      " --- AR02 Params ---
      IF LT_SOURCE_AR02 IS NOT INITIAL.
        LOOP AT LT_SOURCE_AR02 ASSIGNING FIELD-SYMBOL(<AR02>) WHERE SubscrUuid = <SOURCE>-SubscrUuid.
          APPEND VALUE #( %CID_REF = LV_CID
                          %TARGET = VALUE #( (
                            %CID          = |AR02_{ LV_IDX }|
                            %IS_DRAFT     = <SOURCE>-%IS_DRAFT
                            CompanyCode   = <AR02>-CompanyCode
                            CustomerFrom  = <AR02>-CustomerFrom
                            CustomerTo    = <AR02>-CustomerTo
                            FiscalYear    = <AR02>-FiscalYear
                            MaxRows       = <AR02>-MaxRows ) ) )
                 TO LT_PARAM_AR02.
        ENDLOOP.
      ENDIF.

      " --- AR03 Params ---
      IF LT_SOURCE_AR03 IS NOT INITIAL.
        LOOP AT LT_SOURCE_AR03 ASSIGNING FIELD-SYMBOL(<AR03>) WHERE SubscrUuid = <SOURCE>-SubscrUuid.
          APPEND VALUE #( %CID_REF = LV_CID
                          %TARGET = VALUE #( (
                            %CID          = |AR03_{ LV_IDX }|
                            %IS_DRAFT     = <SOURCE>-%IS_DRAFT
                            CompanyCode   = <AR03>-CompanyCode
                            CustomerFrom  = <AR03>-CustomerFrom
                            CustomerTo    = <AR03>-CustomerTo
                            KeyDate       = <AR03>-KeyDate
                            MaxRows       = <AR03>-MaxRows ) ) )
                 TO LT_PARAM_AR03.
        ENDLOOP.
      ENDIF.

      " --- AP01 Params ---
      IF LT_SOURCE_AP01 IS NOT INITIAL.
        LOOP AT LT_SOURCE_AP01 ASSIGNING FIELD-SYMBOL(<AP01>) WHERE SubscrUuid = <SOURCE>-SubscrUuid.
          APPEND VALUE #( %CID_REF = LV_CID
                          %TARGET = VALUE #( (
                            %CID          = |AP01_{ LV_IDX }|
                            %IS_DRAFT     = <SOURCE>-%IS_DRAFT
                            CompanyCode   = <AP01>-CompanyCode
                            VendorFrom    = <AP01>-VendorFrom
                            VendorTo      = <AP01>-VendorTo
                            KeyDate       = <AP01>-KeyDate
                            MaxRows       = <AP01>-MaxRows ) ) )
                 TO LT_PARAM_AP01.
        ENDLOOP.
      ENDIF.

      " --- AP02 Params ---
      IF LT_SOURCE_AR02 IS NOT INITIAL.
        LOOP AT LT_SOURCE_AP02 ASSIGNING FIELD-SYMBOL(<AP02>) WHERE SubscrUuid = <SOURCE>-SubscrUuid.
          APPEND VALUE #( %CID_REF = LV_CID
                          %TARGET = VALUE #( (
                            %CID         = |AP02_{ LV_IDX }|
                            %IS_DRAFT    = <SOURCE>-%IS_DRAFT
                            CompanyCode  = <AP02>-CompanyCode
                            VendorFrom   = <AP02>-VendorFrom
                            VendorTo     = <AP02>-VendorTo
                            FiscalYear   = <AP02>-FiscalYear
                            MaxRows      = <AP02>-MaxRows ) ) )
                 TO LT_PARAM_AP02.
        ENDLOOP.
      ENDIF.

      " --- AP03 Params ---
      IF LT_SOURCE_AP03 IS NOT INITIAL.
        LOOP AT LT_SOURCE_AP03 ASSIGNING FIELD-SYMBOL(<AP03>) WHERE SubscrUuid = <SOURCE>-SubscrUuid.
          APPEND VALUE #( %CID_REF = LV_CID
                          %TARGET = VALUE #( (
                            %CID         = |AP03_{ LV_IDX }|
                            %IS_DRAFT    = <SOURCE>-%IS_DRAFT
                            CompanyCode  = <AP03>-CompanyCode
                            VendorFrom   = <AP03>-VendorFrom
                            VendorTo     = <AP03>-VendorTo
                            KeyDate      = <AP03>-KeyDate
                            MaxRows      = <AP03>-MaxRows ) ) )
                 TO LT_PARAM_AP03.
        ENDLOOP.
      ENDIF.

      LV_NEW_SUBSCR_ID = LV_NEW_SUBSCR_ID + 1.
    ENDLOOP.

*    " Create subscriptions via RAP
*    MODIFY ENTITIES OF ZIR_DRS_SUBSCR IN LOCAL MODE
*      ENTITY Subscription
*        CREATE FROM LT_SUBSCR
*        CREATE BY \_ParamGL01 FROM LT_PARAM_GL01
*      MAPPED DATA(LT_MAPPED)
*      FAILED DATA(LT_CREATE_FAILED)
*      REPORTED DATA(LT_REPORTED).
    " Create subscriptions and all associations via RAP
    MODIFY ENTITIES OF ZIR_DRS_SUBSCR IN LOCAL MODE
      ENTITY Subscription
        CREATE FROM LT_SUBSCR
        CREATE BY \_ParamGL01 FROM LT_PARAM_GL01
        CREATE BY \_ParamAR01 FROM LT_PARAM_AR01
        CREATE BY \_ParamAR02 FROM LT_PARAM_AR02
        CREATE BY \_ParamAR03 FROM LT_PARAM_AR03
        CREATE BY \_ParamAP01 FROM LT_PARAM_AP01
        CREATE BY \_ParamAP02 FROM LT_PARAM_AP02
        CREATE BY \_ParamAP03 FROM LT_PARAM_AP03
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

    " Read existing AP03 params via composition
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
              %MSG = NEW_MESSAGE(
                  ID       = GC_MSG_CLASS
                  NUMBER   = '051' " '&1 parameters already exist...'
                  SEVERITY = IF_ABAP_BEHV_MESSAGE=>SEVERITY-ERROR " Theo code gốc GL-01 là ERROR
                  V1       = <SUBSCR>-ReportId )
              %ELEMENT-ReportId = IF_ABAP_BEHV=>MK-ON )
            TO REPORTED-SUBSCRIPTION.
          ELSE.
            APPEND VALUE #(
              %TKY = CORRESPONDING #( <SUBSCR> )
              %TARGET = VALUE #( (
                %CID        = |{ <SUBSCR>-ReportId }_{ SY-TABIX }|
                %IS_DRAFT   = <SUBSCR>-%IS_DRAFT ) )
            ) TO LT_CREATE_GL01.
          ENDIF.

          "===================AR Report Parameter==================================
        WHEN 'AR-01'.
          READ TABLE LT_EXISTING_AR01 WITH KEY SubscrUuid = <SUBSCR>-SubscrUuid TRANSPORTING NO FIELDS.
          IF SY-SUBRC = 0.
            APPEND VALUE #(
              %TKY = CORRESPONDING #( <SUBSCR> )
              %MSG = NEW_MESSAGE(
                ID       = GC_MSG_CLASS
                NUMBER   = '051' " '&1 parameters already exist...'
                SEVERITY = IF_ABAP_BEHV_MESSAGE=>SEVERITY-INFORMATION
                V1       = <SUBSCR>-ReportId )
            ) TO REPORTED-SUBSCRIPTION.
          ELSE.
            APPEND VALUE #(
              %TKY = CORRESPONDING #( <SUBSCR> )
              %TARGET = VALUE #( (
                %CID        = |{ <SUBSCR>-ReportId }_{ SY-TABIX }|
                %IS_DRAFT   = <SUBSCR>-%IS_DRAFT
                CompanyCode = <SUBSCR>-Bukrs
                KeyDate     = '' ) )
            ) TO LT_CREATE_AR01.
          ENDIF.

        WHEN 'AR-02'.
          READ TABLE LT_EXISTING_AR02 WITH KEY SubscrUuid = <SUBSCR>-SubscrUuid TRANSPORTING NO FIELDS.
          IF SY-SUBRC = 0.
            APPEND VALUE #(
              %TKY = CORRESPONDING #( <SUBSCR> )
              %MSG = NEW_MESSAGE(
                ID       = GC_MSG_CLASS
                NUMBER   = '051' " '&1 parameters already exist...'
                SEVERITY = IF_ABAP_BEHV_MESSAGE=>SEVERITY-INFORMATION
                V1       = <SUBSCR>-ReportId )
            ) TO REPORTED-SUBSCRIPTION.
          ELSE.
            APPEND VALUE #(
              %TKY = CORRESPONDING #( <SUBSCR> )
              %TARGET = VALUE #( (
                %CID        = |{ <SUBSCR>-ReportId }_{ SY-TABIX }|
                %IS_DRAFT   = <SUBSCR>-%IS_DRAFT ) )
            ) TO LT_CREATE_AR02.
          ENDIF.

        WHEN 'AR-03'.
          READ TABLE LT_EXISTING_AR03 WITH KEY SubscrUuid = <SUBSCR>-SubscrUuid TRANSPORTING NO FIELDS.
          IF SY-SUBRC = 0.
            APPEND VALUE #(
              %TKY = CORRESPONDING #( <SUBSCR> )
              %MSG = NEW_MESSAGE(
                ID       = GC_MSG_CLASS
                NUMBER   = '051' " '&1 parameters already exist...'
                SEVERITY = IF_ABAP_BEHV_MESSAGE=>SEVERITY-INFORMATION
                V1       = <SUBSCR>-ReportId )
            ) TO REPORTED-SUBSCRIPTION.
          ELSE.
            APPEND VALUE #(
              %TKY = CORRESPONDING #( <SUBSCR> )
              %TARGET = VALUE #( (
                %CID        = |{ <SUBSCR>-ReportId }_{ SY-TABIX }|
                %IS_DRAFT   = <SUBSCR>-%IS_DRAFT ) )
            ) TO LT_CREATE_AR03.
          ENDIF.

          "===================AP Report Parameter==================================
        WHEN 'AP-01'.
          READ TABLE LT_EXISTING_AP01 WITH KEY SubscrUuid = <SUBSCR>-SubscrUuid TRANSPORTING NO FIELDS.
          IF SY-SUBRC = 0.
            APPEND VALUE #(
              %TKY = CORRESPONDING #( <SUBSCR> )
              %MSG = NEW_MESSAGE(
                ID       = GC_MSG_CLASS
                NUMBER   = '051' " '&1 parameters already exist...'
                SEVERITY = IF_ABAP_BEHV_MESSAGE=>SEVERITY-INFORMATION
                V1       = <SUBSCR>-ReportId )
            ) TO REPORTED-SUBSCRIPTION.
          ELSE.
            APPEND VALUE #(
              %TKY = CORRESPONDING #( <SUBSCR> )
              %TARGET = VALUE #( (
                %CID        = |{ <SUBSCR>-ReportId }_{ SY-TABIX }|
                %IS_DRAFT   = <SUBSCR>-%IS_DRAFT ) )
            ) TO LT_CREATE_AP01.
          ENDIF.

        WHEN 'AP-02'.
          READ TABLE LT_EXISTING_AP02 WITH KEY SubscrUuid = <SUBSCR>-SubscrUuid TRANSPORTING NO FIELDS.
          IF SY-SUBRC = 0.
            APPEND VALUE #(
              %TKY = CORRESPONDING #( <SUBSCR> )
              %MSG = NEW_MESSAGE(
                ID       = GC_MSG_CLASS
                NUMBER   = '051' " '&1 parameters already exist...'
                SEVERITY = IF_ABAP_BEHV_MESSAGE=>SEVERITY-INFORMATION
                V1       = <SUBSCR>-ReportId )
            ) TO REPORTED-SUBSCRIPTION.
          ELSE.
            APPEND VALUE #(
              %TKY = CORRESPONDING #( <SUBSCR> )
              %TARGET = VALUE #( (
                %CID        = |{ <SUBSCR>-ReportId }_{ SY-TABIX }|
                %IS_DRAFT   = <SUBSCR>-%IS_DRAFT ) )
            ) TO LT_CREATE_AP02.
          ENDIF.

        WHEN 'AP-03'.
          READ TABLE LT_EXISTING_AP03 WITH KEY SubscrUuid = <SUBSCR>-SubscrUuid TRANSPORTING NO FIELDS.
          IF SY-SUBRC = 0.
            APPEND VALUE #(
              %TKY = CORRESPONDING #( <SUBSCR> )
              %MSG = NEW_MESSAGE(
                ID       = GC_MSG_CLASS
                NUMBER   = '051' " '&1 parameters already exist...'
                SEVERITY = IF_ABAP_BEHV_MESSAGE=>SEVERITY-INFORMATION
                V1       = <SUBSCR>-ReportId )
            ) TO REPORTED-SUBSCRIPTION.
          ELSE.
            APPEND VALUE #(
              %TKY = CORRESPONDING #( <SUBSCR> )
              %TARGET = VALUE #( (
                %CID        = |{ <SUBSCR>-ReportId }_{ SY-TABIX }|
                %IS_DRAFT   = <SUBSCR>-%IS_DRAFT ) )
            ) TO LT_CREATE_AP03.
          ENDIF.

* WHEN 'GL-02'.
* " TODO: Implement GL-02 parameter creation via _ParamGL02

        WHEN OTHERS.
          APPEND VALUE #(
            %TKY = CORRESPONDING #( <SUBSCR> )
            %MSG = NEW_MESSAGE(
              ID       = GC_MSG_CLASS
              NUMBER   = '053' " 'Report type &1 does not have configurable parameters'
              SEVERITY = IF_ABAP_BEHV_MESSAGE=>SEVERITY-WARNING
              V1       = <SUBSCR>-ReportId )
          ) TO REPORTED-SUBSCRIPTION.
      ENDCASE.
    ENDLOOP.

    "========================================================================
    " CREATION & SUCCESS MESSAGES
    "========================================================================

    " Create GL01 params via composition
    IF LT_CREATE_GL01 IS NOT INITIAL.
      MODIFY ENTITIES OF ZIR_DRS_SUBSCR IN LOCAL MODE
        ENTITY Subscription
          CREATE BY \_ParamGL01 FROM LT_CREATE_GL01
        MAPPED DATA(LT_MAPPED)
        FAILED DATA(LT_CREATE_FAILED)
        REPORTED DATA(LT_CREATE_REPORTED).

      IF LT_CREATE_FAILED-PARAMGL01 IS INITIAL.
        LOOP AT LT_CREATE_GL01 ASSIGNING FIELD-SYMBOL(<CREATED>).
          APPEND VALUE #(
            %TKY = <CREATED>-%TKY
            %MSG = NEW_MESSAGE(
              ID       = GC_MSG_CLASS
              NUMBER   = '052' " '&1 parameters created successfully'
              SEVERITY = IF_ABAP_BEHV_MESSAGE=>SEVERITY-SUCCESS
              V1       = 'GL-01' ) " Truyền trực tiếp ReportId
          ) TO REPORTED-SUBSCRIPTION.
        ENDLOOP.
      ENDIF.
    ENDIF.

    " Create AR01 params
    IF LT_CREATE_AR01 IS NOT INITIAL.
      MODIFY ENTITIES OF ZIR_DRS_SUBSCR IN LOCAL MODE
        ENTITY Subscription
          CREATE BY \_ParamAR01 FROM LT_CREATE_AR01
        MAPPED DATA(LT_MAPPED_AR01)
        FAILED DATA(LT_FAILED_AR01)
        REPORTED DATA(LT_REPORTED_AR01).

      IF LT_FAILED_AR01-PARAMAR01 IS INITIAL.
        LOOP AT LT_CREATE_AR01 ASSIGNING FIELD-SYMBOL(<CREATED_AR01>).
          APPEND VALUE #(
            %TKY = <CREATED_AR01>-%TKY
            %MSG = NEW_MESSAGE(
              ID       = GC_MSG_CLASS
              NUMBER   = '052' " '&1 parameters created successfully'
              SEVERITY = IF_ABAP_BEHV_MESSAGE=>SEVERITY-SUCCESS
              V1       = 'AR-01' )
          ) TO REPORTED-SUBSCRIPTION.
        ENDLOOP.
      ENDIF.
    ENDIF.

    " Create AR02 params
    IF LT_CREATE_AR02 IS NOT INITIAL.
      MODIFY ENTITIES OF ZIR_DRS_SUBSCR IN LOCAL MODE
        ENTITY Subscription
          CREATE BY \_ParamAR02 FROM LT_CREATE_AR02
        MAPPED DATA(LT_MAPPED_AR02)
        FAILED DATA(LT_FAILED_AR02)
        REPORTED DATA(LT_REPORTED_AR02).

      IF LT_FAILED_AR02-PARAMAR02 IS INITIAL.
        LOOP AT LT_CREATE_AR02 ASSIGNING FIELD-SYMBOL(<CREATED_AR02>).
          APPEND VALUE #(
            %TKY = <CREATED_AR02>-%TKY
            %MSG = NEW_MESSAGE(
              ID       = GC_MSG_CLASS
              NUMBER   = '052' " '&1 parameters created successfully'
              SEVERITY = IF_ABAP_BEHV_MESSAGE=>SEVERITY-SUCCESS
              V1       = 'AR-02' )
          ) TO REPORTED-SUBSCRIPTION.
        ENDLOOP.
      ENDIF.
    ENDIF.

    " Create AR03 params
    IF LT_CREATE_AR03 IS NOT INITIAL.
      MODIFY ENTITIES OF ZIR_DRS_SUBSCR IN LOCAL MODE
        ENTITY Subscription
          CREATE BY \_ParamAR03 FROM LT_CREATE_AR03
        MAPPED DATA(LT_MAPPED_AR03)
        FAILED DATA(LT_FAILED_AR03)
        REPORTED DATA(LT_REPORTED_AR03).

      IF LT_FAILED_AR03-PARAMAR03 IS INITIAL.
        LOOP AT LT_CREATE_AR03 ASSIGNING FIELD-SYMBOL(<CREATED_AR03>).
          APPEND VALUE #(
            %TKY = <CREATED_AR03>-%TKY
            %MSG = NEW_MESSAGE(
              ID       = GC_MSG_CLASS
              NUMBER   = '052' " '&1 parameters created successfully'
              SEVERITY = IF_ABAP_BEHV_MESSAGE=>SEVERITY-SUCCESS
              V1       = 'AR-03' )
          ) TO REPORTED-SUBSCRIPTION.
        ENDLOOP.
      ENDIF.
    ENDIF.

    " Create AP01 params
    IF LT_CREATE_AP01 IS NOT INITIAL.
      MODIFY ENTITIES OF ZIR_DRS_SUBSCR IN LOCAL MODE
        ENTITY Subscription
          CREATE BY \_ParamAP01 FROM LT_CREATE_AP01
        MAPPED DATA(LT_MAPPED_AP01)
        FAILED DATA(LT_FAILED_AP01)
        REPORTED DATA(LT_REPORTED_AP01).

      IF LT_FAILED_AP01-PARAMAP01 IS INITIAL.
        LOOP AT LT_CREATE_AP01 ASSIGNING FIELD-SYMBOL(<CREATED_AP01>).
          APPEND VALUE #(
            %TKY = <CREATED_AP01>-%TKY
            %MSG = NEW_MESSAGE(
              ID       = GC_MSG_CLASS
              NUMBER   = '052' " '&1 parameters created successfully'
              SEVERITY = IF_ABAP_BEHV_MESSAGE=>SEVERITY-SUCCESS
              V1       = 'AP-01' )
          ) TO REPORTED-SUBSCRIPTION.
        ENDLOOP.
      ENDIF.
    ENDIF.

    " Create AP02 params
    IF LT_CREATE_AP02 IS NOT INITIAL.
      MODIFY ENTITIES OF ZIR_DRS_SUBSCR IN LOCAL MODE
        ENTITY Subscription
          CREATE BY \_ParamAP02 FROM LT_CREATE_AP02
        MAPPED DATA(LT_MAPPED_AP02)
        FAILED DATA(LT_FAILED_AP02)
        REPORTED DATA(LT_REPORTED_AP02).

      IF LT_FAILED_AP02-PARAMAP02 IS INITIAL.
        LOOP AT LT_CREATE_AP02 ASSIGNING FIELD-SYMBOL(<CREATED_AP02>).
          APPEND VALUE #(
            %TKY = <CREATED_AP02>-%TKY
            %MSG = NEW_MESSAGE(
              ID       = GC_MSG_CLASS
              NUMBER   = '052' " '&1 parameters created successfully'
              SEVERITY = IF_ABAP_BEHV_MESSAGE=>SEVERITY-SUCCESS
              V1       = 'AP-02' )
          ) TO REPORTED-SUBSCRIPTION.
        ENDLOOP.
      ENDIF.
    ENDIF.

    " Create AP03 params
    IF LT_CREATE_AP03 IS NOT INITIAL.
      MODIFY ENTITIES OF ZIR_DRS_SUBSCR IN LOCAL MODE
        ENTITY Subscription
          CREATE BY \_ParamAP03 FROM LT_CREATE_AP03
        MAPPED DATA(LT_MAPPED_AP03)
        FAILED DATA(LT_FAILED_AP03)
        REPORTED DATA(LT_REPORTED_AP03).

      IF LT_FAILED_AP03-PARAMAP03 IS INITIAL.
        LOOP AT LT_CREATE_AP03 ASSIGNING FIELD-SYMBOL(<CREATED_AP03>).
          APPEND VALUE #(
            %TKY = <CREATED_AP03>-%TKY
            %MSG = NEW_MESSAGE(
              ID       = GC_MSG_CLASS
              NUMBER   = '052' " '&1 parameters created successfully'
              SEVERITY = IF_ABAP_BEHV_MESSAGE=>SEVERITY-SUCCESS
              V1       = 'AP-03' )
          ) TO REPORTED-SUBSCRIPTION.
        ENDLOOP.
      ENDIF.
    ENDIF.

    " Return result - re-read to get fresh data
    READ ENTITIES OF ZIR_DRS_SUBSCR IN LOCAL MODE
      ENTITY Subscription
        ALL FIELDS WITH CORRESPONDING #( KEYS )
      RESULT DATA(LT_RESULT).

    RESULT = VALUE #( FOR LS IN LT_RESULT
                      ( %TKY = LS-%TKY
                        %PARAM = CORRESPONDING #( LS ) ) ).
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
          %MSG = NEW_MESSAGE(
            ID       = GC_MSG_CLASS
            NUMBER   = '001' "Description is required
            SEVERITY = IF_ABAP_BEHV_MESSAGE=>SEVERITY-ERROR )
          %ELEMENT-ReportID = IF_ABAP_BEHV=>MK-ON )
        TO REPORTED-Subscription.
      ENDIF.
    ENDLOOP.
  ENDMETHOD.


  "054: The report is yet to be generated
  "055: &1 Report has not been prepared
  "056: &1 parameters are incomplete
  METHOD validateReport.
    " Read entities
    READ ENTITIES OF ZIR_DRS_SUBSCR IN LOCAL MODE
      ENTITY Subscription FIELDS ( ReportId ) WITH CORRESPONDING #( KEYS )
      RESULT DATA(LT_SUBS).

    LOOP AT LT_SUBS INTO DATA(LS_SUB).
      DATA(LV_MSG_NO) = CONV SYMSGNO( '' ).

      " 1. Validate ReportID existence
      IF LS_SUB-ReportID IS INITIAL.
        APPEND VALUE #( %TKY = LS_SUB-%TKY ) TO FAILED-Subscription.
        APPEND VALUE #( %TKY = LS_SUB-%TKY
          %MSG = NEW_MESSAGE(
            ID       = GC_MSG_CLASS
            NUMBER   = '054' " 'The report is yet to be generated'
            SEVERITY = IF_ABAP_BEHV_MESSAGE=>SEVERITY-ERROR )
          %ELEMENT-ReportID = IF_ABAP_BEHV=>MK-ON )
        TO REPORTED-Subscription.

        CONTINUE.
      ENDIF.

      " 2. Validate Parameters
      CASE LS_SUB-ReportId.
        WHEN 'GL-01'.
          READ ENTITIES OF ZIR_DRS_SUBSCR IN LOCAL MODE
            ENTITY Subscription BY \_ParamGL01 ALL FIELDS WITH CORRESPONDING #( KEYS ) RESULT DATA(LT_GL01).

          IF LT_GL01 IS INITIAL.
            LV_MSG_NO = '055'. " '&1 Report has not been prepared'
          ELSE.
            DATA(LS_GL01) = LT_GL01[ 1 ].
            IF LS_GL01-CompanyCode IS INITIAL OR LS_GL01-FiscalYear IS INITIAL OR
               LS_GL01-FiscalPeriodFr IS INITIAL OR LS_GL01-FiscalPeriodTo IS INITIAL OR
               LS_GL01-GlAccountFr IS INITIAL OR LS_GL01-GlAccountTo IS INITIAL.
              LV_MSG_NO = '056'. " '&1 parameters are incomplete'
            ENDIF.
          ENDIF.

        WHEN 'AR-01'.
          READ ENTITIES OF ZIR_DRS_SUBSCR IN LOCAL MODE
            ENTITY Subscription BY \_ParamAR01 ALL FIELDS WITH CORRESPONDING #( KEYS ) RESULT DATA(LT_AR01).

          IF LT_AR01 IS INITIAL.
            LV_MSG_NO = '055'.
          ELSE.
            DATA(LS_AR01) = LT_AR01[ 1 ].
            IF LS_AR01-CompanyCode IS INITIAL OR LS_AR01-KeyDate IS INITIAL.
              LV_MSG_NO = '056'.
            ENDIF.
          ENDIF.

        WHEN 'AR-02'.
          READ ENTITIES OF ZIR_DRS_SUBSCR IN LOCAL MODE
            ENTITY Subscription BY \_ParamAR02 ALL FIELDS WITH CORRESPONDING #( KEYS ) RESULT DATA(LT_AR02).

          IF LT_AR02 IS INITIAL.
            LV_MSG_NO = '055'.
          ELSE.
            DATA(LS_AR02) = LT_AR02[ 1 ].
            IF LS_AR02-CompanyCode IS INITIAL OR LS_AR02-FiscalYear IS INITIAL.
              LV_MSG_NO = '056'.
            ENDIF.
          ENDIF.

        WHEN 'AR-03'.
          READ ENTITIES OF ZIR_DRS_SUBSCR IN LOCAL MODE
            ENTITY Subscription BY \_ParamAR03 ALL FIELDS WITH CORRESPONDING #( KEYS ) RESULT DATA(LT_AR03).

          IF LT_AR03 IS INITIAL.
            LV_MSG_NO = '055'.
          ELSE.
            DATA(LS_AR03) = LT_AR03[ 1 ].
            IF LS_AR03-CompanyCode IS INITIAL OR LS_AR03-KeyDate IS INITIAL.
              LV_MSG_NO = '056'.
            ENDIF.
          ENDIF.

        WHEN 'AP-01'.
          READ ENTITIES OF ZIR_DRS_SUBSCR IN LOCAL MODE
            ENTITY Subscription BY \_ParamAP01 ALL FIELDS WITH CORRESPONDING #( KEYS ) RESULT DATA(LT_AP01).

          IF LT_AP01 IS INITIAL.
            LV_MSG_NO = '055'.
          ELSE.
            DATA(LS_AP01) = LT_AP01[ 1 ].
            IF LS_AP01-CompanyCode IS INITIAL OR LS_AP01-KeyDate IS INITIAL.
              LV_MSG_NO = '056'.
            ENDIF.
          ENDIF.

        WHEN 'AP-02'.
          READ ENTITIES OF ZIR_DRS_SUBSCR IN LOCAL MODE
            ENTITY Subscription BY \_ParamAP02 ALL FIELDS WITH CORRESPONDING #( KEYS ) RESULT DATA(LT_AP02).

          IF LT_AP02 IS INITIAL.
            LV_MSG_NO = '055'.
          ELSE.
            DATA(LS_AP02) = LT_AP02[ 1 ].
            IF LS_AP02-CompanyCode IS INITIAL OR LS_AP02-FiscalYear IS INITIAL.
              LV_MSG_NO = '056'.
            ENDIF.
          ENDIF.

        WHEN 'AP-03'.
          READ ENTITIES OF ZIR_DRS_SUBSCR IN LOCAL MODE
            ENTITY Subscription BY \_ParamAP03 ALL FIELDS WITH CORRESPONDING #( KEYS ) RESULT DATA(LT_AP03).

          IF LT_AP03 IS INITIAL.
            LV_MSG_NO = '055'.
          ELSE.
            DATA(LS_AP03) = LT_AP03[ 1 ].
            IF LS_AP03-CompanyCode IS INITIAL OR LS_AP03-KeyDate IS INITIAL.
              LV_MSG_NO = '056'.
            ENDIF.
          ENDIF.

      ENDCASE.

      " 3. Ghi lỗi bằng Message Class
      IF LV_MSG_NO IS NOT INITIAL.
        APPEND VALUE #( %TKY = LS_SUB-%TKY ) TO FAILED-Subscription.
        APPEND VALUE #( %TKY = LS_SUB-%TKY
          %MSG = NEW_MESSAGE(
            ID       = GC_MSG_CLASS
            NUMBER   = LV_MSG_NO
            SEVERITY = IF_ABAP_BEHV_MESSAGE=>SEVERITY-ERROR
            V1       = LS_SUB-ReportId )
          %ELEMENT-ReportID = IF_ABAP_BEHV=>MK-ON )
        TO REPORTED-Subscription.
      ENDIF.

    ENDLOOP.
  ENDMETHOD.

  METHOD CleanupOnReportChange.

    DATA: LT_DEL_CUSTOMERS TYPE TABLE FOR DELETE ZIR_DRS_SUBSCR\\Customers,
          LT_DEL_VENDORS   TYPE TABLE FOR DELETE ZIR_DRS_SUBSCR\\Vendors.

    " Read current Report
    READ ENTITIES OF ZIR_DRS_SUBSCR IN LOCAL MODE
      ENTITY Subscription
        FIELDS ( ReportId ) WITH CORRESPONDING #( KEYS )
      RESULT DATA(LT_SUBSCRIPTIONS).


    LOOP AT LT_SUBSCRIPTIONS INTO DATA(LS_SUB).

      "Convert to Report AP -> Remove all Customer
      IF LS_SUB-ReportId CP 'AP*'.

        "Get all Customer from Customer list
        READ ENTITIES OF ZIR_DRS_SUBSCR IN LOCAL MODE
          ENTITY Subscription BY \_Customers
            ALL FIELDS WITH VALUE #( ( %TKY = LS_SUB-%TKY ) )
          RESULT DATA(LT_CUSTOMERS).

        LT_DEL_CUSTOMERS = CORRESPONDING #( BASE ( LT_DEL_CUSTOMERS ) LT_CUSTOMERS ).

        "Convert to Report AR -> Remove all Vendor
      ELSEIF LS_SUB-ReportId CP 'AR*'.

        "Get all Vendor from Vendor list
        READ ENTITIES OF ZIR_DRS_SUBSCR IN LOCAL MODE
          ENTITY Subscription BY \_Vendors
            ALL FIELDS WITH VALUE #( ( %TKY = LS_SUB-%TKY ) )
          RESULT DATA(LT_VENDORS).

        LT_DEL_VENDORS = CORRESPONDING #( BASE ( LT_DEL_VENDORS ) LT_VENDORS ).

      ENDIF.
    ENDLOOP.

    IF LT_DEL_CUSTOMERS IS NOT INITIAL.
      MODIFY ENTITIES OF ZIR_DRS_SUBSCR IN LOCAL MODE
        ENTITY Customers
          DELETE FROM LT_DEL_CUSTOMERS.
    ENDIF.

    IF LT_DEL_VENDORS IS NOT INITIAL.
      MODIFY ENTITIES OF ZIR_DRS_SUBSCR IN LOCAL MODE
        ENTITY Vendors
          DELETE FROM LT_DEL_VENDORS.
    ENDIF.

  ENDMETHOD.

ENDCLASS.
