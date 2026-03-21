INTERFACE ZIF_REPORT
  PUBLIC.

  " Subscription parameters — filter conditions read from zders_job_sub136
  TYPES: BEGIN OF TY_PARAMS,
           SUBSCR_UUID            TYPE SYSUUID_X16,
           REPORT_ID              TYPE C LENGTH 10,
           OUTPUT_FORMAT          TYPE C LENGTH 4,    " CSV / XLSX
         END OF TY_PARAMS.

  " Result returned by report execution
  TYPES: BEGIN OF TY_RESULT,
           XSTRING          TYPE XSTRING,   " File content (binary)
           EXTENSION        TYPE STRING,    " e.g. 'csv', 'xlsx'
           MIME_TYPE        TYPE STRING,    " e.g. 'text/csv'
           FILE_NAME_PREFIX TYPE STRING,    " e.g. 'GL_LineItems' — caller appends date/time
         END OF TY_RESULT.

  " Execute the report: query data using params → format → return file content
  METHODS EXECUTE
    RETURNING VALUE(RS_RESULT) TYPE TY_RESULT.

ENDINTERFACE.
