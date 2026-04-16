CLASS zcl_template_email DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC .

  PUBLIC SECTION.
      CLASS-METHODS render_email
          IMPORTING
            iv_job_uuid           TYPE zdrs_job_config-job_uuid
          RETURNING
            VALUE(rv_html)   TYPE string.

      CLASS-METHODS render_error_email
          IMPORTING
            iv_job_uuid           TYPE zdrs_job_config-job_uuid
            iv_error_msg          TYPE string OPTIONAL
          RETURNING
            VALUE(rv_html)   TYPE string.
  PROTECTED SECTION.
  PRIVATE SECTION.
ENDCLASS.



CLASS zcl_template_email IMPLEMENTATION.
  METHOD render_email.

    DATA: lv_html             TYPE string,
          lv_start_d          TYPE d,
          lv_start_t          TYPE t,
          lv_end_d            TYPE d,
          lv_end_t            TYPE t,
          lv_duration         TYPE i,
          lv_status_color     TYPE string,
          lv_status_icon      TYPE string,
          lv_status_text_disp TYPE string,
          lv_schedule_info    TYPE string,
          lv_file_size_disp   TYPE string.

    " Data cho Table Sub & File
    DATA: ls_subscr        TYPE zdrs_subscr,
          ls_file          TYPE zdrs_file,
          lv_file_size  TYPE p LENGTH 8 DECIMALS 2,
          lv_download_link TYPE string.

    " Get file from zdrs_file
    SELECT SINGLE *
      FROM zdrs_job_config
      WHERE job_uuid = @iv_job_uuid
      INTO @DATA(ls_job).

    IF sy-subrc <> 0.
      RETURN. " Return if data not found
    ENDIF.

    " ==========================================
    " 1. FETCH DỮ LIỆU TỪ BẢNG SUBSCRIPTION & FILE
    " ==========================================
    " Lấy thông tin báo cáo (Tên, Định dạng, Report ID...)
    SELECT SINGLE * FROM zdrs_subscr
      INTO @ls_subscr
      WHERE subscr_uuid = @ls_job-subscr_uuid.

    " Lấy thông tin file kết quả
    SELECT SINGLE * FROM zdrs_file
      INTO @ls_file
      WHERE job_uuid = @ls_job-job_uuid.

     IF ls_file-file_size < 1024.
        lv_file_size_disp = |{ ls_file-file_size } B|.
      ELSEIF ls_file-file_size < 1048576. " 1024 * 1024
        DATA(lv_kb) = ls_file-file_size / 1024.
        lv_file_size_disp = |{ lv_kb DECIMALS = 2 } KB|.
      ELSE.
        DATA(lv_mb) = ls_file-file_size / 1048576.
        lv_file_size_disp = |{ lv_mb DECIMALS = 2 } MB|.
      ENDIF.


*    " Tạo Link Download giả định (Bạn thay bằng đường dẫn OData hoặc ICF Service thực tế của hệ thống)
*    IF ls_file-file_uuid IS NOT INITIAL.
*      " Chuyển UUID nhị phân sang chuỗi để gắn vào URL
*      DATA(lv_uuid_str) = cl_system_uuid=>if_system_uuid_static~create_uuid_x16( ls_file-file_uuid )->if_system_uuid~get_uuid_c32( ).
*      lv_download_link = |https://<your-sap-host>:<port>/sap/bc/http/sap/z_download_report?file_id={ lv_uuid_str }|.
*    ENDIF.


    " ==========================================
    " 2. XỬ LÝ LOGIC THỜI GIAN & TRẠNG THÁI
    " ==========================================
    CONVERT TIME STAMP ls_job-start_timestamp TIME ZONE ls_job-tmzone INTO DATE lv_start_d TIME lv_start_t.
    CONVERT TIME STAMP ls_job-end_timestamp TIME ZONE ls_job-tmzone INTO DATE lv_end_d TIME lv_end_t.

    TRY.
        cl_abap_tstmp=>subtract(
          EXPORTING tstmp1 = ls_job-end_timestamp
                    tstmp2 = ls_job-start_timestamp
          RECEIVING r_secs = lv_duration ).
      CATCH cx_parameter_invalid_range cx_parameter_invalid_type.
        lv_duration = 0.
    ENDTRY.

    DATA(lv_min) = lv_duration DIV 60.
    DATA(lv_sec) = lv_duration MOD 60.
    DATA(lv_duration_text) = |{ lv_min } min { lv_sec } sec|.

    DATA(lv_end_string)   = |{ lv_end_d DATE = ISO } { lv_end_t TIME = ISO }|.
    DATA(lv_start_string) = |{ lv_start_d DATE = ISO } { lv_start_t TIME = ISO }|.

