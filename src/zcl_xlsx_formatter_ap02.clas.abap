CLASS zcl_xlsx_formatter_ap02 DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.
    INTERFACES zif_file_formatter.

    METHODS constructor
      IMPORTING is_params TYPE zif_report=>ty_params.

  PRIVATE SECTION.
    DATA ms_params TYPE zif_report=>ty_params.

    METHODS build_styles
      RETURNING VALUE(rv_xml) TYPE string.

    METHODS build_sheet
      IMPORTING ir_data       TYPE REF TO data
                it_col_meta   TYPE zif_file_formatter=>tt_col_meta
      RETURNING VALUE(rv_xml) TYPE string.

    METHODS col_letter
      IMPORTING iv_index         TYPE i
      RETURNING VALUE(rv_letter) TYPE string.

ENDCLASS.

CLASS zcl_xlsx_formatter_ap02 IMPLEMENTATION.

  METHOD constructor.
    ms_params = is_params.
  ENDMETHOD.

  METHOD zif_file_formatter~generate.
    rs_result-extension = 'xlsx'.
    rs_result-mime_type = 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet'.

    DATA(lv_conv) = cl_abap_conv_codepage=>create_out( codepage = `UTF-8` ).
    DATA(lo_zip)  = NEW cl_abap_zip( ).

    lo_zip->add( name = '[Content_Types].xml' content = lv_conv->convert(
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

    lo_zip->add( name = '_rels/.rels' content = lv_conv->convert(
      '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>' &&
      '<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">' &&
      '<Relationship Id="rId1"' &&
        ' Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/officeDocument"' &&
        ' Target="xl/workbook.xml"/>' &&
      '</Relationships>' ) ).

    lo_zip->add( name = 'xl/_rels/workbook.xml.rels' content = lv_conv->convert(
      '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>' &&
      '<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">' &&
      '<Relationship Id="rId1"' &&
        ' Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/worksheet"' &&
        ' Target="worksheets/sheet1.xml"/>' &&
      '<Relationship Id="rId2"' &&
        ' Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/styles"' &&
        ' Target="styles.xml"/>' &&
      '</Relationships>' ) ).

    lo_zip->add( name = 'xl/workbook.xml' content = lv_conv->convert(
      '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>' &&
      '<workbook xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main"' &&
        ' xmlns:r="http://schemas.openxmlformats.org/officeDocument/2006/relationships">' &&
      '<sheets>' &&
        '<sheet name="Supplier Balances" sheetId="1" r:id="rId1"/>' &&
      '</sheets>' &&
      '</workbook>' ) ).

    lo_zip->add( name    = 'xl/styles.xml'
                 content = lv_conv->convert( build_styles( ) ) ).

    lo_zip->add( name    = 'xl/worksheets/sheet1.xml'
                 content = lv_conv->convert(
                   build_sheet( ir_data = ir_data it_col_meta = it_col_meta ) ) ).

    rs_result-xstring = lo_zip->save( ).
  ENDMETHOD.

  METHOD build_styles.
    DATA(lv_numfmts) =
      '<numFmts count="1">' &&
      '<numFmt numFmtId="164" formatCode="#,##0;-#,##0;&quot;-&quot;"/>' &&
      '</numFmts>'.

    DATA(lv_fonts) =
      '<fonts count="4">' &&
      '<font><sz val="11"/><name val="Arial"/></font>' &&
      '<font><sz val="10"/><name val="Arial"/></font>' &&
      '<font><b/><sz val="10"/><name val="Arial"/></font>' &&
      '<font><b/><sz val="14"/><name val="Arial"/></font>' &&
      '</fonts>'.

    DATA(lv_fills) =
      '<fills count="3">' &&
      '<fill><patternFill patternType="none"/></fill>' &&
      '<fill><patternFill patternType="gray125"/></fill>' &&
      '<fill><patternFill patternType="solid">' &&
        '<fgColor rgb="FFFFFF00"/>' &&
      '</patternFill></fill>' &&
      '</fills>'.

    DATA(lv_borders) =
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

    DATA(lv_csxfs) =
      '<cellStyleXfs count="1">' &&
      '<xf numFmtId="0" fontId="0" fillId="0" borderId="0"/>' &&
      '</cellStyleXfs>'.

    DATA(lv_cxfs) =
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

    rv_xml =
      '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>' &&
      '<styleSheet xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main">' &&
      lv_numfmts && lv_fonts && lv_fills && lv_borders && lv_csxfs && lv_cxfs &&
      '</styleSheet>'.
  ENDMETHOD.

  METHOD build_sheet.
    SELECT SINGLE * FROM zdrs_param_ap02
      WHERE subscr_uuid = @ms_params-subscr_uuid
      INTO @DATA(ls_param).

    DATA(lv_gen_date) = |{ sy-datum+6(2) }/{ sy-datum+4(2) }/{ sy-datum(4) }|.

    FIELD-SYMBOLS <lt_data> TYPE STANDARD TABLE.
    ASSIGN ir_data->* TO <lt_data>.

    DATA(lv_data_cnt)   = lines( <lt_data> ).
    DATA(lv_data_first) = 8.
    DATA(lv_data_last)  = lv_data_first + lv_data_cnt - 1.
    DATA(lv_tot_start)  = lv_data_last + 2.

    DATA lv_currency TYPE string.
    READ TABLE <lt_data> INDEX 1 ASSIGNING FIELD-SYMBOL(<ls_first>).
    IF sy-subrc = 0.
      ASSIGN COMPONENT 'LOCALCURRENCY' OF STRUCTURE <ls_first> TO FIELD-SYMBOL(<lv_first_cur>).
      IF sy-subrc = 0.
        lv_currency = condense( |{ <lv_first_cur> }| ).
      ENDIF.
    ENDIF.

    DATA lt_unique_sup TYPE hashed TABLE OF string WITH UNIQUE KEY table_line.
    LOOP AT <lt_data> ASSIGNING FIELD-SYMBOL(<ls_uc>).
      ASSIGN COMPONENT 'SUPPLIER' OF STRUCTURE <ls_uc> TO FIELD-SYMBOL(<lv_uc_val>).
      IF sy-subrc = 0.
        DATA(lv_uc_str) = condense( |{ <lv_uc_val> }| ).
        TRY.
            INSERT lv_uc_str INTO TABLE lt_unique_sup.
          CATCH cx_sy_itab_duplicate_key.
        ENDTRY.
      ENDIF.
    ENDLOOP.
    DATA(lv_sup_cnt) = lines( lt_unique_sup ).

    DATA(lv_cols) =
      '<cols>' &&
      '<col min="1"  max="1"  width="6"  customWidth="1"/>' &&
      '<col min="2"  max="2"  width="14" customWidth="1"/>' &&
      '<col min="3"  max="3"  width="25" customWidth="1"/>' &&
      '<col min="4"  max="4"  width="30" customWidth="1"/>' &&
      '<col min="5"  max="5"  width="14" customWidth="1"/>' &&
      '<col min="6"  max="6"  width="18" customWidth="1"/>' &&
      '<col min="7"  max="7"  width="18" customWidth="1"/>' &&
      '<col min="8"  max="8"  width="18" customWidth="1"/>' &&
      '<col min="9"  max="9"  width="18" customWidth="1"/>' &&
      '<col min="10" max="10" width="18" customWidth="1"/>' &&
      '<col min="11" max="11" width="12" customWidth="1"/>' &&
      '</cols>'.

    DATA lv_rows TYPE string.

    LV_ROWS = LV_ROWS &&
      '<row r="1" ht="35" customHeight="1">' &&
      '<c r="A1" t="inlineStr" s="1">' &&
        '<is><t>SUPPLIER ACCOUNT BALANCE REPORT</t></is>' &&
      '</c>' &&
      '</row>'.

    LV_ROWS = LV_ROWS &&
      '<row r="2" ht="18" customHeight="1">' &&
      |<c r="A2" t="inlineStr" s="2"><is><t>Company code: { ls_param-company_code }</t></is></c>| &&
      '</row>'.

    ASSIGN COMPONENT 'KEY_DATE' OF STRUCTURE ls_param TO FIELD-SYMBOL(<lv_key_date>).
    DATA lv_key_date_str TYPE string.
    IF sy-subrc = 0.
      lv_key_date_str = condense( |{ <lv_key_date> }| ).
    ELSE.
      lv_key_date_str = 'N/A'.
    ENDIF.

    LV_ROWS = LV_ROWS &&
      '<row r="3" ht="18" customHeight="1">' &&
      |<c r="A3" t="inlineStr" s="2"><is><t>Key Date: { lv_key_date_str }</t></is></c>| &&
      '</row>'.

    LV_ROWS = LV_ROWS &&
      '<row r="4" ht="18" customHeight="1">' &&
      |<c r="A4" t="inlineStr" s="2"><is><t>Currency: { lv_currency }</t></is></c>| &&
      '</row>'.

    LV_ROWS = LV_ROWS &&
      '<row r="5" ht="18" customHeight="1">' &&
      |<c r="A5" t="inlineStr" s="2"><is><t>Generated on: { lv_gen_date }</t></is></c>| &&
      '</row>'.

    LV_ROWS = LV_ROWS && '<row r="6" ht="8" customHeight="1"/>'.

    LV_ROWS = LV_ROWS &&
      '<row r="7" ht="40" customHeight="1">' &&
      '<c r="A7" t="inlineStr" s="3"><is><t>No</t></is></c>'               &&
      '<c r="B7" t="inlineStr" s="3"><is><t>Supplier ID</t></is></c>'       &&
      '<c r="C7" t="inlineStr" s="3"><is><t>Supplier Name</t></is></c>'     &&
      '<c r="D7" t="inlineStr" s="3"><is><t>Address</t></is></c>'           &&
      '<c r="E7" t="inlineStr" s="3"><is><t>Posting Date</t></is></c>'      &&
      '<c r="F7" t="inlineStr" s="3"><is><t>Opening Balance</t></is></c>'   &&
      '<c r="G7" t="inlineStr" s="3"><is><t>Debit</t></is></c>'             &&
      '<c r="H7" t="inlineStr" s="3"><is><t>Credit</t></is></c>'            &&
      '<c r="I7" t="inlineStr" s="3"><is><t>Period Activity</t></is></c>'   &&
      '<c r="J7" t="inlineStr" s="3"><is><t>Closing Balance</t></is></c>'   &&
      '<c r="K7" t="inlineStr" s="3"><is><t>Currency</t></is></c>'          &&
      '</row>'.

    TYPES: BEGIN OF ty_col_map,
             field  TYPE string,
             is_num TYPE abap_bool,
           END OF ty_col_map.
    TYPES tt_col_map TYPE STANDARD TABLE OF ty_col_map WITH DEFAULT KEY.

    DATA(lt_map) = VALUE tt_col_map(
      ( field = 'SUPPLIER'       is_num = abap_false )
      ( field = 'SUPPLIERNAME'   is_num = abap_false )
      ( field = 'ADDRESS'        is_num = abap_false )
      ( field = 'POSTINGDATE'    is_num = abap_false )
      ( field = 'OPENINGBALANCE' is_num = abap_true  )
      ( field = 'DEBIT'          is_num = abap_true  )
      ( field = 'CREDIT'         is_num = abap_true  )
      ( field = 'PERIODACTIVITY' is_num = abap_true  )
      ( field = 'CLOSINGBALANCE' is_num = abap_true  )
      ( field = 'LOCALCURRENCY'  is_num = abap_false )
    ).

    DATA: lv_val_str   TYPE string,
          lv_txt_style TYPE string,
          lv_col_idx   TYPE i,
          lv_row_num   TYPE i,
          lv_seq       TYPE i.

    lv_row_num = lv_data_first.
    lv_seq     = 1.

    LOOP AT <lt_data> ASSIGNING FIELD-SYMBOL(<ls_row>).
      lv_rows = lv_rows && |<row r="{ lv_row_num }" ht="18" customHeight="1">|.

      lv_rows = lv_rows &&
        |<c r="A{ lv_row_num }" s="8"><v>{ lv_seq }</v></c>|.

      lv_col_idx = 2.
      LOOP AT lt_map INTO DATA(ls_map).
        DATA(lv_cl) = col_letter( lv_col_idx ).
        ASSIGN COMPONENT ls_map-field OF STRUCTURE <ls_row> TO FIELD-SYMBOL(<lv_val>).
        CLEAR lv_val_str.
        IF sy-subrc = 0.
          lv_val_str = condense( |{ <lv_val> }| ).
        ENDIF.

        IF ls_map-is_num = abap_true.
          lv_rows = lv_rows && |<c r="{ lv_cl }{ lv_row_num }" s="5"><v>{ lv_val_str }</v></c>|.
        ELSE.
          lv_txt_style = COND #( WHEN lv_col_idx = 11 THEN '8' ELSE '6' ).
          lv_rows = lv_rows && |<c r="{ lv_cl }{ lv_row_num }" t="inlineStr" s="{ lv_txt_style }">| &&
                               |<is><t>{ lv_val_str }</t></is></c>|.
        ENDIF.

        lv_col_idx = lv_col_idx + 1.
      ENDLOOP.

      lv_rows    = lv_rows && '</row>'.
      lv_row_num = lv_row_num + 1.
      lv_seq     = lv_seq + 1.
    ENDLOOP.

    DATA(lv_t1) = lv_tot_start.
    DATA(lv_t2) = lv_tot_start + 1.
    DATA(lv_t3) = lv_tot_start + 2.
    DATA(lv_t4) = lv_tot_start + 3.
    DATA(lv_t5) = lv_tot_start + 4.

    lv_rows = lv_rows &&
      |<row r="{ lv_t1 }" ht="18" customHeight="1">| &&
      |<c r="A{ lv_t1 }" t="inlineStr" s="9"><is><t>Total Supplier:</t></is></c>| &&
      |<c r="B{ lv_t1 }" s="8"><v>{ lv_sup_cnt }</v></c>| &&
      '</row>'.

    lv_rows = lv_rows &&
      |<row r="{ lv_t2 }" ht="18" customHeight="1">| &&
      |<c r="A{ lv_t2 }" t="inlineStr" s="9"><is><t>Total Opening Balance:</t></is></c>| &&
      |<c r="B{ lv_t2 }" s="10"><f>SUM(F{ lv_data_first }:F{ lv_data_last })</f></c>| &&
      '</row>'.

    lv_rows = lv_rows &&
      |<row r="{ lv_t3 }" ht="18" customHeight="1">| &&
      |<c r="A{ lv_t3 }" t="inlineStr" s="9"><is><t>Total Debit:</t></is></c>| &&
      |<c r="B{ lv_t3 }" s="10"><f>SUM(G{ lv_data_first }:G{ lv_data_last })</f></c>| &&
      '</row>'.

    lv_rows = lv_rows &&
      |<row r="{ lv_t4 }" ht="18" customHeight="1">| &&
      |<c r="A{ lv_t4 }" t="inlineStr" s="9"><is><t>Total Credit:</t></is></c>| &&
      |<c r="B{ lv_t4 }" s="10"><f>SUM(H{ lv_data_first }:H{ lv_data_last })</f></c>| &&
      '</row>'.

    lv_rows = lv_rows &&
      |<row r="{ lv_t5 }" ht="18" customHeight="1">| &&
      |<c r="A{ lv_t5 }" t="inlineStr" s="9"><is><t>Total Closing Balance:</t></is></c>| &&
      |<c r="B{ lv_t5 }" s="10"><f>SUM(J{ lv_data_first }:J{ lv_data_last })</f></c>| &&
      '</row>'.

    DATA(lv_merges) =
      '<mergeCells count="5">' &&
      '<mergeCell ref="A1:K1"/>' &&
      '<mergeCell ref="A2:K2"/>' &&
      '<mergeCell ref="A3:K3"/>' &&
      '<mergeCell ref="A4:K4"/>' &&
      '<mergeCell ref="A5:K5"/>' &&
      '</mergeCells>'.

    rv_xml =
      '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>' &&
      '<worksheet xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main">' &&
      lv_cols &&
      '<sheetData>' && lv_rows && '</sheetData>' &&
      lv_merges &&
      '</worksheet>'.
  ENDMETHOD.

  METHOD col_letter.
    IF iv_index <= 26.
      rv_letter = substring( val = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ'
                             off = iv_index - 1
                             len = 1 ).
    ELSE.
      DATA(lv_hi) = ( iv_index - 1 ) DIV 26.
      DATA(lv_lo) = ( iv_index - 1 ) MOD 26.
      rv_letter = substring( val = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ' off = lv_hi - 1 len = 1 ) &&
                  substring( val = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ' off = lv_lo len = 1 ).
    ENDIF.
  ENDMETHOD.

ENDCLASS.

