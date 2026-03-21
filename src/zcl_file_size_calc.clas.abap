CLASS ZCL_FILE_SIZE_CALC DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC .

  PUBLIC SECTION.
    INTERFACES IF_SADL_EXIT_CALC_ELEMENT_READ.
ENDCLASS.

CLASS ZCL_FILE_SIZE_CALC IMPLEMENTATION.

  METHOD IF_SADL_EXIT_CALC_ELEMENT_READ~CALCULATE.
    " 1. Cast the input data from CDS to an internal table with the CDS View structure
    DATA LT_ORIGINAL_DATA TYPE STANDARD TABLE OF ZC_DRS_FILE WITH DEFAULT KEY.
    LT_ORIGINAL_DATA = CORRESPONDING #( IT_ORIGINAL_DATA ).

    " 2. Loop through each row and format the number from Bytes to a readable String
    LOOP AT LT_ORIGINAL_DATA ASSIGNING FIELD-SYMBOL(<LS_DATA>).
      DATA(LV_BYTES) = <LS_DATA>-FileSize.

      IF LV_BYTES < 1024.
        <LS_DATA>-FileSizeDisplay = |{ LV_BYTES } B|.
      ELSEIF LV_BYTES < 1048576. " 1024 * 1024
        DATA(LV_KB) = LV_BYTES / 1024.
        <LS_DATA>-FileSizeDisplay = |{ LV_KB DECIMALS = 2 } KB|.
      ELSE.
        DATA(LV_MB) = LV_BYTES / 1048576.
        <LS_DATA>-FileSizeDisplay = |{ LV_MB DECIMALS = 2 } MB|.
      ENDIF.
    ENDLOOP.

    " 3. Return the updated data back to the OData framework
    CT_CALCULATED_DATA = CORRESPONDING #( LT_ORIGINAL_DATA ).

  ENDMETHOD.

  METHOD IF_SADL_EXIT_CALC_ELEMENT_READ~GET_CALCULATION_INFO.
    " Request the framework to retrieve the FILESIZE column from DB required for the Calculate method
    APPEND 'FILESIZE' TO ET_REQUESTED_ORIG_ELEMENTS.
  ENDMETHOD.

ENDCLASS.

