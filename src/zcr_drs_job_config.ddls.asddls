@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Job Config Projection'
@Metadata.ignorePropagatedAnnotations: false
@Metadata.allowExtensions: true
define root view entity ZCR_DRS_JOB_CONFIG
  provider contract transactional_query
  as projection on ZIR_DRS_JOB_CONFIG
{
  key     JobUuid,
          JobId,
          SubscrUuid,
          SubscrId,
          RunType,
          JobText,
          JobTemplateName,
          JobName,
          JobCount,
          StartImmediately,
          StartTimestamp,
          IsPeriodic,
          PeriodicGranularity,
          PeriodicValue,
          Tmzone,
          EndTimestamp,
          MaxIterations,
          OnMonday,
          OnTuesday,
          OnWednesday,
          OnThursday,
          OnFriday,
          OnSaturday,
          OnSunday,
          JobStatus,
          JobStatusCriticality,
          JobStatusText,
          Message,
          CreatedBy,
          CreatedAt,
          LastChangedBy,
          LastChangedAt,
          LocalLastChangedAt,
          MonthDay,
          UseWorkingDays,
          ShiftDirection,
          MonthWeekNumber,
          ExceptionCalendarId,
          EndInfoType,
          ExceptionRestrictionCode,
          ScheduledStartDate,

          /* Associations */
          _File         : redirected to composition child ZC_DRS_FILE,
          _Subscription : redirected to ZCR_DRS_SUBSCR
}
