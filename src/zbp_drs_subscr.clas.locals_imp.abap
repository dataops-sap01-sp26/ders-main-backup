*&---------------------------------------------------------------------*
*& Local Classes for Subscription Behavior
*& COMPOSITION: ParamGL01 is child entity (lifecycle managed by parent)
*& COMPOSITION: ParamAR01 is child entity (lifecycle managed by parent)
*& COMPOSITION: ParamAR02 is child entity (lifecycle managed by parent)
*& COMPOSITION: ParamAR03 is child entity (lifecycle managed by parent)
*& COMPOSITION: ParamAP01 is child entity (lifecycle managed by parent)
*& COMPOSITION: ParamAP02 is child entity (lifecycle managed by parent)
*& COMPOSITION: ParamAP03 is child entity (lifecycle managed by parent)
*&---------------------------------------------------------------------*
CLASS lhc_subscription DEFINITION INHERITING FROM cl_abap_behavior_handler.
  PRIVATE SECTION.

    CONSTANTS gc_msg_class TYPE symsgid VALUE 'ZMSG_DRS_SP26_SAP01'.

    METHODS get_global_authorizations FOR GLOBAL AUTHORIZATION
      IMPORTING REQUEST requested_authorizations FOR Subscription RESULT result.

    METHODS get_instance_authorizations FOR INSTANCE AUTHORIZATION
      IMPORTING keys REQUEST requested_authorizations FOR Subscription RESULT result.

    METHODS get_instance_features FOR INSTANCE FEATURES
      IMPORTING keys REQUEST requested_features FOR Subscription RESULT result.

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
    METHODS setDefaultValue FOR DETERMINE ON MODIFY
      IMPORTING keys FOR Subscription~setDefaultValue.

    " Create Report Parameters - generic action based on ReportId
    METHODS createReportParams FOR MODIFY
      IMPORTING keys FOR ACTION Subscription~createReportParams RESULT result.

    METHODS validateDescription FOR VALIDATE ON SAVE
      IMPORTING keys FOR Subscription~validateDescription.

    METHODS validateReport FOR VALIDATE ON SAVE
      IMPORTING keys FOR Subscription~validateReport.

    METHODS validateEmail FOR VALIDATE ON SAVE
      IMPORTING keys FOR Subscription~validateEmail.

ENDCLASS.
*&---------------------------------------------------------------------*
*& Local Classes for GL01 Behavior
*& COMPOSITION: ParamGL01 is child entity (lifecycle managed by parent)
*&---------------------------------------------------------------------*
CLASS lhc_paramgl01 DEFINITION INHERITING FROM cl_abap_behavior_handler.

  PRIVATE SECTION.

    METHODS validateParam FOR VALIDATE ON SAVE
      IMPORTING keys FOR ParamGL01~validateParam.

ENDCLASS.

CLASS lhc_paramgl01 IMPLEMENTATION.

  METHOD validateParam.

    "Read data entered by user on Screen
    READ ENTITIES OF zir_drs_subscr IN LOCAL MODE
      ENTITY ParamGL01
        FIELDS ( CompanyCode GlAccountFr GlAccountTo FiscalPeriodFr FiscalPeriodTo FiscalYearFr FiscalYearTo )
        WITH CORRESPONDING #( keys )
      RESULT DATA(lt_param_gl01).

    "
    LOOP AT lt_param_gl01 ASSIGNING FIELD-SYMBOL(<fs_gl01>).
      IF <fs_gl01>-CompanyCode    IS INITIAL OR
         <fs_gl01>-FiscalYear     IS INITIAL OR
         <fs_gl01>-FiscalPeriodFr IS INITIAL OR <fs_gl01>-FiscalPeriodTo IS INITIAL OR
         <fs_gl01>-GlAccountFr    IS INITIAL OR <fs_gl01>-GlAccountTo    IS INITIAL.

        APPEND VALUE #( %tky = <fs_gl01>-%tky ) TO failed-paramgl01.
        APPEND VALUE #(
          %tky = <fs_gl01>-%tky
          %msg = new_message(
                   id       = 'ZMSG_DRS_SP26_SAP01'
                   number   = '056' " '&1 parameters are incomplete
                   v1       = 'GL01'
                   severity = if_abap_behv_message=>severity-error )

          %element-CompanyCode    = COND #( WHEN <fs_gl01>-CompanyCode    IS INITIAL THEN if_abap_behv=>mk-on ELSE if_abap_behv=>mk-off )
          %element-FiscalYear     = COND #( WHEN <fs_gl01>-FiscalYear     IS INITIAL THEN if_abap_behv=>mk-on ELSE if_abap_behv=>mk-off )
          %element-FiscalPeriodFr = COND #( WHEN <fs_gl01>-FiscalPeriodFr IS INITIAL THEN if_abap_behv=>mk-on ELSE if_abap_behv=>mk-off )
          %element-FiscalPeriodTo = COND #( WHEN <fs_gl01>-FiscalPeriodTo IS INITIAL THEN if_abap_behv=>mk-on ELSE if_abap_behv=>mk-off )
          %element-GlAccountFr    = COND #( WHEN <fs_gl01>-GlAccountFr    IS INITIAL THEN if_abap_behv=>mk-on ELSE if_abap_behv=>mk-off )
          %element-GlAccountTo    = COND #( WHEN <fs_gl01>-GlAccountTo    IS INITIAL THEN if_abap_behv=>mk-on ELSE if_abap_behv=>mk-off )
        ) TO reported-paramgl01.

        CONTINUE.
      ENDIF.


      " Checked G/L Account
      IF <fs_gl01>-GlAccountFr IS NOT INITIAL AND <fs_gl01>-GlAccountTo IS NOT INITIAL.
        IF <fs_gl01>-GlAccountFr > <fs_gl01>-GlAccountTo.
          APPEND VALUE #( %tky = <fs_gl01>-%tky ) TO failed-paramgl01.
          APPEND VALUE #(
            %tky = <fs_gl01>-%tky
            %msg = new_message(
                     id       = 'ZMSG_DRS_SP26_SAP01'
                     number   = '057'
                     severity = if_abap_behv_message=>severity-error )
            %element-GlAccountFr = if_abap_behv=>mk-on
            %element-GlAccountTo = if_abap_behv=>mk-on
          ) TO reported-paramgl01.
        ENDIF.
      ENDIF.

      " Checked Fiscal Period
      IF <fs_gl01>-FiscalPeriodFr > <fs_gl01>-FiscalPeriodTo.
        APPEND VALUE #( %tky = <fs_gl01>-%tky ) TO failed-paramgl01.
        APPEND VALUE #(
          %tky = <fs_gl01>-%tky
          %msg = new_message(
                   id       = 'ZMSG_DRS_SP26_SAP01'
                   number   = '058'
                   severity = if_abap_behv_message=>severity-error )
          %element-FiscalPeriodFr = if_abap_behv=>mk-on
          %element-FiscalPeriodTo = if_abap_behv=>mk-on
        ) TO reported-paramgl01.
      ENDIF.


    ENDLOOP.
  ENDMETHOD.

ENDCLASS.
*&---------------------------------------------------------------------*
*& Local Classes for AR01 Behavior
*& COMPOSITION: ParamAR01 is child entity (lifecycle managed by parent)
*&---------------------------------------------------------------------*
CLASS lhc_paramar01 DEFINITION INHERITING FROM cl_abap_behavior_handler.

  PRIVATE SECTION.

    METHODS validateParam FOR VALIDATE ON SAVE
      IMPORTING keys FOR ParamAR01~validateParam.

ENDCLASS.

CLASS lhc_paramar01 IMPLEMENTATION.

  METHOD validateParam.
    "Read data entered by user on Screen
    READ ENTITIES OF zir_drs_subscr IN LOCAL MODE
        ENTITY ParamAR01
            FIELDS ( CompanyCode KeyDate CustomerFrom CustomerTo )
            WITH CORRESPONDING #( keys )
        RESULT DATA(lt_param_ar01).

    LOOP AT lt_param_ar01 ASSIGNING FIELD-SYMBOL(<fs_ar01>).
      "Check empty
      IF <fs_ar01>-CompanyCode   IS INITIAL OR <fs_ar01>-KeyDate IS INITIAL
      OR <fs_ar01>-CustomerFrom  IS INITIAL OR <fs_ar01>-CustomerTo IS INITIAL.

        APPEND VALUE #( %tky = <fs_ar01>-%tky ) TO failed-paramar01.
        APPEND VALUE #(
          %tky = <fs_ar01>-%tky
          %msg = new_message(
                   id       = 'ZMSG_DRS_SP26_SAP01'
                   number   = '056' "&1 parameters are incomplete
                   v1       = 'AR01'
                   severity = if_abap_behv_message=>severity-error )

          %element-CompanyCode  = COND #( WHEN <fs_ar01>-CompanyCode    IS INITIAL THEN if_abap_behv=>mk-on ELSE if_abap_behv=>mk-off )
          %element-KeyDate      = COND #( WHEN <fs_ar01>-KeyDate        IS INITIAL THEN if_abap_behv=>mk-on ELSE if_abap_behv=>mk-off )
          %element-CustomerFrom = COND #( WHEN <fs_ar01>-CustomerFrom   IS INITIAL THEN if_abap_behv=>mk-on ELSE if_abap_behv=>mk-off )
          %element-CustomerTo   = COND #( WHEN <fs_ar01>-CustomerTo     IS INITIAL THEN if_abap_behv=>mk-on ELSE if_abap_behv=>mk-off )
        ) TO reported-paramar01.

        CONTINUE.
      ENDIF.


      " Checked Customer
      IF <fs_ar01>-CustomerFrom > <fs_ar01>-CustomerTo.
        APPEND VALUE #( %tky = <fs_ar01>-%tky ) TO failed-paramar01.
        APPEND VALUE #(
          %tky = <fs_ar01>-%tky
          %msg = new_message(
                   id       = 'ZMSG_DRS_SP26_SAP01'
                   number   = '060'
                   severity = if_abap_behv_message=>severity-error )
          %element-CustomerFrom = if_abap_behv=>mk-on
          %element-CustomerTo = if_abap_behv=>mk-on
        ) TO reported-paramar01.
      ENDIF.
    ENDLOOP.


  ENDMETHOD.

