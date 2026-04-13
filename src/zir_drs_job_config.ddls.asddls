@AccessControl.authorizationCheck: #CHECK
@EndUserText.label: 'Job Config Root Entity'
@Metadata.ignorePropagatedAnnotations: true

define root view entity ZIR_DRS_JOB_CONFIG
  as select from zdrs_job_config as JobConfig
  composition [0..*] of ZI_DRS_FILE        as _File
  composition [0..*] of ZI_DRS_JOB_HISTORY as _JobHistory
  association [0..1] to ZIR_DRS_SUBSCR     as _Subscription on  $projection.SubscrUuid = _Subscription.SubscrUuid
                                                            and $projection.SubscrId   = _Subscription.SubscrId
{
  key job_uuid                                                    as JobUuid,
      job_id                                                      as JobId,
      subscr_id                                                   as SubscrId,
      subscr_uuid                                                 as SubscrUuid,
      run_type                                                    as RunType,
      job_text                                                    as JobText,
      job_template_name                                           as JobTemplateName,
      job_name                                                    as JobName,
      job_count                                                   as JobCount,
      start_immediately                                           as StartImmediately,
      start_timestamp                                             as StartTimestamp,
      is_periodic                                                 as IsPeriodic,
      periodic_granularity                                        as PeriodicGranularity,
      periodic_value                                              as PeriodicValue,
      tmzone                                                      as Tmzone,
      end_timestamp                                               as EndTimestamp,
      max_iterations                                              as MaxIterations,
      on_monday                                                   as OnMonday,
      on_tuesday                                                  as OnTuesday,
      on_wednesday                                                as OnWednesday,
      on_thursday                                                 as OnThursday,
      on_friday                                                   as OnFriday,
      on_saturday                                                 as OnSaturday,
      on_sunday                                                   as OnSunday,
      month_day                                                   as MonthDay,
      use_working_days                                            as UseWorkingDays,
      shift_direction                                             as ShiftDirection,
      month_week_number                                           as MonthWeekNumber,
      exception_calendar_id                                       as ExceptionCalendarId,
      end_info_type                                               as EndInfoType,
      exception_restriction_code                                  as ExceptionRestrictionCode,
      message                                                     as Message,
      job_status_text                                             as JobStatusText,
      job_status                                                  as JobStatus,

      @Semantics.user.createdBy: true
      created_by                                                  as CreatedBy,

      @Semantics.systemDateTime.createdAt: true
      created_at                                                  as CreatedAt,

      @Semantics.user.lastChangedBy: true
      last_changed_by                                             as LastChangedBy,

      @Semantics.systemDateTime.lastChangedAt: true
      last_changed_at                                             as LastChangedAt,

      @Semantics.systemDateTime.localInstanceLastChangedAt: true
      local_last_changed_at                                       as LocalLastChangedAt,

      case job_status
      when 'F' then 3  // Finished = Green
      when 'S' then 5  // Scheduled = Blue
      when 'C' then 2  // Cancel = Yellow
      when 'A' then 1  // Failed = Red
      else 0
      end                                                         as JobStatusCriticality,

      cast( substring( cast( created_at as abap.char(23) ), 1, 8 )
      as abap.dats )                                              as JobDate,

      // Association
      _File,
      _JobHistory,
      _Subscription
}
