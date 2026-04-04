CLASS lhc_DrsJobConfig DEFINITION INHERITING FROM CL_ABAP_BEHAVIOR_HANDLER.
  PRIVATE SECTION.
    " Job template name
    CONSTANTS GC_JOB_TEMPLATE_NAME TYPE APJ_JOB_TEMPLATE_NAME VALUE 'ZDRS_JOB_TEMPLATE_V2'.
    " SNRO nr_range_nr value and object name
    CONSTANTS GC_SNRO_NR_RANGE_NR TYPE NRNR VALUE '01'.
    CONSTANTS GC_SNRO_OBJECT TYPE NROBJ VALUE 'ZDRS_JOBID'.

    METHODS GET_GLOBAL_AUTHORIZATIONS FOR GLOBAL AUTHORIZATION
      IMPORTING REQUEST REQUESTED_AUTHORIZATIONS FOR DrsJobConfig RESULT RESULT.

    METHODS GET_INSTANCE_FEATURES FOR INSTANCE FEATURES
      IMPORTING KEYS REQUEST REQUESTED_FEATURES FOR DrsJobConfig RESULT RESULT.

    METHODS setDefaultValues FOR DETERMINE ON MODIFY
      IMPORTING KEYS FOR DrsJobConfig~setDefaultValues.

    METHODS validateDescription FOR VALIDATE ON SAVE
      IMPORTING KEYS FOR DrsJobConfig~validateDescription.

    METHODS validateRunType FOR VALIDATE ON SAVE
      IMPORTING KEYS FOR DrsJobConfig~validateRunType.

    METHODS validateSubscrId FOR VALIDATE ON SAVE
      IMPORTING KEYS FOR DrsJobConfig~validateSubscrId.

    METHODS validatePeriodicGranularity FOR VALIDATE ON SAVE
      IMPORTING KEYS FOR DrsJobConfig~validatePeriodicGranularity.

    METHODS validateShiftDirection FOR VALIDATE ON SAVE
      IMPORTING KEYS FOR DrsJobConfig~validateShiftDirection.

    METHODS validateStartRestriction FOR VALIDATE ON SAVE
      IMPORTING KEYS FOR DrsJobConfig~validateStartRestriction.

    METHODS validateCalendarId FOR VALIDATE ON SAVE
      IMPORTING KEYS FOR DrsJobConfig~validateCalendarId.

    METHODS validateRunSettings FOR VALIDATE ON SAVE
      IMPORTING KEYS FOR DrsJobConfig~validateRunSettings.

    METHODS scheduleJob FOR MODIFY
      IMPORTING KEYS FOR ACTION DrsJobConfig~scheduleJob RESULT RESULT.

    METHODS cancelJob FOR MODIFY
      IMPORTING KEYS FOR ACTION DrsJobConfig~cancelJob RESULT RESULT.

    METHODS refreshStatus FOR MODIFY
      IMPORTING KEYS FOR ACTION DrsJobConfig~refreshStatus RESULT RESULT.

ENDCLASS.