ENDCLASS.
*&---------------------------------------------------------------------*
*& Local Classes for AR02 Behavior
*& COMPOSITION: ParamAR02 is child entity (lifecycle managed by parent)
*&---------------------------------------------------------------------*
CLASS lhc_paramar02 DEFINITION INHERITING FROM cl_abap_behavior_handler.

  PRIVATE SECTION.

    METHODS validateParam FOR VALIDATE ON SAVE
      IMPORTING keys FOR ParamAR02~validateParam.

ENDCLASS.

CLASS lhc_paramar02 IMPLEMENTATION.

  METHOD validateParam.
    "Read data entered by user on Screen
    READ ENTITIES OF zir_drs_subscr IN LOCAL MODE
        ENTITY ParamAR02
            FIELDS ( CompanyCode FiscalYear CustomerFrom CustomerTo )
            WITH CORRESPONDING #( keys )
        RESULT DATA(lt_param_ar02).

    LOOP AT lt_param_ar02 ASSIGNING FIELD-SYMBOL(<fs_ar02>).
      "Check empty
      IF <fs_ar02>-CompanyCode   IS INITIAL OR <fs_ar02>-FiscalYear IS INITIAL
      OR <fs_ar02>-CustomerFrom  IS INITIAL OR <fs_ar02>-CustomerTo IS INITIAL.

        APPEND VALUE #( %tky = <fs_ar02>-%tky ) TO failed-paramar02.
        APPEND VALUE #(
          %tky = <fs_ar02>-%tky
          %msg = new_message(
                   id       = 'ZMSG_DRS_SP26_SAP01'
                   number   = '056' "&1 parameters are incomplete
                   v1       = 'AR02'
                   severity = if_abap_behv_message=>severity-error )

          %element-CompanyCode  = COND #( WHEN <fs_ar02>-CompanyCode    IS INITIAL THEN if_abap_behv=>mk-on ELSE if_abap_behv=>mk-off )
          %element-FiscalYear   = COND #( WHEN <fs_ar02>-FiscalYear     IS INITIAL THEN if_abap_behv=>mk-on ELSE if_abap_behv=>mk-off )
          %element-CustomerFrom = COND #( WHEN <fs_ar02>-CustomerFrom   IS INITIAL THEN if_abap_behv=>mk-on ELSE if_abap_behv=>mk-off )
          %element-CustomerTo   = COND #( WHEN <fs_ar02>-CustomerTo     IS INITIAL THEN if_abap_behv=>mk-on ELSE if_abap_behv=>mk-off )
        ) TO reported-paramar02.

        CONTINUE.
      ENDIF.

      " Checked Customer
      IF <fs_ar02>-CustomerFrom > <fs_ar02>-CustomerTo.
        APPEND VALUE #( %tky = <fs_ar02>-%tky ) TO failed-paramar02.
        APPEND VALUE #(
          %tky = <fs_ar02>-%tky
          %msg = new_message(
                   id       = 'ZMSG_DRS_SP26_SAP01'
                   number   = '060'
                   severity = if_abap_behv_message=>severity-error )
          %element-CustomerFrom = if_abap_behv=>mk-on
          %element-CustomerTo = if_abap_behv=>mk-on
        ) TO reported-paramar02.
      ENDIF.
    ENDLOOP.
  ENDMETHOD.

ENDCLASS.
*&---------------------------------------------------------------------*
*& Local Classes for AR03 Behavior
*& COMPOSITION: ParamAR03 is child entity (lifecycle managed by parent)
*&---------------------------------------------------------------------*
CLASS lhc_paramar03 DEFINITION INHERITING FROM cl_abap_behavior_handler.

  PRIVATE SECTION.

    METHODS validateParam FOR VALIDATE ON SAVE
      IMPORTING keys FOR ParamAR03~validateParam.

ENDCLASS.

CLASS lhc_paramar03 IMPLEMENTATION.

  METHOD validateParam.
    "Read data entered by user on Screen
    READ ENTITIES OF zir_drs_subscr IN LOCAL MODE
        ENTITY ParamAR03
            FIELDS ( CompanyCode KeyDate CustomerFrom CustomerTo )
            WITH CORRESPONDING #( keys )
        RESULT DATA(lt_param_ar03).

    LOOP AT lt_param_ar03 ASSIGNING FIELD-SYMBOL(<fs_ar03>).
      "Check empty
      IF <fs_ar03>-CompanyCode   IS INITIAL OR <fs_ar03>-KeyDate IS INITIAL
      OR <fs_ar03>-CustomerFrom  IS INITIAL OR <fs_ar03>-CustomerTo IS INITIAL.

        APPEND VALUE #( %tky = <fs_ar03>-%tky ) TO failed-paramar03.
        APPEND VALUE #(
          %tky = <fs_ar03>-%tky
          %msg = new_message(
                   id       = 'ZMSG_DRS_SP26_SAP01'
                   number   = '056' "&1 parameters are incomplete
                   v1       = 'AR03'
                   severity = if_abap_behv_message=>severity-error )

          %element-CompanyCode  = COND #( WHEN <fs_ar03>-CompanyCode    IS INITIAL THEN if_abap_behv=>mk-on ELSE if_abap_behv=>mk-off )
          %element-KeyDate      = COND #( WHEN <fs_ar03>-KeyDate        IS INITIAL THEN if_abap_behv=>mk-on ELSE if_abap_behv=>mk-off )
          %element-CustomerFrom = COND #( WHEN <fs_ar03>-CustomerFrom   IS INITIAL THEN if_abap_behv=>mk-on ELSE if_abap_behv=>mk-off )
          %element-CustomerTo   = COND #( WHEN <fs_ar03>-CustomerTo     IS INITIAL THEN if_abap_behv=>mk-on ELSE if_abap_behv=>mk-off )
        ) TO reported-paramar03.

        CONTINUE.
      ENDIF.

      " Checked Customer
      IF <fs_ar03>-CustomerFrom > <fs_ar03>-CustomerTo.
        APPEND VALUE #( %tky = <fs_ar03>-%tky ) TO failed-paramar03.
        APPEND VALUE #(
          %tky = <fs_ar03>-%tky
          %msg = new_message(
                   id       = 'ZMSG_DRS_SP26_SAP01'
                   number   = '060'
                   severity = if_abap_behv_message=>severity-error )
          %element-CustomerFrom = if_abap_behv=>mk-on
          %element-CustomerTo = if_abap_behv=>mk-on
        ) TO reported-paramar03.
      ENDIF.
    ENDLOOP.
  ENDMETHOD.

ENDCLASS.
*&---------------------------------------------------------------------*
*& Local Classes for AR01 Behavior
*& COMPOSITION: ParamAR01 is child entity (lifecycle managed by parent)
*&---------------------------------------------------------------------*
CLASS lhc_paramap01 DEFINITION INHERITING FROM cl_abap_behavior_handler.

  PRIVATE SECTION.

    METHODS validateParam FOR VALIDATE ON SAVE
      IMPORTING keys FOR ParamAP01~validateParam.

ENDCLASS.

