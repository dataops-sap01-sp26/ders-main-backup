CLASS zcl_drs_subscr_hide DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.
    INTERFACES if_sadl_exit_calc_element_read.
ENDCLASS.


CLASS zcl_drs_subscr_hide IMPLEMENTATION.

  METHOD if_sadl_exit_calc_element_read~get_calculation_info.
    " Declare which DB fields are needed to compute the virtual element
    LOOP AT it_requested_calc_elements ASSIGNING FIELD-SYMBOL(<elem>).
      CASE <elem>.
        WHEN 'HIDEPARAMGL01'.
          INSERT |REPORTID| INTO TABLE et_requested_orig_elements.
      ENDCASE.
    ENDLOOP.
  ENDMETHOD.


  METHOD if_sadl_exit_calc_element_read~calculate.
    " Cast generic data to typed table
    DATA lt_data TYPE STANDARD TABLE OF zc_drs_subscr WITH DEFAULT KEY.
    lt_data = CORRESPONDING #( it_original_data ).

    LOOP AT lt_data ASSIGNING FIELD-SYMBOL(<row>).
      " Show GL Report Parameters section only when ReportId = 'GL-01'
      <row>-HideParamGL01 = COND abap_boolean(
        WHEN <row>-ReportId = 'GL-01'
        THEN abap_false    " Show
        ELSE abap_true     " Hide
      ).
    ENDLOOP.

    ct_calculated_data = CORRESPONDING #( lt_data ).
  ENDMETHOD.

ENDCLASS.

