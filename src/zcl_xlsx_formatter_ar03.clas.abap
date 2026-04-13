CLASS ZCL_XLSX_FORMATTER_AR03 DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.
    INTERFACES ZIF_FILE_FORMATTER.

    METHODS CONSTRUCTOR
      IMPORTING IS_PARAMS TYPE ZIF_REPORT=>TY_PARAMS.

  PRIVATE SECTION.
    DATA MS_PARAMS TYPE ZIF_REPORT=>TY_PARAMS.

    METHODS BUILD_STYLES
      RETURNING VALUE(RV_XML) TYPE STRING.

    METHODS BUILD_SHEET
      IMPORTING IR_DATA       TYPE REF TO DATA
                IT_COL_META   TYPE ZIF_FILE_FORMATTER=>TT_COL_META
      RETURNING VALUE(RV_XML) TYPE STRING.

    METHODS COL_LETTER
      IMPORTING IV_INDEX         TYPE I
      RETURNING VALUE(RV_LETTER) TYPE STRING.

ENDCLASS.

CLASS ZCL_XLSX_FORMATTER_AR03 IMPLEMENTATION.

  METHOD CONSTRUCTOR.
    MS_PARAMS = IS_PARAMS.
  ENDMETHOD.

  METHOD ZIF_FILE_FORMATTER~GENERATE.
    RS_RESULT-EXTENSION = 'xlsx'.
    RS_RESULT-MIME_TYPE = 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet'.

    DATA(LV_CONV) = CL_ABAP_CONV_CODEPAGE=>CREATE_OUT( CODEPAGE = `UTF-8` ).
    DATA(LO_ZIP)  = NEW CL_ABAP_ZIP( ).

    LO_ZIP->ADD( NAME = '[Content_Types].xml' CONTENT = LV_CONV->CONVERT(
      '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>' &&
      '<Types xmlns="http://schemas.openxmlformats.org/package/2006/content-types">' &&
      '<Default Extension="rels" ContentType="application/vnd.openxmlformats-package.relationships+xml"/>' &&
      '<Default Extension="xml"  ContentType="application/xml"/>' &&
      '<Override PartName="/xl/workbook.xml"' &&
        ' ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.sheet.main+xml"/>' &&
      '<Override PartName="/xl/worksheets/sheet1.xml"' &&
        ' ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.worksheet+xml"/>' &&
      '<Override PartName="/xl/styles.xml"' &&
        ' ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.styles+xml"/>' &&
      '</Types>' ) ).

    LO_ZIP->ADD( NAME = '_rels/.rels' CONTENT = LV_CONV->CONVERT(
      '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>' &&
      '<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">' &&
      '<Relationship Id="rId1"' &&
        ' Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/officeDocument"' &&
        ' Target="xl/workbook.xml"/>' &&
      '</Relationships>' ) ).

    LO_ZIP->ADD( NAME = 'xl/_rels/workbook.xml.rels' CONTENT = LV_CONV->CONVERT(
      '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>' &&
      '<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">' &&
      '<Relationship Id="rId1"' &&
        ' Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/worksheet"' &&
        ' Target="worksheets/sheet1.xml"/>' &&
      '<Relationship Id="rId2"' &&
        ' Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/styles"' &&
        ' Target="styles.xml"/>' &&
      '</Relationships>' ) ).

    LO_ZIP->ADD( NAME = 'xl/workbook.xml' CONTENT = LV_CONV->CONVERT(
      '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>' &&
      '<workbook xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main"' &&
        ' xmlns:r="http://schemas.openxmlformats.org/officeDocument/2006/relationships">' &&
      '<sheets>' &&
        '<sheet name="AR Aging Report" sheetId="1" r:id="rId1"/>' &&
      '</sheets>' &&
      '</workbook>' ) ).

    LO_ZIP->ADD( NAME    = 'xl/styles.xml'
                 CONTENT = LV_CONV->CONVERT( BUILD_STYLES( ) ) ).

    LO_ZIP->ADD( NAME    = 'xl/worksheets/sheet1.xml'
                 CONTENT = LV_CONV->CONVERT(
                   BUILD_SHEET( IR_DATA = IR_DATA IT_COL_META = IT_COL_META ) ) ).

    RS_RESULT-XSTRING = LO_ZIP->SAVE( ).
  ENDMETHOD.

  METHOD BUILD_STYLES.
    DATA(LV_NUMFMTS) =
      '<numFmts count="1">' &&
      '<numFmt numFmtId="164" formatCode="#,##0;-#,##0;&quot;-&quot;"/>' &&
      '</numFmts>'.

    DATA(LV_FONTS) =
      '<fonts count="4">' &&
      '<font><sz val="11"/><name val="Arial"/></font>' &&
      '<font><sz val="10"/><name val="Arial"/></font>' &&
      '<font><b/><sz val="10"/><name val="Arial"/></font>' &&
      '<font><b/><sz val="14"/><name val="Arial"/></font>' &&
      '</fonts>'.

    DATA(LV_FILLS) =
      '<fills count="3">' &&
      '<fill><patternFill patternType="none"/></fill>' &&
      '<fill><patternFill patternType="gray125"/></fill>' &&
      '<fill><patternFill patternType="solid">' &&
        '<fgColor rgb="FFFFFF00"/>' &&
      '</patternFill></fill>' &&
      '</fills>'.

    DATA(LV_BORDERS) =
      '<borders count="2">' &&
      '<border><left/><right/><top/><bottom/><diagonal/></border>' &&
      '<border>' &&
        '<left   style="thin"><color rgb="FF000000"/></left>'   &&
        '<right  style="thin"><color rgb="FF000000"/></right>'  &&
        '<top    style="thin"><color rgb="FF000000"/></top>'    &&
        '<bottom style="thin"><color rgb="FF000000"/></bottom>' &&
        '<diagonal/>' &&
      '</border>' &&
      '</borders>'.

    DATA(LV_CSXFS) =
      '<cellStyleXfs count="1">' &&
      '<xf numFmtId="0" fontId="0" fillId="0" borderId="0"/>' &&
      '</cellStyleXfs>'.

    DATA(LV_CXFS) =
      '<cellXfs count="11">' &&
      '<xf numFmtId="0" fontId="0" fillId="0" borderId="0" xfId="0"/>' &&
      '<xf numFmtId="0" fontId="3" fillId="0" borderId="0" xfId="0"' &&
          ' applyFont="1" applyAlignment="1">' &&
        '<alignment horizontal="center" vertical="center"/>' &&
      '</xf>' &&
      '<xf numFmtId="0" fontId="1" fillId="0" borderId="0" xfId="0"' &&
          ' applyFont="1" applyAlignment="1">' &&
        '<alignment horizontal="left" vertical="center"/>' &&
      '</xf>' &&
      '<xf numFmtId="0" fontId="2" fillId="2" borderId="1" xfId="0"' &&
          ' applyFont="1" applyFill="1" applyBorder="1" applyAlignment="1">' &&
        '<alignment horizontal="center" vertical="center" wrapText="1"/>' &&
      '</xf>' &&
      '<xf numFmtId="164" fontId="2" fillId="0" borderId="1" xfId="0"' &&
          ' applyFont="1" applyNumberFormat="1" applyBorder="1" applyAlignment="1">' &&
        '<alignment horizontal="right" vertical="center"/>' &&
      '</xf>' &&
      '<xf numFmtId="164" fontId="1" fillId="0" borderId="1" xfId="0"' &&
          ' applyFont="1" applyNumberFormat="1" applyBorder="1" applyAlignment="1">' &&
        '<alignment horizontal="right" vertical="center"/>' &&
      '</xf>' &&
      '<xf numFmtId="0" fontId="1" fillId="0" borderId="1" xfId="0"' &&
          ' applyFont="1" applyBorder="1" applyAlignment="1">' &&
        '<alignment horizontal="left" vertical="center"/>' &&
      '</xf>' &&
      '<xf numFmtId="0" fontId="2" fillId="0" borderId="1" xfId="0"' &&
          ' applyFont="1" applyBorder="1" applyAlignment="1">' &&
        '<alignment horizontal="center" vertical="center"/>' &&
      '</xf>' &&
      '<xf numFmtId="0" fontId="1" fillId="0" borderId="1" xfId="0"' &&
          ' applyFont="1" applyBorder="1" applyAlignment="1">' &&
        '<alignment horizontal="center" vertical="center"/>' &&
      '</xf>' &&
      '<xf numFmtId="0" fontId="2" fillId="0" borderId="0" xfId="0"' &&
          ' applyFont="1" applyAlignment="1">' &&
        '<alignment horizontal="left" vertical="center"/>' &&
      '</xf>' &&
      '<xf numFmtId="164" fontId="2" fillId="0" borderId="0" xfId="0"' &&
          ' applyFont="1" applyNumberFormat="1" applyAlignment="1">' &&
        '<alignment horizontal="right" vertical="center"/>' &&
      '</xf>' &&
      '</cellXfs>'.

    RV_XML =
      '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>' &&
      '<styleSheet xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main">' &&
      LV_NUMFMTS && LV_FONTS && LV_FILLS && LV_BORDERS && LV_CSXFS && LV_CXFS &&
      '</styleSheet>'.
  ENDMETHOD.

  METHOD BUILD_SHEET.
    SELECT SINGLE FROM ZDRS_PARAM_AR03
      FIELDS COMPANY_CODE,
             CUSTOMER_FROM,
             CUSTOMER_TO,
             KEY_DATE,
             MAX_ROWS
      WHERE SUBSCR_UUID = @MS_PARAMS-SUBSCR_UUID
      INTO @DATA(LS_SPEC_PARAM).

    IF SY-SUBRC <> 0.
      " Message: Report parameters not found for report ID &1
      RAISE EXCEPTION TYPE CX_APJ_RT
        MESSAGE ID 'ZMSG_DRS_SP26_SAP01'
        TYPE 'E'
        NUMBER '039'
        WITH MS_PARAMS-REPORT_ID.
    ENDIF.

    DATA(LV_GEN_DATE) = |{ SY-DATUM+6(2) }/{ SY-DATUM+4(2) }/{ SY-DATUM(4) }|.

    FIELD-SYMBOLS <LT_DATA> TYPE STANDARD TABLE.
    ASSIGN IR_DATA->* TO <LT_DATA>.

    DATA(LV_DATA_CNT)   = LINES( <LT_DATA> ).
    DATA(LV_DATA_FIRST) = 8.
    DATA(LV_DATA_LAST)  = LV_DATA_FIRST + LV_DATA_CNT - 1.
    DATA(LV_TOT_START)  = LV_DATA_LAST + 2.

    DATA LV_CURRENCY TYPE STRING.
    READ TABLE <LT_DATA> INDEX 1 ASSIGNING FIELD-SYMBOL(<LS_FIRST>).
    IF SY-SUBRC = 0.
      ASSIGN COMPONENT 'LOCALCURRENCY' OF STRUCTURE <LS_FIRST> TO FIELD-SYMBOL(<LV_FIRST_CUR>).
      IF SY-SUBRC = 0.
        LV_CURRENCY = CONDENSE( |{ <LV_FIRST_CUR> }| ).
      ENDIF.
    ENDIF.

    DATA LT_UNIQUE_CUST TYPE HASHED TABLE OF STRING WITH UNIQUE KEY TABLE_LINE.
    LOOP AT <LT_DATA> ASSIGNING FIELD-SYMBOL(<LS_UC>).
      ASSIGN COMPONENT 'CUSTOMER' OF STRUCTURE <LS_UC> TO FIELD-SYMBOL(<LV_UC_VAL>).
      IF SY-SUBRC = 0.
        DATA(LV_UC_STR) = CONDENSE( |{ <LV_UC_VAL> }| ).
        TRY.
            INSERT LV_UC_STR INTO TABLE LT_UNIQUE_CUST.
          CATCH CX_SY_ITAB_DUPLICATE_KEY.
        ENDTRY.
      ENDIF.
    ENDLOOP.
    DATA(LV_CUST_CNT) = LINES( LT_UNIQUE_CUST ).

    DATA(LV_COLS) =
      '<cols>' &&
      '<col min="1"  max="1"  width="6"  customWidth="1"/>' &&
      '<col min="2"  max="2"  width="14" customWidth="1"/>' &&
      '<col min="3"  max="3"  width="25" customWidth="1"/>' &&
      '<col min="4"  max="4"  width="18" customWidth="1"/>' &&
      '<col min="5"  max="5"  width="18" customWidth="1"/>' &&
      '<col min="6"  max="6"  width="18" customWidth="1"/>' &&
      '<col min="7"  max="7"  width="18" customWidth="1"/>' &&
      '<col min="8"  max="8"  width="18" customWidth="1"/>' &&
      '<col min="9"  max="9"  width="18" customWidth="1"/>' &&
      '<col min="10" max="10" width="12" customWidth="1"/>' &&
      '</cols>'.

    DATA LV_ROWS TYPE STRING.

    LV_ROWS = LV_ROWS &&
      '<row r="1" ht="35" customHeight="1">' &&
      '<c r="A1" t="inlineStr" s="1">' &&
        '<is><t>Accounts Receivable Aging Report</t></is>' &&
      '</c>' &&
      '</row>'.

    LV_ROWS = LV_ROWS &&
      '<row r="2" ht="18" customHeight="1">' &&
      |<c r="A2" t="inlineStr" s="2"><is><t>Company code: { LS_SPEC_PARAM-COMPANY_CODE }</t></is></c>| &&
      '</row>'.

    ASSIGN COMPONENT 'KEY_DATE' OF STRUCTURE LS_SPEC_PARAM TO FIELD-SYMBOL(<LV_KEY_DATE>).
    DATA LV_KEY_DATE_STR TYPE STRING.
    IF SY-SUBRC = 0.
      LV_KEY_DATE_STR = CONDENSE( |{ <LV_KEY_DATE> }| ).
    ELSE.
      LV_KEY_DATE_STR = 'N/A'.
    ENDIF.

    LV_ROWS = LV_ROWS &&
      '<row r="3" ht="18" customHeight="1">' &&
      |<c r="A3" t="inlineStr" s="2"><is><t>Key Date: { LV_KEY_DATE_STR }</t></is></c>| &&
      '</row>'.

    LV_ROWS = LV_ROWS &&
      '<row r="4" ht="18" customHeight="1">' &&
      |<c r="A4" t="inlineStr" s="2"><is><t>Currency: { LV_CURRENCY }</t></is></c>| &&
      '</row>'.

    LV_ROWS = LV_ROWS &&
      '<row r="5" ht="18" customHeight="1">' &&
      |<c r="A5" t="inlineStr" s="2"><is><t>Generated on: { LV_GEN_DATE }</t></is></c>| &&
      '</row>'.

    LV_ROWS = LV_ROWS && '<row r="6" ht="8" customHeight="1"/>'.

    LV_ROWS = LV_ROWS &&
      '<row r="7" ht="40" customHeight="1">' &&
      '<c r="A7" t="inlineStr" s="3"><is><t>No</t></is></c>'               &&
      '<c r="B7" t="inlineStr" s="3"><is><t>Customer ID</t></is></c>'       &&
      '<c r="C7" t="inlineStr" s="3"><is><t>Customer Name</t></is></c>'     &&
      '<c r="D7" t="inlineStr" s="3"><is><t>Not Due</t></is></c>'           &&
      '<c r="E7" t="inlineStr" s="3"><is><t>Aging 1</t></is></c>'           &&
      '<c r="F7" t="inlineStr" s="3"><is><t>Aging 2</t></is></c>'           &&
      '<c r="G7" t="inlineStr" s="3"><is><t>Aging 3</t></is></c>'           &&
      '<c r="H7" t="inlineStr" s="3"><is><t>Aging 4</t></is></c>'           &&
      '<c r="I7" t="inlineStr" s="3"><is><t>Total Amount</t></is></c>'      &&
      '<c r="J7" t="inlineStr" s="3"><is><t>Currency</t></is></c>'          &&
      '</row>'.

    TYPES: BEGIN OF TY_COL_MAP,
             FIELD  TYPE STRING,
             IS_NUM TYPE ABAP_BOOL,
           END OF TY_COL_MAP.
    TYPES TT_COL_MAP TYPE STANDARD TABLE OF TY_COL_MAP WITH DEFAULT KEY.

    DATA(LT_MAP) = VALUE TT_COL_MAP(
      ( FIELD = 'CUSTOMER'        IS_NUM = ABAP_FALSE )
      ( FIELD = 'CUSTOMERNAME'    IS_NUM = ABAP_FALSE )
      ( FIELD = 'NOT_DUE'         IS_NUM = ABAP_TRUE  )
      ( FIELD = 'AGING1'          IS_NUM = ABAP_TRUE  )
      ( FIELD = 'AGING2'          IS_NUM = ABAP_TRUE  )
      ( FIELD = 'AGING3'          IS_NUM = ABAP_TRUE  )
      ( FIELD = 'AGING4'          IS_NUM = ABAP_TRUE  )
      ( FIELD = 'TOTAL_AMOUNT'    IS_NUM = ABAP_TRUE  )
      ( FIELD = 'LOCALCURRENCY'   IS_NUM = ABAP_FALSE )
    ).

    DATA: LV_VAL_STR   TYPE STRING,
          LV_TXT_STYLE TYPE STRING,
          LV_COL_IDX   TYPE I,
          LV_ROW_NUM   TYPE I,
          LV_SEQ       TYPE I.

    LV_ROW_NUM = LV_DATA_FIRST.
    LV_SEQ     = 1.

    LOOP AT <LT_DATA> ASSIGNING FIELD-SYMBOL(<LS_ROW>).
      LV_ROWS = LV_ROWS && |<row r="{ LV_ROW_NUM }" ht="18" customHeight="1">|.

      LV_ROWS = LV_ROWS &&
        |<c r="A{ LV_ROW_NUM }" s="8"><v>{ LV_SEQ }</v></c>|.

      LV_COL_IDX = 2.
      LOOP AT LT_MAP INTO DATA(LS_MAP).
        DATA(LV_CL) = COL_LETTER( LV_COL_IDX ).
        ASSIGN COMPONENT LS_MAP-FIELD OF STRUCTURE <LS_ROW> TO FIELD-SYMBOL(<LV_VAL>).
        CLEAR LV_VAL_STR.
        IF SY-SUBRC = 0.
          LV_VAL_STR = CONDENSE( |{ <LV_VAL> }| ).
        ENDIF.

        IF LS_MAP-IS_NUM = ABAP_TRUE.
          LV_ROWS = LV_ROWS && |<c r="{ LV_CL }{ LV_ROW_NUM }" s="5"><v>{ LV_VAL_STR }</v></c>|.
        ELSE.
          LV_TXT_STYLE = COND #( WHEN LV_COL_IDX = 10 THEN '8' ELSE '6' ).
          LV_ROWS = LV_ROWS && |<c r="{ LV_CL }{ LV_ROW_NUM }" t="inlineStr" s="{ LV_TXT_STYLE }">| &&
                               |<is><t>{ LV_VAL_STR }</t></is></c>|.
        ENDIF.

        LV_COL_IDX = LV_COL_IDX + 1.
      ENDLOOP.

      LV_ROWS    = LV_ROWS && '</row>'.
      LV_ROW_NUM = LV_ROW_NUM + 1.
      LV_SEQ     = LV_SEQ + 1.
    ENDLOOP.

    DATA(LV_T1) = LV_TOT_START.
    DATA(LV_T2) = LV_TOT_START + 1.
    DATA(LV_T3) = LV_TOT_START + 2.
    DATA(LV_T4) = LV_TOT_START + 3.

    LV_ROWS = LV_ROWS &&
      |<row r="{ LV_T1 }" ht="18" customHeight="1">| &&
      |<c r="A{ LV_T1 }" t="inlineStr" s="9"><is><t>Total Customer:</t></is></c>| &&
      |<c r="B{ LV_T1 }" s="8"><v>{ LV_CUST_CNT }</v></c>| &&
      '</row>'.

    LV_ROWS = LV_ROWS &&
      |<row r="{ LV_T2 }" ht="18" customHeight="1">| &&
      |<c r="A{ LV_T2 }" t="inlineStr" s="9"><is><t>Total Not Due Amount:</t></is></c>| &&
      |<c r="B{ LV_T2 }" s="10"><f>SUM(D{ LV_DATA_FIRST }:D{ LV_DATA_LAST })</f></c>| &&
      '</row>'.

    LV_ROWS = LV_ROWS &&
      |<row r="{ LV_T3 }" ht="18" customHeight="1">| &&
      |<c r="A{ LV_T3 }" t="inlineStr" s="9"><is><t>Total Overdue Amount:</t></is></c>| &&
      |<c r="B{ LV_T3 }" s="10"><f>SUM(E{ LV_DATA_FIRST }:H{ LV_DATA_LAST })</f></c>| &&
      '</row>'.

    LV_ROWS = LV_ROWS &&
      |<row r="{ LV_T4 }" ht="18" customHeight="1">| &&
      |<c r="A{ LV_T4 }" t="inlineStr" s="9"><is><t>Total Amount:</t></is></c>| &&
      |<c r="B{ LV_T4 }" s="10"><f>SUM(I{ LV_DATA_FIRST }:I{ LV_DATA_LAST })</f></c>| &&
      '</row>'.

    DATA(LV_MERGES) =
      '<mergeCells count="5">' &&
      '<mergeCell ref="A1:J1"/>' &&
      '<mergeCell ref="A2:J2"/>' &&
      '<mergeCell ref="A3:J3"/>' &&
      '<mergeCell ref="A4:J4"/>' &&
      '<mergeCell ref="A5:J5"/>' &&
      '</mergeCells>'.

    RV_XML =
      '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>' &&
      '<worksheet xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main">' &&
      LV_COLS &&
      '<sheetData>' && LV_ROWS && '</sheetData>' &&
      LV_MERGES &&
      '</worksheet>'.
  ENDMETHOD.

  METHOD COL_LETTER.
    IF IV_INDEX <= 26.
      RV_LETTER = SUBSTRING( VAL = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ'
                             OFF = IV_INDEX - 1
                             LEN = 1 ).
    ELSE.
      DATA(LV_HI) = ( IV_INDEX - 1 ) DIV 26.
      DATA(LV_LO) = ( IV_INDEX - 1 ) MOD 26.
      RV_LETTER = SUBSTRING( VAL = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ' OFF = LV_HI - 1 LEN = 1 ) &&
                  SUBSTRING( VAL = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ' OFF = LV_LO LEN = 1 ).
    ENDIF.
  ENDMETHOD.

ENDCLASS.