*    " Xử lý Trạng thái Job
*    IF is_job-job_status = 'F'.
      lv_status_color = '#28a745'. " Green
      lv_status_icon  = '&#10004;'.
      lv_status_text_disp = 'Completed Successfully'.
*    ELSEIF is_job-job_status = 'A'.
*      lv_status_color = '#dc3545'. " Red
*      lv_status_icon  = '&#10006;'.
*      lv_status_text_disp = 'Job Failed'.
*    ELSE.
*      lv_status_color = '#ffc107'. " Yellow
*      lv_status_icon  = '&#9888;'.
*      lv_status_text_disp = is_job-job_status_text.
*    ENDIF.


    CASE ls_job-run_type.
        WHEN 'I'.
            lv_schedule_info = 'Immediate Run'.
        WHEN 'O'.
            lv_schedule_info = 'Once'.
        WHEN 'P'.
            lv_schedule_info = 'Periodic'.
    ENDCASE.

    " ==========================================
    " 3. XÂY DỰNG HTML NỘI DUNG EMAIL
    " ==========================================
    " -- HEAD & STYLES --
    lv_html = |<!DOCTYPE html><html><head><style>| &&
              |body \{ font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif; background-color: #f4f7f6; margin: 0; padding: 20px; color: #333; \} | &&
              |.container \{ max-width: 650px; background: #ffffff; margin: 0 auto; border-radius: 8px; overflow: hidden; box-shadow: 0 4px 10px rgba(0,0,0,0.05); \} | &&
              |.header \{ background-color: #005587; color: white; padding: 25px 30px; \} | &&
              |.header h1 \{ margin: 0; font-size: 22px; font-weight: 500; \} | &&
              |.header p \{ margin: 5px 0 0 0; font-size: 14px; opacity: 0.8; \} | &&
              |.status-badge \{ display: inline-block; padding: 6px 12px; border-radius: 4px; color: white; font-weight: bold; font-size: 14px; margin-top: 15px; background-color: { lv_status_color }; \} | &&
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

    " -- HEADER -- (Sử dụng Report ID và Sub Name từ bảng zdrs_subscr)
    lv_html = lv_html &&
              |<div class="header">| &&
              |<h1>{ ls_subscr-report_id } - { ls_subscr-subscr_name }</h1>| &&
              |<p>Job ID: { ls_job-job_id } \| Company Code: { ls_subscr-bukrs }</p>| &&
              |<div class="status-badge">{ lv_status_icon } { lv_status_text_disp }</div>| &&
              |</div><div class="content">|.

    " -- LỖI (Nếu có) --
    IF ls_job-job_status = 'A' AND ls_job-message IS NOT INITIAL.
      lv_html = lv_html && |<div class="error-box"><strong>Error Message:</strong><br>{ ls_job-message }</div>|.
    ENDIF.

    " -- BẢNG CHI TIẾT --
    " 1. Bắt đầu bảng và thêm dòng Run Type
    lv_html = lv_html && |<table>| &&
              |<tr><td class="td-label">Run Type</td><td class="td-value">{ lv_schedule_info }</td></tr>|.

    " 2. Kiểm tra Start Time: Chỉ nối thêm 2 dòng này nếu có dữ liệu
    IF ls_job-start_timestamp IS NOT INITIAL.
      lv_html = lv_html && |<tr><td class="td-label">Start Time</td><td class="td-value">{ lv_start_string } ({ ls_job-tmzone })</td></tr>| &&
                           |<tr><td class="td-label">Duration</td><td class="td-value">{ lv_duration_text }</td></tr>|.
    ENDIF.

    " 3. Tiếp tục nối các dòng còn lại (Output Format)
    lv_html = lv_html && |<tr><td class="td-label">Output Format</td><td class="td-value">{ ls_subscr-output_format }</td></tr>|.


*    " Hiển thị số dòng nếu có truyền vào
*    IF iv_rows IS NOT INITIAL.
*      DATA(lv_rows_str) = |{ iv_rows NUMBER = USER }|.
*      lv_html = lv_html && |<tr><td class="td-label">Rows Processed</td><td class="td-value">{ lv_rows_str }</td></tr>|.
*    ENDIF.


    IF ls_file-file_name IS NOT INITIAL.
      lv_html = lv_html &&
                |<tr><td class="td-label">File Name</td><td class="td-value">{ ls_file-file_name }</td></tr>| &&
                |<tr><td class="td-label">File Size</td><td class="td-value">{ lv_file_size_disp } </td></tr>|.
    ENDIF.


    lv_html = lv_html && |</table>|.

    IF ls_file-file_name IS NOT INITIAL.
      IF ls_file-file_size <= 10485760.
        lv_html = lv_html && |<p style="text-align:center; font-size:14px; color:#555;">The output file <strong>{ ls_file-file_name }</strong> is attached to this email.</p>|.
      ELSE.
        lv_html = lv_html && |<p style="text-align:center; font-size:14px; color:#555;">Your file is larger than 10MB and cannot be attached.</p>| &&
                             |<a href="{ lv_download_link }" class="download-btn">Download Report File</a>| &&
                             |<p style="text-align:center; font-size:12px; margin-top:10px; color:#888;">Link expires based on system retention policy.</p>|.
      ENDIF.
    ENDIF.

    lv_html = lv_html && |</div>|. " Đóng Content

    " -- FOOTER --
    lv_html = lv_html &&
              |<div class="footer">| &&
              |<p>This is an automated message from DERS-Fiori System. Created by: { ls_job-created_by }</p>| &&
              |<p>Need help? <a href="https://sap.company.com/ders">Open Support Ticket</a></p>| &&
              |</div></div></body></html>|.

    rv_html = lv_html.

  ENDMETHOD.

  METHOD render_error_email.

    DATA: lv_html             TYPE string,
          lv_start_d          TYPE d,
          lv_start_t          TYPE t,
          lv_schedule_info    TYPE string.

    DATA: ls_subscr TYPE zdrs_subscr.

    " ==========================================
    " 1. LẤY THÔNG TIN JOB & SUBSCRIPTION
    " ==========================================
    SELECT SINGLE *
      FROM zdrs_job_config
      WHERE job_uuid = @iv_job_uuid
      INTO @DATA(ls_job).

    IF sy-subrc <> 0.
      " Trả về HTML cơ bản nếu không tìm thấy Job (đề phòng dump)
      rv_html = |<html><body><h3>Error processing job</h3><p>{ iv_error_msg }</p></body></html>|.
      RETURN.
    ENDIF.

    SELECT SINGLE * FROM zdrs_subscr
      INTO @ls_subscr
      WHERE subscr_uuid = @ls_job-subscr_uuid.

    " ==========================================
    " 2. XỬ LÝ LOGIC THỜI GIAN & TRẠNG THÁI
    " ==========================================
    IF ls_job-start_timestamp IS NOT INITIAL.
      CONVERT TIME STAMP ls_job-start_timestamp TIME ZONE ls_job-tmzone INTO DATE lv_start_d TIME lv_start_t.
      DATA(lv_start_string) = |{ lv_start_d DATE = ISO } { lv_start_t TIME = ISO }|.
    ELSE.
      lv_start_string = 'N/A'.
    ENDIF.

    CASE ls_job-run_type.
        WHEN 'I'. lv_schedule_info = 'Immediate Run'.
        WHEN 'O'. lv_schedule_info = 'Once'.
        WHEN 'P'. lv_schedule_info = 'Periodic'.
    ENDCASE.

    " ==========================================
    " 3. XÂY DỰNG HTML NỘI DUNG EMAIL LỖI (ENGLISH)
    " ==========================================
    " -- HEAD & STYLES --
    " Lưu ý: Các ngoặc nhọn trong CSS phải được escape bằng dấu \
    lv_html = |<!DOCTYPE html><html><head><meta charset="UTF-8"><title>Error Email</title><style>| &&
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
    lv_html = lv_html &&
              |<div class="header">| &&
              |<h1>{ ls_subscr-report_id } - { ls_subscr-subscr_name }</h1>| &&
              |<p>Job ID: { ls_job-job_id } \| Company Code: { ls_subscr-bukrs }</p>| &&
              |<div class="status-badge">&#10006; Export Failed</div>| &&
              |</div><div class="content">|.

    " -- BOX LỖI CHÍNH --
    lv_html = lv_html &&
              |<div class="error-box">| &&
              |<strong>Error Message:</strong><br>| &&
              |{ iv_error_msg }| &&
              |</div>|.

    " -- BẢNG CHI TIẾT --
    lv_html = lv_html && |<table>| &&
              |<tr><td class="td-label">Run Type</td><td class="td-value">{ lv_schedule_info }</td></tr>| &&
              |<tr><td class="td-label">Start Time</td><td class="td-value">{ lv_start_string } ({ ls_job-tmzone })</td></tr>| &&
              |<tr><td class="td-label">Output Format</td><td class="td-value">{ ls_subscr-output_format }</td></tr>| &&
              |</table>|.

    lv_html = lv_html && |<p style="font-size:14px; color:#555;">The report could not be generated successfully. Please check your Job settings or contact the IT department for support.</p>|.

    lv_html = lv_html && |</div>|. " Đóng thẻ Content

    " -- FOOTER --
    lv_html = lv_html &&
              |<div class="footer">| &&
              |<p>This is an automated message from DERS-Fiori System. Created by: { ls_job-created_by }</p>| &&
              |<p>Need help? <a href="https://sap.company.com/ders">Open Support Ticket</a></p>| &&
              |</div></div></body></html>|.

    rv_html = lv_html.

  ENDMETHOD.

ENDCLASS.
