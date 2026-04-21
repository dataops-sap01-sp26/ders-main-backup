CLASS ZCL_XLSX_FORMATTER DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.
    INTERFACES ZIF_FILE_FORMATTER.

  PROTECTED SECTION.
  PRIVATE SECTION.

    " Convert 1-based column index to Excel column letter (A, B, ... Z, AA, AB ...)
    METHODS COL_LETTER
      IMPORTING IV_INDEX         TYPE I
      RETURNING VALUE(RV_LETTER) TYPE STRING.

ENDCLASS.


CLASS ZCL_XLSX_FORMATTER IMPLEMENTATION.

  METHOD COL_LETTER.
    IF IV_INDEX <= 26.
      RV_LETTER = SUBSTRING( VAL = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ'
                             OFF = IV_INDEX - 1  LEN = 1 ).
    ELSE.
      DATA(LV_HI) = ( IV_INDEX - 1 ) DIV 26.
      DATA(LV_LO) = ( IV_INDEX - 1 ) MOD 26.
      RV_LETTER = SUBSTRING( VAL = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ' OFF = LV_HI - 1 LEN = 1 ) &&
                  SUBSTRING( VAL = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ' OFF = LV_LO     LEN = 1 ).
    ENDIF.
  ENDMETHOD.


  METHOD ZIF_FILE_FORMATTER~GENERATE.
    RS_RESULT-EXTENSION = 'xlsx'.
    RS_RESULT-MIME_TYPE = 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet'.

    DATA(LV_CONV) = CL_ABAP_CONV_CODEPAGE=>CREATE_OUT( CODEPAGE = `UTF-8` ).
    DATA(LO_ZIP)  = NEW CL_ABAP_ZIP( ).

    " ── Static OpenXML package parts ──
    LO_ZIP->ADD( NAME = '[Content_Types].xml' CONTENT = LV_CONV->CONVERT(
      '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>' &&
      '<Types xmlns="http://schemas.openxmlformats.org/package/2006/content-types">' &&
      '<Default Extension="rels" ContentType="application/vnd.openxmlformats-package.relationships+xml"/>' &&
      '<Default Extension="xml" ContentType="application/xml"/>' &&
      '<Override PartName="/xl/workbook.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.sheet.main+xml"/>' &&
      '<Override PartName="/xl/worksheets/sheet1.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.worksheet+xml"/>' &&
      '<Override PartName="/xl/styles.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.styles+xml"/>' &&
      '</Types>' ) ).

    LO_ZIP->ADD( NAME = '_rels/.rels' CONTENT = LV_CONV->CONVERT(
      '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>' &&
      '<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">' &&
      '<Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/officeDocument" Target="xl/workbook.xml"/>' &&
      '</Relationships>' ) ).

    LO_ZIP->ADD( NAME = 'xl/_rels/workbook.xml.rels' CONTENT = LV_CONV->CONVERT(
      '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>' &&
      '<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">' &&
      '<Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/worksheet" Target="worksheets/sheet1.xml"/>' &&
      '<Relationship Id="rId2" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/styles" Target="styles.xml"/>' &&
      '</Relationships>' ) ).

    LO_ZIP->ADD( NAME = 'xl/workbook.xml' CONTENT = LV_CONV->CONVERT(
      '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>' &&
      '<workbook xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main"' &&
        ' xmlns:r="http://schemas.openxmlformats.org/officeDocument/2006/relationships">' &&
      '<sheets><sheet name="Sheet1" sheetId="1" r:id="rId1"/></sheets></workbook>' ) ).

    LO_ZIP->ADD( NAME = 'xl/styles.xml' CONTENT = LV_CONV->CONVERT(
      '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>' &&
      '<styleSheet xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main">' &&
      '<fonts count="1"><font><sz val="11"/><name val="Calibri"/></font></fonts>' &&
      '<fills count="2">' &&
        '<fill><patternFill patternType="none"/></fill>' &&
        '<fill><patternFill patternType="gray125"/></fill>' &&
      '</fills>' &&
      '<borders count="1"><border><left/><right/><top/><bottom/><diagonal/></border></borders>' &&
      '<cellStyleXfs count="1"><xf numFmtId="0" fontId="0" fillId="0" borderId="0"/></cellStyleXfs>' &&
      '<cellXfs count="1"><xf numFmtId="0" fontId="0" fillId="0" borderId="0" xfId="0"/></cellXfs>' &&
      '</styleSheet>' ) ).

    " ── Build sheet XML ──
    FIELD-SYMBOLS <LT_DATA> TYPE STANDARD TABLE.
    ASSIGN IR_DATA->* TO <LT_DATA>.

    DATA LT_COL_META TYPE ZIF_FILE_FORMATTER=>TT_COL_META.
    LT_COL_META = IT_COL_META.

    IF LT_COL_META IS INITIAL.
      TRY.
          DATA(LO_TD) = CAST CL_ABAP_TABLEDESCR( CL_ABAP_TYPEDESCR=>DESCRIBE_BY_DATA( <LT_DATA> ) ).
          DATA(LO_SD) = CAST CL_ABAP_STRUCTDESCR( LO_TD->GET_TABLE_LINE_TYPE( ) ).
          LOOP AT LO_SD->COMPONENTS INTO DATA(LS_COMP).
            DATA(LV_IS_NUM) = XSDBOOL( LS_COMP-TYPE_KIND = CL_ABAP_TYPEDESCR=>TYPEKIND_INT OR
                                       LS_COMP-TYPE_KIND = CL_ABAP_TYPEDESCR=>TYPEKIND_INT1 OR
                                       LS_COMP-TYPE_KIND = CL_ABAP_TYPEDESCR=>TYPEKIND_INT2 OR
                                       LS_COMP-TYPE_KIND = CL_ABAP_TYPEDESCR=>TYPEKIND_INT8 OR
                                       LS_COMP-TYPE_KIND = CL_ABAP_TYPEDESCR=>TYPEKIND_PACKED OR
                                       LS_COMP-TYPE_KIND = CL_ABAP_TYPEDESCR=>TYPEKIND_FLOAT OR
                                       LS_COMP-TYPE_KIND = CL_ABAP_TYPEDESCR=>TYPEKIND_DECFLOAT16 OR
                                       LS_COMP-TYPE_KIND = CL_ABAP_TYPEDESCR=>TYPEKIND_DECFLOAT34 ).
            APPEND VALUE #( NAME = LS_COMP-NAME IS_NUM = LV_IS_NUM ) TO LT_COL_META.
          ENDLOOP.
        CATCH CX_ROOT.
      ENDTRY.
    ENDIF.

    DATA LV_SHEET TYPE STRING.
    LV_SHEET =
      '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>' &&
      '<worksheet xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main">' &&
      '<sheetData>'.

    " Header row (row 1)
    DATA LV_HDROW TYPE STRING.
    DATA LV_COL_IDX TYPE I.
    CLEAR: LV_HDROW, LV_COL_IDX.
    LV_HDROW   = '<row r="1">'.
    LV_COL_IDX = 1.
    LOOP AT LT_COL_META INTO DATA(LS_HCOMP).
      DATA(LV_CL_H) = COL_LETTER( LV_COL_IDX ).
      LV_HDROW = LV_HDROW &&
        |<c r="{ LV_CL_H }1" t="inlineStr">| &&
        |<is><t>{ LS_HCOMP-NAME }</t></is></c>|.
      LV_COL_IDX = LV_COL_IDX + 1.
    ENDLOOP.
    LV_HDROW = LV_HDROW && '</row>'.
    LV_SHEET = LV_SHEET && LV_HDROW.

    " Data rows
    DATA LV_ROW_NUM TYPE I.
    LV_ROW_NUM = 2.
    LOOP AT <LT_DATA> ASSIGNING FIELD-SYMBOL(<LS_ROW>).
      DATA LV_XL_ROW TYPE STRING.
      CLEAR LV_XL_ROW.
      LV_XL_ROW = |<row r="{ LV_ROW_NUM }">|.
      DATA LV_CI TYPE I.
      LV_CI = 1.
      LOOP AT LT_COL_META INTO DATA(LS_META).
        DATA(LV_CL_D) = COL_LETTER( LV_CI ).
        ASSIGN COMPONENT LS_META-NAME OF STRUCTURE <LS_ROW> TO FIELD-SYMBOL(<LV_VAL>).
        DATA LV_CELL_VAL TYPE STRING.
        CLEAR LV_CELL_VAL.
        IF SY-SUBRC = 0. LV_CELL_VAL = CONDENSE( |{ <LV_VAL> }| ). ENDIF.
        IF LS_META-IS_NUM = ABAP_TRUE.
          LV_XL_ROW = LV_XL_ROW &&
            |<c r="{ LV_CL_D }{ LV_ROW_NUM }">| &&
            |<v>{ LV_CELL_VAL }</v></c>|.
        ELSE.
          LV_XL_ROW = LV_XL_ROW &&
            |<c r="{ LV_CL_D }{ LV_ROW_NUM }" t="inlineStr">| &&
            |<is><t>{ LV_CELL_VAL }</t></is></c>|.
        ENDIF.
        LV_CI = LV_CI + 1.
      ENDLOOP.
      LV_XL_ROW = LV_XL_ROW && '</row>'.
      LV_SHEET  = LV_SHEET  && LV_XL_ROW.
      LV_ROW_NUM = LV_ROW_NUM + 1.
    ENDLOOP.

    LV_SHEET = LV_SHEET && '</sheetData></worksheet>'.
    LO_ZIP->ADD( NAME = 'xl/worksheets/sheet1.xml' CONTENT = LV_CONV->CONVERT( LV_SHEET ) ).
    RS_RESULT-XSTRING = LO_ZIP->SAVE( ).
  ENDMETHOD.

ENDCLASS.