CLASS lhc_paramap01 IMPLEMENTATION.

  METHOD validateParam.
    "Read data entered by user on Screen
    READ ENTITIES OF zir_drs_subscr IN LOCAL MODE
        ENTITY ParamAP01
            FIELDS ( CompanyCode KeyDate VendorFrom VendorTo )
            WITH CORRESPONDING #( keys )
        RESULT DATA(lt_param_ap01).

    LOOP AT lt_param_ap01 ASSIGNING FIELD-SYMBOL(<fs_ap01>).
      "Check empty
      IF <fs_ap01>-CompanyCode IS INITIAL OR <fs_ap01>-KeyDate IS INITIAL
      OR <fs_ap01>-VendorFrom  IS INITIAL OR <fs_ap01>-VendorTo IS INITIAL.

        APPEND VALUE #( %tky = <fs_ap01>-%tky ) TO failed-paramap01.
        APPEND VALUE #(
          %tky = <fs_ap01>-%tky
          %msg = new_message(
                   id       = 'ZMSG_DRS_SP26_SAP01'
                   number   = '056' "&1 parameters are incomplete
                   v1       = 'AP01'
                   severity = if_abap_behv_message=>severity-error )

          %element-CompanyCode = COND #( WHEN <fs_ap01>-CompanyCode     IS INITIAL THEN if_abap_behv=>mk-on ELSE if_abap_behv=>mk-off )
          %element-KeyDate     = COND #( WHEN <fs_ap01>-KeyDate         IS INITIAL THEN if_abap_behv=>mk-on ELSE if_abap_behv=>mk-off )
          %element-VendorFrom  = COND #( WHEN <fs_ap01>-VendorFrom      IS INITIAL THEN if_abap_behv=>mk-on ELSE if_abap_behv=>mk-off )
          %element-VendorTo    = COND #( WHEN <fs_ap01>-VendorTo        IS INITIAL THEN if_abap_behv=>mk-on ELSE if_abap_behv=>mk-off )
        ) TO reported-paramap01.

        CONTINUE.
      ENDIF.

      " Checked Customer
      IF <fs_ap01>-VendorFrom > <fs_ap01>-VendorTo.
        APPEND VALUE #( %tky = <fs_ap01>-%tky ) TO failed-paramap01.
        APPEND VALUE #(
          %tky = <fs_ap01>-%tky
          %msg = new_message(
                   id       = 'ZMSG_DRS_SP26_SAP01'
                   number   = '061'
                   severity = if_abap_behv_message=>severity-error )
          %element-VendorFrom = if_abap_behv=>mk-on
          %element-VendorTo = if_abap_behv=>mk-on
        ) TO reported-paramap01.
      ENDIF.
    ENDLOOP.


  ENDMETHOD.

ENDCLASS.
*&---------------------------------------------------------------------*
*& Local Classes for AR02 Behavior
*& COMPOSITION: ParamAR02 is child entity (lifecycle managed by parent)
*&---------------------------------------------------------------------*
CLASS lhc_paramap02 DEFINITION INHERITING FROM cl_abap_behavior_handler.

  PRIVATE SECTION.

    METHODS validateParam FOR VALIDATE ON SAVE
      IMPORTING keys FOR ParamAP02~validateParam.

ENDCLASS.

CLASS lhc_paramap02 IMPLEMENTATION.

  METHOD validateParam.
    "Read data entered by user on Screen
    READ ENTITIES OF zir_drs_subscr IN LOCAL MODE
        ENTITY ParamAP02
            FIELDS ( CompanyCode FiscalYear VendorFrom VendorTo )
            WITH CORRESPONDING #( keys )
        RESULT DATA(lt_param_ap02).

    LOOP AT lt_param_ap02 ASSIGNING FIELD-SYMBOL(<fs_ap02>).

      "Check empty
      IF <fs_ap02>-CompanyCode IS INITIAL OR <fs_ap02>-FiscalYear IS INITIAL
      OR <fs_ap02>-VendorFrom  IS INITIAL OR <fs_ap02>-VendorTo IS INITIAL.

        APPEND VALUE #( %tky = <fs_ap02>-%tky ) TO failed-paramap02.
        APPEND VALUE #(
          %tky = <fs_ap02>-%tky
          %msg = new_message(
                   id       = 'ZMSG_DRS_SP26_SAP01'
                   number   = '056' "&1 parameters are incomplete
                   v1       = 'AP02'
                   severity = if_abap_behv_message=>severity-error )

          %element-CompanyCode = COND #( WHEN <fs_ap02>-CompanyCode IS INITIAL THEN if_abap_behv=>mk-on ELSE if_abap_behv=>mk-off )
          %element-FiscalYear  = COND #( WHEN <fs_ap02>-FiscalYear  IS INITIAL THEN if_abap_behv=>mk-on ELSE if_abap_behv=>mk-off )
          %element-VendorFrom  = COND #( WHEN <fs_ap02>-VendorFrom  IS INITIAL THEN if_abap_behv=>mk-on ELSE if_abap_behv=>mk-off )
          %element-VendorTo    = COND #( WHEN <fs_ap02>-VendorTo    IS INITIAL THEN if_abap_behv=>mk-on ELSE if_abap_behv=>mk-off )
        ) TO reported-paramap02.

        CONTINUE.
      ENDIF.

      " Checked Vendor
      IF <fs_ap02>-VendorFrom > <fs_ap02>-VendorTo.
        APPEND VALUE #( %tky = <fs_ap02>-%tky ) TO failed-paramap02.
        APPEND VALUE #(
          %tky = <fs_ap02>-%tky
          %msg = new_message(
                   id       = 'ZMSG_DRS_SP26_SAP01'
                   number   = '061'
                   severity = if_abap_behv_message=>severity-error )
          %element-VendorFrom = if_abap_behv=>mk-on
          %element-VendorTo = if_abap_behv=>mk-on
        ) TO reported-paramap02.
      ENDIF.
    ENDLOOP.
  ENDMETHOD.

ENDCLASS.
*&---------------------------------------------------------------------*
*& Local Classes for AR03 Behavior
*& COMPOSITION: ParamAR03 is child entity (lifecycle managed by parent)
*&---------------------------------------------------------------------*
CLASS lhc_paramap03 DEFINITION INHERITING FROM cl_abap_behavior_handler.

  PRIVATE SECTION.

    METHODS validateParam FOR VALIDATE ON SAVE
      IMPORTING keys FOR ParamAP03~validateParam.

ENDCLASS.

CLASS lhc_paramap03 IMPLEMENTATION.

  METHOD validateParam.
    "Read data entered by user on Screen
    READ ENTITIES OF zir_drs_subscr IN LOCAL MODE
        ENTITY ParamAP03
            FIELDS ( CompanyCode KeyDate VendorFrom VendorTo )
            WITH CORRESPONDING #( keys )
        RESULT DATA(lt_param_ap03).

    LOOP AT lt_param_ap03 ASSIGNING FIELD-SYMBOL(<fs_ap03>).
      "Check empty
      IF <fs_ap03>-CompanyCode IS INITIAL OR <fs_ap03>-KeyDate IS INITIAL
      OR <fs_ap03>-VendorFrom  IS INITIAL OR <fs_ap03>-VendorTo IS INITIAL.

        APPEND VALUE #( %tky = <fs_ap03>-%tky ) TO failed-paramap03.
        APPEND VALUE #(
          %tky = <fs_ap03>-%tky
          %msg = new_message(
                   id       = 'ZMSG_DRS_SP26_SAP01'
                   number   = '056' "&1 parameters are incomplete
                   v1       = 'AP03'
                   severity = if_abap_behv_message=>severity-error )

          %element-CompanyCode = COND #( WHEN <fs_ap03>-CompanyCode IS INITIAL THEN if_abap_behv=>mk-on ELSE if_abap_behv=>mk-off )
          %element-KeyDate     = COND #( WHEN <fs_ap03>-KeyDate     IS INITIAL THEN if_abap_behv=>mk-on ELSE if_abap_behv=>mk-off )
          %element-VendorFrom  = COND #( WHEN <fs_ap03>-VendorFrom  IS INITIAL THEN if_abap_behv=>mk-on ELSE if_abap_behv=>mk-off )
          %element-VendorTo    = COND #( WHEN <fs_ap03>-VendorTo    IS INITIAL THEN if_abap_behv=>mk-on ELSE if_abap_behv=>mk-off )
        ) TO reported-paramap03.

        CONTINUE.
      ENDIF.

      " Checked Vendor
      IF <fs_ap03>-VendorFrom > <fs_ap03>-VendorTo.
        APPEND VALUE #( %tky = <fs_ap03>-%tky ) TO failed-paramap03.
        APPEND VALUE #(
          %tky = <fs_ap03>-%tky
          %msg = new_message(
                   id       = 'ZMSG_DRS_SP26_SAP01'
                   number   = '061'
                   severity = if_abap_behv_message=>severity-error )
          %element-VendorFrom = if_abap_behv=>mk-on
          %element-VendorTo = if_abap_behv=>mk-on
        ) TO reported-paramap03.
      ENDIF.
    ENDLOOP.
  ENDMETHOD.

ENDCLASS.