CLASS lhc_DrsJobConfig IMPLEMENTATION.

  METHOD GET_GLOBAL_AUTHORIZATIONS.
    " Grant all authorizations for demo purposes
    RESULT = VALUE #(
      %CREATE = IF_ABAP_BEHV=>AUTH-ALLOWED
      %UPDATE = IF_ABAP_BEHV=>AUTH-ALLOWED
      %DELETE = IF_ABAP_BEHV=>AUTH-ALLOWED
      %ACTION-scheduleJob = IF_ABAP_BEHV=>AUTH-ALLOWED
      %ACTION-cancelJob = IF_ABAP_BEHV=>AUTH-ALLOWED
      %ACTION-refreshStatus = IF_ABAP_BEHV=>AUTH-ALLOWED ).
  ENDMETHOD.


  METHOD GET_INSTANCE_FEATURES.
    " Read current state of entities
    READ ENTITIES OF ZIR_DRS_JOB_CONFIG IN LOCAL MODE
      ENTITY DrsJobConfig
      FIELDS ( JobName JobStatus )
      WITH CORRESPONDING #( KEYS )
      RESULT DATA(LT_JOBS).

    RESULT = VALUE #( FOR LS_JOB IN LT_JOBS
      ( %TKY = LS_JOB-%TKY
        " Disable Edit once job is scheduled (JobName is set by APJ after scheduling).
        " Prevents users from modifying settings of an already-submitted job.
        %UPDATE = COND #(
          WHEN LS_JOB-JobName IS NOT INITIAL
          THEN IF_ABAP_BEHV=>FC-O-DISABLED
          ELSE IF_ABAP_BEHV=>FC-O-ENABLED )
        " All actions disabled when record is still a DRAFT (not yet saved/activated).
        " User must press 'Create' first to activate the record before scheduling.
        %ACTION-scheduleJob = COND #(
          " record is draft → always disable
          WHEN LS_JOB-%IS_DRAFT = '01'
          THEN IF_ABAP_BEHV=>FC-O-DISABLED
          " active + not yet scheduled → enable
          WHEN LS_JOB-JobName IS INITIAL
          THEN IF_ABAP_BEHV=>FC-O-ENABLED
          ELSE IF_ABAP_BEHV=>FC-O-DISABLED )
        " Enable cancelJob only for cancellable statuses (whitelist):
        "   S = Scheduled, Y = Ready, P = Released
        " All terminal/final statuses are disabled:
        "   F = Finished, A = Failed, X = Unknown,
        "   C = Cancelled, D = Deleted, K = Skipped, U = User Error
        %ACTION-cancelJob = COND #(
          WHEN LS_JOB-%IS_DRAFT = '01'
          THEN IF_ABAP_BEHV=>FC-O-DISABLED
          WHEN LS_JOB-JobName IS NOT INITIAL
            AND ( LS_JOB-JobStatus = 'S'
               OR LS_JOB-JobStatus = 'Y'
               OR LS_JOB-JobStatus = 'P' )
          THEN IF_ABAP_BEHV=>FC-O-ENABLED
          ELSE IF_ABAP_BEHV=>FC-O-DISABLED )
        " Enable refreshStatus only when active AND job is scheduled
        %ACTION-refreshStatus = COND #(
          WHEN LS_JOB-%IS_DRAFT = '01'
          THEN IF_ABAP_BEHV=>FC-O-DISABLED
          WHEN LS_JOB-JobName IS NOT INITIAL
          THEN IF_ABAP_BEHV=>FC-O-ENABLED
          ELSE IF_ABAP_BEHV=>FC-O-DISABLED ) ) ).
  ENDMETHOD.


  METHOD setDefaultValues.
    " Read entities
    READ ENTITIES OF ZIR_DRS_JOB_CONFIG IN LOCAL MODE
      ENTITY DrsJobConfig
      FIELDS ( JobId JobTemplateName RunType Tmzone PeriodicGranularity PeriodicValue )
      WITH CORRESPONDING #( KEYS )
      RESULT DATA(LT_JOBS).

    " Determine how many jobs need an ID
    DATA(lt_jobs_wo_id) = LT_JOBS.
    DELETE lt_jobs_wo_id WHERE JobId IS NOT INITIAL.

    " Set to abap_true IF you have created an SNRO object (e.g. 'ZDRS_JOBID' in T-Code SNRO)
    DATA use_number_range TYPE abap_bool VALUE abap_true.
    DATA lv_next_id TYPE zdrs_job_config-job_id.
    CLEAR lv_next_id.

    IF use_number_range = abap_true AND lines( lt_jobs_wo_id ) > 0.
      TRY.
          cl_numberrange_runtime=>number_get(
            EXPORTING
              nr_range_nr       = GC_SNRO_NR_RANGE_NR
              object            = GC_SNRO_OBJECT
              quantity          = CONV #( lines( lt_jobs_wo_id ) )
            IMPORTING
              number            = DATA(number_range_key)
              returned_quantity = DATA(number_range_returned_quantity)
          ).
          " Number range returns the LAST number in the requested block.
          lv_next_id = number_range_key - number_range_returned_quantity.
        CATCH cx_number_ranges INTO DATA(lx_number_ranges).
           " If SNRO fails (not found etc.), fallback to MAX
           use_number_range = abap_false.
      ENDTRY.
    ENDIF.

    IF use_number_range = abap_false.
      " Fallback: Generate next JobId by checking both Active and Draft tables
      DATA: lv_max_active TYPE zdrs_job_config-job_id,
            lv_max_draft  TYPE zdrs_job_configd-jobid.

      SELECT SINGLE MAX( job_id ) FROM zdrs_job_config  INTO @lv_max_active.
      SELECT SINGLE MAX( jobid ) FROM zdrs_job_configd INTO @lv_max_draft.

      IF lv_max_active > lv_max_draft.
        lv_next_id = lv_max_active.
      ELSE.
        lv_next_id = lv_max_draft.
      ENDIF.
    ENDIF.

    " Resolve user timezone — fallback to UTC if context not available
    DATA LV_USER_TZ TYPE SY-ZONLO.
    CLEAR LV_USER_TZ.
    TRY.
        LV_USER_TZ = CL_ABAP_CONTEXT_INFO=>GET_USER_TIME_ZONE( ).
      CATCH CX_ABAP_CONTEXT_INFO_ERROR.
        LV_USER_TZ = 'UTC'.
    ENDTRY.

    " Prepare updates
    DATA update_jobs TYPE TABLE FOR UPDATE ZIR_DRS_JOB_CONFIG.
    LOOP AT LT_JOBS INTO DATA(LS_JOB).
      IF LS_JOB-JobId IS INITIAL.
        lv_next_id += 1.
        LS_JOB-JobId = lv_next_id.
      ENDIF.

      APPEND VALUE #(
          %TKY                = LS_JOB-%TKY
          JobId               = LS_JOB-JobId
          JobTemplateName     = COND #( WHEN LS_JOB-JobTemplateName IS INITIAL
                                        THEN GC_JOB_TEMPLATE_NAME
                                        ELSE LS_JOB-JobTemplateName )
          RunType             = COND #( WHEN LS_JOB-RunType IS INITIAL
                                        THEN 'I'
                                        ELSE LS_JOB-RunType )
          Tmzone              = COND #( WHEN LS_JOB-Tmzone IS INITIAL
                                        THEN LV_USER_TZ
                                        ELSE LS_JOB-Tmzone )
          PeriodicGranularity = COND #( WHEN LS_JOB-PeriodicGranularity IS INITIAL
                                        THEN 'H'
                                        ELSE LS_JOB-PeriodicGranularity )
          PeriodicValue       = COND #( WHEN LS_JOB-PeriodicValue IS INITIAL
                                        THEN 1
                                        ELSE LS_JOB-PeriodicValue )
      ) TO update_jobs.
    ENDLOOP.

    " Set default values for new entities
    MODIFY ENTITIES OF ZIR_DRS_JOB_CONFIG IN LOCAL MODE
      ENTITY DrsJobConfig
      UPDATE FIELDS ( JobId JobTemplateName RunType Tmzone PeriodicGranularity PeriodicValue )
      WITH update_jobs
      REPORTED DATA(LT_REPORTED).
  ENDMETHOD.


  METHOD validateDescription.
    " Read entities
    READ ENTITIES OF ZIR_DRS_JOB_CONFIG IN LOCAL MODE
      ENTITY DrsJobConfig
      FIELDS ( JobText )
      WITH CORRESPONDING #( KEYS )
      RESULT DATA(LT_JOBS).

    LOOP AT LT_JOBS INTO DATA(LS_JOB).
      IF LS_JOB-JobText IS INITIAL.
        APPEND VALUE #( %TKY = LS_JOB-%TKY ) TO FAILED-DRSJOBCONFIG.
        APPEND VALUE #( %TKY = LS_JOB-%TKY
          %MSG = NEW_MESSAGE_WITH_TEXT(
            SEVERITY = IF_ABAP_BEHV_MESSAGE=>SEVERITY-ERROR
            TEXT = 'Description is required' )
          %ELEMENT-JobText = IF_ABAP_BEHV=>MK-ON )
        TO REPORTED-DRSJOBCONFIG.
      ENDIF.
    ENDLOOP.
  ENDMETHOD.


  METHOD validateSubscrId.
    READ ENTITIES OF ZIR_DRS_JOB_CONFIG IN LOCAL MODE
      ENTITY DrsJobConfig
      FIELDS ( SubscrId )
      WITH CORRESPONDING #( KEYS )
      RESULT DATA(LT_JOBS).

    LOOP AT LT_JOBS INTO DATA(LS_JOB).
      IF LS_JOB-SubscrId IS INITIAL.
        APPEND VALUE #( %TKY = LS_JOB-%TKY ) TO FAILED-DRSJOBCONFIG.
        APPEND VALUE #( %TKY = LS_JOB-%TKY
          %MSG = NEW_MESSAGE_WITH_TEXT(
            SEVERITY = IF_ABAP_BEHV_MESSAGE=>SEVERITY-ERROR
            TEXT = 'Subscription ID is required' )
          %ELEMENT-SubscrId = IF_ABAP_BEHV=>MK-ON )
        TO REPORTED-DRSJOBCONFIG.
      ELSE.
        SELECT SINGLE SubscrId
          FROM ZIR_DRS_SUBSCR
          WHERE SubscrId = @LS_JOB-SubscrId
          INTO @DATA(LV_FOUND).
        IF SY-SUBRC <> 0.
          APPEND VALUE #( %TKY = LS_JOB-%TKY ) TO FAILED-DRSJOBCONFIG.
          APPEND VALUE #( %TKY = LS_JOB-%TKY
            %MSG = NEW_MESSAGE_WITH_TEXT(
              SEVERITY = IF_ABAP_BEHV_MESSAGE=>SEVERITY-ERROR
              TEXT = |Subscription ID { LS_JOB-SubscrId } does not exist| )
            %ELEMENT-SubscrId = IF_ABAP_BEHV=>MK-ON )
          TO REPORTED-DRSJOBCONFIG.
        ENDIF.
      ENDIF.
    ENDLOOP.
  ENDMETHOD.


  METHOD validateRunType.
    " Read entities
    READ ENTITIES OF ZIR_DRS_JOB_CONFIG IN LOCAL MODE
      ENTITY DrsJobConfig
      FIELDS ( RunType )
      WITH CORRESPONDING #( KEYS )
      RESULT DATA(LT_JOBS).

    " Fetch valid values from DB Table
    SELECT value FROM zdrs_run_type_vt INTO TABLE @DATA(lt_valid_run_types).

    LOOP AT LT_JOBS INTO DATA(LS_JOB).
      " Validate existence
      IF LS_JOB-RunType IS INITIAL OR NOT line_exists( lt_valid_run_types[ value = LS_JOB-RunType ] ).
        APPEND VALUE #( %TKY = LS_JOB-%TKY ) TO FAILED-DRSJOBCONFIG.
        APPEND VALUE #( %TKY = LS_JOB-%TKY
          %MSG = NEW_MESSAGE_WITH_TEXT(
            SEVERITY = IF_ABAP_BEHV_MESSAGE=>SEVERITY-ERROR
            TEXT = |Run Type '{ LS_JOB-RunType }' is invalid or missing| )
          %ELEMENT-RunType = IF_ABAP_BEHV=>MK-ON )
        TO REPORTED-DRSJOBCONFIG.
      ENDIF.
    ENDLOOP.
  ENDMETHOD.

  METHOD validatePeriodicGranularity.
    READ ENTITIES OF ZIR_DRS_JOB_CONFIG IN LOCAL MODE
      ENTITY DrsJobConfig
      FIELDS ( RunType PeriodicGranularity )
      WITH CORRESPONDING #( KEYS )
      RESULT DATA(LT_JOBS).

    SELECT value FROM zdrs_per_gran_vt INTO TABLE @DATA(lt_valid_granularity).

    LOOP AT LT_JOBS INTO DATA(LS_JOB).
      " Only validate for Periodic jobs
      IF LS_JOB-RunType = 'P'.
        IF LS_JOB-PeriodicGranularity IS INITIAL OR NOT line_exists( lt_valid_granularity[ value = LS_JOB-PeriodicGranularity ] ).
          APPEND VALUE #( %TKY = LS_JOB-%TKY ) TO FAILED-DRSJOBCONFIG.
          APPEND VALUE #( %TKY = LS_JOB-%TKY
            %MSG = NEW_MESSAGE_WITH_TEXT(
              SEVERITY = IF_ABAP_BEHV_MESSAGE=>SEVERITY-ERROR
              TEXT = |Periodic Granularity '{ LS_JOB-PeriodicGranularity }' is invalid| )
            %ELEMENT-PeriodicGranularity = IF_ABAP_BEHV=>MK-ON )
          TO REPORTED-DRSJOBCONFIG.
        ENDIF.
      ENDIF.
    ENDLOOP.
  ENDMETHOD.

  METHOD validateShiftDirection.
    READ ENTITIES OF ZIR_DRS_JOB_CONFIG IN LOCAL MODE
      ENTITY DrsJobConfig
      FIELDS ( ShiftDirection )
      WITH CORRESPONDING #( KEYS )
      RESULT DATA(LT_JOBS).

    SELECT value FROM zdrs_shiftdir_vt INTO TABLE @DATA(lt_valid_shiftdir).

    LOOP AT LT_JOBS INTO DATA(LS_JOB).
      IF LS_JOB-ShiftDirection IS NOT INITIAL.
        IF NOT line_exists( lt_valid_shiftdir[ value = LS_JOB-ShiftDirection ] ).
          APPEND VALUE #( %TKY = LS_JOB-%TKY ) TO FAILED-DRSJOBCONFIG.
          APPEND VALUE #( %TKY = LS_JOB-%TKY
            %MSG = NEW_MESSAGE_WITH_TEXT(
              SEVERITY = IF_ABAP_BEHV_MESSAGE=>SEVERITY-ERROR
              TEXT = |Shift Direction '{ LS_JOB-ShiftDirection }' is invalid| )
            %ELEMENT-ShiftDirection = IF_ABAP_BEHV=>MK-ON )
          TO REPORTED-DRSJOBCONFIG.
        ENDIF.
      ENDIF.
    ENDLOOP.
  ENDMETHOD.

  METHOD validateStartRestriction.
    READ ENTITIES OF ZIR_DRS_JOB_CONFIG IN LOCAL MODE
      ENTITY DrsJobConfig
      FIELDS ( ExceptionRestrictionCode )
      WITH CORRESPONDING #( KEYS )
      RESULT DATA(LT_JOBS).

    SELECT value FROM zdrs_strt_res_vt INTO TABLE @DATA(lt_valid_strt_res).

    LOOP AT LT_JOBS INTO DATA(LS_JOB).
      IF LS_JOB-ExceptionRestrictionCode IS NOT INITIAL.
        IF NOT line_exists( lt_valid_strt_res[ value = LS_JOB-ExceptionRestrictionCode ] ).
          APPEND VALUE #( %TKY = LS_JOB-%TKY ) TO FAILED-DRSJOBCONFIG.
          APPEND VALUE #( %TKY = LS_JOB-%TKY
            %MSG = NEW_MESSAGE_WITH_TEXT(
              SEVERITY = IF_ABAP_BEHV_MESSAGE=>SEVERITY-ERROR
              TEXT = |Start Restriction '{ LS_JOB-ExceptionRestrictionCode }' is invalid| )
            %ELEMENT-ExceptionRestrictionCode = IF_ABAP_BEHV=>MK-ON )
          TO REPORTED-DRSJOBCONFIG.
        ENDIF.
      ENDIF.
    ENDLOOP.
  ENDMETHOD.

  METHOD validateCalendarId.
    READ ENTITIES OF ZIR_DRS_JOB_CONFIG IN LOCAL MODE
      ENTITY DrsJobConfig
      FIELDS ( ExceptionCalendarId )
      WITH CORRESPONDING #( KEYS )
      RESULT DATA(LT_JOBS).

    " Fetch valid Calendar IDs using the CDS View
    SELECT FactoryCalendar
      FROM ZI_VH_DRS_CALENDAR_ID
      INTO TABLE @DATA(lt_valid_calendars).

    LOOP AT LT_JOBS INTO DATA(LS_JOB).
      IF LS_JOB-ExceptionCalendarId IS NOT INITIAL.
        IF NOT line_exists( lt_valid_calendars[ FactoryCalendar = LS_JOB-ExceptionCalendarId ] ).
          APPEND VALUE #( %TKY = LS_JOB-%TKY ) TO FAILED-DRSJOBCONFIG.
          APPEND VALUE #( %TKY = LS_JOB-%TKY
            %MSG = NEW_MESSAGE_WITH_TEXT(
              SEVERITY = IF_ABAP_BEHV_MESSAGE=>SEVERITY-ERROR
              TEXT = |Exception Calendar '{ LS_JOB-ExceptionCalendarId }' is invalid| )
            %ELEMENT-ExceptionCalendarId = IF_ABAP_BEHV=>MK-ON )
          TO REPORTED-DRSJOBCONFIG.
        ENDIF.
      ENDIF.
    ENDLOOP.
  ENDMETHOD.

  METHOD validateRunSettings.
    " Read entities
    READ ENTITIES OF ZIR_DRS_JOB_CONFIG IN LOCAL MODE
      ENTITY DrsJobConfig
      FIELDS ( RunType StartTimestamp PeriodicGranularity PeriodicValue EndTimestamp MaxIterations
               OnMonday OnTuesday OnWednesday OnThursday OnFriday OnSaturday OnSunday
               MonthDay MonthWeekNumber Tmzone )
      WITH CORRESPONDING #( KEYS )
      RESULT DATA(LT_JOBS).

    " Get current UTC timestamp once before loop — ensures consistent comparison
    " across all records and avoids redundant system calls per iteration.
    DATA LV_NOW TYPE TIMESTAMP.
    CLEAR LV_NOW.
    GET TIME STAMP FIELD LV_NOW.

    LOOP AT LT_JOBS INTO DATA(LS_JOB).

      CASE LS_JOB-RunType.

          " Once: one-time run at a specific timestamp
        WHEN 'O'.
          IF LS_JOB-StartTimestamp IS INITIAL.
            APPEND VALUE #( %TKY = LS_JOB-%TKY ) TO FAILED-DRSJOBCONFIG.
            APPEND VALUE #( %TKY = LS_JOB-%TKY
              %MSG = NEW_MESSAGE_WITH_TEXT(
                SEVERITY = IF_ABAP_BEHV_MESSAGE=>SEVERITY-ERROR
                TEXT = 'Start Timestamp is required for once jobs' )
              %ELEMENT-StartTimestamp = IF_ABAP_BEHV=>MK-ON )
            TO REPORTED-DRSJOBCONFIG.
          ELSEIF LS_JOB-StartTimestamp <= LV_NOW.
            APPEND VALUE #( %TKY = LS_JOB-%TKY ) TO FAILED-DRSJOBCONFIG.
            APPEND VALUE #( %TKY = LS_JOB-%TKY
              %MSG = NEW_MESSAGE_WITH_TEXT(
                SEVERITY = IF_ABAP_BEHV_MESSAGE=>SEVERITY-ERROR
                TEXT = 'Start Timestamp must be a future date and time' )
              %ELEMENT-StartTimestamp = IF_ABAP_BEHV=>MK-ON )
            TO REPORTED-DRSJOBCONFIG.
          ENDIF.

          " Periodic: recurring job with granularity & stop condition
        WHEN 'P'.
          " 1. Validate StartTimestamp
          IF LS_JOB-StartTimestamp IS INITIAL.
            APPEND VALUE #( %TKY = LS_JOB-%TKY ) TO FAILED-DRSJOBCONFIG.
            APPEND VALUE #( %TKY = LS_JOB-%TKY
              %MSG = NEW_MESSAGE_WITH_TEXT(
                SEVERITY = IF_ABAP_BEHV_MESSAGE=>SEVERITY-ERROR
                TEXT = 'Start Timestamp is required for periodic jobs' )
              %ELEMENT-StartTimestamp = IF_ABAP_BEHV=>MK-ON )
            TO REPORTED-DRSJOBCONFIG.
          ELSEIF LS_JOB-StartTimestamp <= LV_NOW.
            APPEND VALUE #( %TKY = LS_JOB-%TKY ) TO FAILED-DRSJOBCONFIG.
            APPEND VALUE #( %TKY = LS_JOB-%TKY
              %MSG = NEW_MESSAGE_WITH_TEXT(
                SEVERITY = IF_ABAP_BEHV_MESSAGE=>SEVERITY-ERROR
                TEXT = 'Start Timestamp must be a future date and time' )
              %ELEMENT-StartTimestamp = IF_ABAP_BEHV=>MK-ON )
            TO REPORTED-DRSJOBCONFIG.
          ENDIF.

          " 2. Validate PeriodicGranularity is moved to its own validation method (validatePeriodicGranularity)

          " 3. Validate PeriodicValue
          IF LS_JOB-PeriodicValue IS INITIAL OR LS_JOB-PeriodicValue <= 0.
            APPEND VALUE #( %TKY = LS_JOB-%TKY ) TO FAILED-DRSJOBCONFIG.
            APPEND VALUE #( %TKY = LS_JOB-%TKY
              %MSG = NEW_MESSAGE_WITH_TEXT(
                SEVERITY = IF_ABAP_BEHV_MESSAGE=>SEVERITY-ERROR
                TEXT = 'Periodic Value must be greater than 0' )
              %ELEMENT-PeriodicValue = IF_ABAP_BEHV=>MK-ON )
            TO REPORTED-DRSJOBCONFIG.
          ENDIF.

          " 4. W or WM: at least one weekday must be selected
          IF LS_JOB-PeriodicGranularity = 'W'
          OR LS_JOB-PeriodicGranularity = 'WM'.
            IF LS_JOB-OnMonday    <> ABAP_TRUE AND
               LS_JOB-OnTuesday   <> ABAP_TRUE AND
               LS_JOB-OnWednesday <> ABAP_TRUE AND
               LS_JOB-OnThursday  <> ABAP_TRUE AND
               LS_JOB-OnFriday    <> ABAP_TRUE AND
               LS_JOB-OnSaturday  <> ABAP_TRUE AND
               LS_JOB-OnSunday    <> ABAP_TRUE.
              APPEND VALUE #( %TKY = LS_JOB-%TKY ) TO FAILED-DRSJOBCONFIG.
              APPEND VALUE #( %TKY = LS_JOB-%TKY
                %MSG = NEW_MESSAGE_WITH_TEXT(
                  SEVERITY = IF_ABAP_BEHV_MESSAGE=>SEVERITY-ERROR
                  TEXT = 'Weekly / Week-Month jobs require at least one weekday to be selected' ) )
              TO REPORTED-DRSJOBCONFIG.
            ENDIF.

            " 4a. W or WM: StartTimestamp must fall on one of the selected weekdays.
            "     For WM, also validate that StartTimestamp falls on the correct week-of-month.
            "     IV_ADJUST_START_INFO is NOT passed → SAP never auto-adjusts the date.
            "     cl_apj_job_controller always runs this check → reject early with clear message.
            "     Reference: 2024-01-01 is a Monday (verified).
            "     (date - ref) MOD 7: 0=Mon 1=Tue 2=Wed 3=Thu 4=Fri 5=Sat 6=Sun
            IF ( LS_JOB-PeriodicGranularity = 'W' OR LS_JOB-PeriodicGranularity = 'WM' )
            AND LS_JOB-StartTimestamp IS NOT INITIAL.
              DATA LV_W_START_DATE TYPE D.
              DATA LV_W_START_TIME TYPE T.
              CLEAR LV_W_START_DATE.
              CLEAR LV_W_START_TIME.
              " Use user's timezone to get the LOCAL date (not UTC date)
              " Timestamp is stored as real UTC — converting with 'UTC' gives wrong
              " date when local time crosses midnight boundary (e.g. 5 AM UTC+7 = previous day in UTC)
              DATA(LV_W_TZ) = COND TIMEZONE(
                WHEN LS_JOB-Tmzone IS NOT INITIAL THEN LS_JOB-Tmzone ELSE 'UTC' ).
              CONVERT TIME STAMP LS_JOB-StartTimestamp TIME ZONE LV_W_TZ
                INTO DATE LV_W_START_DATE TIME LV_W_START_TIME.

              " Use SAP's standard utility for reliable weekday computation (1 = Monday ... 7 = Sunday)
              DATA(LV_W_DOW_1TO7) = CL_APJ_FW_utilities=>COMPUTE_DAY( IV_DATE = LV_W_START_DATE ).
              " Convert to our 0-6 format (0=Mon, 1=Tue... 6=Sun) to match the CASE statement below
              DATA LV_W_DOW TYPE I.
              LV_W_DOW = LV_W_DOW_1TO7 - 1.

              DATA(LV_W_DOW_OK) = ABAP_FALSE.
              CASE LV_W_DOW.
                WHEN 0. IF LS_JOB-OnMonday    = ABAP_TRUE. LV_W_DOW_OK = ABAP_TRUE. ENDIF.
                WHEN 1. IF LS_JOB-OnTuesday   = ABAP_TRUE. LV_W_DOW_OK = ABAP_TRUE. ENDIF.
                WHEN 2. IF LS_JOB-OnWednesday = ABAP_TRUE. LV_W_DOW_OK = ABAP_TRUE. ENDIF.
                WHEN 3. IF LS_JOB-OnThursday  = ABAP_TRUE. LV_W_DOW_OK = ABAP_TRUE. ENDIF.
                WHEN 4. IF LS_JOB-OnFriday    = ABAP_TRUE. LV_W_DOW_OK = ABAP_TRUE. ENDIF.
                WHEN 5. IF LS_JOB-OnSaturday  = ABAP_TRUE. LV_W_DOW_OK = ABAP_TRUE. ENDIF.
                WHEN 6. IF LS_JOB-OnSunday    = ABAP_TRUE. LV_W_DOW_OK = ABAP_TRUE. ENDIF.
              ENDCASE.

              IF LV_W_DOW_OK = ABAP_FALSE.
                DATA(LV_W_DAY_NAME) = SWITCH STRING( LV_W_DOW
                  WHEN 0 THEN 'Monday'
                  WHEN 1 THEN 'Tuesday'
                  WHEN 2 THEN 'Wednesday'
                  WHEN 3 THEN 'Thursday'
                  WHEN 4 THEN 'Friday'
                  WHEN 5 THEN 'Saturday'
                  WHEN 6 THEN 'Sunday' ).
                APPEND VALUE #( %TKY = LS_JOB-%TKY ) TO FAILED-DRSJOBCONFIG.
                APPEND VALUE #( %TKY = LS_JOB-%TKY
                  %MSG = NEW_MESSAGE_WITH_TEXT(
                    SEVERITY = IF_ABAP_BEHV_MESSAGE=>SEVERITY-ERROR
                    TEXT = |Start date is a { LV_W_DAY_NAME } — it must fall on one of the selected weekdays| )
                  %ELEMENT-StartTimestamp = IF_ABAP_BEHV=>MK-ON )
                TO REPORTED-DRSJOBCONFIG.
              ENDIF.

              " 4a-WM: additionally validate week-of-month matches MonthWeekNumber.
              " SAP formula: week_number = (day DIV 7) + sign(day MOD 7)   [1-based]
              IF LS_JOB-PeriodicGranularity = 'WM' AND LV_W_DOW_OK = ABAP_TRUE.
                DATA(LV_WM_DAY)         = CONV I( LV_W_START_DATE+6(2) ).
                DATA(LV_WM_WEEK_NUMBER) = ( LV_WM_DAY DIV 7 ) + SIGN( LV_WM_DAY MOD 7 ).
                IF LV_WM_WEEK_NUMBER <> LS_JOB-MonthWeekNumber.
                  APPEND VALUE #( %TKY = LS_JOB-%TKY ) TO FAILED-DRSJOBCONFIG.
                  APPEND VALUE #( %TKY = LS_JOB-%TKY
                    %MSG = NEW_MESSAGE_WITH_TEXT(
                      SEVERITY = IF_ABAP_BEHV_MESSAGE=>SEVERITY-ERROR
                      TEXT = |Start date falls on week { LV_WM_WEEK_NUMBER } of the month — expected week { LS_JOB-MonthWeekNumber }| )
                    %ELEMENT-StartTimestamp = IF_ABAP_BEHV=>MK-ON )
                  TO REPORTED-DRSJOBCONFIG.
                ENDIF.
              ENDIF.
            ENDIF.
          ENDIF.

          " 4b. WM (Week-Month): requires MonthWeekNumber (1-5)
          "     WM does NOT use MonthDay — that is only for MO (Monthly)
          IF LS_JOB-PeriodicGranularity = 'WM'.
            " MonthWeekNumber is mandatory for WM
            IF LS_JOB-MonthWeekNumber <= 0 OR LS_JOB-MonthWeekNumber > 5.
              APPEND VALUE #( %TKY = LS_JOB-%TKY ) TO FAILED-DRSJOBCONFIG.
              APPEND VALUE #( %TKY = LS_JOB-%TKY
                %MSG = NEW_MESSAGE_WITH_TEXT(
                  SEVERITY = IF_ABAP_BEHV_MESSAGE=>SEVERITY-ERROR
                  TEXT = 'Week-Month jobs require a Week Number between 1 and 5 (5 = last week)' )
                %ELEMENT-MonthWeekNumber = IF_ABAP_BEHV=>MK-ON )
              TO REPORTED-DRSJOBCONFIG.
            ENDIF.
          ENDIF.

          " 4c. MO (Monthly): requires MonthDay (1-31); does NOT use weekday
          IF LS_JOB-PeriodicGranularity = 'MO'.
            IF LS_JOB-MonthDay <= 0 OR LS_JOB-MonthDay > 31.
              APPEND VALUE #( %TKY = LS_JOB-%TKY ) TO FAILED-DRSJOBCONFIG.
              APPEND VALUE #( %TKY = LS_JOB-%TKY
                %MSG = NEW_MESSAGE_WITH_TEXT(
                  SEVERITY = IF_ABAP_BEHV_MESSAGE=>SEVERITY-ERROR
                  TEXT = 'Monthly jobs require a Day of Month between 1 and 31' )
                %ELEMENT-MonthDay = IF_ABAP_BEHV=>MK-ON )
              TO REPORTED-DRSJOBCONFIG.
            ENDIF.
          ENDIF.

          " 5. Stop condition: exactly ONE of EndTimestamp / MaxIterations
          IF LS_JOB-EndTimestamp IS NOT INITIAL
            AND LS_JOB-MaxIterations IS NOT INITIAL AND LS_JOB-MaxIterations > 0.
            " Both filled → reject; user must choose one
            APPEND VALUE #( %TKY = LS_JOB-%TKY ) TO FAILED-DRSJOBCONFIG.
            APPEND VALUE #( %TKY = LS_JOB-%TKY
              %MSG = NEW_MESSAGE_WITH_TEXT(
                SEVERITY = IF_ABAP_BEHV_MESSAGE=>SEVERITY-ERROR
                TEXT = 'Provide either End Timestamp or Max Iterations, not both' )
              %ELEMENT-EndTimestamp  = IF_ABAP_BEHV=>MK-ON
              %ELEMENT-MaxIterations = IF_ABAP_BEHV=>MK-ON )
            TO REPORTED-DRSJOBCONFIG.
          ELSEIF LS_JOB-EndTimestamp IS INITIAL
            AND ( LS_JOB-MaxIterations IS INITIAL OR LS_JOB-MaxIterations <= 0 ).
            " Neither filled → reject; at least one is required
            APPEND VALUE #( %TKY = LS_JOB-%TKY ) TO FAILED-DRSJOBCONFIG.
            APPEND VALUE #( %TKY = LS_JOB-%TKY
              %MSG = NEW_MESSAGE_WITH_TEXT(
                SEVERITY = IF_ABAP_BEHV_MESSAGE=>SEVERITY-ERROR
                TEXT = 'Provide either Max Iterations (> 0) or an End Timestamp as stop condition' )
              %ELEMENT-MaxIterations = IF_ABAP_BEHV=>MK-ON )
            TO REPORTED-DRSJOBCONFIG.
          ENDIF.

          " 6. EndTimestamp: must be future and after StartTimestamp
          IF LS_JOB-EndTimestamp IS NOT INITIAL.
            IF LS_JOB-EndTimestamp <= LV_NOW.
              APPEND VALUE #( %TKY = LS_JOB-%TKY ) TO FAILED-DRSJOBCONFIG.
              APPEND VALUE #( %TKY = LS_JOB-%TKY
                %MSG = NEW_MESSAGE_WITH_TEXT(
                  SEVERITY = IF_ABAP_BEHV_MESSAGE=>SEVERITY-ERROR
                  TEXT = 'End Timestamp must be a future date and time' )
                %ELEMENT-EndTimestamp = IF_ABAP_BEHV=>MK-ON )
              TO REPORTED-DRSJOBCONFIG.
            ELSEIF LS_JOB-StartTimestamp IS NOT INITIAL
              AND LS_JOB-EndTimestamp <= LS_JOB-StartTimestamp.
              APPEND VALUE #( %TKY = LS_JOB-%TKY ) TO FAILED-DRSJOBCONFIG.
              APPEND VALUE #( %TKY = LS_JOB-%TKY
                %MSG = NEW_MESSAGE_WITH_TEXT(
                  SEVERITY = IF_ABAP_BEHV_MESSAGE=>SEVERITY-ERROR
                  TEXT = 'End Timestamp must be after Start Timestamp' )
                %ELEMENT-EndTimestamp = IF_ABAP_BEHV=>MK-ON )
              TO REPORTED-DRSJOBCONFIG.
            ELSEIF LS_JOB-StartTimestamp IS NOT INITIAL
              AND LS_JOB-PeriodicGranularity IS NOT INITIAL
              AND LS_JOB-PeriodicValue > 0.
              " Validate that time range covers at least one full periodic interval.
              " e.g. Start=5:00, End=5:30 with granularity=Day is meaningless.
              " MO/WM/W: skip fixed-interval range check.
              " MO/WM — APJ decides the actual run date based on MONTH_INFO.
              " W — multi-weekday runs (e.g. Mon+Wed+Fri) have variable intervals;
              " fixed 604800s check rejects valid short ranges. scheduleJob handles
              " W iteration count using weeks-based calculation instead.
              IF LS_JOB-PeriodicGranularity <> 'MO'
              AND LS_JOB-PeriodicGranularity <> 'WM'
              AND LS_JOB-PeriodicGranularity <> 'W'.
                DATA LV_VAL_DIFF     TYPE I.
                DATA LV_VAL_INTERVAL TYPE I.
                CLEAR LV_VAL_DIFF.
                CLEAR LV_VAL_INTERVAL.
                LV_VAL_DIFF = CL_ABAP_TSTMP=>SUBTRACT(
                  TSTMP1 = LS_JOB-EndTimestamp
                  TSTMP2 = LS_JOB-StartTimestamp ).

                CASE LS_JOB-PeriodicGranularity.
                  WHEN 'MI'. LV_VAL_INTERVAL = LS_JOB-PeriodicValue * 60.
                  WHEN 'H'.  LV_VAL_INTERVAL = LS_JOB-PeriodicValue * 3600.
                  WHEN 'D'.  LV_VAL_INTERVAL = LS_JOB-PeriodicValue * 86400.
                ENDCASE.

                IF LV_VAL_INTERVAL > 0 AND LV_VAL_DIFF < LV_VAL_INTERVAL.
                  APPEND VALUE #( %TKY = LS_JOB-%TKY ) TO FAILED-DRSJOBCONFIG.
                  APPEND VALUE #( %TKY = LS_JOB-%TKY
                    %MSG = NEW_MESSAGE(
                       ID       = 'ZMSG_PHONE_DEMO_DERS'
                       NUMBER   = '001'
                       SEVERITY = IF_ABAP_BEHV_MESSAGE=>SEVERITY-ERROR
                       V1       = 'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa'
                       V2       = LS_JOB-PeriodicGranularity )
                    %ELEMENT-EndTimestamp = IF_ABAP_BEHV=>MK-ON )
                  TO REPORTED-DRSJOBCONFIG.
                ENDIF.
              ENDIF.
            ENDIF.
          ENDIF.

      ENDCASE.
    ENDLOOP.
  ENDMETHOD.


  METHOD scheduleJob.
    " Read entities
    READ ENTITIES OF ZIR_DRS_JOB_CONFIG IN LOCAL MODE
      ENTITY DrsJobConfig
      ALL FIELDS
      WITH CORRESPONDING #( KEYS )
      RESULT DATA(LT_JOBS).

    LOOP AT LT_JOBS INTO DATA(LS_JOB).
      " Skip if already scheduled
      IF LS_JOB-JobName IS NOT INITIAL.
        APPEND VALUE #( %TKY = LS_JOB-%TKY ) TO FAILED-DRSJOBCONFIG.
        APPEND VALUE #( %TKY = LS_JOB-%TKY
          %MSG = NEW_MESSAGE_WITH_TEXT(
            SEVERITY = IF_ABAP_BEHV_MESSAGE=>SEVERITY-ERROR
            TEXT = 'Job is already scheduled' ) )
        TO REPORTED-DRSJOBCONFIG.
        CONTINUE.
      ENDIF.

      TRY.
          " Resolve user timezone — fallback to UTC if not set
          DATA(LV_JOB_TZ) = COND TIMEZONE(
            WHEN LS_JOB-Tmzone IS NOT INITIAL
            THEN LS_JOB-Tmzone ELSE 'UTC' ).

          " Build common job parameters (passed to execute() to identify the record)
          " JOB_UUID = primary lookup (unique binary key)
          " JOB_ID   = fallback lookup (unique auto-increment number)
          DATA(LV_UUID_STR) = CONV STRING( LS_JOB-JobUuid ).
          DATA(LT_PARAMETERS) = VALUE CL_APJ_RT_API=>TT_JOB_PARAMETER_VALUE(
            ( NAME = 'JOB_UUID'
              T_VALUE = VALUE #( ( SIGN = 'I' OPTION = 'EQ'
                                   LOW = CONV #( LV_UUID_STR ) ) ) )
            ( NAME = 'JOB_ID'
              T_VALUE = VALUE #( ( SIGN = 'I' OPTION = 'EQ'
                                   LOW = CONV #( LS_JOB-JobId ) ) ) ) ).

          DATA(LS_START_INFO)      = VALUE CL_APJ_RT_API=>TY_START_INFO( ).
          DATA(LS_SCHEDULING_INFO) = VALUE CL_APJ_RT_API=>TY_SCHEDULING_INFO( ).
          DATA(LS_END_INFO)        = VALUE CL_APJ_RT_API=>TY_END_INFO( ).
          DATA LV_JOBNAME  TYPE CL_APJ_RT_API=>TY_JOBNAME.
          DATA LV_JOBCOUNT TYPE CL_APJ_RT_API=>TY_JOBCOUNT.
          CLEAR LV_JOBNAME.
          CLEAR LV_JOBCOUNT.

          CASE LS_JOB-RunType.

              " Immediate: run right away, no scheduling
            WHEN 'I'.
              LS_START_INFO-START_IMMEDIATELY = ABAP_TRUE.

              MODIFY ENTITIES OF ZIR_DRS_JOB_CONFIG IN LOCAL MODE
                ENTITY DrsJobConfig
                UPDATE FIELDS ( StartImmediately IsPeriodic )
                WITH VALUE #( ( %TKY = LS_JOB-%TKY
                  StartImmediately = ABAP_TRUE
                  IsPeriodic       = ABAP_FALSE ) )
                REPORTED DATA(LT_UPDATE_REPORTED).

              CL_APJ_RT_API=>SCHEDULE_JOB(
                EXPORTING
                  IV_JOB_TEMPLATE_NAME   = LS_JOB-JobTemplateName
                  IV_JOB_TEXT            = LS_JOB-JobText
                  IS_START_INFO          = LS_START_INFO
                  IT_JOB_PARAMETER_VALUE = LT_PARAMETERS
                IMPORTING
                  EV_JOBNAME  = LV_JOBNAME
                  EV_JOBCOUNT = LV_JOBCOUNT ).

              " Once: one-time run at a specific timestamp
            WHEN 'O'.
              " Convert StartTimestamp: Fiori local to UTC (APJ expects UTC)
              DATA LV_S_DATE TYPE D.
              DATA LV_S_TIME TYPE T.
              DATA LV_S_UTC  TYPE TIMESTAMP.
              CLEAR LV_S_DATE.
              CLEAR LV_S_TIME.
              CLEAR LV_S_UTC.
              CONVERT TIME STAMP LS_JOB-StartTimestamp TIME ZONE 'UTC'
                INTO DATE LV_S_DATE TIME LV_S_TIME.
              CONVERT DATE LV_S_DATE TIME LV_S_TIME
                INTO TIME STAMP LV_S_UTC TIME ZONE LV_JOB_TZ.

              LS_START_INFO-START_IMMEDIATELY = ABAP_FALSE.
              LS_START_INFO-TIMESTAMP         = LV_S_UTC.

              MODIFY ENTITIES OF ZIR_DRS_JOB_CONFIG IN LOCAL MODE
                ENTITY DrsJobConfig
                UPDATE FIELDS ( StartImmediately IsPeriodic )
                WITH VALUE #( ( %TKY = LS_JOB-%TKY
                  StartImmediately = ABAP_FALSE
                  IsPeriodic       = ABAP_FALSE ) )
                REPORTED LT_UPDATE_REPORTED.

              CL_APJ_RT_API=>SCHEDULE_JOB(
                EXPORTING
                  IV_JOB_TEMPLATE_NAME   = LS_JOB-JobTemplateName
                  IV_JOB_TEXT            = LS_JOB-JobText
                  IS_START_INFO          = LS_START_INFO
                  IS_END_INFO            = LS_END_INFO
                  IT_JOB_PARAMETER_VALUE = LT_PARAMETERS
                IMPORTING
                  EV_JOBNAME  = LV_JOBNAME
                  EV_JOBCOUNT = LV_JOBCOUNT ).

              " Periodic: recurring job with granularity & stop
            WHEN 'P'.
              " Convert StartTimestamp: Fiori local to UTC
              DATA LV_P_START_DATE TYPE D.
              DATA LV_P_START_TIME TYPE T.
              DATA LV_P_START_UTC  TYPE TIMESTAMP.
              CLEAR LV_P_START_DATE.
              CLEAR LV_P_START_TIME.
              CLEAR LV_P_START_UTC.
              CONVERT TIME STAMP LS_JOB-StartTimestamp TIME ZONE 'UTC'
                INTO DATE LV_P_START_DATE TIME LV_P_START_TIME.
              CONVERT DATE LV_P_START_DATE TIME LV_P_START_TIME
                INTO TIME STAMP LV_P_START_UTC TIME ZONE LV_JOB_TZ.

              LS_START_INFO-START_IMMEDIATELY = ABAP_FALSE.
              LS_START_INFO-TIMESTAMP         = LV_P_START_UTC.

              " Build scheduling recurrence info
              LS_SCHEDULING_INFO-PERIODIC_GRANULARITY = LS_JOB-PeriodicGranularity.
              LS_SCHEDULING_INFO-PERIODIC_VALUE       = LS_JOB-PeriodicValue.
              LS_SCHEDULING_INFO-TIMEZONE             = LS_JOB-Tmzone.
              LS_SCHEDULING_INFO-TEST_MODE            = ABAP_FALSE.
              " Exception calendar: restrict job from running on non-working days
              IF LS_JOB-ExceptionCalendarId IS NOT INITIAL.
                LS_SCHEDULING_INFO-EXCEPTION = VALUE #(
                  CALENDER_ID            = LS_JOB-ExceptionCalendarId
                  START_RESTRICTION_CODE = LS_JOB-ExceptionRestrictionCode ).
              ENDIF.
              " W  (Weekly)     : weekday_info only
              " WM (Week-Month) : weekday_info + month_info.week_number
              " MO (Monthly)    : month_info.day only — no weekday_info
              IF LS_JOB-PeriodicGranularity = 'W'
              OR LS_JOB-PeriodicGranularity = 'WM'.
                LS_SCHEDULING_INFO-WEEKDAY_INFO = VALUE #(
                  ON_MONDAY    = LS_JOB-OnMonday
                  ON_TUESDAY   = LS_JOB-OnTuesday
                  ON_WEDNESDAY = LS_JOB-OnWednesday
                  ON_THURSDAY  = LS_JOB-OnThursday
                  ON_FRIDAY    = LS_JOB-OnFriday
                  ON_SATURDAY  = LS_JOB-OnSaturday
                  ON_SUNDAY    = LS_JOB-OnSunday ).
              ENDIF.

              " WM: month_info only needs WEEK_NUMBER (not DAY — DAY is for MO)
              IF LS_JOB-PeriodicGranularity = 'WM'.
                LS_SCHEDULING_INFO-MONTH_INFO = VALUE #(
                  WEEK_NUMBER = LS_JOB-MonthWeekNumber ).
              ENDIF.

              " MO: month_info uses DAY + working-day shift options (no WEEK_NUMBER)
              IF LS_JOB-PeriodicGranularity = 'MO'.
                LS_SCHEDULING_INFO-MONTH_INFO = VALUE #(
                  DAY                  = LS_JOB-MonthDay
                  USE_WORKING_DAYS_IND = LS_JOB-UseWorkingDays
                  SHIFT_DIRECTION      = LS_JOB-ShiftDirection ).
              ENDIF.

              " Build stop condition
              " ─────────────────────────────────────────────────────────────────────
              " Known limitations & design decisions:
              " ─────────────────────────────────────────────────────────────────────
              " 1. EndInfoType = 'DATE' does NOT work on this SAP TUM environment
              "    APJ ignores is_end_info-timestamp completely → job runs forever
              "    Workaround: always use type='NUM' (max_iterations) instead
              "
              " 2. CALC_ITER for granularity 'MO'/'WM'
              "    Uses calendar month difference instead of fixed seconds.
              "    Same-month range → allows at least 1 iteration.
              "
              " 3. "Run forever" mode NOT supported
              "    Validation enforces: must provide EndTimestamp OR MaxIterations > 0
              "    Prevents accidental infinite jobs consuming system resources.
              "
              " 4. EndInfoType field exists in DB/CDS/BDEF but not written
              "    Field 'end_info_type' is defined across all layers but code does
              "    not persist it (always leaves initial). Future enhancement candidate.
              " ─────────────────────────────────────────────────────────────────────

              IF LS_JOB-EndTimestamp IS NOT INITIAL.
                " Auto-calculate MaxIterations = (EndUTC - StartUTC) / interval_seconds
                DATA LV_P_END_DATE TYPE D.
                DATA LV_P_END_TIME TYPE T.
                DATA LV_P_END_UTC  TYPE TIMESTAMP.
                CLEAR LV_P_END_DATE.
                CLEAR LV_P_END_TIME.
                CLEAR LV_P_END_UTC.
                CONVERT TIME STAMP LS_JOB-EndTimestamp TIME ZONE 'UTC'
                  INTO DATE LV_P_END_DATE TIME LV_P_END_TIME.
                CONVERT DATE LV_P_END_DATE TIME LV_P_END_TIME
                  INTO TIME STAMP LV_P_END_UTC TIME ZONE LV_JOB_TZ.

                DATA LV_DIFF_SECS     TYPE I.
                DATA LV_INTERVAL_SECS TYPE I.
                DATA LV_CALC_ITER     TYPE I.
                CLEAR LV_DIFF_SECS.
                CLEAR LV_INTERVAL_SECS.
                CLEAR LV_CALC_ITER.
                LV_DIFF_SECS = CL_ABAP_TSTMP=>SUBTRACT(
                  TSTMP1 = LV_P_END_UTC
                  TSTMP2 = LV_P_START_UTC ).

                CASE LS_JOB-PeriodicGranularity.
                  WHEN 'MI'. LV_INTERVAL_SECS = LS_JOB-PeriodicValue * 60.
                  WHEN 'H'.  LV_INTERVAL_SECS = LS_JOB-PeriodicValue * 3600.
                  WHEN 'D'.  LV_INTERVAL_SECS = LS_JOB-PeriodicValue * 86400.
                ENDCASE.

                IF LS_JOB-PeriodicGranularity = 'W'.
                  " W (Weekly): count actual matching weekdays in [start..end] range.
                  " Old formula (total_weeks * selected_days) used integer division
                  " by 604800 → truncated to 0 for ranges < 7 days → only 1 iteration.
                  " New approach: loop day-by-day and count matching selected weekdays.
                  DATA LV_W_ITER_DATE TYPE D.
                  LV_W_ITER_DATE = LV_P_START_DATE.
                  LV_CALC_ITER = 0.
                  WHILE LV_W_ITER_DATE <= LV_P_END_DATE.
                    DATA(LV_W_ITER_DOW) = CL_APJ_FW_UTILITIES=>COMPUTE_DAY( IV_DATE = LV_W_ITER_DATE ).
                    CASE LV_W_ITER_DOW.
                      WHEN 1. IF LS_JOB-OnMonday    = ABAP_TRUE. LV_CALC_ITER = LV_CALC_ITER + 1. ENDIF.
                      WHEN 2. IF LS_JOB-OnTuesday   = ABAP_TRUE. LV_CALC_ITER = LV_CALC_ITER + 1. ENDIF.
                      WHEN 3. IF LS_JOB-OnWednesday = ABAP_TRUE. LV_CALC_ITER = LV_CALC_ITER + 1. ENDIF.
                      WHEN 4. IF LS_JOB-OnThursday  = ABAP_TRUE. LV_CALC_ITER = LV_CALC_ITER + 1. ENDIF.
                      WHEN 5. IF LS_JOB-OnFriday    = ABAP_TRUE. LV_CALC_ITER = LV_CALC_ITER + 1. ENDIF.
                      WHEN 6. IF LS_JOB-OnSaturday  = ABAP_TRUE. LV_CALC_ITER = LV_CALC_ITER + 1. ENDIF.
                      WHEN 7. IF LS_JOB-OnSunday    = ABAP_TRUE. LV_CALC_ITER = LV_CALC_ITER + 1. ENDIF.
                    ENDCASE.
                    LV_W_ITER_DATE = LV_W_ITER_DATE + 1.
                  ENDWHILE.
                ELSEIF LS_JOB-PeriodicGranularity = 'MO'
                OR LS_JOB-PeriodicGranularity = 'WM'.
                  " Month-based: dynamic calendar month difference (months vary 28-31 days)
                  DATA LV_SCH_MONTH_DIFF TYPE I.
                  LV_SCH_MONTH_DIFF =
                      ( LV_P_END_DATE+0(4) - LV_P_START_DATE+0(4) ) * 12
                    + ( LV_P_END_DATE+4(2) - LV_P_START_DATE+4(2) ).
                  LV_CALC_ITER = LV_SCH_MONTH_DIFF / LS_JOB-PeriodicValue.
                  " Same month: target run day may still fall within range → allow 1
                  IF LV_CALC_ITER <= 0.
                    LV_CALC_ITER = 1.
                  ENDIF.
                ELSEIF LV_INTERVAL_SECS > 0.
                  LV_CALC_ITER = LV_DIFF_SECS / LV_INTERVAL_SECS.
                ENDIF.

                " Guard: range must cover at least one full interval
                IF LV_CALC_ITER <= 0.
                  APPEND VALUE #( %TKY = LS_JOB-%TKY ) TO FAILED-DRSJOBCONFIG.
                  APPEND VALUE #( %TKY = LS_JOB-%TKY
                    %MSG = NEW_MESSAGE_WITH_TEXT(
                      SEVERITY = IF_ABAP_BEHV_MESSAGE=>SEVERITY-ERROR
                      TEXT = |End Timestamp is too close to Start Timestamp — time range must cover at least one full interval ({ LS_JOB-PeriodicValue } { LS_JOB-PeriodicGranularity })| ) )
                  TO REPORTED-DRSJOBCONFIG.
                  CONTINUE.
                ENDIF.

                LS_END_INFO-TYPE           = 'NUM'.
                LS_END_INFO-MAX_ITERATIONS = LV_CALC_ITER.
              ELSE.
                " No EndTimestamp — use manually entered MaxIterations
                LS_END_INFO-TYPE           = 'NUM'.
                LS_END_INFO-MAX_ITERATIONS = LS_JOB-MaxIterations.
              ENDIF.

              MODIFY ENTITIES OF ZIR_DRS_JOB_CONFIG IN LOCAL MODE
                ENTITY DrsJobConfig
                UPDATE FIELDS ( StartImmediately IsPeriodic )
                WITH VALUE #( ( %TKY = LS_JOB-%TKY
                  StartImmediately = ABAP_FALSE
                  IsPeriodic       = ABAP_TRUE ) )
                REPORTED LT_UPDATE_REPORTED.

              " === MANUAL DATE SHIFT WORKAROUND ===
              " CL_APJ_RT_API does not expose IV_ADJUST_START_INFO.
              " Server validates weekday (W) or weekday+week_number (WM)
              " in the SCHEDULING timezone — so we must check and shift
              " in LV_JOB_TZ (not UTC!) to match the server's logic.
              IF LS_JOB-PeriodicGranularity = 'W'.
                " ── W (Weekly): shift forward until UTC date in scheduling TZ matches a selected weekday ──
                DATA LV_SHIFT_DOW TYPE I.
                DATA LV_SHIFT_DATE TYPE D.
                DATA LV_SHIFT_TIME TYPE T.
                CLEAR LV_SHIFT_DOW.
                CLEAR LV_SHIFT_DATE.
                CLEAR LV_SHIFT_TIME.
                CONVERT TIME STAMP LS_START_INFO-TIMESTAMP TIME ZONE LV_JOB_TZ
                  INTO DATE LV_SHIFT_DATE TIME LV_SHIFT_TIME.

                DO 7 TIMES.
                  DATA(LV_TEST_DOW) = CL_APJ_FW_UTILITIES=>COMPUTE_DAY( IV_DATE = LV_SHIFT_DATE ).
                  DATA(LV_MATCH)    = ABAP_FALSE.
                  CASE LV_TEST_DOW.
                    WHEN 1. IF LS_JOB-OnMonday    = ABAP_TRUE.
                    LV_MATCH = ABAP_TRUE.
                    ENDIF.
                    WHEN 2. IF LS_JOB-OnTuesday   = ABAP_TRUE.
                    LV_MATCH = ABAP_TRUE.
                    ENDIF.
                    WHEN 3. IF LS_JOB-OnWednesday = ABAP_TRUE.
                    LV_MATCH = ABAP_TRUE.
                    ENDIF.
                    WHEN 4. IF LS_JOB-OnThursday  = ABAP_TRUE.
                    LV_MATCH = ABAP_TRUE.
                    ENDIF.
                    WHEN 5. IF LS_JOB-OnFriday    = ABAP_TRUE.
                    LV_MATCH = ABAP_TRUE.
                    ENDIF.
                    WHEN 6. IF LS_JOB-OnSaturday  = ABAP_TRUE.
                    LV_MATCH = ABAP_TRUE.
                    ENDIF.
                    WHEN 7. IF LS_JOB-OnSunday    = ABAP_TRUE.
                    LV_MATCH = ABAP_TRUE.
                    ENDIF.
                  ENDCASE.
                  IF LV_MATCH = ABAP_TRUE.
                    CONVERT DATE LV_SHIFT_DATE TIME LV_SHIFT_TIME
                      INTO TIME STAMP LS_START_INFO-TIMESTAMP TIME ZONE LV_JOB_TZ.
                    EXIT.
                  ENDIF.
                  LV_SHIFT_DATE = LV_SHIFT_DATE + 1.
                ENDDO.

              ELSEIF LS_JOB-PeriodicGranularity = 'WM'.
                " ── WM (Week-Month): find the matching weekday in the target week of month ──
                " Mirrors server logic in __check_and_adjust_week_month:
                "   1. Start from day 1 of the month (in scheduling TZ)
                "   2. Find first matching weekday within first 7 days
                "   3. Jump to target week: date + 7 * (week_number - 1)
                "   4. If past → try next month
                DATA LV_WM_SHIFT_DATE TYPE D.
                DATA LV_WM_SHIFT_TIME TYPE T.
                DATA LV_WM_FOUND      TYPE ABAP_BOOL.
                CLEAR LV_WM_SHIFT_DATE.
                CLEAR LV_WM_SHIFT_TIME.
                LV_WM_FOUND = ABAP_FALSE.
                CONVERT TIME STAMP LS_START_INFO-TIMESTAMP TIME ZONE LV_JOB_TZ
                  INTO DATE LV_WM_SHIFT_DATE TIME LV_WM_SHIFT_TIME.

                DATA LV_WM_ORIG_DATE TYPE D.
                LV_WM_ORIG_DATE = LV_WM_SHIFT_DATE.

                " Try current month, then next month
                DO 2 TIMES.
                  DATA LV_WM_FIRST TYPE D.
                  LV_WM_FIRST = LV_WM_SHIFT_DATE.
                  LV_WM_FIRST+6(2) = '01'.      " go to 1st of month

                  IF SY-INDEX = 2.
                    " Shift to next month
                    DATA(LV_WM_MON) = CONV I( LV_WM_FIRST+4(2) ) + 1.
                    DATA(LV_WM_YR)  = CONV I( LV_WM_FIRST+0(4) ).
                    IF LV_WM_MON > 12.
                      LV_WM_MON = 1.
                      LV_WM_YR  = LV_WM_YR + 1.
                    ENDIF.
                    LV_WM_FIRST+0(4) = CONV #( LV_WM_YR ).
                    LV_WM_FIRST+4(2) = CONV #( LV_WM_MON ).
                  ENDIF.

                  " Find first matching weekday from day 1
                  DO 7 TIMES.
                    DATA(LV_WM_TRY_DATE) = CONV D( LV_WM_FIRST + SY-INDEX - 1 ).
                    DATA(LV_WM_DOW)      = CL_APJ_FW_UTILITIES=>COMPUTE_DAY( IV_DATE = LV_WM_TRY_DATE ).
                    DATA(LV_WM_DAY_OK)   = ABAP_FALSE.
                    CASE LV_WM_DOW.
                      WHEN 1. IF LS_JOB-OnMonday    = ABAP_TRUE. LV_WM_DAY_OK = ABAP_TRUE. ENDIF.
                      WHEN 2. IF LS_JOB-OnTuesday   = ABAP_TRUE. LV_WM_DAY_OK = ABAP_TRUE. ENDIF.
                      WHEN 3. IF LS_JOB-OnWednesday = ABAP_TRUE. LV_WM_DAY_OK = ABAP_TRUE. ENDIF.
                      WHEN 4. IF LS_JOB-OnThursday  = ABAP_TRUE. LV_WM_DAY_OK = ABAP_TRUE. ENDIF.
                      WHEN 5. IF LS_JOB-OnFriday    = ABAP_TRUE. LV_WM_DAY_OK = ABAP_TRUE. ENDIF.
                      WHEN 6. IF LS_JOB-OnSaturday  = ABAP_TRUE. LV_WM_DAY_OK = ABAP_TRUE. ENDIF.
                      WHEN 7. IF LS_JOB-OnSunday    = ABAP_TRUE. LV_WM_DAY_OK = ABAP_TRUE. ENDIF.
                    ENDCASE.

                    IF LV_WM_DAY_OK = ABAP_TRUE.
                      " Jump to target week: week_number 5 = last week (always +28)
                      DATA LV_WM_TARGET TYPE D.
                      IF LS_JOB-MonthWeekNumber = 5.
                        LV_WM_TARGET = LV_WM_TRY_DATE + 28.
                      ELSE.
                        LV_WM_TARGET = LV_WM_TRY_DATE
                          + 7 * ( NMIN( VAL1 = 4 VAL2 = CONV I( LS_JOB-MonthWeekNumber ) ) - 1 ).
                      ENDIF.

                      " Only accept if date is not in the past
                      IF LV_WM_TARGET >= LV_WM_ORIG_DATE.
                        CONVERT DATE LV_WM_TARGET TIME LV_WM_SHIFT_TIME
                          INTO TIME STAMP LS_START_INFO-TIMESTAMP TIME ZONE LV_JOB_TZ.
                        LV_WM_FOUND = ABAP_TRUE.
                        EXIT.  " exit inner DO 7
                      ENDIF.
                    ENDIF.
                  ENDDO.

                  IF LV_WM_FOUND = ABAP_TRUE.
                    EXIT.  " exit outer DO 2
                  ENDIF.
                ENDDO.
              ENDIF.

              CL_APJ_RT_API=>SCHEDULE_JOB(
                EXPORTING
                  IV_JOB_TEMPLATE_NAME   = LS_JOB-JobTemplateName
                  IV_JOB_TEXT            = LS_JOB-JobText
                  IS_START_INFO          = LS_START_INFO
                  IS_SCHEDULING_INFO     = LS_SCHEDULING_INFO
                  IS_END_INFO            = LS_END_INFO
                  IT_JOB_PARAMETER_VALUE = LT_PARAMETERS
                IMPORTING
                  EV_JOBNAME  = LV_JOBNAME
                  EV_JOBCOUNT = LV_JOBCOUNT ).

          ENDCASE.

          " Get initial job status
          CL_APJ_RT_API=>GET_JOB_STATUS(
            EXPORTING
              IV_JOBNAME = LV_JOBNAME
              IV_JOBCOUNT = LV_JOBCOUNT
            IMPORTING
              EV_JOB_STATUS = DATA(LV_STATUS)
              EV_JOB_STATUS_TEXT = DATA(LV_STATUS_TEXT) ).

          " Update entity with job details
          MODIFY ENTITIES OF ZIR_DRS_JOB_CONFIG IN LOCAL MODE
            ENTITY DrsJobConfig
            UPDATE FIELDS ( JobName JobCount JobStatus JobStatusText Message )
            WITH VALUE #( ( %TKY = LS_JOB-%TKY
              JobName = LV_JOBNAME
              JobCount = LV_JOBCOUNT
              JobStatus = LV_STATUS
              JobStatusText = LV_STATUS_TEXT
              Message = |Job scheduled successfully| ) )
            REPORTED DATA(LT_REPORTED).

          " Show success toast on Fiori UI
          APPEND VALUE #( %TKY = LS_JOB-%TKY
            %MSG = NEW_MESSAGE_WITH_TEXT(
              SEVERITY = IF_ABAP_BEHV_MESSAGE=>SEVERITY-SUCCESS
              TEXT = |Job ID { CONV I( LS_JOB-JobId ) } scheduled successfully| ) )
          TO REPORTED-DRSJOBCONFIG.

        CATCH CX_APJ_RT INTO DATA(LX_APJ).
          " GET_TEXT() returns generic 'An exception was raised' when CX_APJ_RT is
          " raised via EXPORTING bapimsg = ... (the path used by CL_APJ_RT_API).
          " Use GET_BAPIRET2()-MESSAGE first (already T100-formatted by SAP),
          " then fall back to GET_LONGTEXT(), then GET_TEXT().
          DATA(LV_BAPI_MSG) = LX_APJ->GET_BAPIRET2( ).
          DATA(LV_LONGTEXT) = LX_APJ->GET_LONGTEXT( ).
          DATA(LV_ERR_TEXT) = COND STRING(
            WHEN LV_BAPI_MSG-MESSAGE IS NOT INITIAL THEN LV_BAPI_MSG-MESSAGE
            WHEN LV_LONGTEXT          IS NOT INITIAL THEN LV_LONGTEXT
            ELSE LX_APJ->GET_TEXT( ) ).
          APPEND VALUE #( %TKY = LS_JOB-%TKY ) TO FAILED-DRSJOBCONFIG.
          APPEND VALUE #( %TKY = LS_JOB-%TKY
            %MSG = NEW_MESSAGE_WITH_TEXT(
              SEVERITY = IF_ABAP_BEHV_MESSAGE=>SEVERITY-ERROR
              TEXT = LV_ERR_TEXT ) )
          TO REPORTED-DRSJOBCONFIG.
        CATCH CX_ROOT INTO DATA(LX_ROOT).
          APPEND VALUE #( %TKY = LS_JOB-%TKY ) TO FAILED-DRSJOBCONFIG.
          APPEND VALUE #( %TKY = LS_JOB-%TKY
            %MSG = NEW_MESSAGE_WITH_TEXT(
              SEVERITY = IF_ABAP_BEHV_MESSAGE=>SEVERITY-ERROR
              TEXT = LX_ROOT->GET_TEXT( ) ) )
          TO REPORTED-DRSJOBCONFIG.
      ENDTRY.
    ENDLOOP.

    " Return result
    READ ENTITIES OF ZIR_DRS_JOB_CONFIG IN LOCAL MODE
      ENTITY DrsJobConfig
      ALL FIELDS
      WITH CORRESPONDING #( KEYS )
      RESULT DATA(LT_RESULT).

    RESULT = VALUE #( FOR LS_RESULT IN LT_RESULT
      ( %TKY = LS_RESULT-%TKY
        %PARAM = LS_RESULT ) ).
  ENDMETHOD.


  METHOD cancelJob.
    " Read entities
    READ ENTITIES OF ZIR_DRS_JOB_CONFIG IN LOCAL MODE
      ENTITY DrsJobConfig
      ALL FIELDS
      WITH CORRESPONDING #( KEYS )
      RESULT DATA(LT_JOBS).

    LOOP AT LT_JOBS INTO DATA(LS_JOB).
      " Skip if not scheduled
      IF LS_JOB-JobName IS INITIAL.
        APPEND VALUE #( %TKY = LS_JOB-%TKY ) TO FAILED-DRSJOBCONFIG.
        APPEND VALUE #( %TKY = LS_JOB-%TKY
          %MSG = NEW_MESSAGE_WITH_TEXT(
            SEVERITY = IF_ABAP_BEHV_MESSAGE=>SEVERITY-ERROR
            TEXT = 'Job is not scheduled' ) )
        TO REPORTED-DRSJOBCONFIG.
        CONTINUE.
      ENDIF.

      TRY.
          " Cancel the job using SAP standard API
          CL_APJ_RT_API=>CANCEL_JOB(
            EXPORTING
              IV_JOBNAME  = LS_JOB-JobName
              IV_JOBCOUNT = LS_JOB-JobCount ).

          " Fetch the actual status from SAP after cancel
          " (avoids hardcoding 'A' — SAP may return 'C', 'A', etc.)
          DATA LV_CANCEL_STATUS      TYPE CL_APJ_RT_API=>TY_JOB_STATUS.
          DATA LV_CANCEL_STATUS_TEXT TYPE CL_APJ_RT_API=>TY_JOB_STATUS_TEXT.
          TRY.
              CL_APJ_RT_API=>GET_JOB_STATUS(
                EXPORTING
                  IV_JOBNAME         = LS_JOB-JobName
                  IV_JOBCOUNT        = LS_JOB-JobCount
                IMPORTING
                  EV_JOB_STATUS      = LV_CANCEL_STATUS
                  EV_JOB_STATUS_TEXT = LV_CANCEL_STATUS_TEXT ).
            CATCH CX_APJ_RT.
              " Fallback if status fetch fails right after cancel
              LV_CANCEL_STATUS      = 'A'.
              LV_CANCEL_STATUS_TEXT = 'Cancelled'.
          ENDTRY.

          " Update entity with real status returned by SAP
          MODIFY ENTITIES OF ZIR_DRS_JOB_CONFIG IN LOCAL MODE
            ENTITY DrsJobConfig
            UPDATE FIELDS ( JobStatus JobStatusText Message )
            WITH VALUE #( ( %TKY = LS_JOB-%TKY
              JobStatus     = LV_CANCEL_STATUS
              JobStatusText = LV_CANCEL_STATUS_TEXT
              Message       = |Job cancelled successfully| ) )
            REPORTED DATA(LT_REPORTED).

        CATCH CX_APJ_RT INTO DATA(LX_APJ).
          DATA(LV_CANCEL_BAPI_MSG) = LX_APJ->GET_BAPIRET2( ).
          DATA(LV_CANCEL_LONGTEXT) = LX_APJ->GET_LONGTEXT( ).
          DATA(LV_CANCEL_ERR_TEXT) = COND STRING(
            WHEN LV_CANCEL_BAPI_MSG-MESSAGE IS NOT INITIAL THEN LV_CANCEL_BAPI_MSG-MESSAGE
            WHEN LV_CANCEL_LONGTEXT          IS NOT INITIAL THEN LV_CANCEL_LONGTEXT
            ELSE LX_APJ->GET_TEXT( ) ).
          APPEND VALUE #( %TKY = LS_JOB-%TKY ) TO FAILED-DRSJOBCONFIG.
          APPEND VALUE #( %TKY = LS_JOB-%TKY
            %MSG = NEW_MESSAGE_WITH_TEXT(
              SEVERITY = IF_ABAP_BEHV_MESSAGE=>SEVERITY-ERROR
              TEXT = LV_CANCEL_ERR_TEXT ) )
          TO REPORTED-DRSJOBCONFIG.
        CATCH CX_ROOT INTO DATA(LX_CANCEL_ROOT).
          APPEND VALUE #( %TKY = LS_JOB-%TKY ) TO FAILED-DRSJOBCONFIG.
          APPEND VALUE #( %TKY = LS_JOB-%TKY
            %MSG = NEW_MESSAGE_WITH_TEXT(
              SEVERITY = IF_ABAP_BEHV_MESSAGE=>SEVERITY-ERROR
              TEXT = LX_CANCEL_ROOT->GET_TEXT( ) ) )
          TO REPORTED-DRSJOBCONFIG.
      ENDTRY.
    ENDLOOP.

    " Return result
    READ ENTITIES OF ZIR_DRS_JOB_CONFIG IN LOCAL MODE
      ENTITY DrsJobConfig
      ALL FIELDS
      WITH CORRESPONDING #( KEYS )
      RESULT DATA(LT_RESULT).

    RESULT = VALUE #( FOR LS_RESULT IN LT_RESULT
      ( %TKY = LS_RESULT-%TKY
        %PARAM = LS_RESULT ) ).
  ENDMETHOD.


  METHOD refreshStatus.
    " Read entities
    READ ENTITIES OF ZIR_DRS_JOB_CONFIG IN LOCAL MODE
      ENTITY DrsJobConfig
      ALL FIELDS
      WITH CORRESPONDING #( KEYS )
      RESULT DATA(LT_JOBS).

    LOOP AT LT_JOBS INTO DATA(LS_JOB).
      " Skip if not scheduled
      IF LS_JOB-JobName IS INITIAL.
        CONTINUE.
      ENDIF.

      TRY.
          " Get current job status using SAP standard API
          CL_APJ_RT_API=>GET_JOB_STATUS(
            EXPORTING
              IV_JOBNAME = LS_JOB-JobName
              IV_JOBCOUNT = LS_JOB-JobCount
            IMPORTING
              EV_JOB_STATUS = DATA(LV_STATUS)
              EV_JOB_STATUS_TEXT = DATA(LV_STATUS_TEXT) ).

          " Update entity status
          MODIFY ENTITIES OF ZIR_DRS_JOB_CONFIG IN LOCAL MODE
            ENTITY DrsJobConfig
            UPDATE FIELDS ( JobStatus JobStatusText )
            WITH VALUE #( ( %TKY = LS_JOB-%TKY
              JobStatus = LV_STATUS
              JobStatusText = LV_STATUS_TEXT ) )
            REPORTED DATA(LT_REPORTED).

        CATCH CX_APJ_RT INTO DATA(LX_REFRESH_APJ).
          " Log error but don't fail — use same priority chain as scheduleJob/cancelJob
          DATA(LV_REFRESH_BAPI) = LX_REFRESH_APJ->GET_BAPIRET2( ).
          DATA(LV_REFRESH_LT)   = LX_REFRESH_APJ->GET_LONGTEXT( ).
          DATA(LV_REFRESH_MSG)  = COND STRING(
            WHEN LV_REFRESH_BAPI-MESSAGE IS NOT INITIAL THEN LV_REFRESH_BAPI-MESSAGE
            WHEN LV_REFRESH_LT           IS NOT INITIAL THEN LV_REFRESH_LT
            ELSE LX_REFRESH_APJ->GET_TEXT( ) ).
          MODIFY ENTITIES OF ZIR_DRS_JOB_CONFIG IN LOCAL MODE
            ENTITY DrsJobConfig
            UPDATE FIELDS ( Message )
            WITH VALUE #( ( %TKY = LS_JOB-%TKY
              Message = LV_REFRESH_MSG ) )
            REPORTED LT_REPORTED.
        CATCH CX_ROOT INTO DATA(LX_REFRESH_ROOT).
          " Unexpected exception — log root text, don't fail UI
          MODIFY ENTITIES OF ZIR_DRS_JOB_CONFIG IN LOCAL MODE
            ENTITY DrsJobConfig
            UPDATE FIELDS ( Message )
            WITH VALUE #( ( %TKY = LS_JOB-%TKY
              Message = LX_REFRESH_ROOT->GET_TEXT( ) ) )
            REPORTED LT_REPORTED.
      ENDTRY.
    ENDLOOP.

    " Return result
    READ ENTITIES OF ZIR_DRS_JOB_CONFIG IN LOCAL MODE
      ENTITY DrsJobConfig
      ALL FIELDS
      WITH CORRESPONDING #( KEYS )
      RESULT DATA(LT_RESULT).

    RESULT = VALUE #( FOR LS_RESULT IN LT_RESULT
      ( %TKY = LS_RESULT-%TKY
        %PARAM = LS_RESULT ) ).
  ENDMETHOD.

ENDCLASS.
