INTERFACE ZIF_FILE_FORMATTER
  PUBLIC.

  " Column metadata — shared type for all formatters
  TYPES: BEGIN OF TY_COL_META,
           NAME   TYPE STRING,
           IS_NUM TYPE ABAP_BOOL,
           IS_BOLD TYPE ABAP_BOOL,
           ALIGN TYPE STRING,
         END OF TY_COL_META.
  TYPES TT_COL_META TYPE STANDARD TABLE OF TY_COL_META WITH EMPTY KEY.

  " Result structure returned after file generation
  TYPES: BEGIN OF TY_RESULT,
           XSTRING   TYPE XSTRING,
           EXTENSION TYPE STRING,
           MIME_TYPE TYPE STRING,
         END OF TY_RESULT.

  " Generate the output file from the given data + column metadata
  METHODS GENERATE
    IMPORTING IR_DATA          TYPE REF TO DATA
              IT_COL_META      TYPE TT_COL_META
    RETURNING VALUE(RS_RESULT) TYPE TY_RESULT.

ENDINTERFACE.
