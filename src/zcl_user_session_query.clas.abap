CLASS zcl_user_session_query DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.
    INTERFACES if_rap_query_provider.

  PROTECTED SECTION.
  PRIVATE SECTION.
ENDCLASS.


CLASS zcl_user_session_query IMPLEMENTATION.

  METHOD if_rap_query_provider~select.
    "=====================================================================
    " Query Provider for User Session Custom Entity
    " Returns: Current user info + PFCG roles from AGR_USERS
    "=====================================================================
    DATA: lt_result TYPE STANDARD TABLE OF zir_drs_user_session.
    DATA: lv_user_id TYPE sy-uname.

    " Handle paging (required for RAP query provider)
    DATA(lo_paging) = io_request->get_paging( ).
    DATA(lv_offset) = lo_paging->get_offset( ).
    DATA(lv_page_size) = lo_paging->get_page_size( ).

    " Handle filter (required even if not used)
    DATA(lo_filter) = io_request->get_filter( ).

    lv_user_id = sy-uname.

    " Get base data from I_BusinessUser
    SELECT SINGLE
           UserID,
           PersonFullName,
           BusinessPartnerUUID
      FROM I_BusinessUser
      WHERE UserID = @lv_user_id
      INTO @DATA(ls_user).

    IF sy-subrc <> 0.
      " Fallback: User not in I_BusinessUser
      ls_user-UserID = lv_user_id.
      ls_user-PersonFullName = lv_user_id.
    ENDIF.

    " Get Email from WorkplaceAddress
    DATA: lv_email TYPE ad_smtpadr.
    IF ls_user-BusinessPartnerUUID IS NOT INITIAL.
      SELECT SINGLE DefaultEmailAddress
        FROM I_WorkplaceAddress
        INTO @lv_email
        WHERE BusinessPartnerUUID = @ls_user-BusinessPartnerUUID.
    ENDIF.

    " Get PFCG DRS Roles
    SELECT agr_name
      FROM agr_users
      INTO TABLE @DATA(lt_roles)
      WHERE uname = @lv_user_id
        AND ( agr_name LIKE 'ZDRS%' OR agr_name LIKE 'ZBC_ZDRS%' ).

    " Determine role flags and primary role
    DATA: lv_is_admin     TYPE abap_bool,
          lv_is_head_acct TYPE abap_bool,
          lv_has_gl       TYPE abap_bool,
          lv_has_ap       TYPE abap_bool,
          lv_has_ar       TYPE abap_bool,
          lv_role_id      TYPE c LENGTH 30,
          lv_role_name    TYPE c LENGTH 80,
          lv_role_desc    TYPE c LENGTH 255.

    LOOP AT lt_roles INTO DATA(ls_role).
      CASE ls_role-agr_name.
        WHEN 'ZDRS_ADMIN' OR 'ZBC_ZDRS_ADMIN'.
          lv_is_admin = abap_true.
        WHEN 'ZDRS_HEAD_ACCT' OR 'ZBC_ZDRS_HEAD_ACCT'.
          lv_is_head_acct = abap_true.
        WHEN 'ZDRS_FI_GL_STAFF' OR 'ZBC_ZDRS_FI_GL_STAFF'.
          lv_has_gl = abap_true.
        WHEN 'ZDRS_FI_AP_STAFF' OR 'ZBC_ZDRS_FI_AP_STAFF'.
          lv_has_ap = abap_true.
        WHEN 'ZDRS_FI_AR_STAFF' OR 'ZBC_ZDRS_FI_AR_STAFF'.
          lv_has_ar = abap_true.
      ENDCASE.
    ENDLOOP.

    " Set primary role by priority
    IF lv_is_admin = abap_true.
      lv_role_id = 'ZDRS_ADMIN'.
      lv_role_name = 'System Administrator'.
      lv_role_desc = 'Full system access - manage catalog and all subscriptions'.
    ELSEIF lv_is_head_acct = abap_true.
      lv_role_id = 'ZDRS_HEAD_ACCT'.
      lv_role_name = 'Head of Accounting'.
      lv_role_desc = 'Manage subscriptions for all accounting modules'.
    ELSEIF lv_has_gl = abap_true.
      lv_role_id = 'ZDRS_FI_GL_STAFF'.
      lv_role_name = 'GL Accountant'.
      lv_role_desc = 'Access to General Ledger reports'.
    ELSEIF lv_has_ap = abap_true.
      lv_role_id = 'ZDRS_FI_AP_STAFF'.
      lv_role_name = 'AP Accountant'.
      lv_role_desc = 'Access to Accounts Payable reports'.
    ELSEIF lv_has_ar = abap_true.
      lv_role_id = 'ZDRS_FI_AR_STAFF'.
      lv_role_name = 'AR Accountant'.
      lv_role_desc = 'Access to Accounts Receivable reports'.
    ELSE.
      lv_role_id = 'NO_ROLE'.
      lv_role_name = 'No DRS Access'.
      lv_role_desc = 'User does not have any DRS roles assigned'.
    ENDIF.

    " Get Company Code Access
    DATA: lv_cc_list TYPE c LENGTH 1000.

    " First check for wildcard access (*)
    SELECT COUNT(*)
      FROM agr_1251
      INTO @DATA(lv_wc_count)
      WHERE agr_name IN ( SELECT agr_name FROM agr_users WHERE uname = @lv_user_id )
        AND object = 'F_BKPF_BUK'
        AND field = 'BUKRS'
        AND low = '*'.

    IF lv_wc_count > 0.
      lv_cc_list = '*'.  " User has access to all company codes
    ELSE.
      " Get specific company codes (exclude variables starting with $)
      SELECT DISTINCT low
        FROM agr_1251
        INTO TABLE @DATA(lt_cc)
        WHERE agr_name IN ( SELECT agr_name FROM agr_users WHERE uname = @lv_user_id )
          AND object = 'F_BKPF_BUK'
          AND field = 'BUKRS'
          AND low <> ''
          AND low NOT LIKE '$%'.

      IF lt_cc IS NOT INITIAL.
        LOOP AT lt_cc INTO DATA(ls_cc).
          IF lv_cc_list IS INITIAL.
            lv_cc_list = ls_cc-low.
          ELSE.
            lv_cc_list = |{ lv_cc_list },{ ls_cc-low }|.
          ENDIF.
        ENDLOOP.
      ELSE.
        " Check if user has $BUKRS variable - resolve from user defaults
        SELECT SINGLE parva
          FROM usr05
          INTO @DATA(lv_user_bukrs)
          WHERE bname = @lv_user_id
            AND parid = 'BUK'.
        IF sy-subrc = 0 AND lv_user_bukrs IS NOT INITIAL.
          lv_cc_list = lv_user_bukrs.
        ENDIF.
      ENDIF.
    ENDIF.

    " Build result
    APPEND VALUE #(
      SessionId       = 'CURRENT'
      UserId          = ls_user-UserID
      UserFullName    = ls_user-PersonFullName
      Email           = lv_email
      RoleId          = lv_role_id
      RoleName        = lv_role_name
      RoleDescription = lv_role_desc
      IsAdmin         = lv_is_admin
      IsHeadAcct      = lv_is_head_acct
      HasGLAccess     = lv_has_gl
      HasAPAccess     = lv_has_ap
      HasARAccess     = lv_has_ar
      CompanyCodeList = lv_cc_list
    ) TO lt_result.

    " Set response
    io_response->set_total_number_of_records( lines( lt_result ) ).
    io_response->set_data( lt_result ).

  ENDMETHOD.

ENDCLASS.

