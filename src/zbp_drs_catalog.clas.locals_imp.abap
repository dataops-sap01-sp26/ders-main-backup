*&---------------------------------------------------------------------*
*& Local handler class for the Catalog entity.
*& The behavior definition is declared with strict(2), which requires
*& the entity to be flagged as authorization master. Because the catalog
*& is exposed read-only (no create / update / delete operations), the
*& global authorization handler returns an empty result; row-level read
*& access is enforced via the DCL role of ZIR_DRS_CATALOG.
*&---------------------------------------------------------------------*
CLASS lhc_catalog DEFINITION INHERITING FROM cl_abap_behavior_handler.
  PRIVATE SECTION.

    METHODS get_global_authorizations FOR GLOBAL AUTHORIZATION
      IMPORTING REQUEST requested_authorizations FOR Catalog RESULT result.

ENDCLASS.

CLASS lhc_catalog IMPLEMENTATION.

  METHOD get_global_authorizations.
    " No modify operations are exposed; result remains empty.
  ENDMETHOD.

ENDCLASS.
