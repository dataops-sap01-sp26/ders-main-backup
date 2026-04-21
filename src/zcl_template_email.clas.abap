CLASS ZCL_TEMPLATE_EMAIL DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC .

  PUBLIC SECTION.
    CLASS-METHODS RENDER_EMAIL
      IMPORTING
        IV_JOB_UUID    TYPE ZDRS_JOB_CONFIG-JOB_UUID
      RETURNING
        VALUE(RV_HTML) TYPE STRING.

    CLASS-METHODS RENDER_ERROR_EMAIL
      IMPORTING
        IV_JOB_UUID    TYPE ZDRS_JOB_CONFIG-JOB_UUID
        IV_ERROR_MSG   TYPE STRING OPTIONAL
      RETURNING
        VALUE(RV_HTML) TYPE STRING.
  PROTECTED SECTION.
  PRIVATE SECTION.
ENDCLASS.



CLASS ZCL_TEMPLATE_EMAIL IMPLEMENTATION.
  METHOD RENDER_EMAIL.

    DATA: LV_HTML             TYPE STRING,
          LV_START_D          TYPE D,
          LV_START_T          TYPE T,
          LV_END_D            TYPE D,
          LV_END_T            TYPE T,
          LV_DURATION         TYPE I,
          LV_STATUS_COLOR     TYPE STRING,
          LV_STATUS_ICON      TYPE STRING,
          LV_STATUS_TEXT_DISP TYPE STRING,
          LV_SCHEDULE_INFO    TYPE STRING,
          LV_FILE_SIZE_DISP   TYPE STRING,
          LV_DOWNLOAD_LINK    TYPE STRING.

    " Get specific fields from zdrs_job_config
    SELECT SINGLE JOB_UUID, SUBSCR_UUID, JOB_ID, RUN_TYPE,
                  JOB_STATUS, MESSAGE, START_TIMESTAMP,
                  END_TIMESTAMP, TMZONE, CREATED_BY
      FROM ZDRS_JOB_CONFIG
      WHERE JOB_UUID = @IV_JOB_UUID
      INTO @DATA(LS_JOB).

    IF SY-SUBRC <> 0.
      RETURN. " Return if data not found
    ENDIF.

    " ==========================================
    " 1. FETCH DỮ LIỆU TỪ BẢNG SUBSCRIPTION & FILE
    " ==========================================
    " Lấy thông tin báo cáo (Tên, Định dạng, Report ID...)
    SELECT SINGLE REPORT_ID, SUBSCR_NAME, BUKRS, OUTPUT_FORMAT
      FROM ZDRS_SUBSCR
      WHERE SUBSCR_UUID = @LS_JOB-SUBSCR_UUID
      INTO @DATA(LS_SUBSCR).

    " Lấy thông tin file kết quả
    SELECT SINGLE FILE_UUID, FILE_NAME, FILE_SIZE
      FROM ZDRS_FILE
      WHERE JOB_UUID = @LS_JOB-JOB_UUID
      INTO @DATA(LS_FILE).

    IF LS_FILE-FILE_SIZE < 1024.
      LV_FILE_SIZE_DISP = |{ LS_FILE-FILE_SIZE } B|.
    ELSEIF LS_FILE-FILE_SIZE < 1048576. " 1024 * 1024
      DATA(LV_KB) = LS_FILE-FILE_SIZE / 1024.
      LV_FILE_SIZE_DISP = |{ LV_KB DECIMALS = 2 } KB|.
    ELSE.
      DATA(LV_MB) = LS_FILE-FILE_SIZE / 1048576.
      LV_FILE_SIZE_DISP = |{ LV_MB DECIMALS = 2 } MB|.
    ENDIF.



    " ==========================================
    " 2. XỬ LÝ LOGIC THỜI GIAN & TRẠNG THÁI
    " ==========================================
    CONVERT TIME STAMP LS_JOB-START_TIMESTAMP TIME ZONE LS_JOB-TMZONE INTO DATE LV_START_D TIME LV_START_T.
    CONVERT TIME STAMP LS_JOB-END_TIMESTAMP TIME ZONE LS_JOB-TMZONE INTO DATE LV_END_D TIME LV_END_T.

    TRY.
        CL_ABAP_TSTMP=>SUBTRACT(
          EXPORTING TSTMP1 = LS_JOB-END_TIMESTAMP
                    TSTMP2 = LS_JOB-START_TIMESTAMP
          RECEIVING R_SECS = LV_DURATION ).
      CATCH CX_PARAMETER_INVALID_RANGE CX_PARAMETER_INVALID_TYPE.
        LV_DURATION = 0.
    ENDTRY.

    DATA(LV_MIN) = LV_DURATION DIV 60.
    DATA(LV_SEC) = LV_DURATION MOD 60.
    DATA(LV_DURATION_TEXT) = |{ LV_MIN } min { LV_SEC } sec|.

    DATA(LV_END_STRING)   = |{ LV_END_D DATE = ISO } { LV_END_T TIME = ISO }|.
    DATA(LV_START_STRING) = |{ LV_START_D DATE = ISO } { LV_START_T TIME = ISO }|.

