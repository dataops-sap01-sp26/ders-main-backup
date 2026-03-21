@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Job Config Projection'
//@Metadata.ignorePropagatedAnnotations: false
@Metadata.allowExtensions: true
define root view entity ZC_DRS_JOB_CONFIG
  provider contract transactional_query
  as projection on ZR_DRS_JOB_CONFIG
{
  key     JobUuid,
          JobId,
          SubscrUuid,
          SubscrId,
          _Subscription.ReportId,
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
          @ObjectModel.virtualElement: true
          @ObjectModel.virtualElementCalculatedBy: 'ABAP:ZCL_DYNAMIC_FIELD_JOB_CONFIG'
  virtual HideGL01 : abap_boolean,

//          @ObjectModel.virtualElement: true
//          @ObjectModel.virtualElementCalculatedBy: 'ABAP:ZCL_DYNAMIC_FIELD_JOB_CONFIG'
//  virtual HideGL02 : abap_boolean,

          /* Associations */
          _File         : redirected to composition child ZC_DRS_FILE,
          _Subscription : redirected to ZC_DRS_SUBSCR
}
