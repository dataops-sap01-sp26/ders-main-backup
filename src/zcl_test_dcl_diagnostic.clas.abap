CLASS zcl_test_dcl_diagnostic DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC .

  PUBLIC SECTION.
    INTERFACES if_oo_adt_classrun.
  PROTECTED SECTION.
  PRIVATE SECTION.
ENDCLASS.



CLASS zcl_test_dcl_diagnostic IMPLEMENTATION.

  METHOD if_oo_adt_classrun~main.
    DATA: lv_report_id    TYPE char20 VALUE 'AR-01',
          lv_report_gl    TYPE char20 VALUE 'GL-01',
          lv_report_ap    TYPE char20 VALUE 'AP-01',
          lv_subrc        TYPE sy-subrc,
          lv_subrc_gl     TYPE sy-subrc,
          lv_subrc_ap     TYPE sy-subrc,
          lv_count_table  TYPE i,
          lv_count_cds    TYPE i,
          lv_count_prj    TYPE i.

    " Header
    out->write( |====================================| ).
    out->write( |DCL DIAGNOSTIC TEST v2| ).
    out->write( |====================================| ).
    out->write( |Current User: { sy-uname }| ).
    out->write( | | ).

    " ── Test 1: Authorization checks for multiple reports ──
    out->write( |1. Testing Authorization Object ZDRS_REP...| ).

    " Check AR-01 (should pass for AR staff)
    AUTHORITY-CHECK OBJECT 'ZDRS_REP'
      ID 'ZREP_ID' FIELD lv_report_id
      ID 'ACTVT'   FIELD '03'.
    lv_subrc = sy-subrc.

    " Check GL-01 (should FAIL for AR staff)
    AUTHORITY-CHECK OBJECT 'ZDRS_REP'
      ID 'ZREP_ID' FIELD lv_report_gl
      ID 'ACTVT'   FIELD '03'.
    lv_subrc_gl = sy-subrc.

    " Check AP-01 (should FAIL for AR staff)
    AUTHORITY-CHECK OBJECT 'ZDRS_REP'
      ID 'ZREP_ID' FIELD lv_report_ap
      ID 'ACTVT'   FIELD '03'.
    lv_subrc_ap = sy-subrc.

    out->write( |   AR-01: sy-subrc = { lv_subrc } { COND #( WHEN lv_subrc = 0 THEN '✅ Authorized' WHEN lv_subrc = 4 THEN '❌ Object missing' ELSE '❌ Not authorized' ) }| ).
    out->write( |   GL-01: sy-subrc = { lv_subrc_gl } { COND #( WHEN lv_subrc_gl = 0 THEN '⚠️ Authorized (should FAIL for AR staff!)' WHEN lv_subrc_gl = 4 THEN '❌ Object missing' ELSE '✅ Not authorized (correct!)' ) }| ).
    out->write( |   AP-01: sy-subrc = { lv_subrc_ap } { COND #( WHEN lv_subrc_ap = 0 THEN '⚠️ Authorized (should FAIL for AR staff!)' WHEN lv_subrc_ap = 4 THEN '❌ Object missing' ELSE '✅ Not authorized (correct!)' ) }| ).

    " Check wildcard access
    DATA lv_wildcard TYPE char20 VALUE '*'.
    AUTHORITY-CHECK OBJECT 'ZDRS_REP'
      ID 'ZREP_ID' FIELD lv_wildcard
      ID 'ACTVT'   FIELD '03'.
    out->write( |   Wildcard (*): sy-subrc = { sy-subrc } { COND #( WHEN sy-subrc = 0 THEN '⚠️ HAS WILDCARD ACCESS (admin role?)' ELSE '✅ No wildcard' ) }| ).

    out->write( | | ).

    " ── Test 2: Direct table query (no DCL) ──
    SELECT COUNT(*) FROM zdrs_catalog INTO @lv_count_table.
    out->write( |2. Direct table query (no DCL):| ).
    out->write( |   Records in ZDRS_CATALOG table: { lv_count_table }| ).
    out->write( | | ).

    " ── Test 3: Interface CDS view (with DCL) ──
    SELECT COUNT(*) FROM zir_drs_catalog INTO @lv_count_cds.
    out->write( |3. Interface CDS View with DCL (ZIR_DRS_CATALOG):| ).
    out->write( |   Records returned: { lv_count_cds }| ).
    out->write( | | ).

    " ── Test 4: Projection CDS view ──
    SELECT COUNT(*) FROM zcr_drs_catalog INTO @lv_count_prj.
    out->write( |4. Projection CDS View (ZCR_DRS_CATALOG):| ).
    out->write( |   Records returned: { lv_count_prj }| ).
    out->write( | | ).

    " ── Analysis ──
    out->write( |====================================| ).
    out->write( |ANALYSIS:| ).
    out->write( |====================================| ).

    " Check if user has wildcard/admin access
    IF lv_subrc = 0 AND lv_subrc_gl = 0 AND lv_subrc_ap = 0.
      out->write( |⚠️  PROBLEM: User { sy-uname } is authorized for ALL reports!| ).
      out->write( | | ).
      out->write( |   This user has ZREP_ID = * (wildcard) or multiple roles.| ).
      out->write( |   DCL might be working, but user has access to everything.| ).
      out->write( | | ).
      out->write( |   CHECK THESE:| ).
      out->write( |   1. Transaction: SU01 → Display user { sy-uname }| ).
      out->write( |      → Tab: Roles → Check ALL assigned roles| ).
      out->write( |      → Does user have ZDRS_ADMIN role? Remove it for testing.| ).
      out->write( |   2. Transaction: SU01 → Tab: Profiles| ).
      out->write( |      → Does user have SAP_ALL or SAP_NEW profile? These grant EVERYTHING!| ).
      out->write( |   3. Transaction: SU56 → Analyze authorization buffer| ).
      out->write( |      → Search for ZDRS_REP → Check ZREP_ID values| ).
      out->write( | | ).
      out->write( |   SOLUTION:| ).
      out->write( |   - Test with a user that ONLY has ZDRS_FI_AR_STAFF role| ).
      out->write( |   - Remove SAP_ALL / SAP_NEW profiles from test user| ).
      out->write( |   - Remove ZDRS_ADMIN role from test user| ).
      out->write( |   - Create a NEW test user with only ZDRS_FI_AR_STAFF| ).

    ELSEIF lv_subrc = 4.
      out->write( |❌ PROBLEM: Authorization object ZDRS_REP does NOT EXIST| ).
      out->write( |   Create it in SU21 with fields ACTVT and ZREP_ID| ).

    ELSEIF lv_count_table = lv_count_cds AND lv_subrc = 0 AND lv_subrc_gl <> 0.
      out->write( |❌ PROBLEM: DCL is NOT filtering data| ).
      out->write( |   Table: { lv_count_table } records| ).
      out->write( |   CDS:   { lv_count_cds } records (should be 2, not { lv_count_cds })| ).
      out->write( | | ).
      out->write( |   Auth checks are correct (AR-01 ✅, GL-01 ❌) but DCL not applied.| ).
      out->write( |   → Reactivate ZIR_DRS_CATALOG DCL in Eclipse (Ctrl+F3)| ).
      out->write( |   → Clear service cache in /IWFND/MAINT_SERVICE| ).

    ELSEIF lv_count_cds < lv_count_table.
      out->write( |✅ SUCCESS: DCL is filtering correctly!| ).
      out->write( |   Table: { lv_count_table } records (all data)| ).
      out->write( |   ZIR CDS: { lv_count_cds } records (filtered)| ).
      out->write( |   ZCR CDS: { lv_count_prj } records (projection)| ).
      out->write( | | ).
      IF lv_count_prj > lv_count_cds.
        out->write( |   ⚠️ Projection shows MORE than interface view!| ).
        out->write( |   → ZCR_DRS_CATALOG needs DCL with 'inheriting conditions'| ).
      ELSE.
        out->write( |   ✅ Both layers filtering correctly!| ).
      ENDIF.

    ELSE.
      out->write( |⚠️ UNEXPECTED result. Table: { lv_count_table }, CDS: { lv_count_cds }| ).
    ENDIF.

    out->write( | | ).
    out->write( |====================================| ).
    out->write( |Current User: { sy-uname }| ).
    out->write( |Current Date: { sy-datum DATE = USER }| ).
    out->write( |Current Time: { sy-uzeit TIME = USER }| ).
    out->write( |====================================| ).

    " Bonus: Show actual catalog data
    out->write( | | ).
    out->write( |BONUS: Actual catalog records visible to you:| ).
    out->write( |------------------------------------| ).

    SELECT ReportId, ReportName
      FROM zir_drs_catalog
      INTO TABLE @DATA(lt_catalog)
      UP TO 20 ROWS.

    IF lt_catalog IS INITIAL.
      out->write( |   No records found (DCL might be too restrictive)| ).
    ELSE.
      LOOP AT lt_catalog INTO DATA(ls_catalog).
        out->write( |   { ls_catalog-ReportId } - { ls_catalog-ReportName }| ).
      ENDLOOP.
    ENDIF.

    out->write( | | ).
    out->write( |Test completed.| ).

  ENDMETHOD.

ENDCLASS.