* " Xử lý Trạng thái Job
    LV_STATUS_COLOR = '#28a745'. " Green
    LV_STATUS_ICON  = '&#10004;'.
    LV_STATUS_TEXT_DISP = 'Completed Successfully'.


    CASE LS_JOB-RUN_TYPE.
      WHEN 'I'.
        LV_SCHEDULE_INFO = 'Immediate Run'.
      WHEN 'O'.
        LV_SCHEDULE_INFO = 'Once'.
      WHEN 'P'.
        LV_SCHEDULE_INFO = 'Periodic'.
    ENDCASE.

    " ==========================================
    " 3. XÂY DỰNG HTML NỘI DUNG EMAIL
    " ==========================================
    " -- HEAD & STYLES --
    LV_HTML = |<!DOCTYPE html><html><head><style>| &&
              |body \{ font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif; background-color: #f4f7f6; margin: 0; padding: 20px; color: #333; \} | &&
              |.container \{ max-width: 650px; background: #ffffff; margin: 0 auto; border-radius: 8px; overflow: hidden; box-shadow: 0 4px 10px rgba(0,0,0,0.05); \} | &&
              |.header \{ background-color: #005587; color: white; padding: 25px 30px; \} | &&
              |.header h1 \{ margin: 0; font-size: 22px; font-weight: 500; \} | &&
              |.header p \{ margin: 5px 0 0 0; font-size: 14px; opacity: 0.8; \} | &&
              |.status-badge \{ display: inline-block; padding: 6px 12px; border-radius: 4px; color: white; font-weight: bold; font-size: 14px; margin-top: 15px; background-color: { LV_STATUS_COLOR }; \} | &&
              |.content \{ padding: 30px; \} | &&
              |table \{ width: 100%; border-collapse: collapse; margin-bottom: 20px; \} | &&
              |td \{ padding: 10px 0; border-bottom: 1px solid #eee; font-size: 14px; \} | &&
              |.td-label \{ color: #666; width: 40%; \} | &&
              |.td-value \{ color: #222; font-weight: 500; text-align: right; \} | &&
              |.error-box \{ background-color: #f8d7da; color: #721c24; padding: 15px; border-left: 4px solid #dc3545; border-radius: 4px; margin-bottom: 20px; font-size: 14px; \} | &&
              |.download-btn \{ background-color: #0070f2; color: white !important; padding: 12px 24px; text-decoration: none; display: block; text-align: center; border-radius: 4px; font-weight: bold; margin-top: 20px; \} | &&
              |.footer \{ background-color: #f8f9fa; padding: 20px; text-align: center; font-size: 12px; color: #888; border-top: 1px solid #eee; \} | &&
              |.footer a \{ color: #005587; text-decoration: none; \} | &&
              |</style></head><body><div class="container">|.

    " -- HEADER --
    LV_HTML = LV_HTML &&
              |<div class="header">| &&
              |<h1>{ LS_SUBSCR-REPORT_ID } - { LS_SUBSCR-SUBSCR_NAME }</h1>| &&
              |<p>Job ID: { LS_JOB-JOB_ID } \| Company Code: { LS_SUBSCR-BUKRS }</p>| &&
              |<div class="status-badge">{ LV_STATUS_ICON } { LV_STATUS_TEXT_DISP }</div>| &&
              |</div><div class="content">|.

    " -- LỖI (Nếu có) --
    IF LS_JOB-JOB_STATUS = 'A' AND LS_JOB-MESSAGE IS NOT INITIAL.
      LV_HTML = LV_HTML && |<div class="error-box"><strong>Error Message:</strong><br>{ LS_JOB-MESSAGE }</div>|.
    ENDIF.

    " -- BẢNG CHI TIẾT --
    " 1. Bắt đầu bảng và thêm dòng Run Type
    LV_HTML = LV_HTML && |<table>| &&
              |<tr><td class="td-label">Run Type</td><td class="td-value">{ LV_SCHEDULE_INFO }</td></tr>|.

    " 2. Kiểm tra Start Time
    IF LS_JOB-START_TIMESTAMP IS NOT INITIAL.
      LV_HTML = LV_HTML && |<tr><td class="td-label">Start Time</td><td class="td-value">{ LV_START_STRING } ({ LS_JOB-TMZONE })</td></tr>| &&
                           |<tr><td class="td-label">Duration</td><td class="td-value">{ LV_DURATION_TEXT }</td></tr>|.
    ENDIF.

    " 3. Tiếp tục nối các dòng còn lại (Output Format)
    LV_HTML = LV_HTML && |<tr><td class="td-label">Output Format</td><td class="td-value">{ LS_SUBSCR-OUTPUT_FORMAT }</td></tr>|.



    IF LS_FILE-FILE_NAME IS NOT INITIAL.
      LV_HTML = LV_HTML &&
                |<tr><td class="td-label">File Name</td><td class="td-value">{ LS_FILE-FILE_NAME }</td></tr>| &&
                |<tr><td class="td-label">File Size</td><td class="td-value">{ LV_FILE_SIZE_DISP } </td></tr>|.
    ENDIF.

    LV_HTML = LV_HTML && |</table>|.

    IF LS_FILE-FILE_NAME IS NOT INITIAL.
      IF LS_FILE-FILE_SIZE <= 10485760.
        LV_HTML = LV_HTML && |<p style="text-align:center; font-size:14px; color:#555;">The output file <strong>{ LS_FILE-FILE_NAME }</strong> is attached to this email.</p>|.
      ELSE.
        LV_HTML = LV_HTML && |<p style="text-align:center; font-size:14px; color:#555;">Your file is larger than 10MB and cannot be attached.</p>| &&
                             |<a href="{ LV_DOWNLOAD_LINK }" class="download-btn">Download Report File</a>| &&
                             |<p style="text-align:center; font-size:12px; margin-top:10px; color:#888;">Link expires based on system retention policy.</p>|.
      ENDIF.
    ENDIF.

    LV_HTML = LV_HTML && |</div>|. " Đóng Content

    " -- FOOTER --
    LV_HTML = LV_HTML &&
              |<div class="footer">| &&
              |<p>This is an automated message from DERS-Fiori System. Created by: { LS_JOB-CREATED_BY }</p>| &&
              |<p>Need help? <a href="https://sap.company.com/ders">Open Support Ticket</a></p>| &&
              |</div></div></body></html>|.

    RV_HTML = LV_HTML.

  ENDMETHOD.

  METHOD RENDER_ERROR_EMAIL.

    DATA: LV_HTML          TYPE STRING,
          LV_START_D       TYPE D,
          LV_START_T       TYPE T,
          LV_SCHEDULE_INFO TYPE STRING.

    " ==========================================
    " 1. LẤY THÔNG TIN JOB & SUBSCRIPTION
    " ==========================================
    " Chỉ lấy các field cần thiết từ bảng zdrs_job_config
    SELECT SINGLE SUBSCR_UUID, JOB_ID, RUN_TYPE,
                  START_TIMESTAMP, TMZONE, CREATED_BY
      FROM ZDRS_JOB_CONFIG
      WHERE JOB_UUID = @IV_JOB_UUID
      INTO @DATA(LS_JOB).

    IF SY-SUBRC <> 0.
      " Trả về HTML cơ bản nếu không tìm thấy Job (đề phòng dump)
      RV_HTML = |<html><body><h3>Error processing job</h3><p>{ IV_ERROR_MSG }</p></body></html>|.
      RETURN.
    ENDIF.

    " Chỉ lấy các field cần thiết từ bảng zdrs_subscr
    SELECT SINGLE REPORT_ID, SUBSCR_NAME, BUKRS, OUTPUT_FORMAT
      FROM ZDRS_SUBSCR
      WHERE SUBSCR_UUID = @LS_JOB-SUBSCR_UUID
      INTO @DATA(LS_SUBSCR).

    " ==========================================
    " 2. XỬ LÝ LOGIC THỜI GIAN & TRẠNG THÁI
    " ==========================================
    IF LS_JOB-START_TIMESTAMP IS NOT INITIAL.
      CONVERT TIME STAMP LS_JOB-START_TIMESTAMP TIME ZONE LS_JOB-TMZONE INTO DATE LV_START_D TIME LV_START_T.
      DATA(LV_START_STRING) = |{ LV_START_D DATE = ISO } { LV_START_T TIME = ISO }|.
    ELSE.
      LV_START_STRING = 'N/A'.
    ENDIF.

    CASE LS_JOB-RUN_TYPE.
      WHEN 'I'. LV_SCHEDULE_INFO = 'Immediate Run'.
      WHEN 'O'. LV_SCHEDULE_INFO = 'Once'.
      WHEN 'P'. LV_SCHEDULE_INFO = 'Periodic'.
    ENDCASE.

    " ==========================================
    " 3. XÂY DỰNG HTML NỘI DUNG EMAIL LỖI (ENGLISH)
    " ==========================================
    " -- HEAD & STYLES --
    " Lưu ý: Các ngoặc nhọn trong CSS phải được escape bằng dấu \
    LV_HTML = |<!DOCTYPE html><html><head><meta charset="UTF-8"><title>Error Email</title><style>| &&
              |body \{ font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif; background-color: #f4f7f6; margin: 0; padding: 20px; color: #333; \} | &&
              |.container \{ max-width: 650px; background: #ffffff; margin: 0 auto; border-radius: 8px; overflow: hidden; box-shadow: 0 4px 10px rgba(0,0,0,0.05); \} | &&
              |.header \{ background-color: #dc3545; color: white; padding: 25px 30px; \} | &&
              |.header h1 \{ margin: 0; font-size: 22px; font-weight: 500; \} | &&
              |.header p \{ margin: 5px 0 0 0; font-size: 14px; opacity: 0.8; \} | &&
              |.status-badge \{ display: inline-block; padding: 6px 12px; border-radius: 4px; color: white; font-weight: bold; font-size: 14px; margin-top: 15px; background-color: #721c24; \} | &&
              |.content \{ padding: 30px; \} | &&
              |table \{ width: 100%; border-collapse: collapse; margin-bottom: 20px; \} | &&
              |td \{ padding: 10px 0; border-bottom: 1px solid #eee; font-size: 14px; \} | &&
              |.td-label \{ color: #666; width: 40%; \} | &&
              |.td-value \{ color: #222; font-weight: 500; text-align: right; \} | &&
              |.error-box \{ background-color: #f8d7da; color: #721c24; padding: 15px; border-left: 4px solid #dc3545; border-radius: 4px; margin-bottom: 20px; font-size: 14px; \} | &&
              |.footer \{ background-color: #f8f9fa; padding: 20px; text-align: center; font-size: 12px; color: #888; border-top: 1px solid #eee; \} | &&
              |.footer a \{ color: #dc3545; text-decoration: none; \} | &&
              |</style></head><body><div class="container">|.

    " -- HEADER --
    LV_HTML = LV_HTML &&
              |<div class="header">| &&
              |<h1>{ LS_SUBSCR-REPORT_ID } - { LS_SUBSCR-SUBSCR_NAME }</h1>| &&
              |<p>Job ID: { LS_JOB-JOB_ID } \| Company Code: { LS_SUBSCR-BUKRS }</p>| &&
              |<div class="status-badge">&#10006; Export Failed</div>| &&
              |</div><div class="content">|.

    " -- BOX LỖI CHÍNH --
    LV_HTML = LV_HTML &&
              |<div class="error-box">| &&
              |<strong>Error Message:</strong><br>| &&
              |{ IV_ERROR_MSG }| &&
              |</div>|.

    " -- BẢNG CHI TIẾT --
    LV_HTML = LV_HTML && |<table>| &&
              |<tr><td class="td-label">Run Type</td><td class="td-value">{ LV_SCHEDULE_INFO }</td></tr>| &&
              |<tr><td class="td-label">Start Time</td><td class="td-value">{ LV_START_STRING } ({ LS_JOB-TMZONE })</td></tr>| &&
              |<tr><td class="td-label">Output Format</td><td class="td-value">{ LS_SUBSCR-OUTPUT_FORMAT }</td></tr>| &&
              |</table>|.

    LV_HTML = LV_HTML && |<p style="font-size:14px; color:#555;">The report could not be generated successfully. Please check your Job settings or contact the IT department for support.</p>|.

    LV_HTML = LV_HTML && |</div>|. " Đóng thẻ Content

    " -- FOOTER --
    LV_HTML = LV_HTML &&
              |<div class="footer">| &&
              |<p>This is an automated message from DERS-Fiori System. Created by: { LS_JOB-CREATED_BY }</p>| &&
              |<p>Need help? <a href="https://sap.company.com/ders">Open Support Ticket</a></p>| &&
              |</div></div></body></html>|.

    RV_HTML = LV_HTML.

  ENDMETHOD.

ENDCLASS.