CLASS lhc_subscription IMPLEMENTATION.

  METHOD get_global_authorizations.
    " ═══════════════════════════════════════════════════════════════════════════
    " GLOBAL AUTHORIZATION: Check if user has at least ONE report in ZDRS_REP
    " NOTE: This is a coarse-grained check. Fine-grained row-level security is
    "       enforced by DCL (ZIR_DRS_SUBSCR) and GET_INSTANCE_AUTHORIZATIONS.
    " ═══════════════════════════════════════════════════════════════════════════
    DATA lv_has_auth TYPE abap_bool.

    IF requested_authorizations-%create EQ if_abap_behv=>mk-on.
      " Check if user has at least one ZDRS_REP authorization entry
      " Using DUMMY allows specific report IDs (AR-01, AP-01, etc.) to pass
      AUTHORITY-CHECK OBJECT 'ZDRS_REP'
        ID 'ZREP_ID' DUMMY
        ID 'ACTVT'   FIELD '01'.       " 01 = Create
      result-%create = COND #( WHEN sy-subrc = 0
                               THEN if_abap_behv=>auth-allowed
                               ELSE if_abap_behv=>auth-unauthorized ).
    ENDIF.

    IF requested_authorizations-%update EQ if_abap_behv=>mk-on.
      AUTHORITY-CHECK OBJECT 'ZDRS_REP'
        ID 'ZREP_ID' DUMMY
        ID 'ACTVT'   FIELD '02'.       " 02 = Change
      result-%update = COND #( WHEN sy-subrc = 0
                               THEN if_abap_behv=>auth-allowed
                               ELSE if_abap_behv=>auth-unauthorized ).
    ENDIF.

    IF requested_authorizations-%delete EQ if_abap_behv=>mk-on.
      AUTHORITY-CHECK OBJECT 'ZDRS_REP'
        ID 'ZREP_ID' DUMMY
        ID 'ACTVT'   FIELD '06'.       " 06 = Delete
      result-%delete = COND #( WHEN sy-subrc = 0
                               THEN if_abap_behv=>auth-allowed
                               ELSE if_abap_behv=>auth-unauthorized ).
    ENDIF.
  ENDMETHOD.

  METHOD get_instance_authorizations.
    " ═══════════════════════════════════════════════════════════════════════════
    " INSTANCE AUTHORIZATION: Check if user can UPDATE/DELETE specific subscriptions
    " CONDITIONS:
    "   1. User must be the creator (CreatedBy = current user)
    "   2. User must have access to the report (ZDRS_REP check)
    "   3. User must have access to the company code (F_BKPF_BUK check)
    " ═══════════════════════════════════════════════════════════════════════════

    " Read subscription data
    READ ENTITIES OF zir_drs_subscr IN LOCAL MODE
      ENTITY Subscription
        FIELDS ( SubscrUuid ReportId Bukrs CreatedBy )
        WITH CORRESPONDING #( keys )
      RESULT DATA(lt_subscr)
      FAILED failed.

    " Check authorization for each subscription
    DATA lv_update_auth TYPE if_abap_behv=>t_xflag.
    DATA lv_delete_auth TYPE if_abap_behv=>t_xflag.
    DATA lv_current_user TYPE syuname.
    lv_current_user = cl_abap_context_info=>get_user_technical_name( ).

    LOOP AT lt_subscr ASSIGNING FIELD-SYMBOL(<ls_subscr>).
      " For new drafts: fields are empty → allow editing so user can fill them
      IF <ls_subscr>-CreatedBy IS INITIAL
        AND <ls_subscr>-ReportId IS INITIAL.
        lv_update_auth = if_abap_behv=>auth-allowed.
        lv_delete_auth = if_abap_behv=>auth-allowed.

        " Condition 1: User must be creator (skip if CreatedBy not yet set)
      ELSEIF <ls_subscr>-CreatedBy IS NOT INITIAL
        AND <ls_subscr>-CreatedBy <> lv_current_user.
        lv_update_auth = if_abap_behv=>auth-unauthorized.
        lv_delete_auth = if_abap_behv=>auth-unauthorized.

      ELSE.
        " Default: allow (covers case when CreatedBy matches current user)
        lv_update_auth = if_abap_behv=>auth-allowed.
        lv_delete_auth = if_abap_behv=>auth-allowed.

        " Condition 2: Check report access (only if ReportId is filled)
        IF <ls_subscr>-ReportId IS NOT INITIAL.
          AUTHORITY-CHECK OBJECT 'ZDRS_REP'
          ID 'ZREP_ID' FIELD <ls_subscr>-ReportId
          ID 'ACTVT'   FIELD '03'.
          IF sy-subrc <> 0.
            lv_update_auth = if_abap_behv=>auth-unauthorized.
            lv_delete_auth = if_abap_behv=>auth-unauthorized.
          ENDIF.
        ENDIF.

        " Condition 3: Check company code access (only if Bukrs is filled)
        IF lv_update_auth = if_abap_behv=>auth-allowed
          AND <ls_subscr>-Bukrs IS NOT INITIAL.
          AUTHORITY-CHECK OBJECT 'F_BKPF_BUK'
          ID 'BUKRS' FIELD <ls_subscr>-Bukrs
          ID 'ACTVT' FIELD '03'.
          IF sy-subrc <> 0.
            lv_update_auth = if_abap_behv=>auth-unauthorized.
            lv_delete_auth = if_abap_behv=>auth-unauthorized.
          ENDIF.
        ENDIF.
      ENDIF.

      " Add result
      APPEND VALUE #( %tky = <ls_subscr>-%tky
                      %update = lv_update_auth
                      %delete = lv_delete_auth
                      " Actions inherit update authorization
                      %action-pauseSubscription = lv_update_auth
                      %action-resumeSubscription = lv_update_auth
                      %action-copySubscription = lv_update_auth
                      %action-createReportParams = lv_update_auth )
             TO result.
    ENDLOOP.
  ENDMETHOD.

  METHOD get_instance_features.
    " Read ReportID of Subscription
    READ ENTITIES OF zir_drs_subscr IN LOCAL MODE
      ENTITY Subscription
        FIELDS ( ReportId ) WITH CORRESPONDING #( keys )
      RESULT DATA(lt_subscriptions).


    LOOP AT lt_subscriptions ASSIGNING FIELD-SYMBOL(<fs_sub>).
      DATA(lv_is_locked) = abap_false.

      " Check if ReportID is created
      CASE <fs_sub>-ReportId.
        WHEN 'GL-01'.
          READ ENTITIES OF zir_drs_subscr IN LOCAL MODE
            ENTITY Subscription BY \_ParamGL01
            FIELDS ( SubscrUuid ) WITH VALUE #( ( %tky = <fs_sub>-%tky ) )
            RESULT DATA(lt_gl01).
          "if ReportID was created, lock ReportID field
          IF lt_gl01 IS NOT INITIAL. lv_is_locked = abap_true. ENDIF.

        WHEN 'AR-01'.
          READ ENTITIES OF zir_drs_subscr IN LOCAL MODE
            ENTITY Subscription BY \_ParamAR01
            FIELDS ( SubscrUuid ) WITH VALUE #( ( %tky = <fs_sub>-%tky ) )
            RESULT DATA(lt_ar01).
          "if ReportID was created, lock ReportID field
          IF lt_ar01 IS NOT INITIAL. lv_is_locked = abap_true. ENDIF.

        WHEN 'AR-02'.
          READ ENTITIES OF zir_drs_subscr IN LOCAL MODE
            ENTITY Subscription BY \_ParamAR02
            FIELDS ( SubscrUuid ) WITH VALUE #( ( %tky = <fs_sub>-%tky ) )
            RESULT DATA(lt_ar02).
          "if ReportID was created, lock ReportID field
          IF lt_ar02 IS NOT INITIAL. lv_is_locked = abap_true. ENDIF.

        WHEN 'AR-03'.
          READ ENTITIES OF zir_drs_subscr IN LOCAL MODE
            ENTITY Subscription BY \_ParamAR03
            FIELDS ( SubscrUuid ) WITH VALUE #( ( %tky = <fs_sub>-%tky ) )
            RESULT DATA(lt_ar03).
          "if ReportID was created, lock ReportID field
          IF lt_ar03 IS NOT INITIAL. lv_is_locked = abap_true. ENDIF.

        WHEN 'AP-01'.
          READ ENTITIES OF zir_drs_subscr IN LOCAL MODE
            ENTITY Subscription BY \_ParamAP01
            FIELDS ( SubscrUuid ) WITH VALUE #( ( %tky = <fs_sub>-%tky ) )
            RESULT DATA(lt_ap01).
          "if ReportID was created, lock ReportID field
          IF lt_ap01 IS NOT INITIAL. lv_is_locked = abap_true. ENDIF.

        WHEN 'AP-02'.
          READ ENTITIES OF zir_drs_subscr IN LOCAL MODE
            ENTITY Subscription BY \_ParamAP02
            FIELDS ( SubscrUuid ) WITH VALUE #( ( %tky = <fs_sub>-%tky ) )
            RESULT DATA(lt_ap02).
          "if ReportID was created, lock ReportID field
          IF lt_ap02 IS NOT INITIAL. lv_is_locked = abap_true. ENDIF.

        WHEN 'AP-03'.
          READ ENTITIES OF zir_drs_subscr IN LOCAL MODE
            ENTITY Subscription BY \_ParamAP03
            FIELDS ( SubscrUuid ) WITH VALUE #( ( %tky = <fs_sub>-%tky ) )
            RESULT DATA(lt_ap03).
          "if ReportID was created, lock ReportID field
          IF lt_ap03 IS NOT INITIAL. lv_is_locked = abap_true. ENDIF.

      ENDCASE.

      " Render for UI (locking ReportID field)
      APPEND VALUE #(
        %tky = <fs_sub>-%tky
        %field-ReportId = COND #(
          WHEN lv_is_locked = abap_true
          THEN if_abap_behv=>fc-f-read_only
          ELSE if_abap_behv=>fc-f-unrestricted
        )
      ) TO result.

    ENDLOOP.
  ENDMETHOD.


  METHOD earlynumbering_create.
    " Generate UUID and Subscription ID for new subscriptions
    DATA: lv_current_max   TYPE n LENGTH 6,
          lv_new_subscr_id TYPE n LENGTH 6,
          lv_uuid          TYPE sysuuid_x16,
          lv_id            TYPE n LENGTH 6.

    " Get max subscr_id from DB and increment
    SELECT SINGLE MAX( subscr_id ) FROM zdrs_subscr INTO @DATA(lv_max_active).

    " Get max subscr_id from Draft DB and increment
    SELECT SINGLE MAX( subscrid ) FROM zdrs_d_subscr INTO @DATA(lv_max_draft).

    lv_current_max = nmax( val1 = lv_max_active val2 = lv_max_draft ).

    lv_new_subscr_id = lv_current_max + 1.

    LOOP AT entities ASSIGNING FIELD-SYMBOL(<entity>).
      " Generate UUID if not provided
      IF <entity>-SubscrUuid IS INITIAL.
        lv_uuid = cl_system_uuid=>create_uuid_x16_static( ).
      ELSE.
        lv_uuid = <entity>-SubscrUuid.
      ENDIF.

      " Use provided SubscrId or generate new one
      IF <entity>-SubscrId IS INITIAL.
        lv_id = lv_new_subscr_id.
        lv_new_subscr_id = lv_new_subscr_id + 1.
      ELSE.
        lv_id = <entity>-SubscrId.
      ENDIF.

      APPEND VALUE #( %cid       = <entity>-%cid
                      %is_draft  = <entity>-%is_draft
                      SubscrUuid = lv_uuid
                      SubscrId   = lv_id )
             TO mapped-subscription.
    ENDLOOP.
  ENDMETHOD.


  METHOD setDefaultValue.
    " Set status to 'A' (Active) when subscription is created
    READ ENTITIES OF zir_drs_subscr IN LOCAL MODE
      ENTITY Subscription
        FIELDS ( Status OutputFormat ) WITH CORRESPONDING #( keys )
      RESULT DATA(lt_subscr).

    DATA lt_update TYPE TABLE FOR UPDATE zir_drs_subscr.

    LOOP AT lt_subscr INTO DATA(ls_subscr).

      IF ls_subscr-Status IS INITIAL OR ls_subscr-OutputFormat IS INITIAL.

        APPEND VALUE #(
            %tky          = ls_subscr-%tky
            Status        = COND #( WHEN ls_subscr-Status IS INITIAL THEN 'A' ELSE ls_subscr-Status )
            OutputFormat  = COND #( WHEN ls_subscr-OutputFormat IS INITIAL THEN 'XLSX' ELSE ls_subscr-OutputFormat )
            %control-Status       = if_abap_behv=>mk-on
            %control-OutputFormat = if_abap_behv=>mk-on
        ) TO lt_update.

      ENDIF.
    ENDLOOP.

    IF lt_update IS NOT INITIAL.
      MODIFY ENTITIES OF zir_drs_subscr IN LOCAL MODE
        ENTITY Subscription
          UPDATE FIELDS ( Status OutputFormat ) WITH lt_update
        REPORTED DATA(lt_reported)
        FAILED DATA(lt_failed_modify).
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

    " Read associated parameters via composition
    READ ENTITIES OF zir_drs_subscr IN LOCAL MODE
        ENTITY Subscription BY \_ParamGL01 ALL FIELDS WITH CORRESPONDING #( keys ) RESULT DATA(lt_source_gl01)
        ENTITY Subscription BY \_ParamAR01 ALL FIELDS WITH CORRESPONDING #( keys ) RESULT DATA(lt_source_ar01)
        ENTITY Subscription BY \_ParamAR02 ALL FIELDS WITH CORRESPONDING #( keys ) RESULT DATA(lt_source_ar02)
        ENTITY Subscription BY \_ParamAR03 ALL FIELDS WITH CORRESPONDING #( keys ) RESULT DATA(lt_source_ar03)
        ENTITY Subscription BY \_ParamAP01 ALL FIELDS WITH CORRESPONDING #( keys ) RESULT DATA(lt_source_ap01)
        ENTITY Subscription BY \_ParamAP02 ALL FIELDS WITH CORRESPONDING #( keys ) RESULT DATA(lt_source_ap02)
        ENTITY Subscription BY \_ParamAP03 ALL FIELDS WITH CORRESPONDING #( keys ) RESULT DATA(lt_source_ap03).

    " Get max subscr_id for new ID generation
    SELECT MAX( subscr_id ) FROM zdrs_subscr INTO @DATA(lv_max_id).
    DATA(lv_new_subscr_id) = lv_max_id + 1.

    " Data declarations for creating composition nodes
    DATA lt_subscr     TYPE TABLE FOR CREATE zir_drs_subscr.
    DATA lt_param_gl01 TYPE TABLE FOR CREATE zir_drs_subscr\_ParamGL01.
    DATA lt_param_ar01 TYPE TABLE FOR CREATE zir_drs_subscr\_ParamAR01.
    DATA lt_param_ar02 TYPE TABLE FOR CREATE zir_drs_subscr\_ParamAR02.
    DATA lt_param_ar03 TYPE TABLE FOR CREATE zir_drs_subscr\_ParamAR03.
    DATA lt_param_ap01 TYPE TABLE FOR CREATE zir_drs_subscr\_ParamAP01.
    DATA lt_param_ap02 TYPE TABLE FOR CREATE zir_drs_subscr\_ParamAP02.
    DATA lt_param_ap03 TYPE TABLE FOR CREATE zir_drs_subscr\_ParamAP03.

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

      " --- GL01 Params (Updated based on image) ---
      IF lt_source_gl01 IS NOT INITIAL.
        LOOP AT lt_source_gl01 ASSIGNING FIELD-SYMBOL(<gl01>) WHERE SubscrUuid = <source>-SubscrUuid.
          APPEND VALUE #( %cid_ref = lv_cid
                          %target = VALUE #( (
                            %cid           = |GL01_{ lv_idx }|
                            %is_draft      = <source>-%is_draft
                            CompanyCode    = <gl01>-CompanyCode
                            GlAccountFr    = <gl01>-GlAccountFr
                            GlAccountTo    = <gl01>-GlAccountTo
                            FiscalPeriodFr = <gl01>-FiscalPeriodFr
                            FiscalPeriodTo = <gl01>-FiscalPeriodTo
                            FiscalYearFr   = <gl01>-FiscalYearFr
                            FiscalYearTo   = <gl01>-FiscalYearTo
                            MaxRows        = <gl01>-MaxRows ) ) )
                 TO lt_param_gl01.
        ENDLOOP.
      ENDIF.

      " --- AR01 Params ---
      IF lt_source_ar01 IS NOT INITIAL.
        LOOP AT lt_source_ar01 ASSIGNING FIELD-SYMBOL(<ar01>) WHERE SubscrUuid = <source>-SubscrUuid.
          APPEND VALUE #( %cid_ref = lv_cid
                          %target = VALUE #( (
                            %cid          = |AR01_{ lv_idx }|
                            %is_draft     = <source>-%is_draft
                            CompanyCode   = <ar01>-CompanyCode
                            CustomerFrom  = <ar01>-CustomerFrom
                            CustomerTo    = <ar01>-CustomerTo
                            KeyDate       = <ar01>-KeyDate
                            MaxRows       = <ar01>-MaxRows ) ) )
                 TO lt_param_ar01.
        ENDLOOP.
      ENDIF.

      " --- AR02 Params ---
      IF lt_source_ar02 IS NOT INITIAL.
        LOOP AT lt_source_ar02 ASSIGNING FIELD-SYMBOL(<ar02>) WHERE SubscrUuid = <source>-SubscrUuid.
          APPEND VALUE #( %cid_ref = lv_cid
                          %target = VALUE #( (
                            %cid          = |AR02_{ lv_idx }|
                            %is_draft     = <source>-%is_draft
                            CompanyCode   = <ar02>-CompanyCode
                            CustomerFrom  = <ar02>-CustomerFrom
                            CustomerTo    = <ar02>-CustomerTo
                            FiscalYear    = <ar02>-FiscalYear
                            MaxRows       = <ar02>-MaxRows ) ) )
                 TO lt_param_ar02.
        ENDLOOP.
      ENDIF.

      " --- AR03 Params ---
      IF lt_source_ar03 IS NOT INITIAL.
        LOOP AT lt_source_ar03 ASSIGNING FIELD-SYMBOL(<ar03>) WHERE SubscrUuid = <source>-SubscrUuid.
          APPEND VALUE #( %cid_ref = lv_cid
                          %target = VALUE #( (
                            %cid          = |AR03_{ lv_idx }|
                            %is_draft     = <source>-%is_draft
                            CompanyCode   = <ar03>-CompanyCode
                            CustomerFrom  = <ar03>-CustomerFrom
                            CustomerTo    = <ar03>-CustomerTo
                            KeyDate       = <ar03>-KeyDate
                            MaxRows       = <ar03>-MaxRows ) ) )
                 TO lt_param_ar03.
        ENDLOOP.
      ENDIF.

      " --- AP01 Params ---
      IF lt_source_ap01 IS NOT INITIAL.
        LOOP AT lt_source_ap01 ASSIGNING FIELD-SYMBOL(<ap01>) WHERE SubscrUuid = <source>-SubscrUuid.
          APPEND VALUE #( %cid_ref = lv_cid
                          %target = VALUE #( (
                            %cid          = |AP01_{ lv_idx }|
                            %is_draft     = <source>-%is_draft
                            CompanyCode   = <ap01>-CompanyCode
                            VendorFrom    = <ap01>-VendorFrom
                            VendorTo      = <ap01>-VendorTo
                            KeyDate       = <ap01>-KeyDate
                            MaxRows       = <ap01>-MaxRows ) ) )
                 TO lt_param_ap01.
        ENDLOOP.
      ENDIF.

      " --- AP02 Params ---
      IF lt_source_ar02 IS NOT INITIAL.
        LOOP AT lt_source_ap02 ASSIGNING FIELD-SYMBOL(<ap02>) WHERE SubscrUuid = <source>-SubscrUuid.
          APPEND VALUE #( %cid_ref = lv_cid
                          %target = VALUE #( (
                            %cid         = |AP02_{ lv_idx }|
                            %is_draft    = <source>-%is_draft
                            CompanyCode  = <ap02>-CompanyCode
                            VendorFrom   = <ap02>-VendorFrom
                            VendorTo     = <ap02>-VendorTo
                            FiscalYear   = <ap02>-FiscalYear
                            MaxRows      = <ap02>-MaxRows ) ) )
                 TO lt_param_ap02.
        ENDLOOP.
      ENDIF.

      " --- AP03 Params ---
      IF lt_source_ap03 IS NOT INITIAL.
        LOOP AT lt_source_ap03 ASSIGNING FIELD-SYMBOL(<ap03>) WHERE SubscrUuid = <source>-SubscrUuid.
          APPEND VALUE #( %cid_ref = lv_cid
                          %target = VALUE #( (
                            %cid         = |AP03_{ lv_idx }|
                            %is_draft    = <source>-%is_draft
                            CompanyCode  = <ap03>-CompanyCode
                            VendorFrom   = <ap03>-VendorFrom
                            VendorTo     = <ap03>-VendorTo
                            KeyDate      = <ap03>-KeyDate
                            MaxRows      = <ap03>-MaxRows ) ) )
                 TO lt_param_ap03.
        ENDLOOP.
      ENDIF.

      lv_new_subscr_id = lv_new_subscr_id + 1.
    ENDLOOP.

    " Create subscriptions and all associations via RAP
    MODIFY ENTITIES OF zir_drs_subscr IN LOCAL MODE
      ENTITY Subscription
        CREATE FROM lt_subscr
        CREATE BY \_ParamGL01 FROM lt_param_gl01
        CREATE BY \_ParamAR01 FROM lt_param_ar01
        CREATE BY \_ParamAR02 FROM lt_param_ar02
        CREATE BY \_ParamAR03 FROM lt_param_ar03
        CREATE BY \_ParamAP01 FROM lt_param_ap01
        CREATE BY \_ParamAP02 FROM lt_param_ap02
        CREATE BY \_ParamAP03 FROM lt_param_ap03
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
    " createReportParams: Generic action based on ReportId
    " Uses composition - creates ParamGL01 via _ParamGL01 association
    " GL-01 → _ParamGL01, GL-02 → _ParamGL02 (future), etc.
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

    " Read existing AP03 params via composition
    READ ENTITIES OF zir_drs_subscr IN LOCAL MODE
      ENTITY Subscription BY \_ParamAP03
        FIELDS ( SubscrUuid ) WITH CORRESPONDING #( keys )
      RESULT DATA(lt_existing_ap03).

    DATA lt_create_ap03 TYPE TABLE FOR CREATE zir_drs_subscr\_ParamAP03.

    LOOP AT lt_subscr ASSIGNING FIELD-SYMBOL(<subscr>).
      CASE <subscr>-ReportId.
        WHEN 'GL-01'.
          " Check if already exists
          READ TABLE lt_existing_gl01 WITH KEY SubscrUuid = <subscr>-SubscrUuid TRANSPORTING NO FIELDS.
          IF sy-subrc = 0.
            " Already exists - report info message
            APPEND VALUE #(
              %tky = CORRESPONDING #( <subscr> )
              %msg = new_message(
                  id       = gc_msg_class
                  number   = '051' " '&1 parameters already exist...'
                  severity = if_abap_behv_message=>severity-error " Theo code gốc GL-01 là ERROR
                  v1       = <subscr>-ReportId )
              %element-ReportId = if_abap_behv=>mk-on )
            TO reported-subscription.
          ELSE.
            APPEND VALUE #(
              %tky = CORRESPONDING #( <subscr> )
              %target = VALUE #( (
                %cid        = |{ <subscr>-ReportId }_{ sy-tabix }|
                %is_draft   = <subscr>-%is_draft
                MaxRows     = 100
                %control-MaxRows = if_abap_behv=>mk-on ) )
            ) TO lt_create_gl01.
          ENDIF.

        WHEN 'AR-01'.
          READ TABLE lt_existing_ar01 WITH KEY SubscrUuid = <subscr>-SubscrUuid TRANSPORTING NO FIELDS.
          IF sy-subrc = 0.
            APPEND VALUE #(
              %tky = CORRESPONDING #( <subscr> )
              %msg = new_message(
                id       = gc_msg_class
                number   = '051' " '&1 parameters already exist...'
                severity = if_abap_behv_message=>severity-information
                v1       = <subscr>-ReportId )
            ) TO reported-subscription.
          ELSE.
            APPEND VALUE #(
              %tky = CORRESPONDING #( <subscr> )
              %target = VALUE #( (
                %cid        = |{ <subscr>-ReportId }_{ sy-tabix }|
                %is_draft   = <subscr>-%is_draft
                MaxRows     = 100
                %control-MaxRows = if_abap_behv=>mk-on ) )
            ) TO lt_create_ar01.
          ENDIF.

        WHEN 'AR-02'.
          READ TABLE lt_existing_ar02 WITH KEY SubscrUuid = <subscr>-SubscrUuid TRANSPORTING NO FIELDS.
          IF sy-subrc = 0.
            APPEND VALUE #(
              %tky = CORRESPONDING #( <subscr> )
              %msg = new_message(
                id       = gc_msg_class
                number   = '051' " '&1 parameters already exist...'
                severity = if_abap_behv_message=>severity-information
                v1       = <subscr>-ReportId )
            ) TO reported-subscription.
          ELSE.
            APPEND VALUE #(
              %tky = CORRESPONDING #( <subscr> )
              %target = VALUE #( (
                %cid        = |{ <subscr>-ReportId }_{ sy-tabix }|
                %is_draft   = <subscr>-%is_draft
                MaxRows     = 100
                %control-MaxRows = if_abap_behv=>mk-on ) )
            ) TO lt_create_ar02.
          ENDIF.

        WHEN 'AR-03'.
          READ TABLE lt_existing_ar03 WITH KEY SubscrUuid = <subscr>-SubscrUuid TRANSPORTING NO FIELDS.
          IF sy-subrc = 0.
            APPEND VALUE #(
              %tky = CORRESPONDING #( <subscr> )
              %msg = new_message(
                id       = gc_msg_class
                number   = '051' " '&1 parameters already exist...'
                severity = if_abap_behv_message=>severity-information
                v1       = <subscr>-ReportId )
            ) TO reported-subscription.
          ELSE.
            APPEND VALUE #(
              %tky = CORRESPONDING #( <subscr> )
              %target = VALUE #( (
                %cid        = |{ <subscr>-ReportId }_{ sy-tabix }|
                %is_draft   = <subscr>-%is_draft
                MaxRows     = 100
                %control-MaxRows = if_abap_behv=>mk-on ) )
            ) TO lt_create_ar03.
          ENDIF.

        WHEN 'AP-01'.
          READ TABLE lt_existing_ap01 WITH KEY SubscrUuid = <subscr>-SubscrUuid TRANSPORTING NO FIELDS.
          IF sy-subrc = 0.
            APPEND VALUE #(
              %tky = CORRESPONDING #( <subscr> )
              %msg = new_message(
                id       = gc_msg_class
                number   = '051' " '&1 parameters already exist...'
                severity = if_abap_behv_message=>severity-information
                v1       = <subscr>-ReportId )
            ) TO reported-subscription.
          ELSE.
            APPEND VALUE #(
              %tky = CORRESPONDING #( <subscr> )
              %target = VALUE #( (
                %cid        = |{ <subscr>-ReportId }_{ sy-tabix }|
                %is_draft   = <subscr>-%is_draft
                MaxRows     = 100
                %control-MaxRows = if_abap_behv=>mk-on ) )
            ) TO lt_create_ap01.
          ENDIF.

        WHEN 'AP-02'.
          READ TABLE lt_existing_ap02 WITH KEY SubscrUuid = <subscr>-SubscrUuid TRANSPORTING NO FIELDS.
          IF sy-subrc = 0.
            APPEND VALUE #(
              %tky = CORRESPONDING #( <subscr> )
              %msg = new_message(
                id       = gc_msg_class
                number   = '051' " '&1 parameters already exist...'
                severity = if_abap_behv_message=>severity-information
                v1       = <subscr>-ReportId )
            ) TO reported-subscription.
          ELSE.
            APPEND VALUE #(
              %tky = CORRESPONDING #( <subscr> )
              %target = VALUE #( (
                %cid        = |{ <subscr>-ReportId }_{ sy-tabix }|
                %is_draft   = <subscr>-%is_draft
                MaxRows     = 100
                %control-MaxRows = if_abap_behv=>mk-on ) )
            ) TO lt_create_ap02.
          ENDIF.

        WHEN 'AP-03'.
          READ TABLE lt_existing_ap03 WITH KEY SubscrUuid = <subscr>-SubscrUuid TRANSPORTING NO FIELDS.
          IF sy-subrc = 0.
            APPEND VALUE #(
              %tky = CORRESPONDING #( <subscr> )
              %msg = new_message(
                id       = gc_msg_class
                number   = '051' " '&1 parameters already exist...'
                severity = if_abap_behv_message=>severity-information
                v1       = <subscr>-ReportId )
            ) TO reported-subscription.
          ELSE.
            APPEND VALUE #(
              %tky = CORRESPONDING #( <subscr> )
              %target = VALUE #( (
                %cid        = |{ <subscr>-ReportId }_{ sy-tabix }|
                %is_draft   = <subscr>-%is_draft
                MaxRows     = 100
                %control-MaxRows = if_abap_behv=>mk-on ) )
            ) TO lt_create_ap03.
          ENDIF.

        WHEN OTHERS.
          APPEND VALUE #(
            %tky = CORRESPONDING #( <subscr> )
            %msg = new_message(
              id       = gc_msg_class
              number   = '053' " 'Report type &1 does not have configurable parameters'
              severity = if_abap_behv_message=>severity-warning
              v1       = <subscr>-ReportId )
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

      IF lt_create_failed-paramgl01 IS INITIAL.
        LOOP AT lt_create_gl01 ASSIGNING FIELD-SYMBOL(<created>).
          APPEND VALUE #(
            %tky = <created>-%tky
            %msg = new_message(
              id       = gc_msg_class
              number   = '052' " '&1 parameters created successfully'
              severity = if_abap_behv_message=>severity-success
              v1       = 'GL-01' ) " Truyền trực tiếp ReportId
          ) TO reported-subscription.
        ENDLOOP.
      ENDIF.
    ENDIF.

    " Create AR01 params
    IF lt_create_ar01 IS NOT INITIAL.
      MODIFY ENTITIES OF zir_drs_subscr IN LOCAL MODE
        ENTITY Subscription
          CREATE BY \_ParamAR01 FROM lt_create_ar01
        MAPPED DATA(lt_mapped_ar01)
        FAILED DATA(lt_failed_ar01)
        REPORTED DATA(lt_reported_ar01).

      IF lt_failed_ar01-paramar01 IS INITIAL.
        LOOP AT lt_create_ar01 ASSIGNING FIELD-SYMBOL(<created_ar01>).
          APPEND VALUE #(
            %tky = <created_ar01>-%tky
            %msg = new_message(
              id       = gc_msg_class
              number   = '052' " '&1 parameters created successfully'
              severity = if_abap_behv_message=>severity-success
              v1       = 'AR-01' )
          ) TO reported-subscription.
        ENDLOOP.
      ENDIF.
    ENDIF.

    " Create AR02 params
    IF lt_create_ar02 IS NOT INITIAL.
      MODIFY ENTITIES OF zir_drs_subscr IN LOCAL MODE
        ENTITY Subscription
          CREATE BY \_ParamAR02 FROM lt_create_ar02
        MAPPED DATA(lt_mapped_ar02)
        FAILED DATA(lt_failed_ar02)
        REPORTED DATA(lt_reported_ar02).

      IF lt_failed_ar02-paramar02 IS INITIAL.
        LOOP AT lt_create_ar02 ASSIGNING FIELD-SYMBOL(<created_ar02>).
          APPEND VALUE #(
            %tky = <created_ar02>-%tky
            %msg = new_message(
              id       = gc_msg_class
              number   = '052' " '&1 parameters created successfully'
              severity = if_abap_behv_message=>severity-success
              v1       = 'AR-02' )
          ) TO reported-subscription.
        ENDLOOP.
      ENDIF.
    ENDIF.

    " Create AR03 params
    IF lt_create_ar03 IS NOT INITIAL.
      MODIFY ENTITIES OF zir_drs_subscr IN LOCAL MODE
        ENTITY Subscription
          CREATE BY \_ParamAR03 FROM lt_create_ar03
        MAPPED DATA(lt_mapped_ar03)
        FAILED DATA(lt_failed_ar03)
        REPORTED DATA(lt_reported_ar03).

      IF lt_failed_ar03-paramar03 IS INITIAL.
        LOOP AT lt_create_ar03 ASSIGNING FIELD-SYMBOL(<created_ar03>).
          APPEND VALUE #(
            %tky = <created_ar03>-%tky
            %msg = new_message(
              id       = gc_msg_class
              number   = '052' " '&1 parameters created successfully'
              severity = if_abap_behv_message=>severity-success
              v1       = 'AR-03' )
          ) TO reported-subscription.
        ENDLOOP.
      ENDIF.
    ENDIF.

    " Create AP01 params
    IF lt_create_ap01 IS NOT INITIAL.
      MODIFY ENTITIES OF zir_drs_subscr IN LOCAL MODE
        ENTITY Subscription
          CREATE BY \_ParamAP01 FROM lt_create_ap01
        MAPPED DATA(lt_mapped_ap01)
        FAILED DATA(lt_failed_ap01)
        REPORTED DATA(lt_reported_ap01).

      IF lt_failed_ap01-paramap01 IS INITIAL.
        LOOP AT lt_create_ap01 ASSIGNING FIELD-SYMBOL(<created_ap01>).
          APPEND VALUE #(
            %tky = <created_ap01>-%tky
            %msg = new_message(
              id       = gc_msg_class
              number   = '052' " '&1 parameters created successfully'
              severity = if_abap_behv_message=>severity-success
              v1       = 'AP-01' )
          ) TO reported-subscription.
        ENDLOOP.
      ENDIF.
    ENDIF.

    " Create AP02 params
    IF lt_create_ap02 IS NOT INITIAL.
      MODIFY ENTITIES OF zir_drs_subscr IN LOCAL MODE
        ENTITY Subscription
          CREATE BY \_ParamAP02 FROM lt_create_ap02
        MAPPED DATA(lt_mapped_ap02)
        FAILED DATA(lt_failed_ap02)
        REPORTED DATA(lt_reported_ap02).

      IF lt_failed_ap02-paramap02 IS INITIAL.
        LOOP AT lt_create_ap02 ASSIGNING FIELD-SYMBOL(<created_ap02>).
          APPEND VALUE #(
            %tky = <created_ap02>-%tky
            %msg = new_message(
              id       = gc_msg_class
              number   = '052' " '&1 parameters created successfully'
              severity = if_abap_behv_message=>severity-success
              v1       = 'AP-02' )
          ) TO reported-subscription.
        ENDLOOP.
      ENDIF.
    ENDIF.

    " Create AP03 params
    IF lt_create_ap03 IS NOT INITIAL.
      MODIFY ENTITIES OF zir_drs_subscr IN LOCAL MODE
        ENTITY Subscription
          CREATE BY \_ParamAP03 FROM lt_create_ap03
        MAPPED DATA(lt_mapped_ap03)
        FAILED DATA(lt_failed_ap03)
        REPORTED DATA(lt_reported_ap03).

      IF lt_failed_ap03-paramap03 IS INITIAL.
        LOOP AT lt_create_ap03 ASSIGNING FIELD-SYMBOL(<created_ap03>).
          APPEND VALUE #(
            %tky = <created_ap03>-%tky
            %msg = new_message(
              id       = gc_msg_class
              number   = '052' " '&1 parameters created successfully'
              severity = if_abap_behv_message=>severity-success
              v1       = 'AP-03' )
          ) TO reported-subscription.
        ENDLOOP.
      ENDIF.
    ENDIF.

    " Return result - re-read to get fresh data
    READ ENTITIES OF zir_drs_subscr IN LOCAL MODE
      ENTITY Subscription
        ALL FIELDS WITH CORRESPONDING #( keys )
      RESULT DATA(lt_result).

    result = VALUE #( FOR ls IN lt_result
                      ( %tky = ls-%tky
                        %param = CORRESPONDING #( ls ) ) ).
  ENDMETHOD.



  METHOD validateDescription.
    " Read entities
    READ ENTITIES OF zir_drs_subscr IN LOCAL MODE
      ENTITY Subscription
      FIELDS ( subscrname )
      WITH CORRESPONDING #( keys )
      RESULT DATA(lt_subs).

    LOOP AT lt_subs INTO DATA(ls_sub).
      IF ls_sub-SubscrName IS INITIAL.
        APPEND VALUE #( %tky = ls_sub-%tky ) TO failed-Subscription.
        APPEND VALUE #( %tky = ls_sub-%tky
          %msg = new_message(
            id       = gc_msg_class
            number   = '001' "Description is required
            severity = if_abap_behv_message=>severity-error )
          %element-ReportID = if_abap_behv=>mk-on )
        TO reported-Subscription.
      ENDIF.
    ENDLOOP.
  ENDMETHOD.


  "054: The report is yet to be generated
  "055: &1 Report has not been prepared
  "056: &1 parameters are incomplete
  METHOD validateReport.
    " Read entities
    READ ENTITIES OF zir_drs_subscr IN LOCAL MODE
      ENTITY Subscription FIELDS ( ReportId ) WITH CORRESPONDING #( keys )
      RESULT DATA(lt_subs).

    LOOP AT lt_subs INTO DATA(ls_sub).
      DATA(lv_msg_no) = CONV symsgno( '' ).

      " 1. Validate ReportID existence
      IF ls_sub-ReportID IS INITIAL.
        APPEND VALUE #( %tky = ls_sub-%tky ) TO failed-Subscription.
        APPEND VALUE #( %tky = ls_sub-%tky
          %msg = new_message(
            id       = gc_msg_class
            number   = '054' " 'The report is yet to be generated'
            severity = if_abap_behv_message=>severity-error )
          %element-ReportID = if_abap_behv=>mk-on )
        TO reported-Subscription.

        CONTINUE.
      ENDIF.

      " 2. Validate Parameters
      CASE ls_sub-ReportId.
        WHEN 'GL-01'.
          READ ENTITIES OF zir_drs_subscr IN LOCAL MODE
            ENTITY Subscription BY \_ParamGL01 ALL FIELDS WITH CORRESPONDING #( keys ) RESULT DATA(lt_gl01).

          IF lt_gl01 IS INITIAL.
            lv_msg_no = '055'. " '&1 Report has not been prepared'


          ENDIF.

        WHEN 'AR-01'.
          READ ENTITIES OF zir_drs_subscr IN LOCAL MODE
            ENTITY Subscription BY \_ParamAR01 ALL FIELDS WITH CORRESPONDING #( keys ) RESULT DATA(lt_ar01).

          IF lt_ar01 IS INITIAL.
            lv_msg_no = '055'.

          ENDIF.

        WHEN 'AR-02'.
          READ ENTITIES OF zir_drs_subscr IN LOCAL MODE
            ENTITY Subscription BY \_ParamAR02 ALL FIELDS WITH CORRESPONDING #( keys ) RESULT DATA(lt_ar02).

          IF lt_ar02 IS INITIAL.
            lv_msg_no = '055'.


          ENDIF.

        WHEN 'AR-03'.
          READ ENTITIES OF zir_drs_subscr IN LOCAL MODE
            ENTITY Subscription BY \_ParamAR03 ALL FIELDS WITH CORRESPONDING #( keys ) RESULT DATA(lt_ar03).

          IF lt_ar03 IS INITIAL.
            lv_msg_no = '055'.

          ENDIF.

        WHEN 'AP-01'.

          READ ENTITIES OF zir_drs_subscr IN LOCAL MODE
            ENTITY Subscription BY \_ParamAP01 ALL FIELDS WITH CORRESPONDING #( keys ) RESULT DATA(lt_ap01).

          IF lt_ap01 IS INITIAL.
            lv_msg_no = '055'.

          ENDIF.

          CLEAR lt_ap01.

        WHEN 'AP-02'.
          READ ENTITIES OF zir_drs_subscr IN LOCAL MODE
            ENTITY Subscription BY \_ParamAP02 ALL FIELDS WITH CORRESPONDING #( keys ) RESULT DATA(lt_ap02).

          IF lt_ap02 IS INITIAL.
            lv_msg_no = '055'.

          ENDIF.

        WHEN 'AP-03'.
          READ ENTITIES OF zir_drs_subscr IN LOCAL MODE
            ENTITY Subscription BY \_ParamAP03 ALL FIELDS WITH CORRESPONDING #( keys ) RESULT DATA(lt_ap03).

          IF lt_ap03 IS INITIAL.
            lv_msg_no = '055'.

          ENDIF.

      ENDCASE.

      IF lv_msg_no IS NOT INITIAL.
        APPEND VALUE #( %tky = ls_sub-%tky ) TO failed-Subscription.
        APPEND VALUE #( %tky = ls_sub-%tky
          %msg = new_message(
            id       = gc_msg_class
            number   = lv_msg_no
            severity = if_abap_behv_message=>severity-error
            v1       = ls_sub-ReportId )
          %element-ReportID = if_abap_behv=>mk-on )
        TO reported-Subscription.
      ENDIF.

    ENDLOOP.
  ENDMETHOD.

  METHOD validateEmail.
    DATA:
      lt_emails TYPE string_table,
      lv_mail   TYPE string.

    CONSTANTS:
      lc_email_regex TYPE string
        VALUE `^[a-zA-Z0-9._%+\-]+@[a-zA-Z0-9.\-]+\.[a-zA-Z]{2,}$`.

    READ ENTITIES OF zir_drs_subscr IN LOCAL MODE
      ENTITY Subscription
        FIELDS ( EmailTo EmailCc )
        WITH CORRESPONDING #( keys )
      RESULT DATA(lt_subscr).

    LOOP AT lt_subscr ASSIGNING FIELD-SYMBOL(<fs_subscr>).
      IF <fs_subscr>-EmailTo IS NOT INITIAL.
        SPLIT <fs_subscr>-EmailTo AT ',' INTO TABLE lt_emails.
        LOOP AT lt_emails ASSIGNING FIELD-SYMBOL(<lv_addr>).
          lv_mail = condense( val = <lv_addr> ).
          FIND REGEX lc_email_regex IN lv_mail.
          IF sy-subrc <> 0.
            APPEND VALUE #( %tky = <fs_subscr>-%tky ) TO failed-Subscription.
            APPEND VALUE #(
              %tky = <fs_subscr>-%tky
              %msg = new_message(
                id       = gc_msg_class
                number   = '062'
                severity = if_abap_behv_message=>severity-error
                v1       = 'Email To'
                v2       = lv_mail )
              %element-EmailTo = if_abap_behv=>mk-on )
            TO reported-Subscription.
            EXIT. " report once per field per entity
          ENDIF.
        ENDLOOP.
      ENDIF.

      IF <fs_subscr>-EmailCc IS NOT INITIAL.
        SPLIT <fs_subscr>-EmailCc AT ',' INTO TABLE lt_emails.
        LOOP AT lt_emails ASSIGNING FIELD-SYMBOL(<lv_cc>).
          lv_mail = condense( val = <lv_cc> ).
          FIND REGEX lc_email_regex IN lv_mail.
          IF sy-subrc <> 0.
            APPEND VALUE #( %tky = <fs_subscr>-%tky ) TO failed-Subscription.
            APPEND VALUE #(
              %tky = <fs_subscr>-%tky
              %msg = new_message(
                id       = gc_msg_class
                number   = '062'
                severity = if_abap_behv_message=>severity-error
                v1       = 'Email CC'
                v2       = lv_mail )
              %element-EmailCc = if_abap_behv=>mk-on )
            TO reported-Subscription.
            EXIT. " report once per field per entity
          ENDIF.
        ENDLOOP.
      ENDIF.

    ENDLOOP.
  ENDMETHOD.



ENDCLASS.
